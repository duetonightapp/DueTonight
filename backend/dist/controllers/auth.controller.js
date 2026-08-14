"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.connectMicrosoft = connectMicrosoft;
exports.microsoftCallback = microsoftCallback;
const microsoft_service_1 = require("../services/microsoft.service");
const db_service_1 = require("../services/db.service");
async function connectMicrosoft(req, res) {
    const { userId } = req.query;
    if (!userId || typeof userId !== 'string') {
        return res.status(400).send('Missing userId parameter');
    }
    const authUrl = (0, microsoft_service_1.getAuthorizationUrl)(userId);
    return res.redirect(authUrl);
}
async function microsoftCallback(req, res) {
    const { code, state: userId, error, error_description } = req.query;
    if (error) {
        console.error('Microsoft OAuth error:', error_description);
        return res.redirect(`com.college.due-tonight://microsoft-connected?status=error&message=${encodeURIComponent(String(error_description))}`);
    }
    if (!code || !userId || typeof code !== 'string' || typeof userId !== 'string') {
        return res.status(400).send('Invalid request payload or state parameters missing');
    }
    try {
        const { accessToken, refreshToken, expiresIn } = await (0, microsoft_service_1.exchangeCodeForTokens)(code);
        const expiresAt = new Date(Date.now() + expiresIn * 1000);
        const userInfo = await (0, microsoft_service_1.getMicrosoftUserInfo)(accessToken);
        await db_service_1.prisma.profile.upsert({
            where: { id: userId },
            update: { email: userInfo.email },
            create: { id: userId, email: userInfo.email },
        });
        await db_service_1.prisma.microsoftAccount.upsert({
            where: { userId },
            update: {
                email: userInfo.email,
                accessToken,
                refreshToken,
                expiresAt,
                updatedAt: new Date(),
            },
            create: {
                userId,
                email: userInfo.email,
                accessToken,
                refreshToken,
                expiresAt,
            },
        });
        console.log(`Successfully connected Microsoft Teams account: ${userInfo.email} for user: ${userId}`);
        return res.redirect('com.college.due-tonight://microsoft-connected?status=success');
    }
    catch (err) {
        console.error('Error during Microsoft OAuth callback processing:', err);
        const errMsg = err?.response?.data?.error_description || err?.message || 'Unknown error occurred';
        return res.redirect(`com.college.due-tonight://microsoft-connected?status=error&message=${encodeURIComponent(String(errMsg))}`);
    }
}
