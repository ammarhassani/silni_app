"use client";

import { useRef, useEffect, useState, type ReactNode } from "react";

type Direction = "up" | "down" | "right" | "left";

interface ScrollRevealProps {
  children: ReactNode;
  direction?: Direction;
  delay?: number;
  duration?: number;
  className?: string;
  distance?: number;
}

const getTransform = (direction: Direction, distance: number): string => {
  switch (direction) {
    case "up": return `translateY(${distance}px)`;
    case "down": return `translateY(-${distance}px)`;
    case "right": return `translateX(-${distance}px)`;
    case "left": return `translateX(${distance}px)`;
  }
};

export default function ScrollReveal({
  children,
  direction = "up",
  delay = 0,
  duration = 0.7,
  className = "",
  distance = 60,
}: ScrollRevealProps) {
  const ref = useRef<HTMLDivElement>(null);
  const [isRevealed, setIsRevealed] = useState(false);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setHydrated(true);
    const el = ref.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsRevealed(true);
          observer.disconnect();
        }
      },
      { rootMargin: "-80px" }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  // Before hydration: no inline styles → content fully visible via CSS defaults
  // After hydration, not yet in view: hidden + transformed
  // After hydration, in view: animate to visible
  const style: React.CSSProperties = hydrated
    ? {
        opacity: isRevealed ? 1 : 0,
        transform: isRevealed ? "translate3d(0,0,0)" : getTransform(direction, distance),
        transition: `opacity ${duration}s cubic-bezier(0.25,0.46,0.45,0.94) ${delay}s, transform ${duration}s cubic-bezier(0.25,0.46,0.45,0.94) ${delay}s`,
      }
    : {};

  return (
    <div ref={ref} className={className} style={style}>
      {children}
    </div>
  );
}
