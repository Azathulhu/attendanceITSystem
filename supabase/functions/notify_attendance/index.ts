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
  const { tokens, className } = await req.json();

  if (!tokens || tokens.length === 0) {
    return new Response("No tokens", { status: 400 });
  }

  await admin.messaging().sendMulticast({
    tokens,
    notification: {
      title: "Attendance Started",
      body: `Attendance for ${className} is now active.`,
    },
  });

  return new Response(
    JSON.stringify({ success: true }),
    { headers: { "Content-Type": "application/json" } }
  );
});
