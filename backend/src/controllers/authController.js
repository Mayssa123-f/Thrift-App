import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import db from "../config/db.js";
import crypto from "crypto";
import transporter from "../config/email.js";
import { OAuth2Client } from "google-auth-library";

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

export const registerUser = async (req, res) => {
  try {
    const { full_name, email, password } = req.body;

    if (!full_name || !email || !password) {
      return res.status(400).json({
        message: "All fields are required",
      });
    }

    if (!isValidEmail(email)) {
      return res.status(400).json({
        message: "Invalid email format",
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        message: "Password must be at least 6 characters",
      });
    }

    const [existingUsers] = await db.query(
      "SELECT * FROM users WHERE email = ?",
      [email]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({
        message: "Email already exists",
      });
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    const [result] = await db.query(
      `INSERT INTO users (full_name, email, password_hash)
       VALUES (?, ?, ?)`,
      [full_name.trim(), email.trim(), password_hash]
    );

    const [newUsers] = await db.query(
      `SELECT id, full_name, email, role, bio, location, profile_image_url
       FROM users
       WHERE id = ?`,
      [result.insertId]
    );

    const user = newUsers[0];

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role,
      },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    res.status(201).json({
      message: "User registered successfully",
      token,
      user,
    });
  } catch (error) {
    console.log(error);

    res.status(500).json({
      message: "Server error",
    });
  }
};

export const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        message: "Email and password are required",
      });
    }

    if (!isValidEmail(email)) {
      return res.status(400).json({
        message: "Invalid email format",
      });
    }

    const [users] = await db.query("SELECT * FROM users WHERE email = ?", [
      email,
    ]);

    if (users.length === 0) {
      return res.status(401).json({
        message: "Invalid email or password",
      });
    }

    const user = users[0];

    const isPasswordCorrect = await bcrypt.compare(
      password,
      user.password_hash,
    );

    if (!isPasswordCorrect) {
      return res.status(401).json({
        message: "Invalid email or password",
      });
    }

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role,
      },
      process.env.JWT_SECRET,
      { expiresIn: "7d" },
    );

    res.json({
      message: "Login successful",
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.log(error);

    res.status(500).json({
      message: "Server error",
    });
  }
};

export const getUser = async (req, res) => {
  try {
    const [users] = await db.query(
      `SELECT id, full_name, email, role, bio, location, profile_image_url, created_at
       FROM users
       WHERE id = ?`,
      [req.user.id],
    );

    if (users.length === 0) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    res.json({
      user: users[0],
    });
  } catch (error) {
    console.log(error);

    res.status(500).json({
      message: "Server error",
    });
  }
};

export const updateProfile = async (req, res) => {
  try {
    const { full_name, bio, location, profile_image_url } = req.body;

    await db.query(
      `UPDATE users
       SET full_name = ?, bio = ?, location = ?, profile_image_url = ?
       WHERE id = ?`,
      [
        full_name,
        bio || null,
        location || null,
        profile_image_url || null,
        req.user.id,
      ],
    );

    const [users] = await db.query(
      `SELECT id, full_name, email, role, bio, location, profile_image_url, created_at
       FROM users
       WHERE id = ?`,
      [req.user.id],
    );

    res.json({
      message: "Profile updated successfully",
      user: users[0],
    });
  } catch (error) {
    console.log(error);

    res.status(500).json({
      message: "Server error",
    });
  }
};

export const googleLogin = async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ message: "Google token is required" });
    }

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();

    const googleId = payload.sub;
    const email = payload.email;
    const fullName = payload.name;

    const [users] = await db.query(
      "SELECT * FROM users WHERE google_id = ? OR email = ?",
      [googleId, email],
    );

    let user;

    if (users.length > 0) {
      user = users[0];

      if (!user.google_id) {
        await db.query("UPDATE users SET google_id = ? WHERE id = ?", [
          googleId,
          user.id,
        ]);
        user.google_id = googleId;
      }
    } else {
      const [result] = await db.query(
        `INSERT INTO users (google_id, full_name, email, password_hash)
         VALUES (?, ?, ?, ?)`,
        [googleId, fullName, email, "GOOGLE_AUTH"],
      );

      const [newUsers] = await db.query("SELECT * FROM users WHERE id = ?", [
        result.insertId,
      ]);

      user = newUsers[0];
    }

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role,
      },
      process.env.JWT_SECRET,
      { expiresIn: "7d" },
    );

    res.json({
      message: "Google login successful",
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.log(error);
    res.status(401).json({ message: "Google authentication failed" });
  }
};
export const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        message: "Email is required",
      });
    }

    const [users] = await db.query("SELECT * FROM users WHERE email = ?", [
      email,
    ]);

    if (users.length === 0) {
      return res.json({
        message: "If this email exists, a reset code has been sent",
      });
    }

    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();

    const hashedCode = crypto
      .createHash("sha256")
      .update(resetCode)
      .digest("hex");

    const expiry = new Date(Date.now() + 10 * 60 * 1000);

    await db.query(
      `UPDATE users
       SET reset_code = ?, reset_code_expiry = ?
       WHERE email = ?`,
      [hashedCode, expiry, email],
    );

    await transporter.sendMail({
      from: `"Vinty Support" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: "Vinty Password Reset Code",
      html: `
  <div style="font-family: Arial; padding: 20px;">
    <h2 style="color:#111;">Vinty Password Reset</h2>

    <p>We received a request to reset your password.</p>

    <p>Your verification code is:</p>

    <div style="
      font-size:32px;
      font-weight:bold;
      letter-spacing:4px;
      margin:20px 0;
      color:#000;
    ">
      ${resetCode}
    </div>

    <p>This code expires in 10 minutes.</p>

    <p>If you did not request this, you can safely ignore this email.</p>

    <br/>

    <p>— Vinty Support Team</p>
  </div>
`,
    });

    res.json({
      message: "If this email exists, a reset code has been sent",
    });
  } catch (error) {
    console.log(error);

    res.status(500).json({
      message: "Server error",
    });
  }
};
export const resetPassword = async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;

    if (!email || !code || !newPassword) {
      return res.status(400).json({
        message: "Email, code, and new password are required",
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        message: "Password must be at least 6 characters",
      });
    }

    const hashedCode = crypto.createHash("sha256").update(code).digest("hex");

    const [users] = await db.query(
      `SELECT * FROM users
       WHERE email = ?
       AND reset_code = ?
       AND reset_code_expiry > NOW()`,
      [email, hashedCode],
    );

    if (users.length === 0) {
      return res.status(400).json({
        message: "Invalid or expired reset code",
      });
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(newPassword, salt);

    await db.query(
      `UPDATE users
       SET password_hash = ?, reset_code = NULL, reset_code_expiry = NULL
       WHERE email = ?`,
      [password_hash, email],
    );

    res.json({
      message: "Password reset successfully",
    });
  } catch (error) {
    console.log(error);

    res.status(500).json({
      message: "Server error",
    });
  }
};
