import { NextResponse } from "next/server";

export async function POST(request: Request) {
  const { email } = await request.json();

  // TODO: Wire up to email service (Mailchimp, Resend, Supabase, etc.)
  console.log("Newsletter signup:", email);

  return NextResponse.json({ success: true });
}
