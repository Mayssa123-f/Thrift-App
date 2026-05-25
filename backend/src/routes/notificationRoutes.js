import express from "express";

import {
  saveFcmToken,
  getNotifications,
  getUnreadNotificationCount,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  clearNotifications,
} from "../controllers/notificationController.js";

import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/token", protect, saveFcmToken);

router.get("/", protect, getNotifications);
router.get("/unread-count", protect, getUnreadNotificationCount);

router.patch("/read-all", protect, markAllNotificationsAsRead);
router.patch("/:id/read", protect, markNotificationAsRead);

router.delete("/clear", protect, clearNotifications);

export default router;
