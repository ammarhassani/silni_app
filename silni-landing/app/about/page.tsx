import type { Metadata } from "next";
import ScrollReveal from "@/components/animations/ScrollReveal";
import TextReveal from "@/components/animations/TextReveal";
import IslamicPattern from "@/components/animations/IslamicPattern";

export const metadata: Metadata = {
  title: "عن صِلني — قصتنا ورؤيتنا",
  description: "صِلني تطبيق مبني على قيمة إسلامية عظيمة — صلة الرحم.",
};

export default function AboutPage() {
  return (
    <>
      <section className="relative gradient-hero text-white pt-[120px] pb-3xl overflow-hidden">
        <IslamicPattern color="#81C784" opacity={0.05} />
        <div className="max-w-4xl mx-auto px-md lg:px-xl relative z-10 text-center">
          <TextReveal text="عن صِلني" as="h1" className="text-hero mb-lg" />
          <ScrollReveal delay={0.4}>
            <p className="text-body-lg text-white/80 leading-relaxed max-w-2xl mx-auto">
              تطبيق مبني على فريضة إسلامية عظيمة
            </p>
          </ScrollReveal>
        </div>
      </section>

      <section className="py-3xl bg-surface">
        <div className="max-w-3xl mx-auto px-md lg:px-xl">
          <ScrollReveal>
            <blockquote className="text-center mb-2xl">
              <p className="font-amiri text-[24px] leading-[2] text-primary-deep mb-md">
                «مَن أَحَبَّ أن يُبسَط له في رِزقه، ويُنسأ له في أَثَره، فليَصِل رَحِمَه»
              </p>
              <cite className="text-text-secondary text-body-md italic block">
                — متفق عليه
              </cite>
            </blockquote>
          </ScrollReveal>

          <ScrollReveal delay={0.2}>
            <div className="space-y-lg text-body-lg text-text-secondary leading-relaxed">
              <p>
                صلة الرحم من أعظم العبادات في الإسلام. النبي ﷺ وصّى بها وبيّن
                أن من وصلها وصله الله، ومن قطعها قطعه الله. لكن في عصرنا، مع
                زحمة الحياة والمشاغل اليومية، صار كثير منّا ينسى يتواصل مع
                أقاربه.
              </p>
              <p>
                صِلني وُلد من هذي المشكلة. تطبيق بسيط يساعدك تحافظ على صلة
                رحمك بطريقة عملية — يتابع تواصلك، يذكّرك، ويحفّزك تستمر.
              </p>
            </div>
          </ScrollReveal>
        </div>
      </section>

      <section className="py-3xl bg-white">
        <div className="max-w-3xl mx-auto px-md lg:px-xl">
          <ScrollReveal>
            <h2 className="text-headline-lg text-primary-deep mb-xl text-center">
              رؤيتنا
            </h2>
          </ScrollReveal>

          <div className="space-y-xl">
            {[
              {
                title: "التقنية في خدمة الدين",
                text: "نؤمن إن التقنية لازم تخدم قيمنا الإسلامية، مو بس ترفيه.",
              },
              {
                title: "البساطة أولاً",
                text: "تطبيق سهل وواضح. ما نبي نعقّد عبادة بسيطة وجميلة.",
              },
              {
                title: "خصوصيتك مقدسة",
                text: "بياناتك لك. ما نبيع معلوماتك ولا نشاركها مع أحد.",
              },
            ].map((item, i) => (
              <ScrollReveal key={item.title} delay={i * 0.15}>
                <div className="bg-surface rounded-card p-xl">
                  <h3 className="text-headline-sm text-primary-deep mb-sm">
                    {item.title}
                  </h3>
                  <p className="text-body-lg text-text-secondary leading-relaxed">
                    {item.text}
                  </p>
                </div>
              </ScrollReveal>
            ))}
          </div>
        </div>
      </section>
    </>
  );
}
