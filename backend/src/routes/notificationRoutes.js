import express from "express";
import { saveFcmToken } from "../controllers/notificationController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/token", protect, saveFcmToken);

export default router;