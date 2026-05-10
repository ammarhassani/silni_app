"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import { motion } from "framer-motion";

const APP_STORE_URL =
  "https://apps.apple.com/sa/app/%D8%B5%D9%84%D9%86%D9%8A/id6756042988";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.silni.app";

export default function JoinClient() {
  const [deepLink, setDeepLink] = useState<string | null>(null);
  const [platform, setPlatform] = useState<"ios" | "android" | "desktop">(
    "desktop"
  );

  useEffect(() => {
    // 1. Detect platform.
    const ua = navigator.userAgent || "";
    const isIOS = /iPad|iPhone|iPod/.test(ua) && !(window as unknown as { MSStream?: unknown }).MSStream;
    const isAndroid = /android/i.test(ua);
    setPlatform(isIOS ? "ios" : isAndroid ? "android" : "desktop");

    // 2. Extract + sanitize the invite code from the URL path.
    const path = window.location.pathname;
    const match = path.match(/^\/join\/(.+)/);
    if (!match) return;

    const rawCode = match[1];
    if (!/^[a-zA-Z0-9_-]{4,64}$/.test(rawCode)) return;

    // 3. Build deep link with optional rid query.
    const searchParams = new URLSearchParams(window.location.search);
    let safeQuery = "";
    const rid = searchParams.get("rid");
    if (
      rid &&
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        rid
      )
    ) {
      safeQuery = `?rid=${rid}`;
    }

    setDeepLink(`com.silni.app://join/${rawCode}${safeQuery}`);
  }, []);

  // Best-of-both: when on iOS or Android with the deep link ready, auto-attempt
  // it via window.location (which iOS treats as a user-initiated navigation
  // when it happens early after a real link tap from another app like Mail or
  // Messages). Modern iOS Safari blocks iframe-based attempts silently, so we
  // skip that pattern. The visible "Open in app" button below is the reliable
  // path — it always works on direct user tap.
  useEffect(() => {
    if (!deepLink) return;
    if (platform !== "ios" && platform !== "android") return;
    // Tiny delay so the page can paint first.
    const t = setTimeout(() => {
      // Mobile browsers will either open the app or do nothing if it's not
      // installed. Either way, the user can still tap the visible button.
      window.location.href = deepLink;
    }, 250);
    return () => clearTimeout(t);
  }, [deepLink, platform]);

  return (
    <section className="min-h-screen gradient-hero flex items-center justify-center px-md py-3xl">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="bg-white/[0.08] backdrop-blur-xl border border-white/[0.12] rounded-card p-xl max-w-[400px] w-full text-center"
      >
        <Image
          src="/images/app_icon.png"
          alt="صِلني"
          width={80}
          height={80}
          className="mx-auto mb-lg rounded-2xl"
        />

        <h1 className="text-headline-md text-white mb-sm leading-relaxed">
          تمت دعوتك للانضمام لشجرة عائلة في صِلني
        </h1>

        <p className="text-body-lg text-white/70 mb-xl leading-relaxed">
          حمّل التطبيق وانضم لعائلتك لتتابعوا صلة الرحم معًا
        </p>

        <div className="flex flex-col gap-sm">
          {deepLink && (platform === "ios" || platform === "android") && (
            <a
              href={deepLink}
              className="flex items-center justify-center gap-[10px] py-[14px] px-lg rounded-2xl bg-white text-black font-bold text-body-lg transition-transform active:scale-[0.97]"
            >
              <svg
                className="w-[22px] h-[22px]"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z" />
              </svg>
              افتح في تطبيق صِلني
            </a>
          )}

          {platform === "ios" && (
            <a
              href={APP_STORE_URL}
              className="flex items-center justify-center gap-[10px] py-[14px] px-lg rounded-2xl bg-white/15 text-white border border-white/20 font-semibold text-body-lg transition-transform active:scale-[0.97]"
            >
              <svg
                className="w-[22px] h-[22px]"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
              </svg>
              لا يعمل؟ حمّل من App Store
            </a>
          )}

          {platform === "android" && (
            <span className="flex items-center justify-center gap-[10px] py-[14px] px-lg rounded-2xl bg-white/[0.05] text-white/40 border border-white/[0.08] font-medium text-body-lg">
              قريباً على Google Play
            </span>
          )}

          {platform === "desktop" && (
            <>
              <p className="text-white/60 text-body-md mb-sm leading-relaxed">
                افتح هذا الرابط من جوالك للانضمام
              </p>
              <a
                href={APP_STORE_URL}
                className="flex items-center justify-center gap-[10px] py-[14px] px-lg rounded-2xl bg-white/15 text-white border border-white/20 font-semibold text-body-lg transition-transform active:scale-[0.97]"
              >
                <svg
                  className="w-[22px] h-[22px]"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                </svg>
                App Store
              </a>
            </>
          )}
        </div>

        <div className="h-px bg-white/10 my-lg" />
        <p className="text-[13px] text-white/40 leading-relaxed">
          صِلني — تطبيق صلة الرحم
        </p>
      </motion.div>
    </section>
  );
}
