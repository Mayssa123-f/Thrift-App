import express from "express";
import { GoogleGenerativeAI } from "@google/generative-ai";
import db from "../config/db.js";

const router = express.Router();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const normalize = (value) => (value ?? "").toString().trim().toLowerCase();

const buildCandidateSummary = (product) => ({
  id: product.id,
  title: product.title,
  category: product.category,
  category_id: product.category_id,
  style_tag: product.style_tag,
  color: product.color,
  gender: product.gender,
  brand: product.brand,
  size: product.size,
  condition_type: product.condition_type,
  price: product.price,
  image: product.image,
});

router.post("/suggest-outfit", async (req, res) => {
  try {
    const productId = Number(req.body.productId || 0);

    if (!productId) {
      return res.status(400).json({
        error: "productId is required",
      });
    }

    const [sourceRows] = await db.query(
      `
      SELECT
        p.*,
        c.name AS category,
        u.id AS seller_id,
        u.full_name AS seller,
        u.profile_image_url AS seller_image,
        pi.image_url AS image
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN users u ON p.seller_id = u.id
      LEFT JOIN product_images pi
        ON p.id = pi.product_id AND pi.is_primary = 1
      WHERE p.id = ?
      LIMIT 1
      `,
      [productId]
    );

    if (!sourceRows.length) {
      return res.status(404).json({
        error: "Product not found",
      });
    }

    const source = sourceRows[0];

    const [candidateRows] = await db.query(
      `
      SELECT
        p.*,
        c.name AS category,
        u.id AS seller_id,
        u.full_name AS seller,
        u.profile_image_url AS seller_image,
        pi.image_url AS image
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN users u ON p.seller_id = u.id
      LEFT JOIN product_images pi
        ON p.id = pi.product_id AND pi.is_primary = 1
      WHERE p.is_available = 1
        AND p.id != ?
        AND p.category_id != ?
      `,
      [productId, source.category_id]
    );

    const candidates = candidateRows.map(buildCandidateSummary);

    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
    });

    const prompt = `
You are an expert fashion stylist for a thrift/secondhand clothing app.

Return ONLY valid JSON. No markdown. No explanation.

GOAL:
Build a complete wearable outfit around the opened product.

OPENED PRODUCT:
${JSON.stringify(buildCandidateSummary(source), null, 2)}

AVAILABLE PRODUCTS:
${JSON.stringify(candidates, null, 2)}

STRICT RULES:
1. Choose exactly 3 different products if possible.
2. Every chosen product_id MUST exist in AVAILABLE PRODUCTS.
3. Never choose the opened product.
4. Do not choose more than one product from the same category.
5. Create a balanced outfit:
   - If opened product is bottoms, suggest one top, one shoes, and one accessory/jacket/bag if available.
   - If opened product is top, suggest one bottom, one shoes, and one accessory/jacket/bag if available.
   - If opened product is shoes, suggest one top, one bottom, and one accessory/jacket/bag if available.
   - If opened product is jacket/outerwear, suggest one top, one bottom, and one shoes if available.
   - If opened product is bag/accessory, suggest one top, one bottom, and one shoes if available.
6. Match style_tag, color, gender, and occasion.
7. Prefer complementary colors:
   - black, white, beige, denim, brown, grey are safe neutrals.
   - avoid clashing colors unless the style_tag supports bold styling.
8. The tip must explain why this specific item completes the opened product.

Return this exact JSON shape:
{
  "style_name": "short outfit name",
  "suggestions": [
    {
      "product_id": 123,
      "category": "category name",
      "role": "top | bottom | shoes | outerwear | accessory | bag",
      "tip": "one short styling reason"
    }
  ]
}
`;

    const result = await model.generateContent(prompt);
    const text = result.response.text();

    const clean = text
      .replace(/```json/g, "")
      .replace(/```/g, "")
      .trim();

    const parsed = JSON.parse(clean);

    const candidateById = new Map(
      candidates.map((product) => [Number(product.id), product])
    );

    const usedCategories = new Set();
    const suggestions = [];

    for (const suggestion of parsed.suggestions || []) {
      const suggestedProductId = Number(suggestion.product_id);
      const product = candidateById.get(suggestedProductId);

      if (!product) continue;
      if (usedCategories.has(product.category_id)) continue;

      usedCategories.add(product.category_id);

      suggestions.push({
        category_id: product.category_id,
        category: product.category,
        role: suggestion.role || product.category || "item",
        tip: suggestion.tip || "This item completes the outfit.",
        products: [product],
      });

      if (suggestions.length >= 3) break;
    }

    if (!suggestions.length && candidates.length) {
      const fallback = candidates
        .filter((p) => p.category_id !== source.category_id)
        .sort((a, b) => {
          const sameStyleA =
            normalize(a.style_tag) === normalize(source.style_tag) ? 1 : 0;
          const sameStyleB =
            normalize(b.style_tag) === normalize(source.style_tag) ? 1 : 0;

          return sameStyleB - sameStyleA;
        })
        .slice(0, 3);

      fallback.forEach((product) => {
        suggestions.push({
          category_id: product.category_id,
          category: product.category,
          role: product.category || "item",
          tip: `A strong match for the ${source.style_tag || "current"} look.`,
          products: [product],
        });
      });
    }

    res.json({
      source_product: source,
      style_name: parsed.style_name || source.style_tag || "Styled Look",
      suggestions,
    });
  } catch (err) {
    console.error("AI Stylist error:", err);

const [fallbackRows] = await db.query(
  `
  SELECT
    p.*,
    c.name AS category,
    u.id AS seller_id,
    u.full_name AS seller,
    u.profile_image_url AS seller_image,
    pi.image_url AS image
  FROM products p
  LEFT JOIN categories c ON p.category_id = c.id
  LEFT JOIN users u ON p.seller_id = u.id
  LEFT JOIN product_images pi
    ON p.id = pi.product_id AND pi.is_primary = 1
  WHERE p.is_available = 1
    AND p.id != ?
  LIMIT 3
  `,
  [req.body.productId || 0]
);

return res.json({
  source: "fallback",
  style_name: "Styled Look",
  suggestions: fallbackRows.map((product) => ({
    category_id: product.category_id,
    category: product.category,
    role: product.category || "item",
    tip: "A good match to complete this outfit.",
    products: [product],
  })),
});
  }
});

export default router;