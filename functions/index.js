const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/**
 * Automatically triggers when an order's status is changed in Firestore.
 * Dispatches an FCM push notification to the customer's phone even if the app is completely closed.
 */
exports.onOrderStatusChange = onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data.before ? event.data.before.data() : null;
  const after = event.data.after ? event.data.after.data() : null;

  if (!before || !after) return null;

  const oldStatus = (before.status || "").toLowerCase().trim();
  const newStatus = (after.status || "").toLowerCase().trim();

  // If status did not change, ignore
  if (oldStatus === newStatus) return null;

  const orderId = event.params.orderId;
  const userId = after.userId;

  // 1. Try to get FCM Token from the order itself (supports guest orders)
  let fcmToken = after.fcmToken;

  // 2. If not found in order, look up user document in Firestore
  if (!fcmToken && userId && userId !== "guest") {
    try {
      const userDoc = await db.collection("users").doc(userId).get();
      if (userDoc.exists) {
        fcmToken = userDoc.data().fcmToken;
      }
    } catch (e) {
      console.error(`Error looking up user token for ${userId}:`, e);
    }
  }

  if (!fcmToken) {
    console.log(`[Push Notification] No FCM Token found for order #${orderId}`);
    return null;
  }

  // 3. Prepare titles & descriptions based on status
  let title = "Order Update";
  let body = `Your order #${orderId} status changed to ${after.status}.`;

  if (newStatus === "delivered" || newStatus === "completed") {
    title = "Order Delivered! ✅";
    body = `Your order #${orderId} has been delivered. Enjoy!`;
  } else if (newStatus === "pending") {
    title = "Order Submitted! 📦";
    body = `Your order #${orderId} has been placed and is currently pending.`;
  } else if (newStatus.includes("cancel")) {
    title = "Order Cancelled ❌";
    body = `Your order #${orderId} has been cancelled.`;
  }

  // 4. Construct high-priority FCM payload
  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body,
    },
    data: {
      orderId: String(orderId),
      status: String(after.status),
      action: "order_view",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "restomart_high_importance_channel",
        icon: "launcher_icon",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log(`[Push Notification] Successfully sent to device for order #${orderId}:`, response);
    return response;
  } catch (error) {
    console.error(`[Push Notification] Error sending FCM push for order #${orderId}:`, error);
    return null;
  }
});

