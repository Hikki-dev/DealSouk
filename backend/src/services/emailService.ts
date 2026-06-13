import nodemailer from 'nodemailer';

const smtpHost = process.env.SMTP_HOST;
const smtpPort = process.env.SMTP_PORT ? Number(process.env.SMTP_PORT) : 587;
const smtpUser = process.env.SMTP_USER;
const smtpPass = process.env.SMTP_PASS;
const fromEmail = process.env.FROM_EMAIL || 'noreply@dealsouk.com';

let transporter: nodemailer.Transporter | null = null;

if (smtpHost && smtpUser && smtpPass) {
  transporter = nodemailer.createTransport({
    host: smtpHost,
    port: smtpPort,
    secure: smtpPort === 465,
    auth: {
      user: smtpUser,
      pass: smtpPass,
    },
  });
  console.log('[EmailService] SMTP transporter configured.');
} else {
  console.log('[EmailService] SMTP not configured. Falling back to console logging for emails.');
}

export async function sendEmail(to: string, subject: string, text: string, html?: string): Promise<void> {
  if (transporter) {
    try {
      await transporter.sendMail({
        from: fromEmail,
        to,
        subject,
        text,
        html: html || text,
      });
      console.log(`[EmailService] Email sent successfully to ${to}`);
    } catch (err) {
      console.error(`[EmailService] Failed to send email to ${to}:`, err);
    }
  } else {
    if (process.env.NODE_ENV === 'production') {
      const emailParts = to.split('@');
      const maskedEmail = emailParts.length === 2
        ? `${emailParts[0].slice(0, 3)}...` + `@${emailParts[1]}`
        : '***';
      console.warn(`[EmailService] SMTP not configured. Suppressed logging email body to prevent PII leak. Target: ${maskedEmail}, Subject: "${subject}"`);
    } else {
      console.log('\n=================== MOCK EMAIL ===================');
      console.log(`TO:      ${to}`);
      console.log(`FROM:    ${fromEmail}`);
      console.log(`SUBJECT: ${subject}`);
      console.log(`BODY:\n${text}`);
      console.log('==================================================\n');
    }
  }
}

export async function sendWarningEmail(email: string, reason: string): Promise<void> {
  const subject = 'DealSouk Account Warning';
  const text = `Hello,\n\nThis is a warning regarding your DealSouk account.\n\nReason: ${reason}\n\nPlease follow DealSouk rules and guidelines when submitting supermarket prices.\n\nBest regards,\nDealSouk Team`;
  await sendEmail(email, subject, text);
}

export async function sendSuspensionEmail(email: string, suspendedUntil: Date, reason: string): Promise<void> {
  const subject = 'DealSouk Account Suspended';
  const text = `Hello,\n\nYour DealSouk account has been temporarily suspended until ${suspendedUntil.toLocaleString()}.\n\nReason: ${reason}\n\nDuring this time, you will not be able to log in or submit prices.\n\nBest regards,\nDealSouk Team`;
  await sendEmail(email, subject, text);
}

export async function sendBanEmail(email: string, reason: string): Promise<void> {
  const subject = 'DealSouk Account Permanently Banned';
  const text = `Hello,\n\nYour DealSouk account has been permanently banned.\n\nReason: ${reason}\n\nYou will no longer have access to DealSouk shopper operations.\n\nBest regards,\nDealSouk Team`;
  await sendEmail(email, subject, text);
}
