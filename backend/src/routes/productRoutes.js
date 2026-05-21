import express from "express";
import { protect } from "../middleware/authMiddleware.js";
import { upload } from "../middleware/uploadMiddleware.js";

import {
  getProducts,
  getProductById,
  getMyListings,
  createProduct,
  updateProduct,
  deleteProduct,
} from "../controllers/productController.js";

const router = express.Router();

// ================= ROUTES =================

// GET all products
router.get("/", protect, getProducts);

// GET my listings
router.get("/my-listings", protect, getMyListings);

// GET single product
router.get("/:id", protect, getProductById);

// CREATE product
router.post(
  "/",
  protect,
  upload.array("images", 4),
  createProduct
);

// UPDATE product
router.put("/:id", protect, updateProduct);

// DELETE product
router.delete("/:id", protect, deleteProduct);

export default router;