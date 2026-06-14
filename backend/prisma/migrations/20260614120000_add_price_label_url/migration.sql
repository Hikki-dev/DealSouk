-- Persist the price-label proof photo URL on a submission so admins can preview
-- it during moderation (the receipt URL was already stored; the price-label
-- photo was captured client-side but discarded). Additive, nullable column.
ALTER TABLE "PriceSubmission" ADD COLUMN "priceLabelUrl" TEXT;
