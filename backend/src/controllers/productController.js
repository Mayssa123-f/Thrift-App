import db from "../config/db.js";

export const getProducts = async (req, res) => {
  try {
    const { category, style, search } = req.query;
    const currentUserId = req.user.id;

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
      AND p.seller_id != ?
    `;

    const values = [currentUserId];

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
      [id],
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
      [id],
    );

    product.images = images.map((img) => img.image_url);
    product.image = product.images[0] || null;

    res.json({ product });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};
export const getMyListings = async (req, res) => {
  try {
    const sellerId = req.user.id;

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
        u.profile_image_url AS seller_image,

        pi.image_url AS image

      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN users u ON p.seller_id = u.id
      LEFT JOIN product_images pi
        ON p.id = pi.product_id AND pi.is_primary = TRUE

      WHERE p.seller_id = ?
      ORDER BY p.created_at DESC
      `,
      [sellerId]
    );

    res.json({
      message: "My listings fetched successfully",
      count: products.length,
      products,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};
export const createProduct = async (req, res) => {
  try {
    const sellerId = req.user.id;

    const {
      title,
      description,
      price,
      category,
      size,
      condition_type,
      gender,
      style_tag,
      brand,
      color,
      location,
    } = req.body;

    // ✅ STEP 1: validation
    if (!title || !price || !category) {
      return res.status(400).json({
        message: "Title, price and category are required",
      });
    }

    if (isNaN(price) || Number(price) <= 0) {
      return res.status(400).json({
        message: "Price must be a valid positive number",
      });
    }

    // ❗ NEW: images come from req.files (NOT req.body)
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        message: "At least one image is required",
      });
    }

    // Convert uploaded files → URLs
    const uploadedImages = req.files.map((file) => {
      return `${req.protocol}://${req.get("host")}/uploads/${file.filename}`;
    });

    // Look up category
    const [categories] = await db.query(
      "SELECT id FROM categories WHERE name = ?",
      [category]
    );

    if (categories.length === 0) {
      return res.status(400).json({
        message: `Category "${category}" not found`,
      });
    }

    const categoryId = categories[0].id;

    // Insert product
    const [result] = await db.query(
      `INSERT INTO products
        (seller_id, category_id, title, description, price, currency,
         size, condition_type, gender, style_tag, brand, color, location, is_available)
       VALUES (?, ?, ?, ?, ?, 'USD', ?, ?, ?, ?, ?, ?, ?, TRUE)`,
      [
        sellerId,
        categoryId,
        title.trim(),
        description?.trim() || null,
        Number(price),
        size || null,
        condition_type || "good",
        gender || "unisex",
        style_tag || null,
        brand || null,
        color || null,
        location || null,
      ]
    );

    const productId = result.insertId;

    // Insert images (first = primary)
    for (let i = 0; i < uploadedImages.length; i++) {
      await db.query(
        `INSERT INTO product_images (product_id, image_url, is_primary)
         VALUES (?, ?, ?)`,
        [productId, uploadedImages[i], i === 0 ? 1 : 0]
      );
    }

    // Return full product
    const [newProduct] = await db.query(
      `SELECT
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
        p.color,
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
       WHERE p.id = ?`,
      [productId]
    );

    res.status(201).json({
      message: "Product listed successfully",
      product: newProduct[0],
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};