import type { VercelRequest, VercelResponse } from '@vercel/node';
import { Client } from 'pg';
import webpush from 'web-push';

const databaseUrl =
  process.env.DATABASE_URL ||
  'postgresql://postgres:HotgHGEQypvRXXWb@db.tdotndrapfawgljyzrkn.supabase.co:5432/postgres';
const vapidPublicKey =
  process.env.VAPID_PUBLIC_KEY ||
  'BJD0k-xLMppRIu6ARcTQVCpO17S-ZVS-TW6AgyCDOqX7Lzl_yQY1v4eeWGodRHibzSGaodeYtjid8lSU2qKIDVI';
const vapidPrivateKey =
  process.env.VAPID_PRIVATE_KEY ||
  'fkb_Wjq4Dvt75gvG_mKUKWI0yNgUmCacRIz7RAukSWM';

webpush.setVapidDetails(
  'mailto:support@duetonight.app',
  vapidPublicKey,
  vapidPrivateKey
);

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { roomId, type, title, details, uploaderName, uploaderId } = req.body || {};

  if (!roomId || !type || !title || !uploaderName) {
    return res.status(400).json({ error: 'Missing required parameters' });
  }

  const client = new Client({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
  });

  try {
    await client.connect();

    // 1. Fetch room members
    const membersRes = await client.query(
      'SELECT user_id FROM public.room_members WHERE room_id = $1::uuid',
      [roomId]
    );

    if (membersRes.rows.length === 0) {
      await client.end();
      return res.status(200).json({ status: 'No members in room' });
    }

    // 2. Filter out the uploader
    const recipientIds = membersRes.rows
      .map((m: any) => m.user_id)
      .filter((id: string) => id !== uploaderId);

    if (recipientIds.length === 0) {
      await client.end();
      return res.status(200).json({ status: 'No recipients (only uploader in room)' });
    }

    // 3. Fetch push subscriptions
    const subsRes = await client.query(
      'SELECT id, user_id, endpoint, p256dh, auth FROM public.push_subscriptions WHERE user_id = ANY($1::uuid[])',
      [recipientIds]
    );

    if (subsRes.rows.length === 0) {
      await client.end();
      return res.status(200).json({ status: 'No active push subscriptions' });
    }

    let notificationTitle = `${uploaderName} posted an update`;
    if (type === 'assignment') {
      notificationTitle = `New Assignment from ${uploaderName}`;
    } else if (type === 'announcement') {
      notificationTitle = `New Announcement from ${uploaderName}`;
    } else if (type === 'solution') {
      notificationTitle = `New Solution from ${uploaderName}`;
    }

    const payload = JSON.stringify({
      title: notificationTitle,
      body: `${title}${details ? ': ' + details : ''}`,
      url: `/rooms/${roomId}`,
    });

    const deleteIds: string[] = [];
    const sendPromises = subsRes.rows.map(async (sub: any) => {
      try {
        await webpush.sendNotification(
          {
            endpoint: sub.endpoint,
            keys: { p256dh: sub.p256dh, auth: sub.auth },
          },
          payload
        );
      } catch (err: any) {
        console.error(`Failed push delivery to subscription ${sub.id}:`, err.message);
        if (err.statusCode === 410 || err.statusCode === 404) {
          deleteIds.push(sub.id);
        }
      }
    });

    await Promise.all(sendPromises);

    if (deleteIds.length > 0) {
      await client.query(
        'DELETE FROM public.push_subscriptions WHERE id = ANY($1::uuid[])',
        [deleteIds]
      );
    }

    await client.end();
    return res.status(200).json({
      status: 'Notifications sent successfully',
      deliveredCount: subsRes.rows.length - deleteIds.length,
    });
  } catch (err: any) {
    console.error('Error in notify handler:', err);
    try {
      await client.end();
    } catch (_) {}
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
}
