-- CreateTable
CREATE TABLE "VoucherInventory" (
    "id" TEXT NOT NULL,
    "supermarket" TEXT NOT NULL,
    "denominationAed" INTEGER NOT NULL DEFAULT 50,
    "code" TEXT NOT NULL,
    "isUsed" BOOLEAN NOT NULL DEFAULT false,
    "importedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usedAt" TIMESTAMP(3),
    "voucherRequestId" TEXT,

    CONSTRAINT "VoucherInventory_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "VoucherInventory_code_key" ON "VoucherInventory"("code");

-- CreateIndex
CREATE UNIQUE INDEX "VoucherInventory_voucherRequestId_key" ON "VoucherInventory"("voucherRequestId");

-- CreateIndex
CREATE INDEX "VoucherInventory_supermarket_denominationAed_isUsed_idx" ON "VoucherInventory"("supermarket", "denominationAed", "isUsed");

-- AddForeignKey
ALTER TABLE "VoucherInventory" ADD CONSTRAINT "VoucherInventory_voucherRequestId_fkey" FOREIGN KEY ("voucherRequestId") REFERENCES "VoucherRequest"("id") ON DELETE SET NULL ON UPDATE CASCADE;
