"use client";

import TextReveal from "@/components/animations/TextReveal";
import ScrollReveal from "@/components/animations/ScrollReveal";
import ParallaxLayer from "@/components/animations/ParallaxLayer";
import IslamicPattern from "@/components/animations/IslamicPattern";
import PhoneMockup from "@/components/ui/PhoneMockup";
import Button from "@/components/ui/Button";
import AppStoreBadge from "@/components/ui/AppStoreBadge";

export default function Hero() {
  return (
    <section className="relative min-h-screen gradient-hero overflow-hidden flex items-center">
      <IslamicPattern color="#81C784" opacity={0.06} />

      <div className="max-w-7xl mx-auto px-md lg:px-xl py-3xl relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-3xl items-center">
          <div className="text-white text-right">
            <TextReveal
              text="صلة الرحم فريضة"
              as="h1"
              className="text-hero mb-md"
            />
            <TextReveal
              text="وصِلني يساعدك تحافظ عليها"
              as="h2"
              className="text-dramatic text-gold mb-xl"
              delay={0.5}
            />

            <ScrollReveal delay={0.8}>
              <p className="text-body-lg text-white/80 leading-relaxed mb-xl max-w-lg">
                في زحمة الحياة، ننسى نسأل عن أقاربنا. صِلني يذكّرك، يتابع
                تواصلك، ويحفّزك تحافظ على أجمل عبادة — صلة الرحم.
              </p>
            </ScrollReveal>

            <ScrollReveal delay={1}>
              <div className="flex flex-wrap items-center gap-md">
                <Button
                  href="https://apps.apple.com/app/id_PLACEHOLDER"
                  size="lg"
                >
                  حمّل التطبيق مجاناً
                </Button>
                <AppStoreBadge />
              </div>
            </ScrollReveal>
          </div>

          <ParallaxLayer speed={0.3} className="hidden lg:block">
            <PhoneMockup />
          </ParallaxLayer>
        </div>
      </div>

      <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-surface to-transparent" />
    </section>
  );
}
