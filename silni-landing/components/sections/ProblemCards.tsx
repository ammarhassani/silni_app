"use client";

import StaggerChildren from "@/components/animations/StaggerChildren";
import ScrollReveal from "@/components/animations/ScrollReveal";
import IslamicPattern from "@/components/animations/IslamicPattern";

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
    <section className="relative py-3xl gradient-soft overflow-hidden">
      <IslamicPattern color="#2E7D32" opacity={0.04} />

      <div className="max-w-7xl mx-auto px-md lg:px-xl relative z-10">
        <ScrollReveal>
          <h2 className="text-headline-lg text-primary-deep text-center mb-2xl">
            المشكلة اللي كلنا نعيشها
          </h2>
        </ScrollReveal>

        <StaggerChildren className="grid grid-cols-1 md:grid-cols-3 gap-lg">
          {problems.map((problem) => (
            <div
              key={problem.title}
              className="bg-white/80 backdrop-blur-sm rounded-card p-xl shadow-md hover:shadow-xl transition-all duration-300 border border-primary-pale/30 hover:-translate-y-1"
            >
              <div className="w-16 h-16 rounded-2xl bg-primary-pale/30 flex items-center justify-center mb-lg">
                <span className="text-4xl">{problem.icon}</span>
              </div>
              <h3 className="text-headline-sm text-primary-deep mb-sm">
                {problem.title}
              </h3>
              <p className="text-body-lg text-text-secondary leading-relaxed">
                {problem.description}
              </p>
            </div>
          ))}
        </StaggerChildren>
      </div>
    </section>
  );
}
