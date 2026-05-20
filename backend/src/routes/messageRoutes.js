import express from "express";
import {
  getMessages,
  sendMessage,
  sendProductMessage,
} from "../controllers/messageController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.get("/:conversationId", protect, getMessages);
router.post("/", protect, sendMessage);
router.post("/product", protect, sendProductMessage);
router.post("/product", protect, sendProductMessage);
export default router;