import crypto from 'crypto';

const ALGORITHM = 'aes-256-cbc';
const IV_LENGTH = 16;

// Key must be exactly 32 bytes. We generate a 32-byte key from the env variable,
// or use a development fallback key if not specified.
const ENCRYPTION_KEY = process.env.DATABASE_ENCRYPTION_KEY 
  ? crypto.createHash('sha256').update(process.env.DATABASE_ENCRYPTION_KEY).digest()
  : crypto.createHash('sha256').update('dealsouk-default-development-encryption-key-secret-12345').digest();

export function encrypt(text: string): string {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return iv.toString('hex') + ':' + encrypted;
}

export function decrypt(text: string): string {
  const parts = text.split(':');
  if (parts.length !== 2) {
    throw new Error('Invalid encrypted format');
  }
  const iv = Buffer.from(parts[0], 'hex');
  const encryptedText = Buffer.from(parts[1], 'hex');
  const decipher = crypto.createDecipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
  let decrypted = decipher.update(encryptedText);
  let decryptedStr = decrypted.toString('utf8');
  decryptedStr += decipher.final('utf8');
  return decryptedStr;
}
