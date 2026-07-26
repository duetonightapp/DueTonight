import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createClient } from '@supabase/supabase-js';
import webpush from 'web-push';

const supabaseUrl = process.env.SUPABASE_URL || 'https://tdotndrapfawgljyzrkn.supabase.co';
const supabaseServiceRoleKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
  process.env.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRkb3RuZHJhcGZhd2dsanl6cmtuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg3NzYzNTQsImV4cCI6MjA5NDM1MjM1NH0.eGmy70EUcoAtqixypn6_eZMvGziXtNmLTj3sPbsYNQU';

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

const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // Enable CORS
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
    return res.status(400).json({
      error: 'Missing required parameters (roomId, type, title, uploaderName)',
    });
  }

  try {
    console.log(`[Push Notification] Processing ${type} for room ${roomId} by ${uploaderName}`);

    // 1. Fetch room members
    const { data: members, error: membersErr } = await supabase
      .from('room_members')
      .select('user_id')
      .eq('room_id', roomId);

    if (membersErr) {
      console.error('Error fetching room members:', membersErr);
      return res.status(500).json({ error: 'Failed to fetch room members' });
    }

    if (!members || members.length === 0) {
      return res.status(200).json({ status: 'No members in room' });
    }

    // 2. Filter out the uploader
    const recipientIds = members
      .map((m: any) => m.user_id)
      .filter((id: string) => id !== uploaderId);

    if (recipientIds.length === 0) {
      return res.status(200).json({ status: 'No recipients (only uploader in room)' });
    }

    // 3. Fetch push subscriptions for recipients
    const { data: subscriptions, error: subErr } = await supabase
      .from('push_subscriptions')
      .select('id, user_id, endpoint, p256dh, auth')
      .in('user_id', recipientIds);

    if (subErr) {
      console.error('Error fetching subscriptions:', subErr);
      return res.status(500).json({ error: 'Failed to fetch push subscriptions' });
    }

    if (!subscriptions || subscriptions.length === 0) {
      return res.status(200).json({ status: 'No active push subscriptions' });
    }

    // Formulate notification title and body
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
      url: `/rooms/${roomId}`
    });

    console.log(`Broadcasting to ${subscriptions.length} active browser subscriptions...`);

    // 4. Send push notifications
    const deleteIds: string[] = [];
    const sendPromises = subscriptions.map(async (sub: any) => {
      const pushSubscription = {
        endpoint: sub.endpoint,
        keys: {
          p256dh: sub.p256dh,
          auth: sub.auth,
        },
      };

      try {
        await webpush.sendNotification(pushSubscription, payload);
      } catch (err: any) {
        console.error(`Failed push delivery to subscription ${sub.id}:`, err.message);
        if (err.statusCode === 410 || err.statusCode === 404) {
          deleteIds.push(sub.id);
        }
      }
    });

    await Promise.all(sendPromises);

    // Delete expired subscriptions
    if (deleteIds.length > 0) {
      console.log(`Cleaning up ${deleteIds.length} expired subscriptions...`);
      await supabase.from('push_subscriptions').delete().in('id', deleteIds);
    }

    return res.status(200).json({
      status: 'Notifications sent successfully',
      deliveredCount: subscriptions.length - deleteIds.length,
    });
  } catch (error: any) {
    console.error('Unhandled error sending push notification:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
