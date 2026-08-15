"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const db_service_1 = require("../services/db.service");
const web_push_1 = __importDefault(require("web-push"));
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
const router = (0, express_1.Router)();
const vapidPublicKey = process.env.VAPID_PUBLIC_KEY || '';
const vapidPrivateKey = process.env.VAPID_PRIVATE_KEY || '';
if (vapidPublicKey && vapidPrivateKey) {
    web_push_1.default.setVapidDetails('mailto:support@duetonight.app', vapidPublicKey, vapidPrivateKey);
}
else {
    console.warn('Warning: VAPID keys not configured in backend environment.');
}
// POST /api/notifications/notify
router.post('/notify', async (req, res) => {
    const { roomId, type, title, details, uploaderName, uploaderId } = req.body;
    if (!roomId || !type || !title || !uploaderName) {
        return res.status(400).json({ error: 'Missing required parameters (roomId, type, title, uploaderName)' });
    }
    try {
        console.log(`Notification request received for room ${roomId}, type: ${type}`);
        // 1. Fetch all members of the room using Prisma raw query to bypass RLS
        const members = await db_service_1.prisma.$queryRaw `
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
        const subscriptions = await db_service_1.prisma.$queryRaw `
      SELECT id, user_id, endpoint, p256dh, auth FROM public.push_subscriptions WHERE user_id = ANY(${recipientIds}::uuid[])
    `;
        if (!subscriptions || subscriptions.length === 0) {
            return res.status(200).json({ status: 'No active push subscriptions' });
        }
        // 4. Send push notifications
        let notificationTitle = `${uploaderName} uploaded a new ${type}`;
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
            url: targetUrl
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
                await web_push_1.default.sendNotification(pushSubscription, payload);
            }
            catch (err) {
                console.error(`Failed to send notification to subscription ${sub.id}:`, err.message);
                // If subscription is expired or unsubscribed, remove it from the DB
                if (err.statusCode === 410 || err.statusCode === 404) {
                    console.log(`Deleting expired subscription: ${sub.id}`);
                    await db_service_1.prisma.$queryRaw `
            DELETE FROM public.push_subscriptions WHERE id = ${sub.id}::uuid
          `;
                }
            }
        });
        await Promise.all(promises);
        return res.status(200).json({ status: 'Notifications sent successfully' });
    }
    catch (error) {
        console.error('Error sending push notifications:', error);
        return res.status(500).json({ error: 'Internal server error while sending notifications' });
    }
});
exports.default = router;
