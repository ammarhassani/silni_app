"use client";

import { useRef, useEffect, useState, type ReactNode, Children, isValidElement } from "react";

interface StaggerChildrenProps {
  children: ReactNode;
  staggerDelay?: number;
  className?: string;
}

export default function StaggerChildren({
  children,
  staggerDelay = 0.15,
  className = "",
}: StaggerChildrenProps) {
  const ref = useRef<HTMLDivElement>(null);
  const [isVisible, setIsVisible] = useState(false);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setHydrated(true);
    const el = ref.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
          observer.disconnect();
        }
      },
      { rootMargin: "-60px" }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return (
    <div ref={ref} className={className}>
      {Children.map(children, (child, index) => {
        if (!isValidElement(child)) return child;

        const delay = 0.1 + index * staggerDelay;
        const style: React.CSSProperties = hydrated
          ? {
              opacity: isVisible ? 1 : 0,
              transform: isVisible ? "translateY(0)" : "translateY(40px)",
              transition: `opacity 0.6s cubic-bezier(0.25,0.46,0.45,0.94) ${delay}s, transform 0.6s cubic-bezier(0.25,0.46,0.45,0.94) ${delay}s`,
            }
          : {};

        return (
          <div style={style}>
            {child}
          </div>
        );
      })}
    </div>
  );
}
