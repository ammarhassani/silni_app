"use client";

import { motion, type TargetAndTransition } from "framer-motion";
import { type ReactNode } from "react";

type Direction = "up" | "down" | "right" | "left";

interface ScrollRevealProps {
  children: ReactNode;
  direction?: Direction;
  delay?: number;
  duration?: number;
  className?: string;
  distance?: number;
}

const getInitial = (direction: Direction, distance: number): TargetAndTransition => {
  const map: Record<Direction, TargetAndTransition> = {
    up: { opacity: 0, y: distance },
    down: { opacity: 0, y: -distance },
    right: { opacity: 0, x: -distance },
    left: { opacity: 0, x: distance },
  };
  return map[direction];
};

export default function ScrollReveal({
  children,
  direction = "up",
  delay = 0,
  duration = 0.7,
  className = "",
  distance = 60,
}: ScrollRevealProps) {
  return (
    <motion.div
      initial={getInitial(direction, distance)}
      whileInView={{ opacity: 1, x: 0, y: 0 }}
      viewport={{ once: true, margin: "-80px" }}
      transition={{ duration, delay, ease: [0.25, 0.46, 0.45, 0.94] }}
      className={className}
    >
      {children}
    </motion.div>
  );
}
