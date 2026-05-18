import express from "express";
import cors from "cors";
import authRoutes from "./routes/authRoutes.js";


import favoritesRoutes from "./routes/favoritesRoutes.js";
import productRoutes from "./routes/productRoutes.js"

import conversationRoutes from "./routes/conversationRoutes.js";
import messageRoutes from "./routes/messageRoutes.js";
import offerRoutes from "./routes/offerRoutes.js";
  



const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({ message: "Thrift app backend is running" });
});

app.use("/api/auth", authRoutes);


app.use("/api/favorites", favoritesRoutes);
app.use("/api/products", productRoutes);
app.use("/api/conversations", conversationRoutes);
app.use("/api/messages", messageRoutes);
app.use("/api/offers", offerRoutes);






export default app;



