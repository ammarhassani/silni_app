"use client";

import { useEffect } from "react";
import Image from "next/image";
import { motion } from "framer-motion";

const APP_STORE_URL =
  "https://apps.apple.com/sa/app/%D8%B5%D9%84%D9%86%D9%8A/id6756042988";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.silni.app";

export default function DownloadPage() {
  useEffect(() => {
    const ua = navigator.userAgent.toLowerCase();
    if (/iphone|ipad|ipod/.test(ua)) {
      window.location.href = APP_STORE_URL;
    } else if (/android/.test(ua)) {
      window.location.href = PLAY_STORE_URL;
    }
    // Desktop or unknown — stay on page and show both links
  }, []);

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
          حمّل صِلني
        </h1>

        <p className="text-body-lg text-white/70 mb-xl leading-relaxed">
          حافظ على صلة الرحم مع عائلتك
        </p>

        <div className="flex flex-col gap-sm">
          <a
            href={APP_STORE_URL}
            className="flex items-center justify-center gap-[10px] py-[14px] px-lg rounded-2xl bg-white text-black font-semibold text-body-lg transition-transform active:scale-[0.97]"
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

          <a
            href={PLAY_STORE_URL}
            className="flex items-center justify-center gap-[10px] py-[14px] px-lg rounded-2xl bg-white/15 text-white border border-white/20 font-semibold text-body-lg transition-transform active:scale-[0.97]"
          >
            <svg
              className="w-[22px] h-[22px]"
              viewBox="0 0 24 24"
              fill="currentColor"
            >
              <path d="M3.18 23.04l8.85-8.84L3.2.96C2.83 1.17 2.57 1.6 2.57 2.1v19.81c0 .5.25.93.61 1.13zm1.57 1.13l9.78-5.52-2.78-2.78-7 6.99v1.31zm12.95-7.33l2.61-1.47c.49-.27.49-.95 0-1.22l-2.61-1.47-3.03 3.03 3.03 3.13zM4.75.24L13 8.49l-2.78 2.78L4.75.24z" />
            </svg>
            Google Play
          </a>
        </div>

        <div className="h-px bg-white/10 my-lg" />
        <p className="text-[13px] text-white/40 leading-relaxed">
          صِلني — تطبيق صلة الرحم
        </p>
      </motion.div>
    </section>
  );
}
