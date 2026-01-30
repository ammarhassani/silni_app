"use client";

import { useState } from "react";
import { motion, useScroll, useMotionValueEvent } from "framer-motion";
import Link from "next/link";
import Image from "next/image";
import Button from "@/components/ui/Button";
import MobileMenu from "./MobileMenu";

const links = [
  { href: "/", label: "الرئيسية" },
  { href: "/about", label: "عن صِلني" },
  { href: "/features", label: "المميزات" },
  { href: "/pricing", label: "الأسعار" },
  { href: "/faq", label: "الأسئلة الشائعة" },
  { href: "/blog", label: "المدونة" },
];

export default function Navbar() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const { scrollY } = useScroll();

  useMotionValueEvent(scrollY, "change", (latest) => {
    setIsScrolled(latest > 50);
  });

  return (
    <>
      <motion.header
        className={`fixed top-0 right-0 left-0 z-40 transition-all duration-500 ${
          isScrolled
            ? "bg-primary-deep/90 backdrop-blur-xl shadow-lg"
            : "bg-transparent"
        }`}
        initial={false}
        animate={{ y: 0 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
      >
        <nav className="max-w-7xl mx-auto px-md lg:px-xl flex items-center justify-between h-[72px]">
          <Link href="/" className="flex items-center gap-2">
            <Image
              src="/images/app_icon.png"
              alt="صِلني"
              width={40}
              height={40}
              className="rounded-xl"
            />
            <span className="text-white text-headline-sm font-bold">
              صِلني
            </span>
          </Link>

          <div className="hidden lg:flex items-center gap-xl">
            {links.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className="text-white/80 hover:text-white transition-colors text-label-lg"
              >
                {link.label}
              </Link>
            ))}
          </div>

          <div className="hidden lg:block">
            <Button href="https://apps.apple.com/app/id_PLACEHOLDER" size="sm">
              حمّل التطبيق
            </Button>
          </div>

          <button
            onClick={() => setMobileOpen(true)}
            className="lg:hidden text-white text-2xl"
          >
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M3 12h18M3 6h18M3 18h18" />
            </svg>
          </button>
        </nav>
      </motion.header>

      <MobileMenu isOpen={mobileOpen} onClose={() => setMobileOpen(false)} />
    </>
  );
}
