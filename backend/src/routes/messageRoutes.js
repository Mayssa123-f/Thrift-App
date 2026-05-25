import express from "express";
import {
  getMessages,
  sendMessage,
  sendProductMessage,
  markConversationMessagesAsRead,
} from "../controllers/messageController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();
router.put("/read/:conversationId", protect, markConversationMessagesAsRead);
router.get("/:conversationId", protect, getMessages);
router.post("/", protect, sendMessage);
router.post("/product", protect, sendProductMessage);
router.post("/product", protect, sendProductMessage);
export default router;
