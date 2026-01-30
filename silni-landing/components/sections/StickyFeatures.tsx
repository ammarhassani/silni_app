"use client";

import ScrollReveal from "@/components/animations/ScrollReveal";
import PhoneMockup from "@/components/ui/PhoneMockup";

const features = [
  {
    title: "تتبّع تواصلك",
    description: "سجّل كل اتصال، زيارة، رسالة، أو هدية. ما يضيع شي.",
    color: "text-primary",
    accent: "border-primary/40 bg-primary-pale/10",
    iconBg: "bg-primary/10",
    icon: "📞",
  },
  {
    title: "تذكيرات ذكية",
    description: "يذكّرك تتواصل مع أقاربك بناءً على أولوياتك — يومي، أسبوعي، أو شهري.",
    color: "text-accent-orange",
    accent: "border-accent-orange/30 bg-orange-50",
    iconBg: "bg-accent-orange/10",
    icon: "🔔",
  },
  {
    title: "سلاسل التواصل",
    description: "حافظ على سلسلة تواصلك مع كل قريب. كل يوم يحسب.",
    color: "text-gold-dark",
    accent: "border-gold-dark/30 bg-amber-50",
    iconBg: "bg-gold/20",
    icon: "🔥",
  },
  {
    title: "مساعد ذكي",
    description: "الذكاء الاصطناعي يساعدك تكتب رسائل ويقترح أفكار للتواصل.",
    color: "text-primary-dark",
    accent: "border-primary-dark/30 bg-green-50",
    iconBg: "bg-primary-dark/10",
    icon: "🤖",
  },
];

export default function StickyFeatures() {
  return (
    <section className="relative gradient-warm">
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

          <div className="space-y-lg">
            {features.map((feature, i) => (
              <ScrollReveal
                key={feature.title}
                direction="right"
                delay={i * 0.1}
              >
                <div className={`rounded-card p-xl border-r-4 ${feature.accent} shadow-sm hover:shadow-md transition-all duration-300`}>
                  <div className="flex items-center gap-md mb-sm">
                    <div className={`w-12 h-12 rounded-xl ${feature.iconBg} flex items-center justify-center`}>
                      <span className="text-2xl">{feature.icon}</span>
                    </div>
                    <h3 className={`text-headline-sm ${feature.color}`}>
                      {feature.title}
                    </h3>
                  </div>
                  <p className="text-body-lg text-text-secondary leading-relaxed pr-[3.75rem]">
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
