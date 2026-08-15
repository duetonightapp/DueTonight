import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createClient } from '@supabase/supabase-js';
import webpush from 'web-push';

const supabaseUrl = process.env.SUPABASE_URL || 'https://tdotndrapfawgljyzrkn.supabase.co';
const supabaseAnonKey =
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

const supabase = createClient(supabaseUrl, supabaseAnonKey);

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
    return res.status(400).json({ error: 'Missing required parameters (roomId, type, title, uploaderName)' });
  }

  try {
    // Call SECURITY DEFINER RPC function to fetch subscriptions for room members
    const { data: subscriptions, error } = await supabase.rpc(
      'get_push_subscriptions_for_room',
      { p_room_id: roomId }
    );

    if (error) {
      console.error('RPC Error:', error);
      return res.status(500).json({ error: error.message });
    }

    if (!subscriptions || subscriptions.length === 0) {
      return res.status(200).json({ status: 'No subscriptions found for room' });
    }

    let recipientSubscriptions = subscriptions;
    if (uploaderId && Array.isArray(subscriptions)) {
      recipientSubscriptions = subscriptions.filter((sub: any) => sub.user_id && sub.user_id !== uploaderId);
    }

    let notificationTitle = uploaderName ? `${uploaderName} posted an update` : 'New Update';
    if (type === 'assignment') {
      notificationTitle = `New Assignment from ${uploaderName}`;
    } else if (type === 'announcement') {
      notificationTitle = `New Announcement from ${uploaderName}`;
    } else if (type === 'solution') {
      notificationTitle = `New Solution from ${uploaderName}`;
    } else if (type === 'resource') {
      notificationTitle = `New Resource Uploaded`;
    }

    let targetUrl = `/rooms/${roomId}`;
    if (type === 'resource') {
      targetUrl = `/rooms/${roomId}?initialTab=2`;
    } else if (type === 'assignment') {
      targetUrl = `/rooms/${roomId}?initialTab=1`;
    } else if (type === 'announcement') {
      targetUrl = `/rooms/${roomId}?initialTab=3`;
    }

    const payload = JSON.stringify({
      title: notificationTitle,
      body: `${title}${details ? ': ' + details : ''}`,
      url: targetUrl,
    });

    const deleteIds: string[] = [];
    const sendPromises = recipientSubscriptions.map(async (sub: any) => {
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
      await supabase.from('push_subscriptions').delete().in('id', deleteIds);
    }

    return res.status(200).json({
      status: 'Notifications sent successfully',
      deliveredCount: recipientSubscriptions.length - deleteIds.length,
    });
  } catch (err: any) {
    console.error('Error in notify handler:', err);
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
}
