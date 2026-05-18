import express from "express";
import {
  getFavorites,
  addFavorite,
  removeFavorite,
  checkFavorite,
} from "../controllers/favoritesController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();


router.use(protect);

router.get("/", getFavorites);
router.post("/:productId", addFavorite);
router.delete("/:productId", removeFavorite);
router.get("/check/:productId", checkFavorite);

export default router;