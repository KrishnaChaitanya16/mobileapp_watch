import { createClient } from 'npm:@supabase/supabase-js@2';

// Supabase Configuration (replace with actual values)
const SUPABASE_URL = "https://fmtzufgmbciovdxflkqm.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZtdHp1ZmdtYmNpb3ZkeGZsa3FtIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNDE4MzU2MCwiZXhwIjoyMDQ5NzU5NTYwfQ.ZHuLemZsLLfLVZSL07_a72JH7PXyE1fDwHReuoRVTOk";

// Initialize Supabase Client
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// Deno server to handle incoming requests
Deno.serve(async (req) => {
  console.log("Request received to store FCM token");

  // Parse the request body
  const body = await req.json();
  const { fcmToken, deviceType } = body;

  // Validate incoming data
  if (!fcmToken || !deviceType) {
    return new Response(
      JSON.stringify({ error: 'fcmToken and deviceType are required' }),
      { status: 400 }
    );
  }

  // Insert the FCM token into the device_tokens table
  const { data, error } = await supabase
    .from('device_tokens')
    .upsert(
      { device_type: deviceType, fcm_token: fcmToken },
      { onConflict: ['fcm_token'] } // Ensure fcm_token is unique
    );

  if (error) {
    console.error("Error storing FCM token:", error);
    return new Response(
      JSON.stringify({ error: 'Failed to store FCM token', details: error.message }),
      { status: 500 }
    );
  }

  console.log("FCM token stored successfully");

  // Respond with success
  return new Response(
    JSON.stringify({ message: 'FCM token stored successfully', data }),
    { headers: { 'Content-Type': 'application/json' } }
  );
});
