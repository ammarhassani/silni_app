"use client";

import CountUp from "@/components/animations/CountUp";
import StaggerChildren, { staggerItem } from "@/components/animations/StaggerChildren";
import { motion } from "framer-motion";

const stats = [
  { value: 4.8, suffix: " ⭐", label: "تقييم المستخدمين" },
  { value: 1000, suffix: "+", label: "تحميل" },
  { value: 50000, suffix: "+", label: "تواصل تم تسجيله" },
];

export default function SocialProof() {
  return (
    <section className="py-3xl gradient-deep text-white">
      <div className="max-w-7xl mx-auto px-md lg:px-xl">
        <StaggerChildren className="grid grid-cols-1 md:grid-cols-3 gap-xl text-center">
          {stats.map((stat) => (
            <motion.div key={stat.label} variants={staggerItem}>
              <div className="mb-sm">
                <CountUp
                  end={stat.value}
                  suffix={stat.suffix}
                  className="text-[64px] font-black"
                />
              </div>
              <p className="text-white/70 text-body-lg">{stat.label}</p>
            </motion.div>
          ))}
        </StaggerChildren>
      </div>
    </section>
  );
}
