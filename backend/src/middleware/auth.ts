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
  firebaseToken?: admin.auth.DecodedIdToken;
}

const INACTIVITY_LIMIT_MS = 30 * 24 * 60 * 60 * 1000;
const ABSOLUTE_SESSION_LIMIT_MS = 90 * 24 * 60 * 60 * 1000;
const ACTIVITY_UPDATE_INTERVAL_MS = 60 * 60 * 1000;

function isEnabled(value: string | undefined): boolean {
  return value === 'true' || value === '1';
}

function isAdminMfaSatisfied(decoded: admin.auth.DecodedIdToken): boolean {
  const firebaseClaims = (decoded as any).firebase;
  const signInAttributes = firebaseClaims?.sign_in_attributes;
  return (
    signInAttributes?.mfa_verified === true ||
    signInAttributes?.mfa_verified === 'true' ||
    Boolean(firebaseClaims?.sign_in_second_factor) ||
    Boolean(firebaseClaims?.second_factor_identifier)
  );
}

async function revokeAndReject(
  firebaseUid: string,
  res: Response,
  message: string,
): Promise<void> {
  try {
    await admin.auth().revokeRefreshTokens(firebaseUid);
  } catch (err) {
    console.warn('[Auth] Failed to revoke expired session refresh tokens:', err);
  }
  res.status(401).json({ error: message, code: 'SESSION_EXPIRED' });
}

export async function requireAuth(req: AuthRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing authorization token' });
    return;
  }

  const token = authHeader.slice(7);
  try {
    const decoded = await admin.auth().verifyIdToken(token, true);
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
    const now = new Date();
    const lastActiveAt = user.lastActiveAt ? new Date(user.lastActiveAt) : null;
    if (lastActiveAt && now.getTime() - lastActiveAt.getTime() > INACTIVITY_LIMIT_MS) {
      await revokeAndReject(decoded.uid, res, 'Session expired after 30 days of inactivity. Please sign in again.');
      return;
    }

    const tokenAuthTime = typeof decoded.auth_time === 'number'
      ? new Date(decoded.auth_time * 1000)
      : null;
    const sessionStartedAt = tokenAuthTime ?? (user.sessionStartedAt ? new Date(user.sessionStartedAt) : null);
    if (sessionStartedAt && now.getTime() - sessionStartedAt.getTime() > ABSOLUTE_SESSION_LIMIT_MS) {
      await revokeAndReject(decoded.uid, res, 'Session expired after 90 days. Please sign in again.');
      return;
    }

    if (!lastActiveAt || now.getTime() - lastActiveAt.getTime() > ACTIVITY_UPDATE_INTERVAL_MS) {
      await prisma.user.update({
        where: { id: user.id },
        data: {
          lastActiveAt: now,
          sessionStartedAt: user.sessionStartedAt ?? sessionStartedAt ?? now,
        },
      });
    }

    req.userId = user.id;
    req.firebaseUid = decoded.uid;
    req.isAdmin = user.isAdmin;
    req.firebaseToken = decoded;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

// Guards reward-earning routes against throwaway / unverified accounts.
// Google Sign-In and Apple Sign-In always set email_verified = true.
// Email+password users must complete Firebase's email verification flow first.
// Must be applied AFTER requireAuth (depends on req.firebaseToken being set).
export function requireEmailVerified(req: AuthRequest, res: Response, next: NextFunction) {
  if (!req.firebaseToken?.email_verified) {
    res.status(403).json({
      error: 'A verified email address is required to earn or spend rewards.',
      code: 'EMAIL_NOT_VERIFIED',
    });
    return;
  }
  next();
}

export function requireAdmin(req: AuthRequest, res: Response, next: NextFunction) {
  if (!req.isAdmin) {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }
  if (isEnabled(process.env.ADMIN_MFA_REQUIRED) && !isAdminMfaSatisfied(req.firebaseToken as admin.auth.DecodedIdToken)) {
    res.status(403).json({ error: 'Admin multi-factor authentication required', code: 'ADMIN_MFA_REQUIRED' });
    return;
  }
  next();
}
