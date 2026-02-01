"use client";

import { motion } from "framer-motion";
import ScrollReveal from "@/components/animations/ScrollReveal";
import Button from "@/components/ui/Button";

const tiers = [
  {
    name: "مجاني",
    price: "٠",
    period: "",
    description: "ابدأ بصلة رحمك اليوم",
    features: [
      "تسجيل التواصل مع الأقارب",
      "٣ تذكيرات",
      "شجرة العائلة",
      "ثيمات مخصصة",
      "سلاسل التواصل",
      "نقاط وإنجازات",
    ],
    cta: "حمّل مجاناً",
    featured: false,
  },
  {
    name: "ماكس",
    price: "٧٫٩٩",
    period: "/شهرياً",
    annualPrice: "٧٩٫٩٩$/سنوياً",
    description: "كل المميزات + الذكاء الاصطناعي",
    features: [
      "كل مميزات المجاني",
      "تذكيرات غير محدودة",
      "المساعد الذكي (AI)",
      "كتابة الرسائل بالذكاء الاصطناعي",
      "تحليل العلاقات",
      "تقارير أسبوعية",
      "إحصائيات متقدمة",
      "تصدير البيانات",
    ],
    cta: "جرّب مجاناً لمدة أسبوع",
    featured: true,
  },
];

export default function PricingCards() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-xl max-w-4xl mx-auto">
      {tiers.map((tier, i) => (
        <ScrollReveal key={tier.name} delay={i * 0.2}>
          <motion.div
            className={`relative rounded-card p-xl ${
              tier.featured
                ? "bg-white shadow-xl border-2 border-gold"
                : "bg-white shadow-sm border border-text-hint/20"
            }`}
            whileHover={{ y: -8 }}
            transition={{ duration: 0.3 }}
          >
            {tier.featured && (
              <div className="absolute -top-4 left-1/2 -translate-x-1/2 gradient-golden text-primary-deep font-bold text-label-lg px-lg py-xs rounded-full animate-pulse-glow">
                الأكثر طلباً
              </div>
            )}

            {tier.featured && (
              <div className="absolute inset-0 rounded-card overflow-hidden pointer-events-none">
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-gold/10 to-transparent animate-shimmer bg-[length:200%_100%]" />
              </div>
            )}

            <div className="text-center mb-xl relative">
              <h3 className="text-headline-md text-primary-deep mb-sm">
                {tier.name}
              </h3>
              <p className="text-text-secondary text-body-md mb-lg">
                {tier.description}
              </p>
              <div className="flex items-baseline justify-center gap-xs">
                <span className="font-poppins text-[48px] font-black text-primary-deep">
                  ${tier.price}
                </span>
                {tier.period && (
                  <span className="text-text-secondary text-body-lg">
                    {tier.period}
                  </span>
                )}
              </div>
              {"annualPrice" in tier && tier.annualPrice && (
                <p className="text-text-hint text-body-md mt-xs">
                  أو {tier.annualPrice}
                </p>
              )}
            </div>

            <ul className="space-y-md mb-xl">
              {tier.features.map((feature) => (
                <li
                  key={feature}
                  className="flex items-center gap-sm text-body-lg text-text-primary"
                >
                  <span className="text-primary flex-shrink-0">✓</span>
                  {feature}
                </li>
              ))}
            </ul>

            <Button
              href="https://apps.apple.com/sa/app/%D8%B5%D9%84%D9%86%D9%8A/id6756042988"
              variant={tier.featured ? "golden" : "outline"}
              size="lg"
              className={`w-full ${!tier.featured ? "!border-primary !text-primary hover:!bg-primary/5" : ""}`}
            >
              {tier.cta}
            </Button>
          </motion.div>
        </ScrollReveal>
      ))}
    </div>
  );
}
