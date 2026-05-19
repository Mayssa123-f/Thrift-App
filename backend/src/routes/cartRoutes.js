import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  getCartItems,
  addToCart,
  removeFromCart,
  clearCart,
} from "../controllers/cartController.js";

const router = express.Router();

router.get("/", protect, getCartItems);
router.post("/:productId", protect, addToCart);
router.delete("/:productId", protect, removeFromCart);
router.delete("/", protect, clearCart);

export default router;