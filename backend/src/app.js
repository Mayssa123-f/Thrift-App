import express from "express";
import cors from "cors";
import authRoutes from "./routes/authRoutes.js";
import path from "path";
import favoritesRoutes from "./routes/favoritesRoutes.js";
import productRoutes from "./routes/productRoutes.js";

import conversationRoutes from "./routes/conversationRoutes.js";
import messageRoutes from "./routes/messageRoutes.js";
import offerRoutes from "./routes/offerRoutes.js";

import cartRoutes from "./routes/cartRoutes.js";
import orderRoutes from "./routes/orderRoutes.js";

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({ message: "Thrift app backend is running" });
});

app.use("/api/auth", authRoutes);
app.use("/uploads", express.static(path.resolve("uploads")));
app.use("/api/favorites", favoritesRoutes);
app.use("/api/products", productRoutes);
app.use("/api/conversations", conversationRoutes);
app.use("/api/messages", messageRoutes);
app.use("/api/offers", offerRoutes);

app.use("/api/orders", orderRoutes);
app.use("/api/cart", cartRoutes);

export default app;