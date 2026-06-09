import express from "express";
import {
  createConversation,
  getConversations,
  getConversationById,
  getUnreadMessagesCount,
} from "../controllers/conversationController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/", protect, createConversation);
router.get("/", protect, getConversations);
router.get("/unread/count", protect, getUnreadMessagesCount);
router.get("/:id", protect, getConversationById);

export default router;
