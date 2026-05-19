import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import {
  getProducts,
  getProductById,
  getMyListings
} from "../controllers/productController.js";

const router = express.Router();

router.get("/", protect, getProducts);
router.get("/my-listings", protect, getMyListings);
router.get("/:id", protect, getProductById);

export default router;