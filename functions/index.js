const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const fcm = admin.messaging();

// Automatic SOS notification to security
exports.sendSosNotificationToSecurity = functions.firestore
    .document('incidents/{incidentId}')
    .onCreate(async (snap, context) => {
        const incident = snap.data();
        const incidentId = context.params.incidentId;

        if (!incident) return null;

        const title = `🚨 ${incident.type || "SOS"} ALERT`;
        const body = `${incident.studentName} at ${incident.location} - ${incident.description || "Needs immediate assistance"}`;

        const payload = {
            notification: {
                title: title,
                body: body,
                sound: "default",
            },
            data: {
                incidentId: incidentId,
                type: 'sos_alert',
                studentName: incident.studentName || "Anonymous",
                location: incident.location || "Unknown",
                priority: 'high',
                timestamp: new Date().toISOString(),
            },
            android: {
                priority: 'high',
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                        priority: 'high',
                    },
                },
            },
        };

        try {
            // Send to ALL security personnel
            await fcm.sendToTopic("security", payload);
            console.log(`🔔 SOS notification sent to security for incident: ${incidentId}`);
            
        } catch (error) {
            console.error("❌ Error sending SOS notification:", error);
        }

        return null;
    });