"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import ScrollReveal from "@/components/animations/ScrollReveal";

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
    <section className="py-3xl bg-surface">
      <div className="max-w-2xl mx-auto px-md lg:px-xl text-center">
        <ScrollReveal>
          <h2 className="text-headline-lg text-primary-deep mb-md">
            كن أول من يعرف
          </h2>
          <p className="text-body-lg text-text-secondary mb-xl">
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
              className="flex-1 px-lg py-md rounded-button bg-white border border-text-hint/30 text-text-primary text-body-lg focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all placeholder:text-text-hint"
            />
            <motion.button
              type="submit"
              className="gradient-golden text-primary-deep font-bold px-xl py-md rounded-button text-button-lg"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.97 }}
            >
              اشترك
            </motion.button>
          </form>

          {status === "success" && (
            <motion.p
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-primary mt-md text-body-lg"
            >
              تم التسجيل بنجاح!
            </motion.p>
          )}
          {status === "error" && (
            <motion.p
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-red-500 mt-md text-body-lg"
            >
              حدث خطأ، حاول مرة أخرى
            </motion.p>
          )}
        </ScrollReveal>
      </div>
    </section>
  );
}
