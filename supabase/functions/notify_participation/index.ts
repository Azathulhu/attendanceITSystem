import { serve } from "https://deno.land/std/http/server.ts";
import admin from "npm:firebase-admin";

const serviceAccount = JSON.parse(
  Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!
);

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

serve(async (req) => {
  const { fcmToken, points } = await req.json();

  if (!fcmToken) {
    return new Response("Missing token", { status: 400 });
  }

  await admin.messaging().send({
    token: fcmToken,
    notification: {
      title: "Participation Updated",
      body: `You received ${points} participation point(s).`,
    },
  });

  return new Response(
    JSON.stringify({ success: true }),
    { headers: { "Content-Type": "application/json" } }
  );
});
