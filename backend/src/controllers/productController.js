import db from "../config/db.js";

export const getProducts = async (req, res) => {
  try {
    const { category, style, search } = req.query;

    let sql = `
      SELECT
        p.id,
        p.title,
        p.description,
        p.price,
        p.currency,
        p.brand,
        p.size,
        p.condition_type,
        p.gender,
        p.style_tag,
        p.location,
        p.is_available,
        p.created_at,

        c.name AS category,

        u.id AS seller_id,
        u.full_name AS seller,
        u.profile_image_url AS seller_image,

        pi.image_url AS image
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN users u ON p.seller_id = u.id
      LEFT JOIN product_images pi 
        ON p.id = pi.product_id AND pi.is_primary = TRUE
      WHERE p.is_available = TRUE
    `;

    const values = [];

    if (category && category !== "All") {
      sql += " AND c.name = ?";
      values.push(category);
    }
    if (style && style !== "All") {
      sql += " AND p.style_tag = ?";
      values.push(style);
    }

    if (search) {
      sql +=
        " AND (p.title LIKE ? OR p.style_tag LIKE ? OR c.name LIKE ? OR p.brand LIKE ?)";
      values.push(`%${search}%`, `%${search}%`, `%${search}%`, `%${search}%`);
    }

    sql += " ORDER BY p.created_at DESC";

    const [products] = await db.query(sql, values);

    res.json({ products });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getProductById = async (req, res) => {
  try {
    const { id } = req.params;

    const [products] = await db.query(
      `
      SELECT
        p.id,
        p.title,
        p.description,
        p.price,
        p.currency,
        p.brand,
        p.size,
        p.condition_type,
        p.gender,
        p.style_tag,
        p.location,
        p.is_available,
        p.created_at,

        c.name AS category,

        u.id AS seller_id,
        u.full_name AS seller,
        u.profile_image_url AS seller_image
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN users u ON p.seller_id = u.id
      WHERE p.id = ?
      `,
      [id]
    );

    if (products.length === 0) {
      return res.status(404).json({ message: "Product not found" });
    }

    const product = products[0];

    const [images] = await db.query(
      `
      SELECT image_url
      FROM product_images
      WHERE product_id = ?
      ORDER BY is_primary DESC, id ASC
      `,
      [id]
    );

    product.images = images.map((img) => img.image_url);
    product.image = product.images[0] || null;

    res.json({ product });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};
