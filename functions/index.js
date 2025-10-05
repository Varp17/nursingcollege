const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

exports.onNewIncidentSendNotifications = functions.firestore
  .document('incidents/{incidentId}') // 👈 now listens to "incidents"
  .onCreate(async (snap, context) => {
    const incident = snap.data();
    if (!incident) return null;

    // Only trigger if status = "sent"
    if (incident.status !== 'sent') return null;

    const type = incident.type || 'SOS';
    const section = incident.section || 'Campus';
    const id = context.params.incidentId;

    // Compose notification payload
    const payload = {
      notification: {
        title: `🚨 SOS: ${type}`,
        body: `${section} — Tap to view.`,
      },
      data: {
        incidentId: id,
        type: type,
        section: section,
        anonymous: String(incident.anonymous || false),
        createdAt: new Date().toISOString(),
        click_action: "FLUTTER_NOTIFICATION_CLICK", // 👈 required for navigation
      },
      android: {
        priority: "high",
        ttl: 3600 * 1000, // 1 hour
        notification: {
          channelId: "sos_alerts",
          sound: "default",
          vibrateTimingsMillis: [200, 500, 200, 500],
          priority: "max",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    // 1) Broadcast to "security" topic
    try {
      await messaging.sendToTopic('security', payload);
      console.log('✅ Sent notification to topic security');
    } catch (err) {
      console.error('❌ Error sending to topic security', err);
    }

    // 2) Send to individual approved security users (device tokens)
    try {
      const secQuery = await db.collection('users')
        .where('role', '==', 'security')
        .where('approved', '==', true)
        .get();

      let tokens = [];
      secQuery.forEach(doc => {
        const data = doc.data();
        if (data && data.fcmToken) tokens.push(data.fcmToken);
      });

      // Clean invalid / duplicate tokens
      tokens = Array.from(new Set(tokens.filter(t => typeof t === 'string' && t.length > 10)));

      if (tokens.length > 0) {
        const chunkSize = 500; // FCM limit
        for (let i = 0; i < tokens.length; i += chunkSize) {
          const batch = tokens.slice(i, i + chunkSize);
          const res = await messaging.sendToDevice(batch, payload);
          console.log(
            `✅ Sent to ${batch.length} devices:`,
            res.successCount, "success,", res.failureCount, "failed"
          );

          res.results.forEach((r, idx) => {
            if (r.error) {
              console.error(`❌ Token failed: ${batch[idx]}`, r.error);
              if (r.error.code === 'messaging/registration-token-not-registered') {
                // Remove invalid token from Firestore
                db.collection('users')
                  .where('fcmToken', '==', batch[idx])
                  .get()
                  .then(query => {
                    query.forEach(doc => doc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() })

                  });
              }
            }
          });
        }
      } else {
        console.log('⚠️ No security tokens found to send to.');
      }
    } catch (err) {
      console.error('❌ Error sending to security devices', err);
    }

    // 3) Audit log in Firestore
    await snap.ref.update({
      notificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
    }).catch(console.error);

    return null;
  });
