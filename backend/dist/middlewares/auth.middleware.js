"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = authMiddleware;
const supabase_service_1 = require("../services/supabase.service");
async function authMiddleware(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Authorization header missing or invalid' });
    }
    const token = authHeader.split(' ')[1];
    const user = await (0, supabase_service_1.verifyUserToken)(token);
    if (!user) {
        return res.status(401).json({ error: 'Unauthorized or invalid token' });
    }
    req.user = user;
    next();
}
