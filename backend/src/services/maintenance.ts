import { prisma } from '../index';
import { awardTokens } from './tokenEngine';

// Periodic maintenance that enforces time-based PRD rules instead of relying
// purely on lazy evaluation at read time.
//
//  - FR-18: price submissions auto-expire 72h after submission and are removed
//           from active results (the feed has no time filter, so they must be
//           flipped out of 'approved'/'pending' explicitly).
//  - FR-29: open price requests past their 48h window are expired and the
//           bounty is refunded to the requester.
//  - Hygiene: clear the isSuspended flag once a suspension window has elapsed.
//
// All writes use atomic, status-guarded updates so they are safe to run
// alongside the lazy paths (e.g. /requests/board) without double-processing.

export async function expireStaleSubmissions(now = new Date()): Promise<number> {
  const result = await prisma.priceSubmission.updateMany({
    where: {
      status: { in: ['pending', 'approved'] },
      expiresAt: { lte: now },
    },
    data: { status: 'expired' },
  });
  return result.count;
}

export async function refundExpiredRequests(now = new Date()): Promise<number> {
  const overdue = await prisma.priceRequest.findMany({
    where: { status: 'open', expiresAt: { lte: now } },
    select: { id: true, requesterId: true, bountyTokens: true, productName: true },
  });
  let refunded = 0;
  for (const r of overdue) {
    // Guard: only refund if THIS call is the one that flips it out of 'open'.
    const updated = await prisma.priceRequest.updateMany({
      where: { id: r.id, status: 'open' },
      data: { status: 'expired' },
    });
    if (updated.count > 0) {
      await awardTokens(r.requesterId, r.bountyTokens, `Refund: expired request for ${r.productName}`);
      refunded += 1;
    }
  }
  return refunded;
}

export async function clearElapsedSuspensions(now = new Date()): Promise<number> {
  const result = await prisma.user.updateMany({
    where: {
      isSuspended: true,
      bannedAt: null,
      suspendedUntil: { lte: now },
    },
    data: { isSuspended: false, suspendedUntil: null },
  });
  return result.count;
}

let running = false;

export async function runMaintenance(): Promise<void> {
  if (running) return; // avoid overlap if a previous tick is still working
  running = true;
  try {
    const now = new Date();
    const [expired, refunded, unsuspended] = [
      await expireStaleSubmissions(now),
      await refundExpiredRequests(now),
      await clearElapsedSuspensions(now),
    ];
    if (expired || refunded || unsuspended) {
      console.log(
        `[Maintenance] expired ${expired} submissions, refunded ${refunded} requests, lifted ${unsuspended} suspensions`,
      );
    }
  } catch (err) {
    console.error('[Maintenance] run failed:', err);
  } finally {
    running = false;
  }
}

export function startMaintenanceScheduler(): NodeJS.Timeout {
  const minutes = Number(process.env.MAINTENANCE_INTERVAL_MINUTES ?? 15);
  const intervalMs = Math.max(1, minutes) * 60 * 1000;
  // Kick off once shortly after boot, then on the configured interval.
  setTimeout(() => void runMaintenance(), 10_000);
  const timer = setInterval(() => void runMaintenance(), intervalMs);
  timer.unref?.();
  console.log(`[Maintenance] scheduler started (every ${minutes} min)`);
  return timer;
}
