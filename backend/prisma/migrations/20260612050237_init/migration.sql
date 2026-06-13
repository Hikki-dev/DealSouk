-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "firebaseUid" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "phoneNumber" TEXT,
    "homeArea" TEXT,
    "preferredLocale" TEXT NOT NULL DEFAULT 'en',
    "tokenBalance" INTEGER NOT NULL DEFAULT 0,
    "accuracyRating" DOUBLE PRECISION NOT NULL DEFAULT 100.0,
    "isSuspended" BOOLEAN NOT NULL DEFAULT false,
    "suspendedUntil" TIMESTAMP(3),
    "isAdmin" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Store" (
    "id" TEXT NOT NULL,
    "chain" TEXT NOT NULL,
    "branchName" TEXT NOT NULL,
    "area" TEXT NOT NULL,
    "lat" DOUBLE PRECISION NOT NULL,
    "lng" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "Store_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Product" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "brand" TEXT,
    "packSize" TEXT,
    "category" TEXT NOT NULL,
    "imageUrl" TEXT,

    CONSTRAINT "Product_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PriceSubmission" (
    "id" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "storeId" TEXT NOT NULL,
    "sourcerId" TEXT NOT NULL,
    "priceAed" DECIMAL(10,2) NOT NULL,
    "hasReceipt" BOOLEAN NOT NULL DEFAULT false,
    "receiptUrl" TEXT,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "flagCount" INTEGER NOT NULL DEFAULT 0,
    "tokensAwarded" INTEGER NOT NULL DEFAULT 0,
    "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PriceSubmission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SubmissionFlag" (
    "id" TEXT NOT NULL,
    "submissionId" TEXT NOT NULL,
    "flaggerId" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SubmissionFlag_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TokenTransaction" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "reason" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TokenTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PriceRequest" (
    "id" TEXT NOT NULL,
    "requesterId" TEXT NOT NULL,
    "productName" TEXT NOT NULL,
    "storeName" TEXT NOT NULL,
    "bountyTokens" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'open',
    "fulfilledBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PriceRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Badge" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "emoji" TEXT NOT NULL,
    "description" TEXT NOT NULL,

    CONSTRAINT "Badge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserBadge" (
    "userId" TEXT NOT NULL,
    "badgeId" TEXT NOT NULL,
    "unlockedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UserBadge_pkey" PRIMARY KEY ("userId","badgeId")
);

-- CreateTable
CREATE TABLE "AdminSettings" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "tokenEarnRate" INTEGER NOT NULL DEFAULT 50,
    "voucherThreshold" INTEGER NOT NULL DEFAULT 500,
    "dailySubmissionCap" INTEGER NOT NULL DEFAULT 30,
    "requestCostTokens" INTEGER NOT NULL DEFAULT 10,
    "decayFactor" DOUBLE PRECISION NOT NULL DEFAULT 0.7,

    CONSTRAINT "AdminSettings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_firebaseUid_key" ON "User"("firebaseUid");

-- CreateIndex
CREATE UNIQUE INDEX "User_phoneNumber_key" ON "User"("phoneNumber");

-- CreateIndex
CREATE INDEX "Store_chain_idx" ON "Store"("chain");

-- CreateIndex
CREATE INDEX "Store_lat_lng_idx" ON "Store"("lat", "lng");

-- CreateIndex
CREATE INDEX "Product_name_idx" ON "Product"("name");

-- CreateIndex
CREATE INDEX "Product_category_idx" ON "Product"("category");

-- CreateIndex
CREATE INDEX "PriceSubmission_productId_storeId_submittedAt_idx" ON "PriceSubmission"("productId", "storeId", "submittedAt");

-- CreateIndex
CREATE INDEX "PriceSubmission_status_submittedAt_idx" ON "PriceSubmission"("status", "submittedAt");

-- CreateIndex
CREATE INDEX "PriceSubmission_sourcerId_idx" ON "PriceSubmission"("sourcerId");

-- CreateIndex
CREATE UNIQUE INDEX "SubmissionFlag_submissionId_flaggerId_key" ON "SubmissionFlag"("submissionId", "flaggerId");

-- CreateIndex
CREATE INDEX "TokenTransaction_userId_createdAt_idx" ON "TokenTransaction"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "PriceRequest_status_bountyTokens_idx" ON "PriceRequest"("status", "bountyTokens");

-- AddForeignKey
ALTER TABLE "PriceSubmission" ADD CONSTRAINT "PriceSubmission_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PriceSubmission" ADD CONSTRAINT "PriceSubmission_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "Store"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PriceSubmission" ADD CONSTRAINT "PriceSubmission_sourcerId_fkey" FOREIGN KEY ("sourcerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SubmissionFlag" ADD CONSTRAINT "SubmissionFlag_submissionId_fkey" FOREIGN KEY ("submissionId") REFERENCES "PriceSubmission"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SubmissionFlag" ADD CONSTRAINT "SubmissionFlag_flaggerId_fkey" FOREIGN KEY ("flaggerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TokenTransaction" ADD CONSTRAINT "TokenTransaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PriceRequest" ADD CONSTRAINT "PriceRequest_requesterId_fkey" FOREIGN KEY ("requesterId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserBadge" ADD CONSTRAINT "UserBadge_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserBadge" ADD CONSTRAINT "UserBadge_badgeId_fkey" FOREIGN KEY ("badgeId") REFERENCES "Badge"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
