ALTER TABLE "User"
ADD COLUMN "suspensionCount" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN "warningCount" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN "bannedAt" TIMESTAMP(3),
ADD COLUMN "banReason" TEXT;

CREATE TABLE "AdminUserAction" (
    "id" TEXT NOT NULL,
    "targetUserId" TEXT NOT NULL,
    "adminUserId" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3),

    CONSTRAINT "AdminUserAction_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "AdminUserAction_targetUserId_createdAt_idx" ON "AdminUserAction"("targetUserId", "createdAt");
CREATE INDEX "AdminUserAction_action_createdAt_idx" ON "AdminUserAction"("action", "createdAt");

ALTER TABLE "AdminUserAction"
ADD CONSTRAINT "AdminUserAction_targetUserId_fkey"
FOREIGN KEY ("targetUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "AdminUserAction"
ADD CONSTRAINT "AdminUserAction_adminUserId_fkey"
FOREIGN KEY ("adminUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
