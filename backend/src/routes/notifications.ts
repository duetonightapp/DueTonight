import { Router, Request, Response } from 'express';
import { prisma } from '../services/db.service';
import webpush from 'web-push';
import dotenv from 'dotenv';

dotenv.config();

const router = Router();

const vapidPublicKey = process.env.VAPID_PUBLIC_KEY || '';
const vapidPrivateKey = process.env.VAPID_PRIVATE_KEY || '';

if (vapidPublicKey && vapidPrivateKey) {
  webpush.setVapidDetails(
    'mailto:support@duetonight.app',
    vapidPublicKey,
    vapidPrivateKey
  );
} else {
  console.warn('Warning: VAPID keys not configured in backend environment.');
}

// POST /api/notifications/notify
router.post('/notify', async (req: Request, res: Response) => {
  const { roomId, type, title, details, uploaderName, uploaderId } = req.body;

  if (!roomId || !type || !title || !uploaderName) {
    return res.status(400).json({ error: 'Missing required parameters (roomId, type, title, uploaderName)' });
  }

  try {
    console.log(`Notification request received for room ${roomId}, type: ${type}`);
    
    // 1. Fetch all members of the room using Prisma raw query to bypass RLS
    const members = await prisma.$queryRaw<{ user_id: string }[]>`
      SELECT user_id FROM public.room_members WHERE room_id = ${roomId}::uuid
    `;

    if (!members || members.length === 0) {
      return res.status(200).json({ status: 'No members in room' });
    }

    // 2. Filter out the uploader
    const recipientIds = members
      .map((m) => m.user_id)
      .filter((id) => id !== uploaderId);

    if (recipientIds.length === 0) {
      return res.status(200).json({ status: 'No recipients (only uploader is in the room)' });
    }

    // 3. Fetch push subscriptions for the recipients
    const subscriptions = await prisma.$queryRaw<{ id: string; user_id: string; endpoint: string; p256dh: string; auth: string }[]>`
      SELECT id, user_id, endpoint, p256dh, auth FROM public.push_subscriptions WHERE user_id = ANY(${recipientIds}::uuid[])
    `;

    if (!subscriptions || subscriptions.length === 0) {
      return res.status(200).json({ status: 'No active push subscriptions' });
    }

    // 4. Send push notifications
    const payload = JSON.stringify({
      title: `${uploaderName} uploaded a new ${type}`,
      body: `${title}${details ? ': ' + details : ''}`,
      url: `/rooms/${roomId}`
    });

    console.log(`Broadcasting push notification to ${subscriptions.length} subscriptions...`);

    const promises = subscriptions.map(async (sub) => {
      const pushSubscription = {
        endpoint: sub.endpoint,
        keys: {
          p256dh: sub.p256dh,
          auth: sub.auth
        }
      };

      try {
        await webpush.sendNotification(pushSubscription, payload);
      } catch (err: any) {
        console.error(`Failed to send notification to subscription ${sub.id}:`, err.message);
        // If subscription is expired or unsubscribed, remove it from the DB
        if (err.statusCode === 410 || err.statusCode === 404) {
          console.log(`Deleting expired subscription: ${sub.id}`);
          await prisma.$queryRaw`
            DELETE FROM public.push_subscriptions WHERE id = ${sub.id}::uuid
          `;
        }
      }
    });

    await Promise.all(promises);

    return res.status(200).json({ status: 'Notifications sent successfully' });
  } catch (error: any) {
    console.error('Error sending push notifications:', error);
    return res.status(500).json({ error: 'Internal server error while sending notifications' });
  }
});

export default router;
