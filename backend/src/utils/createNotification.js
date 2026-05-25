import db from "../config/db.js";

export const createNotification = async ({
  userId,
  actorId = null,
  type,
  title,
  body,
  conversationId = null,
  productId = null,
  orderId = null,
  offerId = null,
}) => {
  await db.query(
    `
    INSERT INTO notifications
    (
      user_id,
      actor_id,
      type,
      title,
      body,
      conversation_id,
      product_id,
      order_id,
      offer_id
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [
      userId,
      actorId,
      type,
      title,
      body,
      conversationId,
      productId,
      orderId,
      offerId,
    ]
  );
};