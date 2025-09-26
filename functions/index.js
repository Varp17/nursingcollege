const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

exports.onNewIncidentSendNotifications = functions.firestore
  .document('incidents/{incidentId}')
  .onCreate(async (snap, context) => {
    const incident = snap.data();
    if (!incident) return null;

    // Only trigger for 'sent' incidents
    if (incident.status !== 'sent') return null;

    const type = incident.type || 'SOS';
    const section = incident.section || 'Campus';
    const id = context.params.incidentId;

    // Compose notification payload
    const payload = {
      notification: {
        title: `SOS: ${type}`,
        body: `${section} — Tap to view.`,
      },
      data: {
        incidentId: id,
        type: type,
        section: section,
      }
    };

    // 1) Send to topic 'security' (subscribe security devices to this topic)
    try {
      await messaging.sendToTopic('security', payload);
      console.log('Sent notification to topic security');
    } catch (err) {
      console.error('Error sending to topic security', err);
    }

    // 2) Also send to individual security users (if they have tokens)
    try {
      const secQuery = await db.collection('users').where('role', '==', 'security').where('approved', '==', true).get();
      const tokens = [];
      secQuery.forEach(doc => {
        const data = doc.data();
        if (data && data.fcmToken) tokens.push(data.fcmToken);
      });

      // Remove empty tokens and duplicates
      const filteredTokens = Array.from(new Set(tokens.filter(t => typeof t === 'string' && t.length > 10)));
      if (filteredTokens.length > 0) {
        const res = await messaging.sendToDevice(filteredTokens, payload);
        console.log('Sent to devices, results:', res);
      } else {
        console.log('No security tokens found to send to.');
      }
    } catch (err) {
      console.error('Error sending to security devices', err);
    }

    // Save a small audit in incident doc
    await snap.ref.update({ notificationSentAt: admin.firestore.FieldValue.serverTimestamp() }).catch(console.error);

    return null;
  });
