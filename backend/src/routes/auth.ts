import { Router } from 'express';
import * as admin from 'firebase-admin';
import { prisma } from '../index';

const router = Router();

// POST /auth/verify
// Called on first launch and after token refresh. Creates the User row if it doesn't exist.
router.post('/verify', async (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing authorization token' });
    return;
  }

  const token = authHeader.slice(7);
  try {
    const decoded = await admin.auth().verifyIdToken(token);

    let user = await prisma.user.findUnique({ where: { firebaseUid: decoded.uid } });

    if (!user) {
      const displayName = decoded.name ?? decoded.email?.split('@')[0] ?? 'Souk User';
      const phoneNumber = decoded.phone_number ?? null;
      user = await prisma.user.create({
        data: {
          firebaseUid: decoded.uid,
          displayName,
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
    }

    res.json({
      id: user.id,
      displayName: user.displayName,
      homeArea: user.homeArea,
      preferredLocale: user.preferredLocale,
      tokenBalance: user.tokenBalance,
      accuracyRating: user.accuracyRating,
      isAdmin: user.isAdmin,
      isSuspended: user.isSuspended,
      createdAt: user.createdAt,
    });
  } catch (err) {
    console.error(err);
    res.status(401).json({ error: 'Invalid or expired token' });
  }
});

export default router;
