import { Router } from "express";
import { prisma } from "../index";
import { requireAuth, AuthRequest } from "../middleware/auth";

const router = Router();

// Challenge templates for auto-generation
const CHALLENGE_TEMPLATES = [
  {
    title: "Submit 5 prices from Carrefour today",
    description: "Find 5 items at any Carrefour branch and submit their prices",
    chainTarget: "Carrefour",
    targetCount: 5,
    bonusTokens: 100,
  },
  {
    title: "Submit 5 prices from Lulu Hypermarket",
    description: "Visit any Lulu branch and submit 5 fresh prices",
    chainTarget: "Lulu Hypermarket",
    targetCount: 5,
    bonusTokens: 100,
  },
  {
    title: "Submit 3 prices from Spinneys or Waitrose",
    description:
      "Check premium store prices and help shoppers find the best deals",
    chainTarget: "Spinneys",
    targetCount: 3,
    bonusTokens: 80,
  },
  {
    title: "Submit 5 prices from Union Coop",
    description: "Help the community find UAE-favourites pricing at Union Coop",
    chainTarget: "Union Coop",
    targetCount: 5,
    bonusTokens: 100,
  },
  {
    title: "Submit 5 prices from any store today",
    description: "Any supermarket counts. Just keep the data fresh!",
    chainTarget: null,
    targetCount: 5,
    bonusTokens: 75,
  },
  {
    title: "Submit 3 Dairy & Eggs prices",
    description:
      "Dairy prices change frequently. Help shoppers find the best deals.",
    chainTarget: null,
    targetCount: 3,
    bonusTokens: 60,
  },
  {
    title: "Submit 3 Fresh Produce prices",
    description:
      "Fresh fruit and vegetable prices vary widely. Submit 3 today.",
    chainTarget: null,
    targetCount: 3,
    bonusTokens: 60,
  },
];

async function getOrCreateTodayChallenge() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Pick a template based on day of year for deterministic daily rotation
  const dayOfYear = Math.floor(
    (today.getTime() - new Date(today.getFullYear(), 0, 0).getTime()) / 86400000,
  );
  const template = CHALLENGE_TEMPLATES[dayOfYear % CHALLENGE_TEMPLATES.length];

  // upsert instead of findFirst+create to eliminate the race condition where
  // two concurrent first-request-of-the-day calls both try to INSERT the row
  // and the second one hits the @@unique([date]) constraint with a P2002.
  return prisma.dailyChallenge.upsert({
    where: { date: today },
    update: {},
    create: {
      date: today,
      title: template.title,
      description: template.description,
      chainTarget: template.chainTarget ?? null,
      targetCount: template.targetCount,
      bonusTokens: template.bonusTokens,
    },
  });
}

// GET /challenges/today — today's challenge + authenticated user's progress
router.get("/today", async (req, res) => {
  const challenge = await getOrCreateTodayChallenge();

  // Check auth header for user progress (optional — unauthenticated users get challenge without progress)
  const authHeader = req.headers.authorization;
  let userProgress = null;

  if (authHeader) {
    try {
      const { getAuth } = await import("firebase-admin/auth");
      const token = authHeader.replace("Bearer ", "");
      const decoded = await getAuth().verifyIdToken(token);
      const user = await prisma.user.findUnique({
        where: { firebaseUid: decoded.uid },
      });
      if (user) {
        userProgress = await prisma.userDailyChallenge.findUnique({
          where: {
            userId_challengeId: { userId: user.id, challengeId: challenge.id },
          },
        });
      }
    } catch {
      // Invalid token — return challenge without progress
    }
  }

  res.json({
    id: challenge.id,
    date: challenge.date,
    title: challenge.title,
    description: challenge.description,
    chainTarget: challenge.chainTarget,
    targetCount: challenge.targetCount,
    bonusTokens: challenge.bonusTokens,
    userProgress: userProgress
      ? {
          progress: userProgress.progress,
          completed: userProgress.completed,
          bonusAwarded: userProgress.bonusAwarded,
        }
      : { progress: 0, completed: false, bonusAwarded: false },
  });
});

export default router;
