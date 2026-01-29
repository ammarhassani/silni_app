import type { Metadata } from "next";
import TextReveal from "@/components/animations/TextReveal";
import ScrollReveal from "@/components/animations/ScrollReveal";
import IslamicPattern from "@/components/animations/IslamicPattern";
import PricingCards from "@/components/sections/PricingCards";

export const metadata: Metadata = {
  title: "أسعار صِلني — ابدأ مجاناً",
  description: "باقة مجانية للجميع وباقة ماكس مع الذكاء الاصطناعي وتذكيرات غير محدودة.",
};

export default function PricingPage() {
  return (
    <>
      <section className="relative gradient-hero text-white pt-[120px] pb-3xl overflow-hidden">
        <IslamicPattern color="#81C784" opacity={0.05} />
        <div className="max-w-4xl mx-auto px-md lg:px-xl relative z-10 text-center">
          <TextReveal text="ابدأ مجاناً" as="h1" className="text-hero mb-md" />
          <ScrollReveal delay={0.4}>
            <p className="text-body-lg text-white/80 max-w-2xl mx-auto">
              صلة الرحم ما لها سعر — وصِلني يخلّيك تبدأ بدون أي تكلفة
            </p>
          </ScrollReveal>
        </div>
      </section>

      <section className="py-3xl bg-surface">
        <div className="max-w-7xl mx-auto px-md lg:px-xl">
          <PricingCards />
        </div>
      </section>
    </>
  );
}
