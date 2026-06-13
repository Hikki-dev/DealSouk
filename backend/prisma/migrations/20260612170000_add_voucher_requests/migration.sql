-- CreateTable
CREATE TABLE "VoucherRequest" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "thresholdTokens" INTEGER NOT NULL,
    "tokenCost" INTEGER NOT NULL,
    "denominationAed" INTEGER NOT NULL DEFAULT 50,
    "supermarket" TEXT NOT NULL,
    "voucherCode" TEXT,
    "adminNote" TEXT,
    "requestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewedAt" TIMESTAMP(3),
    "deliveredAt" TIMESTAMP(3),

    CONSTRAINT "VoucherRequest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "VoucherRequest_status_requestedAt_idx" ON "VoucherRequest"("status", "requestedAt");

-- CreateIndex
CREATE INDEX "VoucherRequest_userId_status_idx" ON "VoucherRequest"("userId", "status");

-- AddForeignKey
ALTER TABLE "VoucherRequest" ADD CONSTRAINT "VoucherRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
