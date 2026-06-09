import Stripe from "stripe";
import db from "../config/db.js";
import { sendPushNotification } from "../utils/sendNotifications.js";
import { createNotification } from "../utils/createNotification.js";
import transporter from "../config/email.js";
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

// POST /api/orders/payment-intent — create Stripe PaymentIntent
export const createPaymentIntent = async (req, res) => {
  try {
    const buyerId = req.user.id;
    const { delivery_method } = req.body;

    const [cartItems] = await db.query(
      `SELECT
        ci.id AS cart_item_id,
        ci.product_id,
        ci.quantity,
        p.price,
        p.seller_id,
        p.is_available,
        p.title,

        ao.id AS accepted_offer_id,
        ao.offered_price AS accepted_offer_price

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

       WHERE ci.buyer_id = ?`,
      [buyerId, buyerId],
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

    const subtotal = cartItems.reduce((sum, item) => {
      const finalPrice = item.accepted_offer_price
        ? parseFloat(item.accepted_offer_price)
        : parseFloat(item.price);

      return sum + finalPrice * item.quantity;
    }, 0);

    const shipping = delivery_method === "pickup" ? 0 : 8.0;
    const tax = parseFloat((subtotal * 0.05).toFixed(2));
    const total = parseFloat((subtotal + shipping + tax).toFixed(2));

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

    // VERIFY STRIPE PAYMENT
    if (payment_intent_id) {
      const paymentIntent =
        await stripe.paymentIntents.retrieve(payment_intent_id);

      if (paymentIntent.status !== "succeeded") {
        return res.status(400).json({
          message: "Payment not confirmed",
        });
      }
    }

    // GET CART ITEMS
    const [cartItems] = await db.query(
      `
      SELECT
        ci.id AS cart_item_id,
        ci.product_id,
        ci.quantity,
        ci.selected_size,

        p.price,
        p.seller_id,
        p.is_available,
        p.title,

        ao.id AS accepted_offer_id,
        ao.offered_price AS accepted_offer_price

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

      WHERE ci.buyer_id = ?
      `,
      [buyerId, buyerId],
    );

    if (cartItems.length === 0) {
      return res.status(400).json({
        message: "Your cart is empty",
      });
    }

    // CHECK AVAILABILITY
    const unavailable = cartItems.filter((item) => !item.is_available);

    if (unavailable.length > 0) {
      return res.status(400).json({
        message: `"${unavailable[0].title}" is no longer available`,
      });
    }

    // CALCULATE TOTALS
    const subtotal = cartItems.reduce((sum, item) => {
      const finalPrice = item.accepted_offer_price
        ? parseFloat(item.accepted_offer_price)
        : parseFloat(item.price);

      return sum + finalPrice * item.quantity;
    }, 0);

    const shipping = delivery_method === "pickup" ? 0 : 8.0;

    const tax = parseFloat((subtotal * 0.05).toFixed(2));

    const totalPrice = parseFloat((subtotal + shipping + tax).toFixed(2));

    const createdOrders = [];

    // GET BUYER INFO
    const [buyers] = await db.query(
      `
      SELECT full_name, email
      FROM users
      WHERE id = ?
      `,
      [buyerId],
    );

    const buyer = buyers[0];

    if (!buyer?.email) {
      return res.status(400).json({
        message: "Buyer email not found",
      });
    }

    // CREATE ORDERS
    for (const item of cartItems) {
      const finalPrice = item.accepted_offer_price
        ? parseFloat(item.accepted_offer_price)
        : parseFloat(item.price);

      const [result] = await db.query(
        `
        INSERT INTO orders
        (
          buyer_id,
          seller_id,
          product_id,
          total_price,
          offer_id,
          original_price,
          final_price,
          delivery_method,
          status
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'accepted')
        `,
        [
          buyerId,
          item.seller_id,
          item.product_id,
          totalPrice,
          item.accepted_offer_id || null,
          item.price,
          finalPrice,
          delivery_method || "delivery",
        ],
      );

      createdOrders.push(result.insertId);

      // SELLER NOTIFICATION
      const soldBody = `${item.title} was purchased by ${
        buyer.full_name || "a buyer"
      }`;

      await createNotification({
        userId: item.seller_id,
        actorId: buyerId,
        type: "order",
        title: "Your item was sold",
        body: soldBody,
        productId: item.product_id,
        orderId: result.insertId,
        offerId: item.accepted_offer_id || null,
      });

      // PUSH NOTIFICATION
      await sendPushNotification({
        userId: item.seller_id,
        title: "Your item was sold",
        body: soldBody,
        data: {
          type: "order",
          order_id: result.insertId.toString(),
          product_id: item.product_id.toString(),
          offer_id: item.accepted_offer_id
            ? item.accepted_offer_id.toString()
            : "",
        },
      });

      // MARK PRODUCT SOLD
      await db.query(
        `
        UPDATE products
        SET is_available = FALSE
        WHERE id = ?
        `,
        [item.product_id],
      );

      // MARK OFFER USED
      if (item.accepted_offer_id) {
        await db.query(
          `
          UPDATE offers
          SET status = 'used'
          WHERE id = ?
          `,
          [item.accepted_offer_id],
        );
      }
    }

    // CLEAR CART
    await db.query(
      `
      DELETE FROM cart_items
      WHERE buyer_id = ?
      `,
      [buyerId],
    );

    // SEND EMAIL
    await transporter.sendMail({
      from: `"Vinty" <${process.env.EMAIL_USER}>`,
      to: buyer.email,
      subject: "Your order is confirmed ✨",

      html: `
  <div style="
    background:#f7f7f5;
    padding:40px 20px;
    font-family:Arial,sans-serif;
    color:#111;
  ">

    <div style="
      max-width:600px;
      margin:0 auto;
      background:white;
      border-radius:24px;
      overflow:hidden;
      border:1px solid #ececec;
    ">

      <!-- HEADER -->
      <div style="
        padding:40px 30px 24px;
        text-align:center;
      ">
        <h1 style="
          margin:0;
          font-size:42px;
          letter-spacing:8px;
          color:#18392b;
        ">
          VINTY
        </h1>

        <p style="
          margin-top:10px;
          color:#777;
          font-size:13px;
          letter-spacing:2px;
        ">
          PRELOVED. LOVED. AGAIN.
        </p>
      </div>

      <!-- SUCCESS -->
      <div style="
        margin:0 24px;
        background:#f3f5f2;
        border-radius:20px;
        padding:36px 24px;
        text-align:center;
      ">

        <div style="
          width:64px;
          height:64px;
          line-height:64px;
          margin:0 auto 18px;
          border-radius:50%;
          background:#2f6f4f;
          color:white;
          font-size:32px;
        ">
          ✓
        </div>

        <h2 style="
          margin:0;
          font-size:34px;
          color:#111;
        ">
          Order Confirmed
        </h2>

        <p style="
          margin-top:16px;
          font-size:16px;
          color:#555;
          line-height:1.6;
        ">
          Thanks for shopping with Vinty.<br/>
          We’ve received your order and we’re getting it ready.
        </p>
      </div>

      <!-- CONTENT -->
      <div style="padding:40px 30px;">

        <p style="
          font-size:18px;
          margin-bottom:10px;
        ">
          Hi ${buyer.full_name},
        </p>

        <p style="
          color:#555;
          line-height:1.7;
          margin-bottom:32px;
        ">
          Your order has been placed successfully.
          We’ll notify you again once your items are shipped.
        </p>

        <!-- ORDER BOX -->
        <div style="
          border:1px solid #ececec;
          border-radius:18px;
          overflow:hidden;
        ">

          <div style="
            padding:20px 24px;
            border-bottom:1px solid #ececec;
            background:#fafafa;
            font-weight:600;
            font-size:17px;
          ">
            Order Summary
          </div>

          <div style="padding:24px;">

            <table width="100%" cellspacing="0">
              <tr>
                <td style="padding-bottom:14px; color:#666;">
                  Items
                </td>

                <td align="right" style="
                  padding-bottom:14px;
                  font-weight:600;
                ">
                  ${cartItems.length}
                </td>
              </tr>

              <tr>
                <td style="padding-bottom:14px; color:#666;">
                  Delivery
                </td>

                <td align="right" style="
                  padding-bottom:14px;
                  font-weight:600;
                ">
                  ${delivery_method || "delivery"}
                </td>
              </tr>

              <tr>
                <td style="
                  padding-top:18px;
                  border-top:1px solid #ececec;
                  font-size:18px;
                  font-weight:700;
                ">
                  Total Paid
                </td>

                <td align="right" style="
                  padding-top:18px;
                  border-top:1px solid #ececec;
                  font-size:22px;
                  font-weight:700;
                  color:#18392b;
                ">
                  $${totalPrice}
                </td>
              </tr>
            </table>

          </div>
        </div>

        <!-- FOOTER MESSAGE -->
        <div style="
          margin-top:32px;
          padding:20px;
          border-radius:16px;
          background:#f5f7f4;
          color:#444;
          line-height:1.7;
          font-size:15px;
        ">
          Thank you for supporting sustainable fashion ♻️
          <br/>
          Every pre-loved item gets a new story with Vinty.
        </div>

      </div>

      <!-- FOOTER -->
      <div style="
        padding:28px;
        text-align:center;
        border-top:1px solid #ececec;
        color:#888;
        font-size:13px;
      ">
        © 2025 Vinty. All rights reserved.
      </div>

    </div>
  </div>
  `,
    });

    return res.status(201).json({
      message: "Order placed successfully",
      order_ids: createdOrders,
      total_price: totalPrice,
      items_count: cartItems.length,
    });
  } catch (error) {
    console.log(error);

    return res.status(500).json({
      message: "Server error",
    });
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
        o.seller_id,
        o.buyer_id,
        p.id AS product_id,
        p.title,
        p.price,
        c.name AS category,
        u.full_name AS seller,
        u.profile_image_url AS seller_image,
        pi.image_url AS image,
        CASE
          WHEN o.seller_id = ? THEN 'sale'
          ELSE 'purchase'
        END AS type
       FROM orders o
       JOIN products p ON o.product_id = p.id
       LEFT JOIN categories c ON p.category_id = c.id
       JOIN users u ON o.seller_id = u.id
       LEFT JOIN product_images pi
         ON p.id = pi.product_id AND pi.is_primary = TRUE
       WHERE o.buyer_id = ?
       ORDER BY o.created_at DESC`,
      [buyerId, buyerId],
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
      [sellerId],
    );

    // FIXED: correct variable + correct alias
    const [earningsResult] = await db.query(
      `SELECT COALESCE(SUM(final_price), 0) AS total_earnings
       FROM orders
       WHERE seller_id = ?
       AND status IN ('accepted', 'completed')`,
      [sellerId],
    );

    return res.json({
      message: "Seller orders fetched",
      count: orders.length,
      total_earnings: Number(earningsResult?.[0]?.total_earnings || 0),
      orders,
    });
  } catch (error) {
    console.log(error);
    return res.status(500).json({ message: "Server error" });
  }
};

// PUT /api/orders/:orderId/status
export const updateOrderStatus = async (req, res) => {
  try {
    const sellerId = req.user.id;
    const { orderId } = req.params;
    const { status } = req.body;

    const validStatuses = [
      "pending",
      "accepted",
      "rejected",
      "completed",
      "cancelled",
    ];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: "Invalid status" });
    }

    const [orders] = await db.query(
      "SELECT * FROM orders WHERE id = ? AND seller_id = ?",
      [orderId, sellerId],
    );

    if (orders.length === 0) {
      return res.status(404).json({
        message: "Order not found or not yours",
      });
    }

    await db.query("UPDATE orders SET status = ? WHERE id = ?", [
      status,
      orderId,
    ]);

    if (status === "rejected" || status === "cancelled") {
      await db.query("UPDATE products SET is_available = TRUE WHERE id = ?", [
        orders[0].product_id,
      ]);
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

    // ================== EARNED ==================
    const [earned] = await db.query(
      `SELECT COALESCE(SUM(final_price), 0) AS total
       FROM orders
       WHERE seller_id = ?
       AND status IN ('accepted', 'completed')`,
      [userId],
    );

    // ================== SPENT ==================
    const [spent] = await db.query(
      `SELECT COALESCE(SUM(final_price), 0) AS total
       FROM orders
       WHERE buyer_id = ?
       AND status NOT IN ('cancelled', 'rejected')`,
      [userId],
    );

    // ================== FIXED TRANSACTIONS QUERY ==================
    const [transactions] = await db.query(
      `SELECT
        o.id,
        o.status,
        o.final_price,
        o.created_at,
        o.seller_id,
        o.buyer_id,
        p.title,
        pi.image_url AS image,
        CASE
          WHEN o.seller_id = ? THEN 'sale'
          WHEN o.buyer_id = ? THEN 'purchase'
          ELSE 'unknown'
        END AS type
       FROM orders o
       JOIN products p ON o.product_id = p.id
       LEFT JOIN product_images pi
         ON p.id = pi.product_id AND pi.is_primary = TRUE
       WHERE o.seller_id = ? OR o.buyer_id = ?
       ORDER BY o.created_at DESC`,
      [userId, userId, userId, userId],
    );

    const totalEarned = Number(earned?.[0]?.total || 0);
    const totalSpent = Number(spent?.[0]?.total || 0);

    const balance = Number((totalEarned - totalSpent).toFixed(2));

    return res.json({
      balance,
      total_earned: totalEarned,
      total_spent: totalSpent,
      transactions,
    });
  } catch (error) {
    console.log("getWallet error:", error);
    return res.status(500).json({ message: "Server error" });
  }
};
// GET /api/orders/:orderId
export const getOrderById = async (req, res) => {
  try {
    const userId = req.user.id;
    const { orderId } = req.params;

    const [orders] = await db.query(
      `
      SELECT
        o.id,
        o.status,
        o.total_price,
        o.original_price,
        o.final_price,
        o.delivery_method,
        o.created_at,
        o.buyer_id,
        o.seller_id,

        p.id AS product_id,
        p.title,
        p.price,
        p.size,
        p.condition_type,
        p.gender,
        p.brand,
        p.color,

        pi.image_url AS image,

        buyer.full_name AS buyer_name,
        buyer.profile_image_url AS buyer_image,

        seller.full_name AS seller_name,
        seller.profile_image_url AS seller_image,

        CASE
          WHEN o.seller_id = ? THEN 'seller'
          WHEN o.buyer_id = ? THEN 'buyer'
          ELSE 'unknown'
        END AS viewer_role

      FROM orders o
      JOIN products p ON o.product_id = p.id

      LEFT JOIN product_images pi
        ON p.id = pi.product_id AND pi.is_primary = TRUE

      JOIN users buyer
        ON o.buyer_id = buyer.id

      JOIN users seller
        ON o.seller_id = seller.id

      WHERE o.id = ?
      AND (o.buyer_id = ? OR o.seller_id = ?)
      LIMIT 1
      `,
      [userId, userId, orderId, userId, userId],
    );

    if (orders.length === 0) {
      return res.status(404).json({
        message: "Order not found",
      });
    }

    res.json({
      order: orders[0],
    });
  } catch (error) {
    console.log("getOrderById error:", error);
    res.status(500).json({ message: "Server error" });
  }
};
