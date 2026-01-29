"use client";

import { motion } from "framer-motion";
import { type ReactNode } from "react";

interface ButtonProps {
  children: ReactNode;
  href?: string;
  variant?: "golden" | "outline" | "ghost";
  size?: "sm" | "md" | "lg";
  className?: string;
  onClick?: () => void;
}

const variants = {
  golden:
    "gradient-golden text-primary-deep font-bold shadow-lg hover:shadow-xl",
  outline:
    "border-2 border-white text-white hover:bg-white/10",
  ghost:
    "text-white hover:bg-white/10",
};

const sizes = {
  sm: "px-4 py-2 text-sm rounded-xl",
  md: "px-6 py-3 text-body-lg rounded-button",
  lg: "px-8 py-4 text-button-lg rounded-button h-[56px]",
};

export default function Button({
  children,
  href,
  variant = "golden",
  size = "md",
  className = "",
  onClick,
}: ButtonProps) {
  const classes = `inline-flex items-center justify-center transition-all duration-300 ${variants[variant]} ${sizes[size]} ${className}`;

  const MotionTag = href ? motion.a : motion.button;

  return (
    <MotionTag
      href={href}
      onClick={onClick}
      className={classes}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.97 }}
      {...(variant === "golden" && {
        animate: {
          boxShadow: [
            "0 0 20px rgba(255, 215, 0, 0.3)",
            "0 0 40px rgba(255, 215, 0, 0.5)",
            "0 0 20px rgba(255, 215, 0, 0.3)",
          ],
        },
        transition: {
          boxShadow: { duration: 2, repeat: Infinity, ease: "easeInOut" },
        },
      })}
    >
      {children}
    </MotionTag>
  );
}
