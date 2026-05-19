import express from "express";
import {
  createOffer,
  acceptOffer,
  declineOffer,
} from "../controllers/offerController.js";
import { protect } from "../middleware/authMiddleware.js";


const router = express.Router();

router.post("/", protect, createOffer);
router.patch("/:offerId/accept", protect, acceptOffer);
router.patch("/:offerId/decline", protect, declineOffer);

export default router;