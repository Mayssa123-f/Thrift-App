import Stripe from "stripe";
import db from "../config/db.js";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

// POST /api/orders/payment-intent — create Stripe PaymentIntent
export const createPaymentIntent = async (req, res) => {
  try {
    const buyerId = req.user.id;

    const [cartItems] = await db.query(
      `SELECT
        ci.id AS cart_item_id,
        ci.product_id,
        ci.quantity,
        p.price,
        p.seller_id,
        p.is_available,
        p.title
       FROM cart_items ci
       JOIN products p ON ci.product_id = p.id
       WHERE ci.buyer_id = ?`,
      [buyerId]
    );

    if (cartItems.length === 0) {
      return res.status(400).json({ message: "Your cart is empty" });
    }

    const unavailable = cartItems.filter((item) => !item.is_available);
    if (unavailable.length > 0) {
      return res.status(400).json({
        message: `"${unavailable[0].title}" is no longer available`,
      });
    }

    const subtotal = cartItems.reduce(
      (sum, item) => sum + parseFloat(item.price) * item.quantity,
      0
    );
    const shipping = 8.0;
    const tax = parseFloat((subtotal * 0.05).toFixed(2));
    const total = parseFloat((subtotal + shipping + tax).toFixed(2));

    // Stripe amount is in cents
    const amountInCents = Math.round(total * 100);

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInCents,
      currency: "usd",
      metadata: {
        buyer_id: buyerId.toString(),
      },
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      total,
      amountInCents,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

// POST /api/orders — create order after payment confirmed
export const createOrder = async (req, res) => {
  try {
    const buyerId = req.user.id;
    const { delivery_method, payment_intent_id } = req.body;

    // Verify payment with Stripe
    if (payment_intent_id) {
      const paymentIntent = await stripe.paymentIntents.retrieve(
        payment_intent_id
      );

      if (paymentIntent.status !== "succeeded") {
        return res.status(400).json({
          message: "Payment not confirmed",
        });
      }
    }

    const [cartItems] = await db.query(
      `SELECT
        ci.id AS cart_item_id,
        ci.product_id,
        ci.quantity,
        ci.selected_size,
        p.price,
        p.seller_id,
        p.is_available,
        p.title
       FROM cart_items ci
       JOIN products p ON ci.product_id = p.id
       WHERE ci.buyer_id = ?`,
      [buyerId]
    );

    if (cartItems.length === 0) {
      return res.status(400).json({ message: "Your cart is empty" });
    }

    const unavailable = cartItems.filter((item) => !item.is_available);
    if (unavailable.length > 0) {
      return res.status(400).json({
        message: `"${unavailable[0].title}" is no longer available`,
      });
    }

    const subtotal = cartItems.reduce(
      (sum, item) => sum + parseFloat(item.price) * item.quantity,
      0
    );
    const shipping = 8.0;
    const tax = parseFloat((subtotal * 0.05).toFixed(2));
    const totalPrice = parseFloat((subtotal + shipping + tax).toFixed(2));

    const createdOrders = [];

    for (const item of cartItems) {
      const [result] = await db.query(
        `INSERT INTO orders
          (buyer_id, seller_id, product_id, total_price,
           original_price, final_price, delivery_method, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')`,
        [
          buyerId,
          item.seller_id,
          item.product_id,
          totalPrice,
          item.price,
          item.price,
          delivery_method || "delivery",
        ]
      );

      createdOrders.push(result.insertId);

      await db.query(
        "UPDATE products SET is_available = FALSE WHERE id = ?",
        [item.product_id]
      );
    }

    await db.query(
      "DELETE FROM cart_items WHERE buyer_id = ?",
      [buyerId]
    );

    res.status(201).json({
      message: "Order placed successfully",
      order_ids: createdOrders,
      total_price: totalPrice,
      items_count: cartItems.length,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

// GET /api/orders — buyer order history
export const getMyOrders = async (req, res) => {
  try {
    const buyerId = req.user.id;

    const [orders] = await db.query(
      `SELECT
        o.id,
        o.status,
        o.total_price,
        o.final_price,
        o.delivery_method,
        o.created_at,
        p.id AS product_id,
        p.title,
        p.price,
        c.name AS category,
        u.full_name AS seller,
        u.profile_image_url AS seller_image,
        pi.image_url AS image
       FROM orders o
       JOIN products p ON o.product_id = p.id
       LEFT JOIN categories c ON p.category_id = c.id
       JOIN users u ON o.seller_id = u.id
       LEFT JOIN product_images pi
         ON p.id = pi.product_id AND pi.is_primary = TRUE
       WHERE o.buyer_id = ?
       ORDER BY o.created_at DESC`,
      [buyerId]
    );

    res.json({
      message: "Orders fetched successfully",
      count: orders.length,
      orders,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

// GET /api/orders/seller — seller incoming orders
export const getSellerOrders = async (req, res) => {
  try {
    const sellerId = req.user.id;

    const [orders] = await db.query(
      `SELECT
        o.id,
        o.status,
        o.total_price,
        o.final_price,
        o.delivery_method,
        o.created_at,
        p.id AS product_id,
        p.title,
        p.price,
        u.full_name AS buyer,
        u.profile_image_url AS buyer_image,
        pi.image_url AS image
       FROM orders o
       JOIN products p ON o.product_id = p.id
       JOIN users u ON o.buyer_id = u.id
       LEFT JOIN product_images pi
         ON p.id = pi.product_id AND pi.is_primary = TRUE
       WHERE o.seller_id = ?
       ORDER BY o.created_at DESC`,
      [sellerId]
    );

    // Calculate total earnings from completed orders
    const [earningsResult] = await db.query(
      `SELECT COALESCE(SUM(final_price), 0) AS total_earnings
       FROM orders
       WHERE seller_id = ? AND status = 'completed'`,
      [sellerId]
    );

    res.json({
      message: "Seller orders fetched",
      count: orders.length,
      total_earnings: parseFloat(earningsResult[0].total_earnings),
      orders,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

// PUT /api/orders/:orderId/status
export const updateOrderStatus = async (req, res) => {
  try {
    const sellerId = req.user.id;
    const { orderId } = req.params;
    const { status } = req.body;

    const validStatuses = [
      "pending", "accepted", "rejected", "completed", "cancelled",
    ];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: "Invalid status" });
    }

    const [orders] = await db.query(
      "SELECT * FROM orders WHERE id = ? AND seller_id = ?",
      [orderId, sellerId]
    );

    if (orders.length === 0) {
      return res.status(404).json({
        message: "Order not found or not yours",
      });
    }

    await db.query(
      "UPDATE orders SET status = ? WHERE id = ?",
      [status, orderId]
    );

    if (status === "rejected" || status === "cancelled") {
      await db.query(
        "UPDATE products SET is_available = TRUE WHERE id = ?",
        [orders[0].product_id]
      );
    }

    res.json({ message: `Order marked as ${status}` });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};
// GET /api/orders/wallet — full wallet summary for current user
export const getWallet = async (req, res) => {
  try {
    const userId = req.user.id;

    // Money earned as seller (completed orders)
    const [earned] = await db.query(
      `SELECT COALESCE(SUM(final_price), 0) AS total
       FROM orders
       WHERE seller_id = ? AND status = 'completed'`,
      [userId]
    );

    // Money spent as buyer (pending/accepted/completed orders)
    const [spent] = await db.query(
      `SELECT COALESCE(SUM(final_price), 0) AS total
       FROM orders
       WHERE buyer_id = ? AND status != 'cancelled' AND status != 'rejected'`,
      [userId]
    );

    // All transactions — both buying and selling
    const [transactions] = await db.query(
      `SELECT
        o.id,
        o.status,
        o.final_price,
        o.created_at,
        p.title,
        pi.image_url AS image,
        CASE
          WHEN o.seller_id = ? THEN 'sale'
          ELSE 'purchase'
        END AS type
       FROM orders o
       JOIN products p ON o.product_id = p.id
       LEFT JOIN product_images pi
         ON p.id = pi.product_id AND pi.is_primary = TRUE
       WHERE o.seller_id = ? OR o.buyer_id = ?
       ORDER BY o.created_at DESC`,
      [userId, userId, userId]
    );

    const totalEarned = parseFloat(earned[0].total);
    const totalSpent = parseFloat(spent[0].total);
    const balance = parseFloat((totalEarned - totalSpent).toFixed(2));

    res.json({
      balance,
      total_earned: totalEarned,
      total_spent: totalSpent,
      transactions,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};