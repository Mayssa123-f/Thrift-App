import express from "express";
import { botChat } from "../controllers/botController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/chat", protect, botChat);

export default router;