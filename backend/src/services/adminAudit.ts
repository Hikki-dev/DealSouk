import { prisma } from '../index';

export async function recordAdminAction(params: {
  adminUserId: string;
  targetUserId: string;
  action: string;
  reason: string;
  expiresAt?: Date;
}) {
  await prisma.adminUserAction.create({
    data: {
      adminUserId: params.adminUserId,
      targetUserId: params.targetUserId,
      action: params.action,
      reason: params.reason,
      expiresAt: params.expiresAt,
    },
  });
}
