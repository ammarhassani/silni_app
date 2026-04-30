// @deno-types="npm:@types/node"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { getCorsHeaders } from "../_shared/cors.ts";

/**
 * Cron job: Send smart nudge notifications based on contact gaps
 *
 * Scans all users' relatives, calculates days since last contact,
 * matches to admin-configured nudge templates by gap tier and gender,
 * enforces cooldown and daily caps, rotates template copy.
 *
 * Schedule: 0 * * * * (every hour)
 */

// Max nudges per user per cron run
const MAX_NUDGES_PER_RUN = 1;
// Max nudges per user per day
const MAX_NUDGES_PER_DAY = 2;  // Reduced from 3 — less pressure
// Minimum gap days to even consider nudging
const MIN_GAP_DAYS = 5;  // Increased from 3 — more grace period
// How many recent template_keys to exclude for rotation
const ROTATION_LOOKBACK = 5;

// Relationship type → Arabic possessive label
// Used to build {{relative_label}} like "عمك سعد" or "أمك"
// Paternal (default) labels
const RELATIONSHIP_LABELS: Record<string, { male: string; female: string }> = {
  father:      { male: "أبوك",      female: "أبوك" },
  mother:      { male: "أمك",       female: "أمك" },
  brother:     { male: "أخوك",      female: "أخوك" },
  sister:      { male: "أختك",      female: "أختك" },
  son:         { male: "ولدك",      female: "ولدك" },
  daughter:    { male: "بنتك",      female: "بنتك" },
  grandfather: { male: "جدك",       female: "جدك" },
  grandmother: { male: "جدتك",      female: "جدتك" },
  uncle:       { male: "عمك",       female: "عمك" },
  aunt:        { male: "عمتك",      female: "عمتك" },
  nephew:      { male: "ابن أخوك",  female: "ابن أخوك" },
  niece:       { male: "بنت أختك",  female: "بنت أختك" },
  cousin:      { male: "ولد عمك",   female: "بنت عمك" },
  husband:     { male: "زوجك",      female: "زوجك" },
  wife:        { male: "زوجتك",     female: "زوجتك" },
};

// Maternal side overrides for uncle/aunt/cousin/grandparent
const MATERNAL_LABELS: Record<string, { male: string; female: string }> = {
  uncle:       { male: "خالك",      female: "خالك" },
  aunt:        { male: "خالتك",     female: "خالتك" },
  cousin:      { male: "ولد خالك",  female: "بنت خالك" },
  grandfather: { male: "جدك",       female: "جدك" },
  grandmother: { male: "جدتك",      female: "جدتك" },
};

interface RelativeRow {
  id: string;
  user_id: string;
  full_name: string;
  relationship_type: string;
  gender: string | null;
  family_side: string | null;
  last_contact_date: string | null;
  is_archived: boolean;
}

interface NudgeTemplate {
  template_key: string;
  title_ar: string;
  body_ar: string;
  gap_min_days: number;
  gap_max_days: number;
  gender: string | null;
  nudge_cooldown_hours: number;
}

interface NudgeHistoryRow {
  template_key: string;
  sent_at: string;
}

/**
 * Use AI to compose a natural Arabic label from the system relationship label
 * and the user-entered name, removing redundancy across dialects.
 *
 * Examples:
 *   (عمك, عمي سعد)     → عمك سعد       (strips redundant title)
 *   (جدتك, امي الكبيره) → جدتك امي الكبيره (keeps endearing nickname)
 *   (خالك, اونكل ماجد)  → خالك ماجد      (strips dialect title)
 *   (عمك, العم فهد)     → عمك فهد        (strips formal title)
 *
 * Falls back to simple concatenation on any error.
 */
async function composeRelativeLabel(
  systemLabel: string,
  userName: string
): Promise<string> {
  try {
    const apiKey = Deno.env.get("DEEPSEEK_API_KEY");
    if (!apiKey) return `${systemLabel} ${userName}`;

    const response = await fetch("https://api.deepseek.com/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "deepseek-chat",
        messages: [
          {
            role: "system",
            content:
              "أنت تبني عناوين إشعارات عربية. يعطيك النظام صلة القرابة (مثل عمك، خالك، جدتك) واسم الشخص اللي المستخدم كتبه. " +
              "ادمجهم بشكل طبيعي بدون تكرار.\n" +
              "- إذا الاسم فيه لقب قرابة يطابق الصلة، شيله: عمك + عمي سعد → عمك سعد\n" +
              "- إذا الاسم فيه لقب قرابة بلهجة ثانية يطابق نفس الصلة، شيله: خالك + اونكل ماجد → خالك ماجد\n" +
              "- إذا الاسم فيه لقب حنون أو مختلف، خله: جدتك + امي الكبيره → جدتك امي الكبيره\n" +
              "- إذا الاسم مجرد اسم عادي، ادمج: عمك + سعد → عمك سعد\n" +
              "رد بالنتيجة النهائية فقط، بدون شرح.",
          },
          { role: "user", content: `صلة=${systemLabel}, اسم=${userName}` },
        ],
        temperature: 0,
        max_tokens: 30,
      }),
      signal: AbortSignal.timeout(3000),
    });

    if (!response.ok) return `${systemLabel} ${userName}`;

    const data = await response.json();
    const result = data.choices?.[0]?.message?.content?.trim();
    return result || `${systemLabel} ${userName}`;
  } catch {
    return `${systemLabel} ${userName}`;
  }
}

/**
 * Build the relative label: "عمك سعد", "أمك", etc.
 * Uses AI to handle dialect variations and avoid redundancy.
 */
async function buildRelativeLabel(
  relationshipType: string,
  fullName: string,
  relativeGender: string | null,
  familySide: string | null
): Promise<string> {
  // Use maternal labels when family_side is maternal, fall back to default
  const labels =
    (familySide === "maternal" && MATERNAL_LABELS[relationshipType]) ||
    RELATIONSHIP_LABELS[relationshipType];
  if (!labels) {
    return fullName;
  }

  const gender = relativeGender === "female" ? "female" : "male";
  const label = labels[gender];

  if (!label) return fullName;

  // For parent/spouse relationships where the label IS the identity (أمك, أبوك)
  const singleLabelTypes = ["father", "mother", "husband", "wife"];
  if (singleLabelTypes.includes(relationshipType)) {
    return label;
  }

  // Use AI to compose naturally, handling dialects and nicknames
  return await composeRelativeLabel(label, fullName);
}

/**
 * Replace template variables with actual values
 */
function renderTemplate(
  template: string,
  relativeLabel: string,
  daysSince: number
): string {
  return template
    .replace(/\{\{relative_label\}\}/g, relativeLabel)
    .replace(/\{\{days\}\}/g, daysSince.toString());
}

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("🧠 Starting smart nudges check...");

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey =
      Deno.env.get("SERVICE_ROLE_JWT") ??
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Current time in Riyadh (UTC+3)
    const now = new Date();
    const riyadhTime = new Date(now.getTime() + 3 * 60 * 60 * 1000);
    const todayStart = new Date(riyadhTime);
    todayStart.setUTCHours(0, 0, 0, 0);

    console.log(`⏰ Riyadh time: ${riyadhTime.toISOString()}`);

    // 1. Fetch all active nudge templates
    const { data: templates, error: templatesError } = await supabase
      .from("admin_notification_templates")
      .select(
        "template_key, title_ar, body_ar, gap_min_days, gap_max_days, gender, nudge_cooldown_hours"
      )
      .eq("category", "nudge")
      .eq("is_active", true)
      .not("gap_min_days", "is", null)
      .not("gap_max_days", "is", null);

    if (templatesError) {
      console.error("❌ Error fetching nudge templates:", templatesError);
      throw templatesError;
    }

    if (!templates || templates.length === 0) {
      console.log("ℹ️ No active nudge templates found");
      return new Response(
        JSON.stringify({ message: "No active nudge templates" }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`📋 Loaded ${templates.length} active nudge templates`);

    // 2. Fetch all non-archived, non-self relatives with gap >= MIN_GAP_DAYS.
    //
    // CRITICAL: is_self=false filter prevents the user's own self-node (the
    // anchor row with their own name) from being treated as a "relative
    // overdue for contact" — without this, users get nudges telling them
    // they haven't heard from themselves in N days. Phase 9.X.D.B fix.
    //
    // Also dropped the `last_contact_date IS NULL` branch from the .or():
    // never-contacted relatives are excluded from the smart-nudge stream
    // because the {{days}} substitution would otherwise become a meaningless
    // sentinel ("له 999 يوم"). They'll still appear in scheduled reminders
    // (which use the schedule's own logic, not last_contact_date).
    const cutoffDate = new Date(now.getTime() - MIN_GAP_DAYS * 24 * 60 * 60 * 1000);

    const { data: relatives, error: relativesError } = await supabase
      .from("relatives")
      .select("id, user_id, full_name, relationship_type, gender, family_side, last_contact_date, is_archived")
      .eq("is_archived", false)
      .eq("is_self", false)
      .not("last_contact_date", "is", null)
      .lte("last_contact_date", cutoffDate.toISOString());

    if (relativesError) {
      console.error("❌ Error fetching relatives:", relativesError);
      throw relativesError;
    }

    if (!relatives || relatives.length === 0) {
      console.log("ℹ️ No relatives needing nudges");
      return new Response(
        JSON.stringify({ message: "No relatives needing nudges" }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`👥 Found ${relatives.length} relative(s) with gap >= ${MIN_GAP_DAYS} days`);

    // 3. Group relatives by user, sorted by gap DESC
    const userRelatives = new Map<string, Array<RelativeRow & { daysSince: number }>>();

    for (const rel of relatives as RelativeRow[]) {
      // last_contact_date is guaranteed non-null by the query filter above
      // (was previously a 999-day sentinel that leaked into notifications).
      const daysSince = Math.floor(
        (now.getTime() - new Date(rel.last_contact_date!).getTime()) /
          (1000 * 60 * 60 * 24)
      );

      if (daysSince < MIN_GAP_DAYS) continue;

      const list = userRelatives.get(rel.user_id) || [];
      list.push({ ...rel, daysSince });
      userRelatives.set(rel.user_id, list);
    }

    // Sort each user's relatives by gap DESC (most overdue first)
    for (const [userId, rels] of userRelatives) {
      rels.sort((a, b) => b.daysSince - a.daysSince);
      // Only consider top 3 most overdue
      userRelatives.set(userId, rels.slice(0, 3));
    }

    console.log(`👤 Processing ${userRelatives.size} user(s)`);

    let totalNudgesSent = 0;
    let totalSkipped = 0;

    // 4. Process each user
    for (const [userId, rels] of userRelatives) {
      // Check daily cap
      const { count: todayCount } = await supabase
        .from("nudge_history")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId)
        .gte("sent_at", todayStart.toISOString());

      if ((todayCount ?? 0) >= MAX_NUDGES_PER_DAY) {
        console.log(`   ⏭️ User ${userId}: daily cap reached (${todayCount}/${MAX_NUDGES_PER_DAY})`);
        totalSkipped += rels.length;
        continue;
      }

      let nudgesSentThisRun = 0;

      for (const rel of rels) {
        if (nudgesSentThisRun >= MAX_NUDGES_PER_RUN) break;

        console.log(
          `\n   📝 ${rel.full_name} (${rel.relationship_type}, ${rel.gender ?? "unknown"}, gap: ${rel.daysSince}d)`
        );

        // 4a. Check cooldown — get most recent nudge for this user+relative
        const { data: recentNudges } = await supabase
          .from("nudge_history")
          .select("template_key, sent_at")
          .eq("user_id", userId)
          .eq("relative_id", rel.id)
          .order("sent_at", { ascending: false })
          .limit(ROTATION_LOOKBACK);

        // 4b. Find matching templates for this gap and gender
        const matchingTemplates = (templates as NudgeTemplate[]).filter((t) => {
          if (rel.daysSince < t.gap_min_days || rel.daysSince > t.gap_max_days)
            return false;
          // Gender match: template gender matches relative, or template is NULL (universal)
          if (t.gender !== null && t.gender !== (rel.gender ?? "male"))
            return false;
          return true;
        });

        if (matchingTemplates.length === 0) {
          console.log(`      ⚠️ No matching templates for gap ${rel.daysSince}d, gender ${rel.gender}`);
          totalSkipped++;
          continue;
        }

        // 4c. Check cooldown using the first matching template's cooldown
        const cooldownHours = matchingTemplates[0].nudge_cooldown_hours ?? 72;
        const cooldownCutoff = new Date(
          now.getTime() - cooldownHours * 60 * 60 * 1000
        );

        if (
          recentNudges &&
          recentNudges.length > 0 &&
          new Date((recentNudges as NudgeHistoryRow[])[0].sent_at) > cooldownCutoff
        ) {
          console.log(
            `      ⏭️ Cooldown active (${cooldownHours}h), last nudge: ${(recentNudges as NudgeHistoryRow[])[0].sent_at}`
          );
          totalSkipped++;
          continue;
        }

        // 4d. Exclude recently used templates for rotation
        const recentKeys = new Set(
          (recentNudges as NudgeHistoryRow[] | null)?.map((n) => n.template_key) ?? []
        );
        let availableTemplates = matchingTemplates.filter(
          (t) => !recentKeys.has(t.template_key)
        );

        // If all templates exhausted, reset rotation
        if (availableTemplates.length === 0) {
          availableTemplates = matchingTemplates;
        }

        // 4e. Pick one randomly
        const template =
          availableTemplates[Math.floor(Math.random() * availableTemplates.length)];

        // 4f. Build message
        const relativeLabel = await buildRelativeLabel(
          rel.relationship_type,
          rel.full_name,
          rel.gender,
          rel.family_side
        );

        const title = renderTemplate(template.title_ar, relativeLabel, rel.daysSince);
        const body = renderTemplate(template.body_ar, relativeLabel, rel.daysSince);

        console.log(`      📤 Template: ${template.template_key}`);
        console.log(`      📝 Title: "${title}"`);
        console.log(`      📝 Body: "${body}"`);

        // 4g. Send via existing send-push-notification
        try {
          const notificationResponse = await fetch(
            `${supabaseUrl}/functions/v1/send-push-notification`,
            {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${supabaseKey}`,
              },
              body: JSON.stringify({
                userId,
                notificationType: "nudge",
                title,
                body,
                data: {
                  type: "nudge",
                  relative_id: rel.id,
                  gap_days: rel.daysSince.toString(),
                },
              }),
              signal: AbortSignal.timeout(5000),
            }
          );

          const responseText = await notificationResponse.text();

          if (notificationResponse.ok) {
            const responseData = JSON.parse(responseText);
            if (responseData.sent > 0) {
              // 4h. Log to nudge_history
              await supabase.from("nudge_history").insert({
                user_id: userId,
                relative_id: rel.id,
                template_key: template.template_key,
                gap_days: rel.daysSince,
              });

              nudgesSentThisRun++;
              totalNudgesSent++;
              console.log(`      ✅ Nudge sent and logged`);
            } else {
              console.log(`      ⚠️ No FCM tokens for user`);
            }
          } else {
            console.error(`      ❌ Push failed: ${responseText}`);
          }
        } catch (error) {
          console.error(`      ❌ Error sending nudge:`, error);
        }

        // Rate limiting between sends
        await new Promise((resolve) => setTimeout(resolve, 100));
      }
    }

    console.log(`\n📊 Smart nudges complete:`);
    console.log(`   - Users processed: ${userRelatives.size}`);
    console.log(`   - Nudges sent: ${totalNudgesSent}`);
    console.log(`   - Skipped: ${totalSkipped}`);

    return new Response(
      JSON.stringify({
        success: true,
        usersProcessed: userRelatives.size,
        nudgesSent: totalNudgesSent,
        skipped: totalSkipped,
        message: `Sent ${totalNudgesSent} smart nudges`,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("❌ Unexpected error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
