"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const web_push_1 = __importDefault(require("web-push"));
const supabase_js_1 = require("@supabase/supabase-js");
const dotenv_1 = __importDefault(require("dotenv"));

dotenv_1.default.config();

const router = (0, express_1.Router)();

const supabaseUrl = process.env.SUPABASE_URL || 'https://tdotndrapfawgljyzrkn.supabase.co';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRkb3RuZHJhcGZhd2dsanl6cmtuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg3NzYzNTQsImV4cCI6MjA5NDM1MjM1NH0.eGmy70EUcoAtqixypn6_eZMvGziXtNmLTj3sPbsYNQU';

const vapidPublicKey = process.env.VAPID_PUBLIC_KEY || 'BJD0k-xLMppRIu6ARcTQVCpO17S-ZVS-TW6AgyCDOqX7Lzl_yQY1v4eeWGodRHibzSGaodeYtjid8lSU2qKIDVI';
const vapidPrivateKey = process.env.VAPID_PRIVATE_KEY || 'fkb_Wjq4Dvt75gvG_mKUKWI0yNgUmCacRIz7RAukSWM';

web_push_1.default.setVapidDetails('mailto:support@duetonight.app', vapidPublicKey, vapidPrivateKey);

const supabase = (0, supabase_js_1.createClient)(supabaseUrl, supabaseAnonKey);

// POST /api/notifications/notify
router.post('/notify', async (req, res) => {
    const { roomId, type, title, details, uploaderName, uploaderId } = req.body;
    if (!roomId || !type || !title || !uploaderName) {
        return res.status(400).json({ error: 'Missing required parameters (roomId, type, title, uploaderName)' });
    }
    try {
        console.log(`Notification request received for room ${roomId}, type: ${type}`);
        
        // Fetch subscriptions using RPC to bypass RLS
        const { data: subscriptions, error } = await supabase.rpc(
            'get_push_subscriptions_for_room',
            { p_room_id: roomId }
        );

        if (error) {
            console.error('Supabase RPC Error:', error);
            return res.status(500).json({ error: error.message });
        }

        if (!subscriptions || subscriptions.length === 0) {
            return res.status(200).json({ status: 'No subscriptions found for room' });
        }

        // Filter out the uploader
        let recipientSubscriptions = subscriptions;
        if (uploaderId && Array.isArray(subscriptions)) {
            recipientSubscriptions = subscriptions.filter((sub) => sub.user_id && sub.user_id !== uploaderId);
        }

        if (recipientSubscriptions.length === 0) {
            return res.status(200).json({ status: 'No recipients to notify (only uploader subscribed)' });
        }

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

        console.log(`Broadcasting push notification to ${recipientSubscriptions.length} subscriptions...`);
        const deleteIds = [];
        const promises = recipientSubscriptions.map(async (sub) => {
            const pushSubscription = {
                endpoint: sub.endpoint,
                keys: {
                    p256dh: sub.p256dh,
                    auth: sub.auth
                }
            };
            try {
                await web_push_1.default.sendNotification(pushSubscription, payload);
            } catch (err) {
                console.error(`Failed push delivery to subscription ${sub.id}:`, err.message);
                if (err.statusCode === 410 || err.statusCode === 404) {
                    deleteIds.push(sub.id);
                }
            }
        });

        await Promise.all(promises);

        if (deleteIds.length > 0) {
            await supabase.from('push_subscriptions').delete().in('id', deleteIds);
        }

        return res.status(200).json({
            status: 'Notifications sent successfully',
            deliveredCount: recipientSubscriptions.length - deleteIds.length
        });
    } catch (error) {
        console.error('Error sending push notifications:', error);
        return res.status(500).json({ error: error.message || 'Internal server error' });
    }
});

exports.default = router;
