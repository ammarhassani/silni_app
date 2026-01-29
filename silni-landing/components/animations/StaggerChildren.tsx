"use client";

import { motion } from "framer-motion";
import { type ReactNode } from "react";

interface StaggerChildrenProps {
  children: ReactNode;
  staggerDelay?: number;
  className?: string;
}

const container = (staggerDelay: number) => ({
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: staggerDelay, delayChildren: 0.1 },
  },
});

export const staggerItem = {
  hidden: { opacity: 0, y: 40 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.6, ease: [0.25, 0.46, 0.45, 0.94] as const },
  },
};

export default function StaggerChildren({
  children,
  staggerDelay = 0.15,
  className = "",
}: StaggerChildrenProps) {
  return (
    <motion.div
      variants={container(staggerDelay)}
      initial="hidden"
      whileInView="visible"
      viewport={{ once: true, margin: "-60px" }}
      className={className}
    >
      {children}
    </motion.div>
  );
}
