import express from "express";
import {
  createPaymentIntent,
  createOrder,
  getMyOrders,
  getSellerOrders,
  updateOrderStatus,
  getWallet,
} from "../controllers/orderController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

router.use(protect);

router.post("/payment-intent", createPaymentIntent);
router.post("/", createOrder);
router.get("/", getMyOrders);
router.get("/seller", getSellerOrders);
router.get("/wallet", getWallet);
router.put("/:orderId/status", updateOrderStatus);

export default router;