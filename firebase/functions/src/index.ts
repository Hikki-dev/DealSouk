import { initializeApp } from "firebase-admin/app";
import { getStorage } from "firebase-admin/storage";
import { logger } from "firebase-functions";
import { defineSecret } from "firebase-functions/params";
import { onObjectFinalized } from "firebase-functions/v2/storage";
import { GoogleAuth } from "google-auth-library";
import sharp from "sharp";

initializeApp();

const malwareScanUrl = defineSecret("MALWARE_SCAN_URL");
const googleAuth = new GoogleAuth();

const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
const PRIVATE_UPLOAD_PREFIXES = ["receipts/", "price-labels/"];
const PUBLIC_UPLOAD_PREFIXES = ["avatars/"];
const ALL_UPLOAD_PREFIXES = [...PRIVATE_UPLOAD_PREFIXES, ...PUBLIC_UPLOAD_PREFIXES];

type MalwareScanResult = "clean" | "infected" | "not_configured";

function isManagedUploadPath(name: string): boolean {
  return ALL_UPLOAD_PREFIXES.some((prefix) => name.startsWith(prefix));
}

function isAlreadyProcessed(metadata: Record<string, string> | undefined): boolean {
  return metadata?.dealsoukProcessed === "true";
}

function isSupportedImage(contentType?: string): boolean {
  return Boolean(contentType?.match(/^image\/(jpeg|jpg|png|webp|heic|heif)$/i));
}

async function scanForMalware(bucket: string, objectName: string): Promise<MalwareScanResult> {
  const scanUrl = malwareScanUrl.value();
  if (!scanUrl) return "not_configured";

  const client = await googleAuth.getIdTokenClient(scanUrl);
  const response = await client.request<{ status?: string }>({
    url: scanUrl,
    method: "POST",
    data: { bucket, objectName },
  });

  const result = response.data;
  return result.status === "clean" ? "clean" : "infected";
}

async function quarantineObject(bucketName: string, objectName: string, reason: string): Promise<void> {
  const bucket = getStorage().bucket(bucketName);
  const source = bucket.file(objectName);
  const destinationName = `quarantine/${Date.now()}-${objectName}`;

  await source.move(destinationName);
  await bucket.file(destinationName).setMetadata({
    metadata: {
      dealsoukQuarantineReason: reason,
      dealsoukProcessed: "true",
    },
  });

  logger.warn("Quarantined uploaded object", { objectName, destinationName, reason });
}

export const sanitizeUploadedImage = onObjectFinalized(
  {
    region: "me-central1",
    memory: "1GiB",
    timeoutSeconds: 120,
    secrets: [malwareScanUrl],
  },
  async (event) => {
    const object = event.data;
    const bucketName = object.bucket;
    const objectName = object.name;
    const contentType = object.contentType;
    const metadata = object.metadata;
    const size = Number(object.size ?? 0);

    if (!objectName || !isManagedUploadPath(objectName)) return;
    if (isAlreadyProcessed(metadata)) return;

    if (!isSupportedImage(contentType)) {
      await quarantineObject(bucketName, objectName, "unsupported_content_type");
      return;
    }

    if (!Number.isFinite(size) || size <= 0 || size > MAX_IMAGE_BYTES) {
      await quarantineObject(bucketName, objectName, "invalid_size");
      return;
    }

    const scanStatus = await scanForMalware(bucketName, objectName);
    if (scanStatus === "infected") {
      await quarantineObject(bucketName, objectName, "malware_scan_failed");
      return;
    }

    const bucket = getStorage().bucket(bucketName);
    const file = bucket.file(objectName);
    const [input] = await file.download();

    const output = await sharp(input, { failOn: "truncated" })
      .rotate()
      .resize({
        width: 1600,
        height: 1600,
        fit: "inside",
        withoutEnlargement: true,
      })
      .jpeg({ quality: 82, mozjpeg: true })
      .toBuffer();

    await file.save(output, {
      resumable: false,
      metadata: {
        contentType: "image/jpeg",
        cacheControl: objectName.startsWith("avatars/")
          ? "public, max-age=3600"
          : "private, max-age=0, no-transform",
        metadata: {
          dealsoukProcessed: "true",
          exifStripped: "true",
          malwareScanStatus: scanStatus,
          originalContentType: contentType ?? "unknown",
        },
      },
    });

    logger.info("Sanitized uploaded image", {
      objectName,
      scanStatus,
      originalBytes: size,
      sanitizedBytes: output.length,
    });
  },
);
