import express from "express";
import {
  registerUser,
  loginUser,
  getUser,
  updateProfile,
  googleLogin,
  forgotPassword,
  resetPassword,
} from "../controllers/authController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/register", registerUser);
router.post("/login", loginUser);
router.get("/profile", protect, getUser);
router.put("/profile", protect, updateProfile);
router.post("/google", googleLogin);
router.post("/forgot-password", forgotPassword);
router.post("/reset-password", resetPassword);

export default router;
