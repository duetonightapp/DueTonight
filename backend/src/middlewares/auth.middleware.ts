import { Request, Response, NextFunction } from 'express';
import { verifyUserToken } from '../services/supabase.service';

export interface AuthenticatedRequest extends Request {
  user?: any; // The Supabase user object
}

export async function authMiddleware(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authorization header missing or invalid' });
  }

  const token = authHeader.split(' ')[1];
  const user = await verifyUserToken(token);

  if (!user) {
    return res.status(401).json({ error: 'Unauthorized or invalid token' });
  }

  req.user = user;
  next();
}
