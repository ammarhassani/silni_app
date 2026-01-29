"use client";

import ScrollReveal from "@/components/animations/ScrollReveal";
import PhoneMockup from "@/components/ui/PhoneMockup";

const features = [
  {
    title: "تتبّع تواصلك",
    description: "سجّل كل اتصال، زيارة، رسالة، أو هدية. ما يضيع شي.",
    color: "text-primary",
  },
  {
    title: "تذكيرات ذكية",
    description: "يذكّرك تتواصل مع أقاربك بناءً على أولوياتك — يومي، أسبوعي، أو شهري.",
    color: "text-accent-orange",
  },
  {
    title: "سلاسل التواصل",
    description: "حافظ على سلسلة تواصلك مع كل قريب. كل يوم يحسب.",
    color: "text-gold-dark",
  },
  {
    title: "مساعد ذكي",
    description: "الذكاء الاصطناعي يساعدك تكتب رسائل ويقترح أفكار للتواصل.",
    color: "text-primary-dark",
  },
];

export default function StickyFeatures() {
  return (
    <section className="relative bg-white">
      <div className="max-w-7xl mx-auto px-md lg:px-xl">
        <ScrollReveal className="text-center pt-3xl pb-2xl">
          <h2 className="text-headline-lg text-primary-deep mb-md">
            كيف صِلني يساعدك؟
          </h2>
          <p className="text-body-lg text-text-secondary max-w-2xl mx-auto">
            أدوات بسيطة لعبادة عظيمة
          </p>
        </ScrollReveal>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-3xl pb-3xl">
          <div className="hidden lg:flex items-start justify-center">
            <div className="sticky top-32">
              <PhoneMockup />
            </div>
          </div>

          <div className="space-y-2xl">
            {features.map((feature, i) => (
              <ScrollReveal
                key={feature.title}
                direction="right"
                delay={i * 0.1}
              >
                <div className="bg-surface rounded-card p-xl">
                  <h3 className={`text-headline-sm mb-sm ${feature.color}`}>
                    {feature.title}
                  </h3>
                  <p className="text-body-lg text-text-secondary leading-relaxed">
                    {feature.description}
                  </p>
                </div>
              </ScrollReveal>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
