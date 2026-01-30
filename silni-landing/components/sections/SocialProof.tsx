"use client";

import { useEffect, useRef, useState } from "react";

const stats = [
  { value: 4.8, display: "٤٫٨", suffix: " ⭐", label: "تقييم المستخدمين" },
  { value: 1000, display: "١٬٠٠٠", suffix: "+", label: "تحميل" },
  { value: 50000, display: "٥٠٬٠٠٠", suffix: "+", label: "تواصل تم تسجيله" },
];

function AnimatedStat({
  display,
  suffix,
  label,
  delay,
}: {
  display: string;
  suffix: string;
  label: string;
  delay: number;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setVisible(true);
          observer.disconnect();
        }
      },
      { rootMargin: "0px" }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return (
    <div
      ref={ref}
      className="transition-all duration-700 ease-out"
      style={{
        opacity: visible ? 1 : 0,
        transform: visible ? "translateY(0)" : "translateY(30px)",
        transitionDelay: `${delay}s`,
      }}
    >
      <div className="mb-sm">
        <span className="font-poppins text-[64px] font-black">
          {display}{suffix}
        </span>
      </div>
      <p className="text-white/70 text-body-lg">{label}</p>
    </div>
  );
}

export default function SocialProof() {
  return (
    <section className="py-3xl gradient-deep text-white">
      <div className="max-w-7xl mx-auto px-md lg:px-xl">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-xl text-center">
          {stats.map((stat, i) => (
            <AnimatedStat
              key={stat.label}
              display={stat.display}
              suffix={stat.suffix}
              label={stat.label}
              delay={i * 0.15}
            />
          ))}
        </div>
      </div>
    </section>
  );
}
