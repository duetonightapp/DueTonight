"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getConnectionStatus = getConnectionStatus;
exports.disconnectTeams = disconnectTeams;
exports.syncAssignments = syncAssignments;
const db_service_1 = require("../services/db.service");
const microsoft_service_1 = require("../services/microsoft.service");
async function getConnectionStatus(req, res) {
    const userId = req.user.id;
    try {
        const account = await db_service_1.prisma.microsoftAccount.findUnique({
            where: { userId },
            select: { email: true, createdAt: true },
        });
        if (!account) {
            return res.json({ connected: false });
        }
        return res.json({
            connected: true,
            email: account.email,
            connectedAt: account.createdAt,
        });
    }
    catch (err) {
        console.error('Error fetching connection status:', err);
        return res.status(500).json({ error: err.message });
    }
}
async function disconnectTeams(req, res) {
    const userId = req.user.id;
    try {
        await db_service_1.prisma.microsoftAccount.delete({
            where: { userId },
        });
        const deleteInfo = await db_service_1.prisma.assignment.deleteMany({
            where: {
                userId,
                platform: 'teams',
            },
        });
        console.log(`Disconnected Teams and deleted ${deleteInfo.count} synced assignments for user: ${userId}`);
        return res.json({ success: true, deletedAssignmentsCount: deleteInfo.count });
    }
    catch (err) {
        console.error('Error disconnecting Microsoft Teams:', err);
        if (err.code === 'P2025') {
            return res.json({ success: true, message: 'Already disconnected' });
        }
        return res.status(500).json({ error: err.message });
    }
}
async function syncAssignments(req, res) {
    const userId = req.user.id;
    try {
        const accessToken = await (0, microsoft_service_1.getFreshAccessToken)(userId);
        console.log(`Syncing assignments: Fetching classes and assignments for user: ${userId}`);
        const [classes, assignmentsRaw] = await Promise.all([
            (0, microsoft_service_1.getClasses)(accessToken),
            (0, microsoft_service_1.getAssignments)(accessToken),
        ]);
        const classMap = new Map();
        for (const cls of classes) {
            classMap.set(cls.id, cls.displayName);
        }
        let syncedCount = 0;
        for (const raw of assignmentsRaw) {
            if (raw.status !== 'published') {
                continue;
            }
            const externalId = raw.id;
            const title = raw.displayName;
            const description = raw.instructions?.content || '';
            const deadline = new Date(raw.dueDateTime);
            const classId = raw.classId;
            const subject = classMap.get(classId) || 'Teams Assignment';
            const isCompleted = Array.isArray(raw.submissions) && raw.submissions.some((sub) => sub.status === 'submitted' || sub.status === 'returned');
            await db_service_1.prisma.assignment.upsert({
                where: {
                    unique_user_external_id: {
                        userId,
                        externalId,
                    },
                },
                update: {
                    title,
                    description,
                    subject,
                    deadline,
                    isCompleted,
                    updatedAt: new Date(),
                },
                create: {
                    userId,
                    externalId,
                    title,
                    description,
                    subject,
                    deadline,
                    isCompleted,
                    platform: 'teams',
                    submissionMode: 'online',
                    priority: 'medium',
                },
            });
            syncedCount++;
        }
        console.log(`Successfully synced ${syncedCount} Teams assignments for user: ${userId}`);
        return res.json({
            success: true,
            syncedCount,
        });
    }
    catch (err) {
        console.error('Error syncing Teams assignments:', err);
        if (err.message === 'No Microsoft account connected for this user') {
            return res.status(400).json({ error: 'Microsoft account not connected' });
        }
        return res.status(500).json({ error: err.message || 'Failed to sync assignments' });
    }
}
