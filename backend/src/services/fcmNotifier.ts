import { getMessaging } from "firebase-admin/messaging";

export async function sendPushNotification(
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  try {
    await getMessaging().send({
      token: fcmToken,
      notification: { title, body },
      data: data ?? {},
      apns: { payload: { aps: { sound: "default" } } },
      android: { priority: "high" },
    });
  } catch (err) {
    // FCM errors are non-fatal — log and continue
    console.warn("[FCM] Failed to send notification:", err);
  }
}

export async function notifyRequestFulfilled(
  requesterFcmToken: string | null | undefined,
  sourcerName: string,
  productName: string,
  storeName: string,
  tokensEarned: number,
): Promise<void> {
  if (!requesterFcmToken) return;
  await sendPushNotification(
    requesterFcmToken,
    "Price Request Fulfilled!",
    `${sourcerName} submitted ${productName} @ ${storeName}`,
    { type: "request_fulfilled", tokensEarned: String(tokensEarned) },
  );
}

export async function notifyRankChange(
  fcmToken: string | null | undefined,
  newRank: number,
  oldRank: number,
): Promise<void> {
  if (!fcmToken) return;
  if (Math.abs(newRank - oldRank) < 3) return;
  const direction = newRank < oldRank ? "up" : "down";
  await sendPushNotification(
    fcmToken,
    direction === "up"
      ? `You moved up to #${newRank}!`
      : `You dropped to #${newRank}`,
    direction === "up"
      ? `You climbed ${oldRank - newRank} spots on the leaderboard this month`
      : `You fell ${newRank - oldRank} spots — submit more prices to climb back`,
    { type: "rank_change", newRank: String(newRank), oldRank: String(oldRank) },
  );
}

export async function notifyBadgeEarned(
  fcmToken: string | null | undefined,
  badgeName: string,
  badgeEmoji: string,
): Promise<void> {
  if (!fcmToken) return;
  await sendPushNotification(
    fcmToken,
    `${badgeEmoji} Badge Unlocked!`,
    `You earned the "${badgeName}" badge`,
    { type: "badge_earned", badgeName },
  );
}

export async function notifyStreakMilestone(
  fcmToken: string | null | undefined,
  streak: number,
  bonusTokens: number,
): Promise<void> {
  if (!fcmToken) return;
  await sendPushNotification(
    fcmToken,
    `${streak}-Day Streak!`,
    `You've submitted prices ${streak} days in a row. +${bonusTokens} bonus tokens!`,
    {
      type: "streak_milestone",
      streak: String(streak),
      bonusTokens: String(bonusTokens),
    },
  );
}
