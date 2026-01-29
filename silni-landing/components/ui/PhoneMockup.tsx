"use client";

import { motion } from "framer-motion";
import Image from "next/image";

interface PhoneMockupProps {
  screenshot?: string;
  className?: string;
}

export default function PhoneMockup({
  screenshot = "/images/app_icon.png",
  className = "",
}: PhoneMockupProps) {
  return (
    <motion.div
      className={`relative ${className}`}
      initial={{ y: 80, opacity: 0 }}
      whileInView={{ y: 0, opacity: 1 }}
      viewport={{ once: true }}
      transition={{ duration: 0.8, delay: 0.4, ease: [0.25, 0.46, 0.45, 0.94] }}
    >
      <div className="relative w-[280px] h-[580px] mx-auto">
        <div className="absolute inset-0 bg-gray-900 rounded-[3rem] shadow-2xl border-[6px] border-gray-800">
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[120px] h-[30px] bg-gray-900 rounded-b-2xl z-10" />
          <div className="absolute inset-[3px] rounded-[2.5rem] overflow-hidden bg-primary-deep flex items-center justify-center">
            <Image
              src={screenshot}
              alt="صِلني"
              width={260}
              height={560}
              className="object-cover"
            />
          </div>
        </div>
        <div className="absolute -inset-4 bg-gold/20 blur-3xl rounded-full -z-10" />
      </div>
    </motion.div>
  );
}
