import db from "../config/db.js";
import { createNotification } from "../utils/createNotification.js";
import { sendPushNotification } from "../utils/sendNotifications.js";

export const createOffer = async (req, res) => {
  try {
    const buyerId = req.user.id;
    const { conversation_id, product_id, seller_id, offered_price } = req.body;

    if (!conversation_id || !product_id || !seller_id || !offered_price) {
      return res.status(400).json({
        message: "Missing offer information",
      });
    }

    const offerPrice = Number(offered_price);

    if (Number.isNaN(offerPrice) || offerPrice <= 0) {
      return res.status(400).json({
        message: "Offer price must be greater than 0",
      });
    }

    const [products] = await db.query(
      `
      SELECT id, seller_id, title, is_available
      FROM products
      WHERE id = ?
      `,
      [product_id],
    );

    if (products.length === 0) {
      return res.status(404).json({
        message: "Product not found",
      });
    }

    const product = products[0];

    if (!product.is_available) {
      return res.status(400).json({
        message: "This item is no longer available",
      });
    }

    if (product.seller_id === buyerId) {
      return res.status(400).json({
        message: "You cannot make an offer on your own item",
      });
    }

    if (product.seller_id !== Number(seller_id)) {
      return res.status(400).json({
        message: "Invalid seller for this product",
      });
    }

    const [conversations] = await db.query(
      `
  SELECT id
  FROM conversations
  WHERE id = ?
  AND buyer_id = ?
  AND seller_id = ?
  `,
      [conversation_id, buyerId, seller_id],
    );

    if (conversations.length === 0) {
      return res.status(403).json({
        message: "Invalid conversation for this offer",
      });
    }

    const [buyers] = await db.query(
      "SELECT full_name FROM users WHERE id = ?",
      [buyerId],
    );

    const buyer = buyers[0];

    const [result] = await db.query(
      `
      INSERT INTO offers 
      (conversation_id, product_id, buyer_id, seller_id, offered_price)
      VALUES (?, ?, ?, ?, ?)
      `,
      [conversation_id, product_id, buyerId, seller_id, offerPrice],
    );

    const offerId = result.insertId;

    await db.query(
      `
  INSERT INTO chat_messages 
  (conversation_id, sender_id, message_type, message_text, product_id, offer_id)
  VALUES (?, ?, 'offer', ?, ?, ?)
  `,
      [conversation_id, buyerId, `Offered $${offerPrice}`, product_id, offerId],
    );

    const title = `${buyer?.full_name || "Someone"} sent an offer`;
    const body = `Offered $${offerPrice} for ${product.title}`;

    await createNotification({
      userId: seller_id,
      actorId: buyerId,
      type: "offer",
      title,
      body,
      conversationId: conversation_id,
      productId: product_id,
      offerId,
    });

    await sendPushNotification({
      userId: seller_id,
      title,
      body,
      data: {
        type: "offer",
        conversation_id: String(conversation_id),
        product_id: String(product_id),
        offer_id: String(offerId),
      },
    });

    const [offer] = await db.query("SELECT * FROM offers WHERE id = ?", [
      offerId,
    ]);

    res.status(201).json({
      offer: offer[0],
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

export const acceptOffer = async (req, res) => {
  try {
    const sellerId = req.user.id;
    const { offerId } = req.params;

    const [offers] = await db.query("SELECT * FROM offers WHERE id = ?", [
      offerId,
    ]);

    if (offers.length === 0) {
      return res.status(404).json({ message: "Offer not found" });
    }

    const offer = offers[0];

    if (offer.seller_id !== sellerId) {
      return res.status(403).json({
        message: "Only the seller can accept this offer",
      });
    }

    await db.query(
      `
  UPDATE offers
  SET status = 'expired'
  WHERE buyer_id = ?
  AND product_id = ?
  AND id != ?
  AND status IN ('pending', 'accepted')
  `,
      [offer.buyer_id, offer.product_id, offerId],
    );

    await db.query("UPDATE offers SET status = 'accepted' WHERE id = ?", [
      offerId,
    ]);

    await db.query(
      `INSERT INTO chat_messages
       (conversation_id, sender_id, message_type, message_text, offer_id)
       VALUES (?, ?, 'system', ?, ?)`,
      [
        offer.conversation_id,
        sellerId,
        `Offer accepted for $${offer.offered_price}`,
        offerId,
      ],
    );
    const [sellers] = await db.query(
      "SELECT full_name FROM users WHERE id = ?",
      [sellerId],
    );

    const seller = sellers[0];
    await createNotification({
      userId: offer.buyer_id,
      actorId: sellerId,
      type: "offer",
      title: `${seller.full_name} accepted your offer`,
      body: `Your $${offer.offered_price} offer was accepted`,
      conversationId: offer.conversation_id,
      productId: offer.product_id,
      offerId,
    });

    await sendPushNotification({
      userId: offer.buyer_id,
      title: `${seller.full_name} accepted your offer`,
      body: `Your $${offer.offered_price} offer was accepted`,
      data: {
        type: "offer",
        conversation_id: String(offer.conversation_id),
        product_id: String(offer.product_id),
        offer_id: String(offerId),
      },
    });
    res.json({ message: "Offer accepted successfully" });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};

export const declineOffer = async (req, res) => {
  try {
    const sellerId = req.user.id;
    const { offerId } = req.params;

    const [offers] = await db.query("SELECT * FROM offers WHERE id = ?", [
      offerId,
    ]);

    if (offers.length === 0) {
      return res.status(404).json({ message: "Offer not found" });
    }

    const offer = offers[0];

    if (offer.seller_id !== sellerId) {
      return res.status(403).json({
        message: "Only the seller can decline this offer",
      });
    }

    await db.query("UPDATE offers SET status = 'declined' WHERE id = ?", [
      offerId,
    ]);

    await db.query(
      `INSERT INTO chat_messages
       (conversation_id, sender_id, message_type, message_text, offer_id)
       VALUES (?, ?, 'system', ?, ?)`,
      [offer.conversation_id, sellerId, `Offer declined`, offerId],
    );
    const [sellers] = await db.query(
      "SELECT full_name FROM users WHERE id = ?",
      [sellerId],
    );

    const seller = sellers[0];
    await createNotification({
      userId: offer.buyer_id,
      actorId: sellerId,
      type: "offer",
      title: `${seller.full_name} declined your offer`,
      body: `Your $${offer.offered_price} offer was declined`,
      conversationId: offer.conversation_id,
      productId: offer.product_id,
      offerId,
    });

    await sendPushNotification({
      userId: offer.buyer_id,
      title: `${seller.full_name} declined your offer`,
      body: `Your $${offer.offered_price} offer was declined`,
      data: {
        type: "offer",
        conversation_id: String(offer.conversation_id),
        product_id: String(offer.product_id),
        offer_id: String(offerId),
      },
    });
    res.json({ message: "Offer declined successfully" });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Server error" });
  }
};
