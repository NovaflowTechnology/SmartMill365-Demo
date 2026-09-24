const express = require("express");
const admin = require("firebase-admin");
const crypto = require("crypto");
const nodemailer = require("nodemailer");
const https = require("https");

// eslint-disable-next-line new-cap
const router = express.Router();
const db = admin.firestore();

const OTP_COLLECTION = "otp_verifications";
const OTP_EXPIRY_MS = 15 * 60 * 1000; // 15 minutes
const OTP_MAX_ATTEMPTS = 3;

// ic7 is the Firebase project that holds Firebase Auth users
const IC7_API = "https://api-ic7ypg6ukq-uc.a.run.app";

// ── Helpers ───────────────────────────────────────────────────────────────────

function generateOtp() {
  return String(Math.floor(100000 + crypto.randomInt(900000)));
}

function hashOtp(otp) {
  return crypto.createHash("sha256").update(otp).digest("hex");
}

function createTransporter() {
  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });
}

function otpLockedEmailHtml(userName) {
  return `
<!DOCTYPE html><html><head><meta charset="UTF-8"/>
<style>
  body{font-family:Arial,sans-serif;background:#0f172a;color:#e2e8f0;margin:0;padding:0}
  .container{max-width:480px;margin:40px auto;background:#1e293b;border-radius:12px;overflow:hidden}
  .header{background:linear-gradient(135deg,#0a0a1f 0%,#14142b 100%);padding:32px 24px;text-align:center;border-bottom:1px solid #334155}
  .header h1{color:#31ecfc;font-size:22px;margin:0;letter-spacing:2px;font-family:monospace}
  .body{padding:32px 24px}.body p{color:#94a3b8;font-size:14px;line-height:1.6}
  .alert{background:#450a0a;border:2px solid #ef4444;border-radius:8px;padding:16px;margin:24px 0;text-align:center}
  .alert-text{font-size:15px;font-weight:bold;color:#ef4444}
  .footer{padding:16px 24px;border-top:1px solid #334155;text-align:center;color:#475569;font-size:11px}
</style></head><body>
<div class="container">
  <div class="header"><h1>SMARTFACTORY365</h1></div>
  <div class="body">
    <p>Hello <strong style="color:#e2e8f0">${userName}</strong>,</p>
    <p>Your OTP verification has been <strong style="color:#ef4444">invalidated</strong> after 3 failed attempts.</p>
    <div class="alert"><div class="alert-text">⚠ OTP Invalidated</div></div>
    <p>Please go to <strong>Profile Settings</strong> and submit a new password change request to receive a fresh OTP code.</p>
    <p>If you did not attempt this, please contact your system administrator immediately.</p>
  </div>
  <div class="footer">SmartFactory365 &nbsp;·&nbsp; This is an automated message, do not reply.</div>
</div></body></html>`;
}

function declinedLockedEmailHtml(userName, unlockDate) {
  return `
<!DOCTYPE html><html><head><meta charset="UTF-8"/>
<style>
  body{font-family:Arial,sans-serif;background:#0f172a;color:#e2e8f0;margin:0;padding:0}
  .container{max-width:480px;margin:40px auto;background:#1e293b;border-radius:12px;overflow:hidden}
  .header{background:linear-gradient(135deg,#0a0a1f 0%,#14142b 100%);padding:32px 24px;text-align:center;border-bottom:1px solid #334155}
  .header h1{color:#31ecfc;font-size:22px;margin:0;letter-spacing:2px;font-family:monospace}
  .body{padding:32px 24px}.body p{color:#94a3b8;font-size:14px;line-height:1.6}
  .alert{background:#451a03;border:2px solid #f97316;border-radius:8px;padding:16px;margin:24px 0;text-align:center}
  .alert-text{font-size:15px;font-weight:bold;color:#f97316}
  .date{font-size:20px;font-weight:bold;color:#f97316;margin-top:8px}
  .footer{padding:16px 24px;border-top:1px solid #334155;text-align:center;color:#475569;font-size:11px}
</style></head><body>
<div class="container">
  <div class="header"><h1>SMARTFACTORY365</h1></div>
  <div class="body">
    <p>Hello <strong style="color:#e2e8f0">${userName}</strong>,</p>
    <p>Your password change request has been <strong style="color:#f97316">declined 3 times</strong> and your account has been temporarily locked.</p>
    <div class="alert">
      <div class="alert-text">🔒 Account Locked</div>
      <div class="date">Try again on ${unlockDate}</div>
    </div>
    <p>You will be able to submit a new password change request after the lock expires.</p>
    <p>If you believe this is an error, please contact your system administrator.</p>
  </div>
  <div class="footer">SmartFactory365 &nbsp;·&nbsp; This is an automated message, do not reply.</div>
</div></body></html>`;
}

/**
 * Call ic7 PUT /users/updateUserPassword to change the user's Firebase Auth password.
 * Returns a Promise that resolves on 200, rejects otherwise.
 */
function updatePasswordViaIc7(userUid, newPassword) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ userUid, newPassword });
    const url = new URL(`${IC7_API}/users/updateUserPassword`);
    const options = {
      hostname: url.hostname,
      path: url.pathname,
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body),
      },
    };
    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`ic7 updateUserPassword failed (${res.statusCode}): ${data}`));
        }
      });
    });
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

function otpEmailHtml(userName, otp) {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <style>
    body { font-family: Arial, sans-serif; background: #0f172a; color: #e2e8f0; margin: 0; padding: 0; }
    .container { max-width: 480px; margin: 40px auto; background: #1e293b; border-radius: 12px; overflow: hidden; }
    .header { background: linear-gradient(135deg, #0a0a1f 0%, #14142b 100%); padding: 32px 24px; text-align: center; border-bottom: 1px solid #334155; }
    .header h1 { color: #31ecfc; font-size: 22px; margin: 0; letter-spacing: 2px; font-family: monospace; }
    .body { padding: 32px 24px; }
    .body p { color: #94a3b8; font-size: 14px; line-height: 1.6; }
    .otp-box { background: #0f172a; border: 2px solid #31ecfc; border-radius: 8px; text-align: center; padding: 20px; margin: 24px 0; }
    .otp-code { font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #31ecfc; font-family: monospace; }
    .expiry { color: #64748b; font-size: 12px; margin-top: 8px; }
    .footer { padding: 16px 24px; border-top: 1px solid #334155; text-align: center; color: #475569; font-size: 11px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header"><h1>SMARTFACTORY365</h1></div>
    <div class="body">
      <p>Hello <strong style="color:#e2e8f0">${userName}</strong>,</p>
      <p>Your password change request has been <strong style="color:#24d18a">approved</strong>. Use the OTP code below to set your new password.</p>
      <div class="otp-box">
        <div class="otp-code">${otp}</div>
        <div class="expiry">Expires in 15 minutes &nbsp;·&nbsp; Maximum ${OTP_MAX_ATTEMPTS} attempts</div>
      </div>
      <p>If you did not request a password change, please contact your system administrator immediately.</p>
    </div>
    <div class="footer">SmartFactory365 &nbsp;·&nbsp; This is an automated message, do not reply.</div>
  </div>
</body>
</html>`;
}

// ── POST /password-reset/send-otp ─────────────────────────────────────────────
// Body: { uid, email, userName }
router.post("/send-otp", async (req, res) => {
  const { uid, email, userName } = req.body;

  if (!uid || !email) {
    return res.status(400).json({ error: "uid and email are required." });
  }

  try {
    const otp = generateOtp();
    const hashedOtp = hashOtp(otp);
    const expiresAt = Date.now() + OTP_EXPIRY_MS;

    // Store hashed OTP in Firestore — never store plain text
    await db.collection(OTP_COLLECTION).doc(uid).set({
      hashedOtp,
      expiresAt,
      attempts: 0,
      email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const transporter = createTransporter();
    await transporter.sendMail({
      from: `"SmartFactory365" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: "OTP Code — Password Reset — SmartFactory365",
      html: otpEmailHtml(userName || "User", otp),
    });

    console.log(`[send-otp] OTP sent to ${email} for uid=${uid}`);
    return res.status(200).json({ success: true, message: "OTP generated. Reset email sent." });
  } catch (error) {
    console.error("[send-otp] Error:", error);
    return res.status(500).json({ error: error.message });
  }
});

// ── POST /password-reset/verify-otp ──────────────────────────────────────────
// Body: { uid, otp, newPassword }
router.post("/verify-otp", async (req, res) => {
  const { uid, otp, newPassword } = req.body;

  if (!uid || !otp || !newPassword) {
    return res.status(400).json({ error: "uid, otp, and newPassword are required." });
  }

  if (newPassword.length < 6) {
    return res.status(400).json({ error: "Password must be at least 6 characters." });
  }

  try {
    const otpDoc = await db.collection(OTP_COLLECTION).doc(uid).get();

    if (!otpDoc.exists) {
      return res.status(404).json({ error: "No OTP found. Please request a new one." });
    }

    const { hashedOtp, expiresAt, attempts } = otpDoc.data();

    // Check expiry
    if (Date.now() > expiresAt) {
      await db.collection(OTP_COLLECTION).doc(uid).delete();
      return res.status(410).json({ error: "OTP has expired. Please request a new one." });
    }

    // Check max attempts
    if (attempts >= OTP_MAX_ATTEMPTS) {
      const { email: lockedEmail } = otpDoc.data();
      await db.collection(OTP_COLLECTION).doc(uid).delete();
      // Notify user their OTP is invalidated
      try {
        const roleDoc = await db.collection("roles").doc(uid).get();
        const userName = roleDoc.exists ? (roleDoc.data().display_name || "User") : "User";
        await createTransporter().sendMail({
          from: `"SmartFactory365" <${process.env.EMAIL_USER}>`,
          to: lockedEmail,
          subject: "OTP Invalidated — SmartFactory365",
          html: otpLockedEmailHtml(userName),
        });
      } catch (_) {}
      return res.status(429).json({ error: "Too many attempts. OTP invalidated. Please request a new one." });
    }

    // Verify OTP
    if (hashOtp(otp) !== hashedOtp) {
      const newAttempts = attempts + 1;
      const remaining = OTP_MAX_ATTEMPTS - newAttempts;
      // If this wrong attempt exhausts all tries, send notification email
      if (remaining === 0) {
        const { email: lockedEmail } = otpDoc.data();
        await db.collection(OTP_COLLECTION).doc(uid).delete();
        try {
          const roleDoc = await db.collection("roles").doc(uid).get();
          const userName = roleDoc.exists ? (roleDoc.data().display_name || "User") : "User";
          await createTransporter().sendMail({
            from: `"SmartFactory365" <${process.env.EMAIL_USER}>`,
            to: lockedEmail,
            subject: "OTP Invalidated — SmartFactory365",
            html: otpLockedEmailHtml(userName),
          });
        } catch (_) {}
        return res.status(429).json({ error: "Too many attempts. OTP invalidated. Please request a new one." });
      }
      await db.collection(OTP_COLLECTION).doc(uid).update({
        attempts: admin.firestore.FieldValue.increment(1),
      });
      return res.status(401).json({
        error: `Invalid OTP. ${remaining} attempt(s) remaining.`,
        attemptsRemaining: remaining,
      });
    }

    // OTP valid — update password via ic7 API (Firebase Auth users live in intechsf365)
    await updatePasswordViaIc7(uid, newPassword);

    // Delete OTP doc
    await db.collection(OTP_COLLECTION).doc(uid).delete();

    console.log(`[verify-otp] Password updated for uid=${uid}`);
    return res.status(200).json({ success: true, message: "Password updated successfully." });
  } catch (error) {
    console.error("[verify-otp] Error:", error);
    return res.status(500).json({ error: error.message });
  }
});

// ── POST /password-reset/resend-otp ──────────────────────────────────────────
// Body: { uid }
router.post("/resend-otp", async (req, res) => {
  const { uid } = req.body;
  if (!uid) return res.status(400).json({ error: "uid is required." });

  try {
    const otpDoc = await db.collection(OTP_COLLECTION).doc(uid).get();
    if (!otpDoc.exists) {
      return res.status(404).json({ error: "No active OTP request found for this user." });
    }

    const { email } = otpDoc.data();

    // Get display name from roles collection
    const roleDoc = await db.collection("roles").doc(uid).get();
    const userName = roleDoc.exists ? (roleDoc.data().display_name || "User") : "User";

    const otp = generateOtp();
    const hashedOtp = hashOtp(otp);
    const expiresAt = Date.now() + OTP_EXPIRY_MS;

    await db.collection(OTP_COLLECTION).doc(uid).set({
      hashedOtp,
      expiresAt,
      attempts: 0,
      email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const transporter = createTransporter();
    await transporter.sendMail({
      from: `"SmartFactory365" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: "New OTP Code — Password Reset — SmartFactory365",
      html: otpEmailHtml(userName, otp),
    });

    return res.status(200).json({ success: true, message: "New OTP sent successfully." });
  } catch (error) {
    console.error("[resend-otp] Error:", error);
    return res.status(500).json({ error: error.message });
  }
});

// ── POST /password-reset/notify-locked ───────────────────────────────────────
// Called by Flutter when admin declines request 3 times → user locked until tomorrow.
// Body: { uid, email, userName, unlockDate }
router.post("/notify-locked", async (req, res) => {
  const { uid, email, userName, unlockDate } = req.body;
  if (!uid || !email) {
    return res.status(400).json({ error: "uid and email are required." });
  }
  try {
    await createTransporter().sendMail({
      from: `"SmartFactory365" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: "Password Request Locked — SmartFactory365",
      html: declinedLockedEmailHtml(userName || "User", unlockDate || "tomorrow"),
    });
    console.log(`[notify-locked] Lock email sent to ${email} for uid=${uid}`);
    return res.status(200).json({ success: true });
  } catch (error) {
    console.error("[notify-locked] Error:", error);
    return res.status(500).json({ error: error.message });
  }
});

module.exports = router;
