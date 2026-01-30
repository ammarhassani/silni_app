"use client";

import { useState } from "react";
import ScrollReveal from "@/components/animations/ScrollReveal";
import IslamicPattern from "@/components/animations/IslamicPattern";

export default function NewsletterSignup() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "success" | "error">("idle");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await fetch("/api/newsletter", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      if (res.ok) {
        setStatus("success");
        setEmail("");
      } else {
        setStatus("error");
      }
    } catch {
      setStatus("error");
    }
  };

  return (
    <section className="relative py-3xl gradient-cta overflow-hidden">
      <IslamicPattern color="#81C784" opacity={0.06} />

      <div className="max-w-2xl mx-auto px-md lg:px-xl text-center relative z-10">
        <ScrollReveal>
          <h2 className="text-headline-lg text-white mb-md">
            كن أول من يعرف
          </h2>
          <p className="text-body-lg text-white/80 mb-xl">
            سجّل بريدك وتوصلك آخر الأخبار والتحديثات
          </p>
        </ScrollReveal>

        <ScrollReveal delay={0.2}>
          <form
            onSubmit={handleSubmit}
            className="flex flex-col sm:flex-row gap-md max-w-lg mx-auto"
          >
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="بريدك الإلكتروني"
              required
              dir="ltr"
              className="flex-1 px-lg py-md rounded-button bg-white/95 border border-white/20 text-text-primary text-body-lg focus:outline-none focus:ring-2 focus:ring-gold/40 transition-all placeholder:text-text-hint shadow-lg"
            />
            <button
              type="submit"
              className="gradient-golden text-primary-deep font-bold px-xl py-md rounded-button text-button-lg shadow-lg hover:shadow-xl hover:scale-105 active:scale-[0.97] transition-all duration-200"
            >
              اشترك
            </button>
          </form>

          {status === "success" && (
            <p className="text-gold mt-md text-body-lg animate-fade-up">
              تم التسجيل بنجاح!
            </p>
          )}
          {status === "error" && (
            <p className="text-red-300 mt-md text-body-lg animate-fade-up">
              حدث خطأ، حاول مرة أخرى
            </p>
          )}
        </ScrollReveal>
      </div>
    </section>
  );
}
