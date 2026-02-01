"use client";

import Image from "next/image";
import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence, useReducedMotion } from "framer-motion";

const carouselImages = [
  { src: "/images/screenshots/01-screenshot.png", alt: "الشاشة الرئيسية" },
  { src: "/images/screenshots/03-screenshot.png", alt: "المساعد الذكي واصل" },
  { src: "/images/screenshots/07-screenshot.png", alt: "تحليل العلاقات" },
  { src: "/images/screenshots/02-screenshot.png", alt: "التذكيرات الذكية" },
  { src: "/images/screenshots/09-screenshot.png", alt: "الإنجازات" },
];

const slideVariants = {
  enter: (direction: number) => ({
    x: direction > 0 ? 40 : -40,
    opacity: 0,
    scale: 0.97,
  }),
  center: {
    x: 0,
    opacity: 1,
    scale: 1,
  },
  exit: (direction: number) => ({
    x: direction > 0 ? -40 : 40,
    opacity: 0,
    scale: 0.97,
  }),
};

interface PhoneMockupProps {
  screenshot?: string;
  className?: string;
  autoPlayInterval?: number;
}

export default function PhoneMockup({
  screenshot,
  className = "",
  autoPlayInterval = 2800,
}: PhoneMockupProps) {
  const [[currentIndex, direction], setSlide] = useState([0, 1]);
  const [isPaused, setIsPaused] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const [isVisible, setIsVisible] = useState(true);
  const shouldReduceMotion = useReducedMotion();

  // Pause when off-screen
  useEffect(() => {
    if (screenshot) return;
    const el = containerRef.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => setIsVisible(entry.isIntersecting),
      { rootMargin: "100px" },
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [screenshot]);

  // Auto-advance
  useEffect(() => {
    if (screenshot || isPaused || !isVisible) return;

    const timer = setInterval(() => {
      setSlide(([prev]) => [(prev + 1) % carouselImages.length, 1]);
    }, autoPlayInterval);

    return () => clearInterval(timer);
  }, [screenshot, isPaused, isVisible, autoPlayInterval]);

  // Static image mode
  if (screenshot) {
    return (
      <div
        className={`relative animate-fade-up ${className}`}
        style={{ animationDelay: "0.4s" }}
      >
        <div className="relative w-[280px] h-[580px] mx-auto">
          <div className="absolute inset-0 bg-gray-900 rounded-[3rem] shadow-2xl border-[6px] border-gray-800">
            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[120px] h-[30px] bg-gray-900 rounded-b-2xl z-10" />
            <div className="absolute inset-[3px] rounded-[2.5rem] overflow-hidden bg-primary-deep flex items-center justify-center">
              <Image
                src={screenshot}
                alt="صِلني"
                width={260}
                height={560}
                className="object-cover"
              />
            </div>
          </div>
          <div className="absolute -inset-4 bg-gold/20 blur-3xl rounded-full -z-10" />
        </div>
      </div>
    );
  }

  const currentImage = carouselImages[currentIndex];

  return (
    <div
      ref={containerRef}
      className={`relative animate-fade-up ${className}`}
      style={{ animationDelay: "0.4s" }}
      onMouseEnter={() => setIsPaused(true)}
      onMouseLeave={() => setIsPaused(false)}
    >
      <div className="relative w-[280px] h-[580px] mx-auto">
        {/* Phone bezel */}
        <div className="absolute inset-0 bg-gray-900 rounded-[3rem] shadow-2xl border-[6px] border-gray-800">
          {/* Notch */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[120px] h-[30px] bg-gray-900 rounded-b-2xl z-10" />
          {/* Screen area */}
          <div className="absolute inset-[3px] rounded-[2.5rem] overflow-hidden bg-primary-deep">
            <AnimatePresence mode="wait" custom={direction}>
              <motion.div
                key={currentIndex}
                custom={direction}
                variants={slideVariants}
                initial="enter"
                animate="center"
                exit="exit"
                transition={
                  shouldReduceMotion
                    ? { duration: 0 }
                    : {
                        x: { type: "spring", stiffness: 500, damping: 35 },
                        opacity: { duration: 0.15 },
                        scale: { duration: 0.15 },
                      }
                }
                className="absolute inset-0"
              >
                <Image
                  src={currentImage.src}
                  alt={currentImage.alt}
                  width={520}
                  height={1120}
                  className="w-full h-full object-cover"
                  priority={currentIndex === 0}
                />
              </motion.div>
            </AnimatePresence>
          </div>
        </div>

        {/* Gold glow */}
        <div className="absolute -inset-4 bg-gold/20 blur-3xl rounded-full -z-10" />

        {/* Dot indicators */}
        <div className="absolute -bottom-8 left-1/2 -translate-x-1/2 flex gap-2">
          {carouselImages.map((slide, i) => (
            <button
              key={slide.src}
              onClick={() =>
                setSlide([i, i > currentIndex ? 1 : -1])
              }
              className={`h-2 rounded-full transition-all duration-300 ${
                i === currentIndex
                  ? "bg-gold w-6"
                  : "bg-gray-400 w-2 hover:bg-gray-300"
              }`}
              aria-label={slide.alt}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
