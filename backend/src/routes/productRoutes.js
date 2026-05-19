import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import { upload } from "../middleware/uploadMiddleware.js";
import {
  getProducts,
  getProductById,
  getMyListings,
  createProduct,
} from "../controllers/productController.js";

const router = express.Router();

router.get("/", protect, getProducts);
router.get("/my-listings", protect, getMyListings);
router.get("/:id", protect, getProductById);
router.post(
  "/",
  protect,
  upload.array("images", 4),
  createProduct
);

export default router;