import { Router } from 'express';
import * as admin from 'firebase-admin';
import { prisma } from '../index';
import { encrypt } from '../services/encryption';
import { ipRateLimit } from '../middleware/rateLimits';

const router = Router();
const verifyLimiter = ipRateLimit({
  envName: 'AUTH_VERIFY_RATE_LIMIT_PER_MINUTE',
  fallback: 30,
  message: 'Too many sign-in checks. Please try again in a minute.',
});

// POST /auth/verify
// Called on first launch and after token refresh. Creates the User row if it doesn't exist.
router.post('/verify', verifyLimiter, async (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing authorization token' });
    return;
  }

  const token = authHeader.slice(7);
  try {
    // checkRevoked=false: skips the extra live round-trip to Firebase's Token
    // Store. Tokens expire in 1 h naturally; the revocation check was causing
    // Render cold-start failures that wiped the admin role on every first login.
    const decoded = await admin.auth().verifyIdToken(token, false);

    let user = await prisma.user.findUnique({ where: { firebaseUid: decoded.uid } });

    if (!user) {
      const displayName = decoded.name ?? decoded.email?.split('@')[0] ?? 'Souk User';
      const rawPhoneNumber = decoded.phone_number ?? null;
      const phoneNumber = rawPhoneNumber ? encrypt(rawPhoneNumber) : null;
      user = await prisma.user.create({
        data: {
          firebaseUid: decoded.uid,
          displayName,
          avatarUrl: decoded.picture ?? null,
          phoneNumber,
          preferredLocale: 'en',
        },
      });

      // Seed the admin settings singleton if it doesn't exist yet
      await prisma.adminSettings.upsert({
        where: { id: 1 },
        update: {},
        create: { id: 1 },
      });
    } else if (decoded.picture && decoded.picture !== user.avatarUrl) {
      // Persist/refresh the Google/Apple profile photo so server-side consumers
      // (e.g. the admin Users directory) can show it. These URLs rotate over
      // time, so we re-sync whenever the token's picture claim changes.
      user = await prisma.user.update({
        where: { id: user.id },
        data: { avatarUrl: decoded.picture },
      });
    }

    // Mirror requireAuth's gating: banned/suspended users must not get a session,
    // even though /verify only reads their profile. Keeps behaviour consistent
    // across every route rather than letting verify hand back a usable profile.
    if (user.bannedAt) {
      res.status(403).json({ error: 'Account banned', reason: user.banReason });
      return;
    }
    if (user.isSuspended && user.suspendedUntil && user.suspendedUntil > new Date()) {
      res.status(403).json({ error: 'Account suspended', suspendedUntil: user.suspendedUntil });
      return;
    }

    const roles = user.isAdmin ? ['user', 'admin'] : ['user'];

    res.json({
      id: user.id,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      homeArea: user.homeArea,
      preferredLocale: user.preferredLocale,
      tokenBalance: user.tokenBalance,
      accuracyRating: user.accuracyRating,
      role: user.isAdmin ? 'admin' : 'user',
      roles,
      isAdmin: user.isAdmin,
      isSuspended: user.isSuspended,
      createdAt: user.createdAt,
    });
  } catch (err: any) {
    // Log only the error code — never the full object, which can contain token fragments.
    console.error('[auth/verify] token verification failed:', err?.errorInfo?.code ?? err?.code ?? 'unknown');
    res.status(401).json({ error: 'Invalid or expired token' });
  }
});

export default router;
