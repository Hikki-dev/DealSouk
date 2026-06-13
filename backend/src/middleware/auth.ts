import { Request, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';
import { prisma } from '../index';
import { requireEnv } from '../config/env';

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: requireEnv('FIREBASE_PROJECT_ID'),
      clientEmail: requireEnv('FIREBASE_CLIENT_EMAIL'),
      privateKey: requireEnv('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n'),
    }),
  });
}

export interface AuthRequest extends Request {
  userId?: string;
  firebaseUid?: string;
  isAdmin?: boolean;
}

export async function requireAuth(req: AuthRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing authorization token' });
    return;
  }

  const token = authHeader.slice(7);
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    const user = await prisma.user.findUnique({ where: { firebaseUid: decoded.uid } });
    if (!user) {
      res.status(401).json({ error: 'User not registered' });
      return;
    }
    if (user.bannedAt) {
      res.status(403).json({ error: 'Account banned', reason: user.banReason });
      return;
    }
    if (user.isSuspended && user.suspendedUntil && user.suspendedUntil > new Date()) {
      res.status(403).json({ error: 'Account suspended', suspendedUntil: user.suspendedUntil });
      return;
    }
    req.userId = user.id;
    req.firebaseUid = decoded.uid;
    req.isAdmin = user.isAdmin;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

export function requireAdmin(req: AuthRequest, res: Response, next: NextFunction) {
  if (!req.isAdmin) {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }
  next();
}
