import express from "express";
import cors from "cors";
import authRoutes from "./routes/authRoutes.js";
import favoritesRoutes from "./routes/favoritesRoutes.js";
import productRoutes from "./routes/productRoutes.js"
const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({ message: "Thrift app backend is running" });
});

app.use("/api/auth", authRoutes);
app.use("/api/favorites", favoritesRoutes);
app.use("/api/products", productRoutes);

export default app;

