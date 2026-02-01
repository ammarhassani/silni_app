import type { Metadata } from "next";
import ScrollReveal from "@/components/animations/ScrollReveal";
import TextReveal from "@/components/animations/TextReveal";
import IslamicPattern from "@/components/animations/IslamicPattern";
import Button from "@/components/ui/Button";

export const metadata: Metadata = {
  title: "مميزات صِلني — كل اللي تحتاجه لصلة الرحم",
  description: "تتبّع التواصل، تذكيرات ذكية، سلاسل، مساعد ذكي، شجرة العائلة، وإحصائيات.",
};

const features = [
  {
    icon: "📞",
    title: "تتبّع التواصل",
    description: "سجّل كل تواصل مع أقاربك — اتصال، زيارة، رسالة، هدية، أو مناسبة. كل شي محفوظ.",
  },
  {
    icon: "🔔",
    title: "تذكيرات ذكية",
    description: "حدد أولوياتك وصِلني يذكّرك. يومي، أسبوعي، شهري، أو كل جمعة.",
  },
  {
    icon: "🔥",
    title: "سلاسل التواصل",
    description: "حافظ على سلسلة تواصلك. كل يوم تتواصل يحسب. لا تخلي السلسلة تنقطع!",
  },
  {
    icon: "🤖",
    title: "المساعد الذكي",
    description: "يساعدك تكتب رسائل، يقترح مواضيع للمحادثة، ويحلل علاقاتك. متاح في باقة ماكس.",
  },
  {
    icon: "🌳",
    title: "شجرة العائلة",
    description: "شوف عائلتك بشكل مرئي وتعرّف على علاقاتك بنظرة واحدة.",
  },
  {
    icon: "📊",
    title: "إحصائيات وتقارير",
    description: "تعرّف على نمط تواصلك واكتشف مين يحتاج اهتمام أكثر.",
  },
  {
    icon: "🏆",
    title: "نقاط وإنجازات",
    description: "اكسب نقاط مع كل تواصل وافتح إنجازات تحفّزك تستمر.",
  },
  {
    icon: "🔒",
    title: "خصوصية كاملة",
    description: "بياناتك مشفّرة ومحمية. ما نبيع ولا نشارك معلوماتك مع أي طرف.",
  },
];

function FeatureCard({
  icon,
  title,
  description,
}: {
  icon: string;
  title: string;
  description: string;
}) {
  return (
    <ScrollReveal>
      <div className="bg-white rounded-card p-xl shadow-sm hover:shadow-lg transition-all duration-300 group">
        <span className="text-5xl block mb-md group-hover:scale-110 transition-transform duration-300">
          {icon}
        </span>
        <h3 className="text-headline-sm text-primary-deep mb-sm">{title}</h3>
        <p className="text-body-lg text-text-secondary leading-relaxed">
          {description}
        </p>
      </div>
    </ScrollReveal>
  );
}

export default function FeaturesPage() {
  return (
    <>
      <section className="relative gradient-hero text-white pt-[120px] pb-3xl overflow-hidden">
        <IslamicPattern color="#81C784" opacity={0.05} />
        <div className="max-w-4xl mx-auto px-md lg:px-xl relative z-10 text-center">
          <TextReveal text="كل اللي تحتاجه" as="h1" className="text-hero mb-md" />
          <TextReveal
            text="لصلة الرحم"
            as="h2"
            className="text-dramatic text-gold mb-lg"
            delay={0.4}
          />
          <ScrollReveal delay={0.7}>
            <p className="text-body-lg text-white/80 max-w-2xl mx-auto">
              أدوات بسيطة وفعّالة تساعدك تحافظ على أجمل عبادة
            </p>
          </ScrollReveal>
        </div>
      </section>

      <section className="py-3xl bg-surface">
        <div className="max-w-7xl mx-auto px-md lg:px-xl">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-lg">
            {features.map((feature) => (
              <FeatureCard key={feature.title} {...feature} />
            ))}
          </div>
        </div>
      </section>

      <section className="py-3xl bg-white text-center">
        <ScrollReveal>
          <h2 className="text-headline-lg text-primary-deep mb-lg">
            جاهز تبدأ؟
          </h2>
          <Button href="https://apps.apple.com/sa/app/%D8%B5%D9%84%D9%86%D9%8A/id6756042988" size="lg">
            حمّل التطبيق مجاناً
          </Button>
        </ScrollReveal>
      </section>
    </>
  );
}
