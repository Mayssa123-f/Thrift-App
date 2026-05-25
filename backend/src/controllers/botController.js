import Groq from "groq-sdk";
import db from "../config/db.js";

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

// Helper: fetch user context from DB
const getUserContext = async (userId) => {
  const [cartItems] = await db.query(
    `SELECT p.title, p.price, p.currency
     FROM cart_items ci
     JOIN products p ON ci.product_id = p.id
     WHERE ci.buyer_id = ?`,
    [userId]
  );

  const [orders] = await db.query(
    `SELECT o.id, o.status, o.final_price, p.title
     FROM orders o
     JOIN products p ON o.product_id = p.id
     WHERE o.buyer_id = ?
     ORDER BY o.created_at DESC
     LIMIT 5`,
    [userId]
  );

  const [earned] = await db.query(
    `SELECT COALESCE(SUM(final_price), 0) AS total
     FROM orders WHERE seller_id = ? AND status = 'completed'`,
    [userId]
  );

  const [spent] = await db.query(
    `SELECT COALESCE(SUM(final_price), 0) AS total
     FROM orders WHERE buyer_id = ?
     AND status != 'cancelled' AND status != 'rejected'`,
    [userId]
  );

  const totalEarned = parseFloat(earned[0].total);
  const totalSpent = parseFloat(spent[0].total);
  const balance = parseFloat((totalEarned - totalSpent).toFixed(2));

  return { cartItems, orders, balance, totalEarned, totalSpent };
};

// Helper: search products
const searchProducts = async (query, userId) => {
  const [products] = await db.query(
    `SELECT p.id, p.title, p.price, p.currency, p.size,
            p.condition_type, p.style_tag,
            c.name AS category,
            u.full_name AS seller,
            pi.image_url AS image
     FROM products p
     LEFT JOIN categories c ON p.category_id = c.id
     LEFT JOIN users u ON p.seller_id = u.id
     LEFT JOIN product_images pi
       ON p.id = pi.product_id AND pi.is_primary = TRUE
     WHERE p.is_available = TRUE
     AND p.seller_id != ?
     AND (
       p.title LIKE ? OR
       c.name LIKE ? OR
       p.style_tag LIKE ? OR
       p.brand LIKE ?
     )
     ORDER BY p.created_at DESC
     LIMIT 5`,
    [userId, `%${query}%`, `%${query}%`, `%${query}%`, `%${query}%`]
  );
  return products;
};

// POST /api/bot/chat
export const botChat = async (req, res) => {
  try {
    const userId = req.user.id;
    const { message, history = [] } = req.body;

    if (!message) {
      return res.status(400).json({ message: "Message is required" });
    }

    const { cartItems, orders, balance, totalEarned, totalSpent } =
      await getUserContext(userId);

    const searchKeywords = [
      "find", "search", "looking for", "need", "want",
      "show me", "do you have", "any", "jacket", "shoes",
      "dress", "hoodie", "pants", "bag", "shirt", "sneakers",
      "coat", "jeans", "top", "accessories",
    ];

    const isProductSearch = searchKeywords.some((kw) =>
      message.toLowerCase().includes(kw)
    );

    let productResults = [];
    if (isProductSearch) {
      const cleanQuery = message
        .toLowerCase()
        .replace(
          /find|search|looking for|need|want|show me|do you have|any|i need|i want/g,
          ""
        )
        .trim();
      if (cleanQuery.length > 1) {
        productResults = await searchProducts(cleanQuery, userId);
      }
    }

    const systemPrompt = `You are Vinty Assistant, the smart AI helper for the Vinty thrift marketplace app. You are friendly, helpful, and knowledgeable about sustainable fashion and thrift shopping.

CURRENT USER DATA (use this to answer questions accurately):

🛒 CART (${cartItems.length} items):
${
  cartItems.length > 0
    ? cartItems.map((i) => `- ${i.title}: $${i.price}`).join("\n")
    : "Cart is empty"
}

📦 RECENT ORDERS (last 5):
${
  orders.length > 0
    ? orders
        .map(
          (o) =>
            `- Order #${o.id}: ${o.title} — Status: ${o.status} — $${o.final_price}`
        )
        .join("\n")
    : "No orders yet"
}

💰 WALLET:
- Balance: $${balance}
- Total Earned (sales): $${totalEarned}
- Total Spent (purchases): $${totalSpent}

${
  productResults.length > 0
    ? `🔍 PRODUCT SEARCH RESULTS for "${message}":
${productResults
  .map(
    (p) =>
      `- ID:${p.id} | ${p.title} | $${p.price} | Size: ${p.size || "N/A"} | ${p.category || ""} | Seller: ${p.seller}`
  )
  .join("\n")}`
    : ""
}

YOUR CAPABILITIES:
1. Product search — help users find items, suggest filters
2. Cart help — tell them what's in their cart, total cost
3. Wallet and payments — explain balance, earnings, spending
4. Order tracking — explain order statuses clearly
5. Buyer-seller tips — suggest message templates, negotiation advice
6. General thrift and fashion advice

RESPONSE RULES:
- Keep responses SHORT and conversational (2-4 sentences max unless listing products)
- When showing products, list them clearly with title, price, and size
- Use emojis sparingly but naturally
- Never make up data — only use the real data provided above
- For order statuses: pending=waiting for seller, accepted=confirmed, completed=done, rejected/cancelled=not going through
- If asked about something you cannot answer, suggest they contact support
- Always be encouraging about sustainable fashion choices`;

    // Build messages for Groq — same format as OpenAI
    const groqMessages = [
      { role: "system", content: systemPrompt },
      ...history.slice(-10).map((h) => ({
        role: h.role,
        content: h.content,
      })),
      { role: "user", content: message },
    ];

    // Call Groq API
    const completion = await groq.chat.completions.create({
      model: "llama-3.3-70b-versatile",
      messages: groqMessages,
      max_tokens: 500,
      temperature: 0.7,
    });

    const botReply =
      completion.choices[0]?.message?.content ||
      "Sorry, I could not process that.";

    res.json({
      reply: botReply,
      products: productResults,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};