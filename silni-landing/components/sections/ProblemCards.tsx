"use client";

import { motion } from "framer-motion";
import StaggerChildren, { staggerItem } from "@/components/animations/StaggerChildren";
import ScrollReveal from "@/components/animations/ScrollReveal";

const problems = [
  {
    icon: "🕐",
    title: "ننسى نتواصل",
    description: "الحياة تشغلنا وننسى نسأل عن أقرب الناس لنا",
  },
  {
    icon: "📅",
    title: "ما نعرف متى آخر مرة",
    description: "مرّت أشهر من آخر اتصال ولا ندري",
  },
  {
    icon: "💔",
    title: "نفقد الأجر",
    description: "صلة الرحم عبادة عظيمة وأجرها كبير عند الله",
  },
];

export default function ProblemCards() {
  return (
    <section className="py-3xl bg-surface">
      <div className="max-w-7xl mx-auto px-md lg:px-xl">
        <ScrollReveal>
          <h2 className="text-headline-lg text-primary-deep text-center mb-2xl">
            المشكلة اللي كلنا نعيشها
          </h2>
        </ScrollReveal>

        <StaggerChildren className="grid grid-cols-1 md:grid-cols-3 gap-lg">
          {problems.map((problem) => (
            <motion.div
              key={problem.title}
              variants={staggerItem}
              className="bg-white rounded-card p-xl shadow-sm hover:shadow-lg transition-shadow duration-300"
            >
              <span className="text-5xl block mb-md">{problem.icon}</span>
              <h3 className="text-headline-sm text-primary-deep mb-sm">
                {problem.title}
              </h3>
              <p className="text-body-lg text-text-secondary leading-relaxed">
                {problem.description}
              </p>
            </motion.div>
          ))}
        </StaggerChildren>
      </div>
    </section>
  );
}
