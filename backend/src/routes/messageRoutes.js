import express from "express";
import {
  getMessages,
  sendMessage,
  sendProductMessage,
  markConversationMessagesAsRead,
  sendImageMessage,
} from "../controllers/messageController.js";

import { protect } from "../middleware/authMiddleware.js";
import { upload } from "../middleware/uploadMiddleware.js";

const router = express.Router();

router.put(
  "/read/:conversationId",
  protect,
  markConversationMessagesAsRead
);

router.get("/:conversationId", protect, getMessages);

router.post("/", protect, sendMessage);

router.post("/product", protect, sendProductMessage);

router.post(
  "/image",
  protect,
  upload.single("image"),
  sendImageMessage
);

export default router;