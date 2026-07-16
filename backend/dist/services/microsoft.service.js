"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAuthorizationUrl = getAuthorizationUrl;
exports.exchangeCodeForTokens = exchangeCodeForTokens;
exports.getFreshAccessToken = getFreshAccessToken;
exports.getMicrosoftUserInfo = getMicrosoftUserInfo;
exports.getClasses = getClasses;
exports.getAssignments = getAssignments;
const axios_1 = __importDefault(require("axios"));
const dotenv_1 = __importDefault(require("dotenv"));
const db_service_1 = require("./db.service");
dotenv_1.default.config();
const CLIENT_ID = process.env.MICROSOFT_CLIENT_ID || '';
const CLIENT_SECRET = process.env.MICROSOFT_CLIENT_SECRET || '';
const REDIRECT_URI = process.env.MICROSOFT_REDIRECT_URI || '';
const SCOPES = 'offline_access openid profile email EduRoster.ReadBasic EduAssignments.ReadBasic';
function getAuthorizationUrl(userId) {
    const url = new URL('https://login.microsoftonline.com/common/oauth2/v2.0/authorize');
    url.searchParams.append('client_id', CLIENT_ID);
    url.searchParams.append('response_type', 'code');
    url.searchParams.append('redirect_uri', REDIRECT_URI);
    url.searchParams.append('response_mode', 'query');
    url.searchParams.append('scope', SCOPES);
    url.searchParams.append('state', userId);
    return url.toString();
}
async function exchangeCodeForTokens(code) {
    const params = new URLSearchParams();
    params.append('client_id', CLIENT_ID);
    params.append('client_secret', CLIENT_SECRET);
    params.append('code', code);
    params.append('redirect_uri', REDIRECT_URI);
    params.append('grant_type', 'authorization_code');
    const response = await axios_1.default.post('https://login.microsoftonline.com/common/oauth2/v2.0/token', params.toString(), { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });
    return {
        accessToken: response.data.access_token,
        refreshToken: response.data.refresh_token,
        expiresIn: response.data.expires_in,
    };
}
async function getFreshAccessToken(userId) {
    const account = await db_service_1.prisma.microsoftAccount.findUnique({
        where: { userId },
    });
    if (!account) {
        throw new Error('No Microsoft account connected for this user');
    }
    const isExpired = new Date(account.expiresAt.getTime() - 60000) <= new Date();
    if (!isExpired) {
        return account.accessToken;
    }
    console.log(`Refreshing Microsoft access token for user: ${userId}`);
    const params = new URLSearchParams();
    params.append('client_id', CLIENT_ID);
    params.append('client_secret', CLIENT_SECRET);
    params.append('refresh_token', account.refreshToken);
    params.append('grant_type', 'refresh_token');
    const response = await axios_1.default.post('https://login.microsoftonline.com/common/oauth2/v2.0/token', params.toString(), { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });
    const newAccessToken = response.data.access_token;
    const newRefreshToken = response.data.refresh_token || account.refreshToken;
    const expiresIn = response.data.expires_in;
    const expiresAt = new Date(Date.now() + expiresIn * 1000);
    await db_service_1.prisma.microsoftAccount.update({
        where: { userId },
        data: {
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            expiresAt,
        },
    });
    return newAccessToken;
}
async function getMicrosoftUserInfo(accessToken) {
    const response = await axios_1.default.get('https://graph.microsoft.com/v1.0/me', {
        headers: { Authorization: `Bearer ${accessToken}` },
    });
    return {
        email: response.data.mail || response.data.userPrincipalName,
        displayName: response.data.displayName,
    };
}
async function getClasses(accessToken) {
    const response = await axios_1.default.get('https://graph.microsoft.com/v1.0/education/me/classes', {
        headers: { Authorization: `Bearer ${accessToken}` },
    });
    return response.data.value;
}
async function getAssignments(accessToken) {
    const response = await axios_1.default.get('https://graph.microsoft.com/v1.0/education/me/assignments?$expand=submissions', {
        headers: { Authorization: `Bearer ${accessToken}` },
    });
    return response.data.value;
}
