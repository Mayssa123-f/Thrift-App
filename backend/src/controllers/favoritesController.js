import db from "../config/db.js";

// GET /api/favorites — get all favorites for logged in user
export const getFavorites = async (req, res) => {
  try {
    const buyerId = req.user.id;

    const [favorites] = await db.query(
      `SELECT
        f.id as favorite_id,
        f.created_at as saved_at,
        p.id as product_id,
        p.title,
        p.description,
        p.price,
        p.currency,
        p.brand,
        p.size,
        p.condition_type,
        p.gender,
        p.location,
        p.style_tag,
        p.color,
        p.is_available,
        u.full_name as seller_name,
        u.profile_image_url as seller_image
      FROM favorites f
      JOIN products p ON f.product_id = p.id
      JOIN users u ON p.seller_id = u.id
      WHERE f.buyer_id = ?
      ORDER BY f.created_at DESC`,
      [buyerId]
    );

    res.json({
      message: "Favorites fetched successfully",
      count: favorites.length,
      favorites,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

// POST /api/favorites/:productId — add to favorites
export const addFavorite = async (req, res) => {
  try {
    const buyerId = req.user.id;
    const productId = req.params.productId;

    // Check product exists
    const [products] = await db.query(
      "SELECT id, is_available FROM products WHERE id = ?",
      [productId]
    );

    if (products.length === 0) {
      return res.status(404).json({ message: "Product not found" });
    }

    // Check already in favorites
    const [existing] = await db.query(
      "SELECT id FROM favorites WHERE buyer_id = ? AND product_id = ?",
      [buyerId, productId]
    );

    if (existing.length > 0) {
      return res.status(400).json({ message: "Already in favorites" });
    }

    await db.query(
      "INSERT INTO favorites (buyer_id, product_id) VALUES (?, ?)",
      [buyerId, productId]
    );

    res.status(201).json({ message: "Added to favorites" });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

// DELETE /api/favorites/:productId — remove from favorites
export const removeFavorite = async (req, res) => {
  try {
    const buyerId = req.user.id;
    const productId = req.params.productId;

    const [result] = await db.query(
      "DELETE FROM favorites WHERE buyer_id = ? AND product_id = ?",
      [buyerId, productId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Favorite not found" });
    }

    res.json({ message: "Removed from favorites" });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

// GET /api/favorites/check/:productId — check if product is in favorites
export const checkFavorite = async (req, res) => {
  try {
    const buyerId = req.user.id;
    const productId = req.params.productId;

    const [existing] = await db.query(
      "SELECT id FROM favorites WHERE buyer_id = ? AND product_id = ?",
      [buyerId, productId]
    );

    res.json({ isFavorite: existing.length > 0 });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};