import db from "../config/db.js";

// GET /api/cart
export const getCartItems = async (req, res) => {
  try {
    const buyerId = req.user.id;

    const [items] = await db.query(
      `
  SELECT
    ci.id AS cart_item_id,
    ci.quantity,
    ci.selected_size,
    ci.created_at AS added_at,

    p.id AS id,
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

    ao.id AS accepted_offer_id,
    ao.offered_price AS accepted_offer_price,

    c.name AS category,

    u.id AS seller_id,
    u.full_name AS seller,
    u.profile_image_url AS seller_image,

    pi.image_url AS image

  FROM cart_items ci

  JOIN products p 
    ON ci.product_id = p.id

 LEFT JOIN offers ao
  ON ao.id = (
    SELECT o2.id
    FROM offers o2
    WHERE o2.product_id = p.id
    AND o2.buyer_id = ?
    AND o2.status = 'accepted'
  ORDER BY o2.created_at DESC
    LIMIT 1
  )

  LEFT JOIN categories c 
    ON p.category_id = c.id

  JOIN users u 
    ON p.seller_id = u.id

  LEFT JOIN product_images pi
    ON p.id = pi.product_id 
    AND pi.is_primary = TRUE

  WHERE ci.buyer_id = ?

  ORDER BY ci.created_at DESC
  `,
      [buyerId, buyerId],
    );

    res.json({
      message: "Cart fetched successfully",
      count: items.length,
      cartItems: items,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

// POST /api/cart/:productId
export const addToCart = async (req, res) => {
  try {
    const buyerId = req.user.id;
    const { productId } = req.params;
    const { selected_size } = req.body;

    const [products] = await db.query(
      "SELECT id, is_available, seller_id FROM products WHERE id = ?",
      [productId],
    );

    if (products.length === 0) {
      return res.status(404).json({ message: "Product not found" });
    }

    if (!products[0].is_available) {
      return res.status(400).json({ message: "Product is not available" });
    }
    if (products[0].seller_id === buyerId) {
      return res.status(400).json({
        message: "You cannot add your own item to cart",
      });
    }
    const [existing] = await db.query(
      `
      SELECT id, quantity
      FROM cart_items
      WHERE buyer_id = ? AND product_id = ?
      `,
      [buyerId, productId],
    );

    if (existing.length > 0) {
      return res.status(400).json({
        message: "This item is already in your cart",
      });
    }

    await db.query(
      `
      INSERT INTO cart_items (buyer_id, product_id, quantity, selected_size)
      VALUES (?, ?, 1, ?)
      `,
      [buyerId, productId, selected_size || null],
    );

    res.status(201).json({ message: "Added to cart" });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

// DELETE /api/cart/:productId
export const removeFromCart = async (req, res) => {
  try {
    const buyerId = req.user.id;
    const { productId } = req.params;

    const [result] = await db.query(
      `
      DELETE FROM cart_items
      WHERE buyer_id = ? AND product_id = ?
      `,
      [buyerId, productId],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Cart item not found" });
    }

    res.json({ message: "Removed from cart" });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

// DELETE /api/cart
export const clearCart = async (req, res) => {
  try {
    const buyerId = req.user.id;

    await db.query("DELETE FROM cart_items WHERE buyer_id = ?", [buyerId]);

    res.json({ message: "Cart cleared" });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};
