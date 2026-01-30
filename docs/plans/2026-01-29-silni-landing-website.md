# Silni Landing Website Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a dramatic, fully-animated Arabic (RTL) marketing landing site for the Silni app with 6 pages: Home, About, Features, Pricing, FAQ, Blog.

**Architecture:** Standalone Next.js 14 App Router project (`silni-landing/`) with static export. All animations via Framer Motion + Lenis smooth scroll. MDX-powered blog. Newsletter signup placeholder API. Arabic-only, RTL-first.

**Tech Stack:** Next.js 14, TypeScript, Tailwind CSS (RTL), Framer Motion, Lenis, MDX, Google Fonts (Cairo, Poppins, Amiri Quran)

---

## Design Tokens Reference

### Colors (from app's theme)
```
Primary Green:    #2E7D32
Primary Light:    #60AD5E
Primary Dark:     #005005
Deep Green:       #1B5E20
Medium Green:     #388E3C
Light Green:      #81C784
Pale Green:       #C8E6C9

Gold:             #FFD700
Gold Dark:        #D4AF37
Gold Light:       #FFFF8D
Orange Accent:    #FF6F00

Background:       #F5F5F5
Card White:       #FFFFFF
Text Primary:     #212121
Text Secondary:   #757575
Text Hint:        #BDBDBD

Gradients:
  Primary:  #2E7D32 → #60AD5E → #81C784
  Golden:   #FFD700 → #FFA000 → #FF6F00
  Deep:     #1B5E20 → #2E7D32 → #388E3C
```

### Typography
```
Font Arabic:     Cairo (Google Fonts)
Font English:    Poppins (Google Fonts)
Font Hadith:     Amiri Quran (Google Fonts)

Hero:            48px, weight 900, letter-spacing -1
Dramatic:        32px, weight 800, letter-spacing 0.5
Display Large:   57px, bold
Headline Large:  32px, bold
Body Large:      16px, normal, line-height 1.5
Button Large:    16px, weight 700, letter-spacing 1.25
```

### Spacing (8px base)
```
xs: 4px   sm: 8px   md: 16px   lg: 24px   xl: 32px   xxl: 48px   xxxl: 64px
Card radius: 20px   Button radius: 16px   Button height: 56px
```

### Assets
```
App icon:  assets/images/app_icon.png
Logo SVG:  assets/images/silni_logo.svg
```

---

## Task 1: Project Scaffolding

**Files:**
- Create: `silni-landing/package.json`
- Create: `silni-landing/tsconfig.json`
- Create: `silni-landing/next.config.mjs`
- Create: `silni-landing/tailwind.config.ts`
- Create: `silni-landing/postcss.config.mjs`
- Create: `silni-landing/app/layout.tsx`
- Create: `silni-landing/app/page.tsx`
- Create: `silni-landing/app/globals.css`
- Create: `silni-landing/lib/fonts.ts`
- Create: `silni-landing/lib/theme.ts`

**Step 1: Initialize Next.js project**

```bash
cd /Users/engammar/Apps/silni_app
npx create-next-app@latest silni-landing --typescript --tailwind --eslint --app --src-dir=false --import-alias="@/*" --no-turbopack
```

**Step 2: Install dependencies**

```bash
cd /Users/engammar/Apps/silni_app/silni-landing
npm install framer-motion lenis @next/mdx @mdx-js/loader @mdx-js/react gray-matter reading-time
npm install -D @types/mdx
```

**Step 3: Configure `tailwind.config.ts` with Silni design tokens**

```ts
import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./content/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "#2E7D32",
          light: "#60AD5E",
          dark: "#005005",
          deep: "#1B5E20",
          medium: "#388E3C",
          pale: "#C8E6C9",
          soft: "#81C784",
        },
        gold: {
          DEFAULT: "#FFD700",
          dark: "#D4AF37",
          light: "#FFFF8D",
        },
        accent: {
          orange: "#FF6F00",
        },
        surface: {
          DEFAULT: "#F5F5F5",
          card: "#FFFFFF",
        },
        text: {
          primary: "#212121",
          secondary: "#757575",
          hint: "#BDBDBD",
        },
      },
      fontFamily: {
        cairo: ["var(--font-cairo)"],
        poppins: ["var(--font-poppins)"],
        amiri: ["var(--font-amiri)"],
      },
      fontSize: {
        hero: ["48px", { lineHeight: "1", fontWeight: "900", letterSpacing: "-1px" }],
        dramatic: ["32px", { lineHeight: "1.2", fontWeight: "800", letterSpacing: "0.5px" }],
        "display-lg": ["57px", { lineHeight: "1.12", fontWeight: "700" }],
        "headline-lg": ["32px", { lineHeight: "1.25", fontWeight: "700" }],
        "headline-md": ["28px", { lineHeight: "1.29", fontWeight: "700" }],
        "headline-sm": ["24px", { lineHeight: "1.33", fontWeight: "700" }],
        "body-lg": ["16px", { lineHeight: "1.5", fontWeight: "400" }],
        "body-md": ["14px", { lineHeight: "1.43", fontWeight: "400" }],
        "label-lg": ["14px", { lineHeight: "1.43", fontWeight: "600" }],
        "button-lg": ["16px", { lineHeight: "1", fontWeight: "700", letterSpacing: "1.25px" }],
      },
      spacing: {
        xs: "4px",
        sm: "8px",
        md: "16px",
        lg: "24px",
        xl: "32px",
        "2xl": "48px",
        "3xl": "64px",
      },
      borderRadius: {
        card: "20px",
        button: "16px",
      },
      keyframes: {
        "gradient-shift": {
          "0%, 100%": { backgroundPosition: "0% 50%" },
          "50%": { backgroundPosition: "100% 50%" },
        },
        "pulse-glow": {
          "0%, 100%": { boxShadow: "0 0 20px rgba(255, 215, 0, 0.3)" },
          "50%": { boxShadow: "0 0 40px rgba(255, 215, 0, 0.6)" },
        },
        shimmer: {
          "0%": { backgroundPosition: "-200% 0" },
          "100%": { backgroundPosition: "200% 0" },
        },
      },
      animation: {
        "gradient-shift": "gradient-shift 6s ease infinite",
        "pulse-glow": "pulse-glow 2s ease-in-out infinite",
        shimmer: "shimmer 3s ease-in-out infinite",
      },
    },
  },
  plugins: [],
};

export default config;
```

**Step 4: Create `lib/fonts.ts`**

```ts
import { Cairo, Poppins, Amiri } from "next/font/google";

export const cairo = Cairo({
  subsets: ["arabic", "latin"],
  variable: "--font-cairo",
  display: "swap",
});

export const poppins = Poppins({
  subsets: ["latin"],
  weight: ["400", "600", "700", "800", "900"],
  variable: "--font-poppins",
  display: "swap",
});

export const amiri = Amiri({
  subsets: ["arabic"],
  weight: ["400", "700"],
  variable: "--font-amiri",
  display: "swap",
});
```

**Step 5: Create `lib/theme.ts`**

```ts
export const theme = {
  colors: {
    primary: { DEFAULT: "#2E7D32", light: "#60AD5E", dark: "#005005", deep: "#1B5E20", medium: "#388E3C", soft: "#81C784", pale: "#C8E6C9" },
    gold: { DEFAULT: "#FFD700", dark: "#D4AF37", light: "#FFFF8D" },
    accent: { orange: "#FF6F00" },
  },
  gradients: {
    primary: "linear-gradient(135deg, #2E7D32, #60AD5E, #81C784)",
    golden: "linear-gradient(135deg, #FFD700, #FFA000, #FF6F00)",
    deep: "linear-gradient(135deg, #1B5E20, #2E7D32, #388E3C)",
    hero: "linear-gradient(180deg, #1B5E20 0%, #2E7D32 50%, #388E3C 100%)",
  },
} as const;
```

**Step 6: Create `app/globals.css`**

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  html {
    scroll-behavior: smooth;
  }

  body {
    @apply bg-surface text-text-primary font-cairo;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
  }

  ::selection {
    @apply bg-primary/20 text-primary-dark;
  }
}

@layer components {
  .gradient-primary {
    background: linear-gradient(135deg, #2E7D32, #60AD5E, #81C784);
  }

  .gradient-golden {
    background: linear-gradient(135deg, #FFD700, #FFA000, #FF6F00);
  }

  .gradient-deep {
    background: linear-gradient(180deg, #1B5E20 0%, #2E7D32 50%, #388E3C 100%);
  }

  .gradient-hero {
    background: linear-gradient(180deg, #1B5E20 0%, #2E7D32 40%, #388E3C 100%);
  }

  .text-gradient-golden {
    @apply bg-clip-text text-transparent;
    background-image: linear-gradient(135deg, #FFD700, #FFA000);
  }

  .glass {
    @apply backdrop-blur-xl bg-white/10 border border-white/20;
  }
}

@layer utilities {
  .text-balance {
    text-wrap: balance;
  }
}
```

**Step 7: Create root `app/layout.tsx`**

```tsx
import type { Metadata } from "next";
import { cairo, poppins, amiri } from "@/lib/fonts";
import "./globals.css";

export const metadata: Metadata = {
  title: "صِلني — حافظ على صلة الرحم",
  description:
    "صلة الرحم فريضة وصِلني يساعدك تحافظ عليها. تتبّع تواصلك مع أقاربك، تذكيرات ذكية، وإحصائيات تحفّزك.",
  keywords: ["صلة الرحم", "عائلة", "تواصل", "إسلام", "تطبيق", "صلني"],
  openGraph: {
    title: "صِلني — حافظ على صلة الرحم",
    description: "صلة الرحم فريضة وصِلني يساعدك تحافظ عليها.",
    locale: "ar_SA",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="ar"
      dir="rtl"
      className={`${cairo.variable} ${poppins.variable} ${amiri.variable}`}
    >
      <body className="font-cairo antialiased">{children}</body>
    </html>
  );
}
```

**Step 8: Create placeholder `app/page.tsx`**

```tsx
export default function Home() {
  return (
    <main className="min-h-screen flex items-center justify-center">
      <h1 className="text-hero font-cairo text-primary-deep">صِلني</h1>
    </main>
  );
}
```

**Step 9: Configure `next.config.mjs`**

```mjs
import createMDX from "@next/mdx";

/** @type {import('next').NextConfig} */
const nextConfig = {
  pageExtensions: ["js", "jsx", "md", "mdx", "ts", "tsx"],
  output: "export",
  images: {
    unoptimized: true,
  },
};

const withMDX = createMDX({});

export default withMDX(nextConfig);
```

**Step 10: Run dev server to verify setup**

```bash
cd /Users/engammar/Apps/silni_app/silni-landing
npm run dev
```

Expected: Dev server starts, page shows "صِلني" in deep green hero font.

**Step 11: Copy logo assets**

```bash
mkdir -p /Users/engammar/Apps/silni_app/silni-landing/public/images
cp /Users/engammar/Apps/silni_app/assets/images/app_icon.png /Users/engammar/Apps/silni_app/silni-landing/public/images/
cp /Users/engammar/Apps/silni_app/assets/images/silni_logo.svg /Users/engammar/Apps/silni_app/silni-landing/public/images/
```

**Step 12: Commit**

```bash
cd /Users/engammar/Apps/silni_app
git add silni-landing/
git commit -m "feat(landing): scaffold Next.js project with Silni design tokens"
```

---

## Task 2: Smooth Scroll & Animation Infrastructure

**Files:**
- Create: `silni-landing/components/providers/SmoothScrollProvider.tsx`
- Create: `silni-landing/components/animations/TextReveal.tsx`
- Create: `silni-landing/components/animations/ScrollReveal.tsx`
- Create: `silni-landing/components/animations/ParallaxLayer.tsx`
- Create: `silni-landing/components/animations/CountUp.tsx`
- Create: `silni-landing/components/animations/StaggerChildren.tsx`
- Create: `silni-landing/components/animations/IslamicPattern.tsx`
- Modify: `silni-landing/app/layout.tsx`

**Step 1: Create `SmoothScrollProvider.tsx`**

```tsx
"use client";

import { useEffect } from "react";
import Lenis from "lenis";

export default function SmoothScrollProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  useEffect(() => {
    const lenis = new Lenis({
      duration: 1.2,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      smoothWheel: true,
    });

    function raf(time: number) {
      lenis.raf(time);
      requestAnimationFrame(raf);
    }

    requestAnimationFrame(raf);

    return () => lenis.destroy();
  }, []);

  return <>{children}</>;
}
```

**Step 2: Create `TextReveal.tsx`**

```tsx
"use client";

import { motion } from "framer-motion";

interface TextRevealProps {
  text: string;
  className?: string;
  delay?: number;
  staggerDelay?: number;
  as?: "h1" | "h2" | "h3" | "p" | "span";
}

export default function TextReveal({
  text,
  className = "",
  delay = 0,
  staggerDelay = 0.08,
  as: Tag = "h1",
}: TextRevealProps) {
  const words = text.split(" ");

  return (
    <Tag className={className}>
      {words.map((word, i) => (
        <span key={i} className="inline-block overflow-hidden">
          <motion.span
            className="inline-block"
            initial={{ y: "100%", opacity: 0 }}
            whileInView={{ y: 0, opacity: 1 }}
            viewport={{ once: true }}
            transition={{
              duration: 0.6,
              delay: delay + i * staggerDelay,
              ease: [0.25, 0.46, 0.45, 0.94],
            }}
          >
            {word}
          </motion.span>
          {i < words.length - 1 && "\u00A0"}
        </span>
      ))}
    </Tag>
  );
}
```

**Step 3: Create `ScrollReveal.tsx`**

```tsx
"use client";

import { motion, type Variant } from "framer-motion";
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

const getInitial = (direction: Direction, distance: number): Variant => {
  const map: Record<Direction, Variant> = {
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
```

**Step 4: Create `ParallaxLayer.tsx`**

```tsx
"use client";

import { motion, useScroll, useTransform } from "framer-motion";
import { useRef, type ReactNode } from "react";

interface ParallaxLayerProps {
  children: ReactNode;
  speed?: number;
  className?: string;
}

export default function ParallaxLayer({
  children,
  speed = 0.5,
  className = "",
}: ParallaxLayerProps) {
  const ref = useRef(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"],
  });

  const y = useTransform(scrollYProgress, [0, 1], [0, speed * -200]);

  return (
    <motion.div ref={ref} style={{ y }} className={className}>
      {children}
    </motion.div>
  );
}
```

**Step 5: Create `CountUp.tsx`**

```tsx
"use client";

import { useEffect, useRef, useState } from "react";
import { useInView, motion } from "framer-motion";

interface CountUpProps {
  end: number;
  duration?: number;
  suffix?: string;
  prefix?: string;
  className?: string;
}

export default function CountUp({
  end,
  duration = 2,
  suffix = "",
  prefix = "",
  className = "",
}: CountUpProps) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true });
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (!isInView) return;

    let startTime: number;
    const step = (timestamp: number) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / (duration * 1000), 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      setCount(Math.floor(eased * end));
      if (progress < 1) requestAnimationFrame(step);
    };

    requestAnimationFrame(step);
  }, [isInView, end, duration]);

  return (
    <motion.span
      ref={ref}
      className={`font-poppins ${className}`}
      initial={{ opacity: 0, scale: 0.5 }}
      whileInView={{ opacity: 1, scale: 1 }}
      viewport={{ once: true }}
      transition={{ duration: 0.5 }}
    >
      {prefix}
      {count.toLocaleString("ar-SA")}
      {suffix}
    </motion.span>
  );
}
```

**Step 6: Create `StaggerChildren.tsx`**

```tsx
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
    transition: { duration: 0.6, ease: [0.25, 0.46, 0.45, 0.94] },
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
```

**Step 7: Create `IslamicPattern.tsx`**

```tsx
"use client";

import { motion } from "framer-motion";

interface IslamicPatternProps {
  className?: string;
  color?: string;
  opacity?: number;
}

export default function IslamicPattern({
  className = "",
  color = "#81C784",
  opacity = 0.08,
}: IslamicPatternProps) {
  return (
    <div className={`absolute inset-0 overflow-hidden pointer-events-none ${className}`}>
      <svg
        className="w-full h-full"
        viewBox="0 0 800 800"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        preserveAspectRatio="xMidYMid slice"
      >
        {/* 8-pointed star pattern - traditional Islamic geometry */}
        {Array.from({ length: 6 }).map((_, row) =>
          Array.from({ length: 6 }).map((_, col) => {
            const cx = col * 160 + 80;
            const cy = row * 160 + 80;
            return (
              <motion.g
                key={`${row}-${col}`}
                initial={{ opacity: 0, scale: 0, rotate: -45 }}
                whileInView={{ opacity: 1, scale: 1, rotate: 0 }}
                viewport={{ once: true }}
                transition={{
                  duration: 0.8,
                  delay: (row + col) * 0.1,
                  ease: "easeOut",
                }}
              >
                {/* 8-pointed star */}
                <motion.path
                  d={`M ${cx} ${cy - 40} L ${cx + 12} ${cy - 12} L ${cx + 40} ${cy} L ${cx + 12} ${cy + 12} L ${cx} ${cy + 40} L ${cx - 12} ${cy + 12} L ${cx - 40} ${cy} L ${cx - 12} ${cy - 12} Z`}
                  stroke={color}
                  strokeWidth="1"
                  fill="none"
                  opacity={opacity}
                  initial={{ pathLength: 0 }}
                  whileInView={{ pathLength: 1 }}
                  viewport={{ once: true }}
                  transition={{
                    duration: 1.5,
                    delay: (row + col) * 0.1,
                    ease: "easeInOut",
                  }}
                />
                {/* Inner diamond */}
                <motion.path
                  d={`M ${cx} ${cy - 20} L ${cx + 20} ${cy} L ${cx} ${cy + 20} L ${cx - 20} ${cy} Z`}
                  stroke={color}
                  strokeWidth="0.5"
                  fill="none"
                  opacity={opacity * 0.7}
                  initial={{ pathLength: 0 }}
                  whileInView={{ pathLength: 1 }}
                  viewport={{ once: true }}
                  transition={{
                    duration: 1.2,
                    delay: (row + col) * 0.1 + 0.3,
                    ease: "easeInOut",
                  }}
                />
              </motion.g>
            );
          })
        )}
      </svg>
    </div>
  );
}
```

**Step 8: Wrap layout with SmoothScrollProvider**

Modify `app/layout.tsx` — wrap `{children}` with:

```tsx
import SmoothScrollProvider from "@/components/providers/SmoothScrollProvider";

// In the body:
<body className="font-cairo antialiased">
  <SmoothScrollProvider>{children}</SmoothScrollProvider>
</body>
```

**Step 9: Verify dev server still works**

```bash
cd /Users/engammar/Apps/silni_app/silni-landing
npm run dev
```

Expected: No errors. Page renders.

**Step 10: Commit**

```bash
cd /Users/engammar/Apps/silni_app
git add silni-landing/
git commit -m "feat(landing): add animation infrastructure — Framer Motion, Lenis, Islamic pattern"
```

---

## Task 3: Shared Layout Components (Navbar + Footer)

**Files:**
- Create: `silni-landing/components/layout/Navbar.tsx`
- Create: `silni-landing/components/layout/Footer.tsx`
- Create: `silni-landing/components/layout/MobileMenu.tsx`
- Create: `silni-landing/components/ui/Button.tsx`
- Create: `silni-landing/components/ui/AppStoreBadge.tsx`
- Modify: `silni-landing/app/layout.tsx`

**Step 1: Create `Button.tsx`**

```tsx
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
```

**Step 2: Create `AppStoreBadge.tsx`**

```tsx
import Image from "next/image";

interface AppStoreBadgeProps {
  className?: string;
}

export default function AppStoreBadge({ className = "" }: AppStoreBadgeProps) {
  return (
    <a
      href="https://apps.apple.com/app/id_PLACEHOLDER"
      target="_blank"
      rel="noopener noreferrer"
      className={`inline-block transition-transform hover:scale-105 ${className}`}
    >
      {/* Arabic App Store badge - use SVG */}
      <div className="bg-black text-white rounded-xl px-5 py-3 flex items-center gap-3 border border-white/20">
        <svg className="w-8 h-8" viewBox="0 0 24 24" fill="currentColor">
          <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
        </svg>
        <div className="text-right">
          <div className="text-[10px] opacity-80">حمّل من</div>
          <div className="text-lg font-bold leading-tight">App Store</div>
        </div>
      </div>
    </a>
  );
}
```

**Step 3: Create `MobileMenu.tsx`**

```tsx
"use client";

import { motion, AnimatePresence } from "framer-motion";
import Link from "next/link";
import Button from "@/components/ui/Button";

interface MobileMenuProps {
  isOpen: boolean;
  onClose: () => void;
}

const links = [
  { href: "/", label: "الرئيسية" },
  { href: "/about", label: "عن صِلني" },
  { href: "/features", label: "المميزات" },
  { href: "/pricing", label: "الأسعار" },
  { href: "/faq", label: "الأسئلة الشائعة" },
  { href: "/blog", label: "المدونة" },
];

export default function MobileMenu({ isOpen, onClose }: MobileMenuProps) {
  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 lg:hidden"
        >
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={onClose}
          />

          {/* Menu panel */}
          <motion.nav
            initial={{ x: "100%" }}
            animate={{ x: 0 }}
            exit={{ x: "100%" }}
            transition={{ type: "spring", damping: 25, stiffness: 200 }}
            className="absolute top-0 right-0 h-full w-80 gradient-hero p-8 flex flex-col"
          >
            <button
              onClick={onClose}
              className="self-start text-white/80 hover:text-white text-2xl mb-8"
            >
              ✕
            </button>

            <div className="flex flex-col gap-4">
              {links.map((link, i) => (
                <motion.div
                  key={link.href}
                  initial={{ opacity: 0, x: 40 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.08 }}
                >
                  <Link
                    href={link.href}
                    onClick={onClose}
                    className="text-white text-headline-sm block py-2 hover:text-gold transition-colors"
                  >
                    {link.label}
                  </Link>
                </motion.div>
              ))}
            </div>

            <div className="mt-auto">
              <Button href="https://apps.apple.com/app/id_PLACEHOLDER" size="lg" className="w-full">
                حمّل التطبيق
              </Button>
            </div>
          </motion.nav>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

**Step 4: Create `Navbar.tsx`**

```tsx
"use client";

import { useState, useEffect } from "react";
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
        initial={{ y: -100 }}
        animate={{ y: 0 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
      >
        <nav className="max-w-7xl mx-auto px-md lg:px-xl flex items-center justify-between h-[72px]">
          {/* Logo */}
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

          {/* Desktop links */}
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

          {/* CTA */}
          <div className="hidden lg:block">
            <Button href="https://apps.apple.com/app/id_PLACEHOLDER" size="sm">
              حمّل التطبيق
            </Button>
          </div>

          {/* Mobile hamburger */}
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
```

**Step 5: Create `Footer.tsx`**

```tsx
import Link from "next/link";
import Image from "next/image";
import AppStoreBadge from "@/components/ui/AppStoreBadge";

const footerLinks = [
  {
    title: "صِلني",
    links: [
      { href: "/about", label: "عن صِلني" },
      { href: "/features", label: "المميزات" },
      { href: "/pricing", label: "الأسعار" },
    ],
  },
  {
    title: "الدعم",
    links: [
      { href: "/faq", label: "الأسئلة الشائعة" },
      { href: "mailto:support@silni.app", label: "تواصل معنا" },
    ],
  },
  {
    title: "قانوني",
    links: [
      { href: "/privacy", label: "سياسة الخصوصية" },
      { href: "/terms", label: "شروط الاستخدام" },
    ],
  },
];

export default function Footer() {
  return (
    <footer className="gradient-deep text-white">
      <div className="max-w-7xl mx-auto px-md lg:px-xl py-3xl">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-2xl">
          {/* Brand column */}
          <div className="lg:col-span-1">
            <div className="flex items-center gap-2 mb-lg">
              <Image
                src="/images/app_icon.png"
                alt="صِلني"
                width={48}
                height={48}
                className="rounded-xl"
              />
              <span className="text-headline-md font-bold">صِلني</span>
            </div>
            <p className="text-white/70 text-body-lg mb-lg leading-relaxed">
              حافظ على صلة الرحم مع تطبيق صِلني
            </p>
            <AppStoreBadge />
          </div>

          {/* Link columns */}
          {footerLinks.map((group) => (
            <div key={group.title}>
              <h3 className="font-bold text-lg mb-md">{group.title}</h3>
              <ul className="space-y-sm">
                {group.links.map((link) => (
                  <li key={link.href}>
                    <Link
                      href={link.href}
                      className="text-white/60 hover:text-white transition-colors text-body-lg"
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Bottom bar */}
        <div className="border-t border-white/10 mt-2xl pt-lg text-center text-white/40 text-body-md">
          <p>© {new Date().getFullYear()} صِلني. جميع الحقوق محفوظة.</p>
        </div>
      </div>
    </footer>
  );
}
```

**Step 6: Update `app/layout.tsx` to include Navbar and Footer**

```tsx
import type { Metadata } from "next";
import { cairo, poppins, amiri } from "@/lib/fonts";
import SmoothScrollProvider from "@/components/providers/SmoothScrollProvider";
import Navbar from "@/components/layout/Navbar";
import Footer from "@/components/layout/Footer";
import "./globals.css";

export const metadata: Metadata = {
  title: "صِلني — حافظ على صلة الرحم",
  description:
    "صلة الرحم فريضة وصِلني يساعدك تحافظ عليها. تتبّع تواصلك مع أقاربك، تذكيرات ذكية، وإحصائيات تحفّزك.",
  keywords: ["صلة الرحم", "عائلة", "تواصل", "إسلام", "تطبيق", "صلني"],
  openGraph: {
    title: "صِلني — حافظ على صلة الرحم",
    description: "صلة الرحم فريضة وصِلني يساعدك تحافظ عليها.",
    locale: "ar_SA",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="ar"
      dir="rtl"
      className={`${cairo.variable} ${poppins.variable} ${amiri.variable}`}
    >
      <body className="font-cairo antialiased">
        <SmoothScrollProvider>
          <Navbar />
          <main>{children}</main>
          <Footer />
        </SmoothScrollProvider>
      </body>
    </html>
  );
}
```

**Step 7: Verify all components render**

```bash
cd /Users/engammar/Apps/silni_app/silni-landing
npm run dev
```

Expected: Page renders with sticky navbar (transparent → blur on scroll), content, and footer.

**Step 8: Commit**

```bash
cd /Users/engammar/Apps/silni_app
git add silni-landing/
git commit -m "feat(landing): add Navbar, Footer, Button, AppStoreBadge with animations"
```

---

## Task 4: Home Page — Hero Section

**Files:**
- Create: `silni-landing/components/sections/Hero.tsx`
- Create: `silni-landing/components/ui/PhoneMockup.tsx`
- Modify: `silni-landing/app/page.tsx`

**Step 1: Create `PhoneMockup.tsx`**

```tsx
"use client";

import { motion } from "framer-motion";
import Image from "next/image";

interface PhoneMockupProps {
  screenshot?: string;
  className?: string;
}

export default function PhoneMockup({
  screenshot = "/images/app_icon.png",
  className = "",
}: PhoneMockupProps) {
  return (
    <motion.div
      className={`relative ${className}`}
      initial={{ y: 80, opacity: 0 }}
      whileInView={{ y: 0, opacity: 1 }}
      viewport={{ once: true }}
      transition={{ duration: 0.8, delay: 0.4, ease: [0.25, 0.46, 0.45, 0.94] }}
    >
      {/* Phone frame */}
      <div className="relative w-[280px] h-[580px] mx-auto">
        {/* Outer frame */}
        <div className="absolute inset-0 bg-gray-900 rounded-[3rem] shadow-2xl border-[6px] border-gray-800">
          {/* Notch */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[120px] h-[30px] bg-gray-900 rounded-b-2xl z-10" />

          {/* Screen */}
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

        {/* Glow effect */}
        <div className="absolute -inset-4 bg-gold/20 blur-3xl rounded-full -z-10" />
      </div>
    </motion.div>
  );
}
```

**Step 2: Create `Hero.tsx`**

```tsx
"use client";

import TextReveal from "@/components/animations/TextReveal";
import ScrollReveal from "@/components/animations/ScrollReveal";
import ParallaxLayer from "@/components/animations/ParallaxLayer";
import IslamicPattern from "@/components/animations/IslamicPattern";
import PhoneMockup from "@/components/ui/PhoneMockup";
import Button from "@/components/ui/Button";
import AppStoreBadge from "@/components/ui/AppStoreBadge";

export default function Hero() {
  return (
    <section className="relative min-h-screen gradient-hero overflow-hidden flex items-center">
      <IslamicPattern color="#81C784" opacity={0.06} />

      <div className="max-w-7xl mx-auto px-md lg:px-xl py-3xl relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-3xl items-center">
          {/* Text content */}
          <div className="text-white text-right">
            <TextReveal
              text="صلة الرحم فريضة"
              as="h1"
              className="text-hero mb-md"
            />
            <TextReveal
              text="وصِلني يساعدك تحافظ عليها"
              as="h2"
              className="text-dramatic text-gold mb-xl"
              delay={0.5}
            />

            <ScrollReveal delay={0.8}>
              <p className="text-body-lg text-white/80 leading-relaxed mb-xl max-w-lg">
                في زحمة الحياة، ننسى نسأل عن أقاربنا. صِلني يذكّرك، يتابع
                تواصلك، ويحفّزك تحافظ على أجمل عبادة — صلة الرحم.
              </p>
            </ScrollReveal>

            <ScrollReveal delay={1}>
              <div className="flex flex-wrap items-center gap-md">
                <Button
                  href="https://apps.apple.com/app/id_PLACEHOLDER"
                  size="lg"
                >
                  حمّل التطبيق مجاناً
                </Button>
                <AppStoreBadge />
              </div>
            </ScrollReveal>
          </div>

          {/* Phone mockup */}
          <ParallaxLayer speed={0.3} className="hidden lg:block">
            <PhoneMockup />
          </ParallaxLayer>
        </div>
      </div>

      {/* Bottom gradient fade to surface color */}
      <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-surface to-transparent" />
    </section>
  );
}
```

**Step 3: Update `app/page.tsx`**

```tsx
import Hero from "@/components/sections/Hero";

export default function Home() {
  return (
    <>
      <Hero />
    </>
  );
}
```

**Step 4: Verify hero renders**

```bash
cd /Users/engammar/Apps/silni_app/silni-landing
npm run dev
```

Expected: Full-viewport hero with animated text reveal, Islamic pattern drawing in background, phone mockup floating up, golden pulsing CTA.

**Step 5: Commit**

```bash
cd /Users/engammar/Apps/silni_app
git add silni-landing/
git commit -m "feat(landing): add Hero section with text reveal, parallax phone, Islamic pattern"
```

---

## Task 5: Home Page — Problem, Solution, Social Proof, Newsletter Sections

**Files:**
- Create: `silni-landing/components/sections/ProblemCards.tsx`
- Create: `silni-landing/components/sections/StickyFeatures.tsx`
- Create: `silni-landing/components/sections/SocialProof.tsx`
- Create: `silni-landing/components/sections/NewsletterSignup.tsx`
- Create: `silni-landing/app/api/newsletter/route.ts`
- Modify: `silni-landing/app/page.tsx`

**Step 1: Create `ProblemCards.tsx`**

```tsx
"use client";

import { motion } from "framer-motion";
import StaggerChildren, { staggerItem } from "@/components/animations/StaggerChildren";
import ScrollReveal from "@/components/animations/ScrollReveal";

const problems = [
  {
    icon: "🕐",
    title: "ننسى نتواصل",
    description: "الحياة تشغلنا وننسى نسأل عن أقرب الناس لنا",
  },
  {
    icon: "📅",
    title: "ما نعرف متى آخر مرة",
    description: "مرّت أشهر من آخر اتصال ولا ندري",
  },
  {
    icon: "💔",
    title: "نفقد الأجر",
    description: "صلة الرحم عبادة عظيمة وأجرها كبير عند الله",
  },
];

export default function ProblemCards() {
  return (
    <section className="py-3xl bg-surface">
      <div className="max-w-7xl mx-auto px-md lg:px-xl">
        <ScrollReveal>
          <h2 className="text-headline-lg text-primary-deep text-center mb-2xl">
            المشكلة اللي كلنا نعيشها
          </h2>
        </ScrollReveal>

        <StaggerChildren className="grid grid-cols-1 md:grid-cols-3 gap-lg">
          {problems.map((problem) => (
            <motion.div
              key={problem.title}
              variants={staggerItem}
              className="bg-white rounded-card p-xl shadow-sm hover:shadow-lg transition-shadow duration-300"
            >
              <span className="text-5xl block mb-md">{problem.icon}</span>
              <h3 className="text-headline-sm text-primary-deep mb-sm">
                {problem.title}
              </h3>
              <p className="text-body-lg text-text-secondary leading-relaxed">
                {problem.description}
              </p>
            </motion.div>
          ))}
        </StaggerChildren>
      </div>
    </section>
  );
}
```

**Step 2: Create `StickyFeatures.tsx`**

```tsx
"use client";

import { useRef } from "react";
import { motion, useScroll, useTransform } from "framer-motion";
import ScrollReveal from "@/components/animations/ScrollReveal";
import PhoneMockup from "@/components/ui/PhoneMockup";

const features = [
  {
    title: "تتبّع تواصلك",
    description: "سجّل كل اتصال، زيارة، رسالة، أو هدية. ما يضيع شي.",
    color: "text-primary",
  },
  {
    title: "تذكيرات ذكية",
    description: "يذكّرك تتواصل مع أقاربك بناءً على أولوياتك — يومي، أسبوعي، أو شهري.",
    color: "text-accent-orange",
  },
  {
    title: "سلاسل التواصل",
    description: "حافظ على سلسلة تواصلك مع كل قريب. كل يوم يحسب.",
    color: "text-gold-dark",
  },
  {
    title: "مساعد ذكي",
    description: "الذكاء الاصطناعي يساعدك تكتب رسائل ويقترح أفكار للتواصل.",
    color: "text-primary-dark",
  },
];

export default function StickyFeatures() {
  const containerRef = useRef(null);
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"],
  });

  return (
    <section ref={containerRef} className="relative bg-white">
      <div className="max-w-7xl mx-auto px-md lg:px-xl">
        <ScrollReveal className="text-center pt-3xl pb-2xl">
          <h2 className="text-headline-lg text-primary-deep mb-md">
            كيف صِلني يساعدك؟
          </h2>
          <p className="text-body-lg text-text-secondary max-w-2xl mx-auto">
            أدوات بسيطة لعبادة عظيمة
          </p>
        </ScrollReveal>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-3xl pb-3xl">
          {/* Sticky phone */}
          <div className="hidden lg:flex items-start justify-center">
            <div className="sticky top-32">
              <PhoneMockup />
            </div>
          </div>

          {/* Scrolling features */}
          <div className="space-y-2xl">
            {features.map((feature, i) => (
              <ScrollReveal
                key={feature.title}
                direction="right"
                delay={i * 0.1}
              >
                <div className="bg-surface rounded-card p-xl">
                  <h3 className={`text-headline-sm mb-sm ${feature.color}`}>
                    {feature.title}
                  </h3>
                  <p className="text-body-lg text-text-secondary leading-relaxed">
                    {feature.description}
                  </p>
                </div>
              </ScrollReveal>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
```

**Step 3: Create `SocialProof.tsx`**

```tsx
"use client";

import CountUp from "@/components/animations/CountUp";
import StaggerChildren, { staggerItem } from "@/components/animations/StaggerChildren";
import { motion } from "framer-motion";

const stats = [
  { value: 4.8, suffix: " ⭐", label: "تقييم المستخدمين" },
  { value: 1000, suffix: "+", label: "تحميل" },
  { value: 50000, suffix: "+", label: "تواصل تم تسجيله" },
];

export default function SocialProof() {
  return (
    <section className="py-3xl gradient-deep text-white">
      <div className="max-w-7xl mx-auto px-md lg:px-xl">
        <StaggerChildren className="grid grid-cols-1 md:grid-cols-3 gap-xl text-center">
          {stats.map((stat) => (
            <motion.div key={stat.label} variants={staggerItem}>
              <div className="text-numberLarge font-poppins font-black mb-sm">
                <CountUp
                  end={stat.value}
                  suffix={stat.suffix}
                  className="text-[64px] font-black"
                />
              </div>
              <p className="text-white/70 text-body-lg">{stat.label}</p>
            </motion.div>
          ))}
        </StaggerChildren>
      </div>
    </section>
  );
}
```

**Step 4: Create `NewsletterSignup.tsx`**

```tsx
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
```

**Step 5: Create placeholder `app/api/newsletter/route.ts`**

```ts
import { NextResponse } from "next/server";

export async function POST(request: Request) {
  const { email } = await request.json();

  // TODO: Wire up to email service (Mailchimp, Resend, Supabase, etc.)
  console.log("Newsletter signup:", email);

  return NextResponse.json({ success: true });
}
```

**Step 6: Update `app/page.tsx` with all home sections**

```tsx
import Hero from "@/components/sections/Hero";
import ProblemCards from "@/components/sections/ProblemCards";
import StickyFeatures from "@/components/sections/StickyFeatures";
import SocialProof from "@/components/sections/SocialProof";
import NewsletterSignup from "@/components/sections/NewsletterSignup";

export default function Home() {
  return (
    <>
      <Hero />
      <ProblemCards />
      <StickyFeatures />
      <SocialProof />
      <NewsletterSignup />
    </>
  );
}
```

**Step 7: Verify all sections render and animate on scroll**

```bash
cd /Users/engammar/Apps/silni_app/silni-landing
npm run dev
```

Expected: Full home page with scroll-driven animations on each section.

**Step 8: Commit**

```bash
cd /Users/engammar/Apps/silni_app
git add silni-landing/
git commit -m "feat(landing): complete Home page — Problem, Features, Social Proof, Newsletter"
```

---

## Task 6: About Page

**Files:**
- Create: `silni-landing/app/about/page.tsx`

**Step 1: Create `app/about/page.tsx`**

```tsx
import type { Metadata } from "next";
import ScrollReveal from "@/components/animations/ScrollReveal";
import TextReveal from "@/components/animations/TextReveal";
import IslamicPattern from "@/components/animations/IslamicPattern";

export const metadata: Metadata = {
  title: "عن صِلني — قصتنا ورؤيتنا",
  description: "صِلني تطبيق مبني على قيمة إسلامية عظيمة — صلة الرحم.",
};

export default function AboutPage() {
  return (
    <>
      {/* Hero */}
      <section className="relative gradient-hero text-white pt-[120px] pb-3xl overflow-hidden">
        <IslamicPattern color="#81C784" opacity={0.05} />
        <div className="max-w-4xl mx-auto px-md lg:px-xl relative z-10 text-center">
          <TextReveal text="عن صِلني" as="h1" className="text-hero mb-lg" />
          <ScrollReveal delay={0.4}>
            <p className="text-body-lg text-white/80 leading-relaxed max-w-2xl mx-auto">
              تطبيق مبني على فريضة إسلامية عظيمة
            </p>
          </ScrollReveal>
        </div>
      </section>

      {/* Islamic obligation */}
      <section className="py-3xl bg-surface">
        <div className="max-w-3xl mx-auto px-md lg:px-xl">
          <ScrollReveal>
            <blockquote className="text-center mb-2xl">
              <p className="font-amiri text-[24px] leading-[2] text-primary-deep mb-md">
                «مَن أَحَبَّ أن يُبسَط له في رِزقه، ويُنسأ له في أَثَره، فليَصِل رَحِمَه»
              </p>
              <cite className="text-text-secondary text-body-md italic block">
                — متفق عليه
              </cite>
            </blockquote>
          </ScrollReveal>

          <ScrollReveal delay={0.2}>
            <div className="space-y-lg text-body-lg text-text-secondary leading-relaxed">
              <p>
                صلة الرحم من أعظم العبادات في الإسلام. النبي ﷺ وصّى بها وبيّن
                أن من وصلها وصله الله، ومن قطعها قطعه الله. لكن في عصرنا، مع
                زحمة الحياة والمشاغل اليومية، صار كثير منّا ينسى يتواصل مع
                أقاربه.
              </p>
              <p>
                صِلني وُلد من هذي المشكلة. تطبيق بسيط يساعدك تحافظ على صلة
                رحمك بطريقة عملية — يتابع تواصلك، يذكّرك، ويحفّزك تستمر.
              </p>
            </div>
          </ScrollReveal>
        </div>
      </section>

      {/* Vision */}
      <section className="py-3xl bg-white">
        <div className="max-w-3xl mx-auto px-md lg:px-xl">
          <ScrollReveal>
            <h2 className="text-headline-lg text-primary-deep mb-xl text-center">
              رؤيتنا
            </h2>
          </ScrollReveal>

          <div className="space-y-xl">
            {[
              {
                title: "التقنية في خدمة الدين",
                text: "نؤمن إن التقنية لازم تخدم قيمنا الإسلامية، مو بس ترفيه.",
              },
              {
                title: "البساطة أولاً",
                text: "تطبيق سهل وواضح. ما نبي نعقّد عبادة بسيطة وجميلة.",
              },
              {
                title: "خصوصيتك مقدسة",
                text: "بياناتك لك. ما نبيع معلوماتك ولا نشاركها مع أحد.",
              },
            ].map((item, i) => (
              <ScrollReveal key={item.title} delay={i * 0.15}>
                <div className="bg-surface rounded-card p-xl">
                  <h3 className="text-headline-sm text-primary-deep mb-sm">
                    {item.title}
                  </h3>
                  <p className="text-body-lg text-text-secondary leading-relaxed">
                    {item.text}
                  </p>
                </div>
              </ScrollReveal>
            ))}
          </div>
        </div>
      </section>
    </>
  );
}
```

**Step 2: Verify**

```bash
cd /Users/engammar/Apps/silni_app/silni-landing
npm run dev
```

Navigate to `/about`. Expected: Page renders with animated sections, hadith in Amiri Quran font.

**Step 3: Commit**

```bash
cd /Users/engammar/Apps/silni_app
git add silni-landing/
git commit -m "feat(landing): add About page — Islamic obligation framing and vision"
```

---

## Task 7: Features Page

**Files:**
- Create: `silni-landing/app/features/page.tsx`

**Step 1: Create `app/features/page.tsx`**

```tsx
import type { Metadata } from "next";
import ScrollReveal from "@/components/animations/ScrollReveal";
import TextReveal from "@/components/animations/TextReveal";
import StaggerChildren, { staggerItem } from "@/components/animations/StaggerChildren";
import IslamicPattern from "@/components/animations/IslamicPattern";
import Button from "@/components/ui/Button";
import { motion } from "framer-motion";

export const metadata: Metadata = {
  title: "مميزات صِلني — كل اللي تحتاجه لصلة الرحم",
  description: "تتبّع التواصل، تذكيرات ذكية، سلاسل، مساعد ذكي، شجرة العائلة، وإحصائيات.",
};

const features = [
  {
    icon: "📞",
    title: "تتبّع التواصل",
    description: "سجّل كل تواصل مع أقاربك — اتصال، زيارة، رسالة، هدية، أو مناسبة. كل شي محفوظ.",
    gradient: "from-primary to-primary-light",
  },
  {
    icon: "🔔",
    title: "تذكيرات ذكية",
    description: "حدد أولوياتك وصِلني يذكّرك. يومي، أسبوعي، شهري، أو كل جمعة.",
    gradient: "from-accent-orange to-gold",
  },
  {
    icon: "🔥",
    title: "سلاسل التواصل",
    description: "حافظ على سلسلة تواصلك. كل يوم تتواصل يحسب. لا تخلي السلسلة تنقطع!",
    gradient: "from-gold-dark to-gold",
  },
  {
    icon: "🤖",
    title: "المساعد الذكي",
    description: "يساعدك تكتب رسائل، يقترح مواضيع للمحادثة، ويحلل علاقاتك. متاح في باقة ماكس.",
    gradient: "from-primary-deep to-primary",
  },
  {
    icon: "🌳",
    title: "شجرة العائلة",
    description: "شوف عائلتك بشكل مرئي وتعرّف على علاقاتك بنظرة واحدة.",
    gradient: "from-primary-light to-primary-soft",
  },
  {
    icon: "📊",
    title: "إحصائيات وتقارير",
    description: "تعرّف على نمط تواصلك واكتشف مين يحتاج اهتمام أكثر.",
    gradient: "from-primary to-primary-medium",
  },
  {
    icon: "🏆",
    title: "نقاط وإنجازات",
    description: "اكسب نقاط مع كل تواصل وافتح إنجازات تحفّزك تستمر.",
    gradient: "from-gold to-accent-orange",
  },
  {
    icon: "🔒",
    title: "خصوصية كاملة",
    description: "بياناتك مشفّرة ومحمية. ما نبيع ولا نشارك معلوماتك مع أي طرف.",
    gradient: "from-primary-dark to-primary-deep",
  },
];

export default function FeaturesPage() {
  return (
    <>
      {/* Hero */}
      <section className="relative gradient-hero text-white pt-[120px] pb-3xl overflow-hidden">
        <IslamicPattern color="#81C784" opacity={0.05} />
        <div className="max-w-4xl mx-auto px-md lg:px-xl relative z-10 text-center">
          <TextReveal text="كل اللي تحتاجه" as="h1" className="text-hero mb-md" />
          <TextReveal
            text="لصلة الرحم"
            as="h2"
            className="text-dramatic text-gold mb-lg"
            delay={0.4}
          />
          <ScrollReveal delay={0.7}>
            <p className="text-body-lg text-white/80 max-w-2xl mx-auto">
              أدوات بسيطة وفعّالة تساعدك تحافظ على أجمل عبادة
            </p>
          </ScrollReveal>
        </div>
      </section>

      {/* Features grid */}
      <section className="py-3xl bg-surface">
        <div className="max-w-7xl mx-auto px-md lg:px-xl">
          <StaggerChildren className="grid grid-cols-1 md:grid-cols-2 gap-lg">
            {features.map((feature) => (
              <FeatureCard key={feature.title} {...feature} />
            ))}
          </StaggerChildren>
        </div>
      </section>

      {/* CTA */}
      <section className="py-3xl bg-white text-center">
        <ScrollReveal>
          <h2 className="text-headline-lg text-primary-deep mb-lg">
            جاهز تبدأ؟
          </h2>
          <Button href="https://apps.apple.com/app/id_PLACEHOLDER" size="lg">
            حمّل التطبيق مجاناً
          </Button>
        </ScrollReveal>
      </section>
    </>
  );
}

function FeatureCard({
  icon,
  title,
  description,
}: {
  icon: string;
  title: string;
  description: string;
  gradient: string;
}) {
  return (
    <ScrollReveal>
      <div className="bg-white rounded-card p-xl shadow-sm hover:shadow-lg transition-all duration-300 group">
        <span className="text-5xl block mb-md group-hover:scale-110 transition-transform duration-300">
          {icon}
        </span>
        <h3 className="text-headline-sm text-primary-deep mb-sm">{title}</h3>
        <p className="text-body-lg text-text-secondary leading-relaxed">
          {description}
        </p>
      </div>
    </ScrollReveal>
  );
}
```

**Step 2: Verify**

Navigate to `/features`. Expected: Animated hero, staggered feature cards, CTA.

**Step 3: Commit**

```bash
cd /Users/engammar/Apps/silni_app
git add silni-landing/
git commit -m "feat(landing): add Features page with animated feature cards"
```

---

## Task 8: Pricing Page

**Files:**
- Create: `silni-landing/app/pricing/page.tsx`
- Create: `silni-landing/components/sections/PricingCards.tsx`

**Step 1: Create `PricingCards.tsx`**

```tsx
"use client";

import { motion } from "framer-motion";
import ScrollReveal from "@/components/animations/ScrollReveal";
import Button from "@/components/ui/Button";

const tiers = [
  {
    name: "مجاني",
    price: "٠",
    period: "",
    description: "ابدأ بصلة رحمك اليوم",
    features: [
      "تسجيل التواصل مع الأقارب",
      "٣ تذكيرات",
      "شجرة العائلة",
      "ثيمات مخصصة",
      "سلاسل التواصل",
      "نقاط وإنجازات",
    ],
    cta: "حمّل مجاناً",
    featured: false,
  },
  {
    name: "ماكس",
    price: "٧٫٩٩",
    period: "/شهرياً",
    annualPrice: "٧٩٫٩٩$/سنوياً",
    description: "كل المميزات + الذكاء الاصطناعي",
    features: [
      "كل مميزات المجاني",
      "تذكيرات غير محدودة",
      "المساعد الذكي (AI)",
      "كتابة الرسائل بالذكاء الاصطناعي",
      "تحليل العلاقات",
      "تقارير أسبوعية",
      "إحصائيات متقدمة",
      "تصدير البيانات",
    ],
    cta: "جرّب مجاناً لمدة أسبوع",
    featured: true,
  },
];

export default function PricingCards() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-xl max-w-4xl mx-auto">
      {tiers.map((tier, i) => (
        <ScrollReveal key={tier.name} delay={i * 0.2}>
          <motion.div
            className={`relative rounded-card p-xl ${
              tier.featured
                ? "bg-white shadow-xl border-2 border-gold"
                : "bg-white shadow-sm border border-text-hint/20"
            }`}
            whileHover={{ y: -8 }}
            transition={{ duration: 0.3 }}
          >
            {/* Featured badge */}
            {tier.featured && (
              <div className="absolute -top-4 left-1/2 -translate-x-1/2 gradient-golden text-primary-deep font-bold text-label-lg px-lg py-xs rounded-full animate-pulse-glow">
                الأكثر طلباً
              </div>
            )}

            {/* Shimmer border for featured */}
            {tier.featured && (
              <div className="absolute inset-0 rounded-card overflow-hidden pointer-events-none">
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-gold/10 to-transparent animate-shimmer bg-[length:200%_100%]" />
              </div>
            )}

            <div className="text-center mb-xl relative">
              <h3 className="text-headline-md text-primary-deep mb-sm">
                {tier.name}
              </h3>
              <p className="text-text-secondary text-body-md mb-lg">
                {tier.description}
              </p>
              <div className="flex items-baseline justify-center gap-xs">
                <span className="font-poppins text-[48px] font-black text-primary-deep">
                  ${tier.price}
                </span>
                {tier.period && (
                  <span className="text-text-secondary text-body-lg">
                    {tier.period}
                  </span>
                )}
              </div>
              {tier.annualPrice && (
                <p className="text-text-hint text-body-md mt-xs">
                  أو {tier.annualPrice}
                </p>
              )}
            </div>

            {/* Features list */}
            <ul className="space-y-md mb-xl">
              {tier.features.map((feature, j) => (
                <motion.li
                  key={feature}
                  className="flex items-center gap-sm text-body-lg text-text-primary"
                  initial={{ opacity: 0, x: 20 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.2 + j * 0.05 }}
                >
                  <span className="text-primary flex-shrink-0">✓</span>
                  {feature}
                </motion.li>
              ))}
            </ul>

            <Button
              href="https://apps.apple.com/app/id_PLACEHOLDER"
              variant={tier.featured ? "golden" : "outline"}
              size="lg"
              className={`w-full ${!tier.featured ? "!border-primary !text-primary hover:!bg-primary/5" : ""}`}
            >
              {tier.cta}
            </Button>
          </motion.div>
        </ScrollReveal>
      ))}
    </div>
  );
}
```

**Step 2: Create `app/pricing/page.tsx`**

```tsx
import type { Metadata } from "next";
import TextReveal from "@/components/animations/TextReveal";
import ScrollReveal from "@/components/animations/ScrollReveal";
import IslamicPattern from "@/components/animations/IslamicPattern";
import PricingCards from "@/components/sections/PricingCards";

export const metadata: Metadata = {
  title: "أسعار صِلني — ابدأ مجاناً",
  description: "باقة مجانية للجميع وباقة ماكس مع الذكاء الاصطناعي وتذكيرات غير محدودة.",
};

export default function PricingPage() {
  return (
    <>
      <section className="relative gradient-hero text-white pt-[120px] pb-3xl overflow-hidden">
        <IslamicPattern color="#81C784" opacity={0.05} />
        <div className="max-w-4xl mx-auto px-md lg:px-xl relative z-10 text-center">
          <TextReveal text="ابدأ مجاناً" as="h1" className="text-hero mb-md" />
          <ScrollReveal delay={0.4}>
            <p className="text-body-lg text-white/80 max-w-2xl mx-auto">
              صلة الرحم ما لها سعر — وصِلني يخلّيك تبدأ بدون أي تكلفة
            </p>
          </ScrollReveal>
        </div>
      </section>

      <section className="py-3xl bg-surface">
        <div className="max-w-7xl mx-auto px-md lg:px-xl">
          <PricingCards />
        </div>
      </section>
    </>
  );
}
```

**Step 3: Verify and Commit**

```bash
cd /Users/engammar/Apps/silni_app/silni-landing && npm run dev
# Navigate to /pricing
cd /Users/engammar/Apps/silni_app && git add silni-landing/ && git commit -m "feat(landing): add Pricing page with animated tier cards"
```

---

## Task 9: FAQ Page

**Files:**
- Create: `silni-landing/app/faq/page.tsx`
- Create: `silni-landing/components/sections/FaqAccordion.tsx`

**Step 1: Create `FaqAccordion.tsx`**

```tsx
"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import ScrollReveal from "@/components/animations/ScrollReveal";

interface FaqItem {
  question: string;
  answer: string;
}

interface FaqAccordionProps {
  items: FaqItem[];
}

export default function FaqAccordion({ items }: FaqAccordionProps) {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  return (
    <div className="space-y-md max-w-3xl mx-auto">
      {items.map((item, i) => (
        <ScrollReveal key={i} delay={i * 0.08}>
          <div className="bg-white rounded-card overflow-hidden shadow-sm">
            <button
              onClick={() => setOpenIndex(openIndex === i ? null : i)}
              className="w-full text-right p-xl flex items-center justify-between gap-md hover:bg-surface/50 transition-colors"
            >
              <span className="text-headline-sm text-primary-deep">
                {item.question}
              </span>
              <motion.span
                animate={{ rotate: openIndex === i ? 180 : 0 }}
                transition={{ duration: 0.3 }}
                className="text-primary text-2xl flex-shrink-0"
              >
                ▼
              </motion.span>
            </button>

            <AnimatePresence>
              {openIndex === i && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: "auto", opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  transition={{ duration: 0.3, ease: "easeInOut" }}
                  className="overflow-hidden"
                >
                  <div className="px-xl pb-xl text-body-lg text-text-secondary leading-relaxed">
                    {item.answer}
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </ScrollReveal>
      ))}
    </div>
  );
}
```

**Step 2: Create `app/faq/page.tsx`**

```tsx
import type { Metadata } from "next";
import TextReveal from "@/components/animations/TextReveal";
import IslamicPattern from "@/components/animations/IslamicPattern";
import FaqAccordion from "@/components/sections/FaqAccordion";

export const metadata: Metadata = {
  title: "الأسئلة الشائعة — صِلني",
  description: "إجابات على الأسئلة الأكثر شيوعاً عن تطبيق صِلني.",
};

const faqs = [
  {
    question: "هل التطبيق مجاني؟",
    answer: "نعم! تقدر تستخدم صِلني مجاناً مع المميزات الأساسية — تسجيل التواصل، ٣ تذكيرات، شجرة العائلة، والإنجازات. باقة ماكس تعطيك تذكيرات غير محدودة والمساعد الذكي.",
  },
  {
    question: "هل بياناتي آمنة؟",
    answer: "بياناتك مشفّرة ومحمية بالكامل. ما نبيع ولا نشارك معلوماتك مع أي طرف ثالث. خصوصيتك أولويتنا.",
  },
  {
    question: "هل أقدر أستخدم التطبيق بدون إنترنت؟",
    answer: "نعم! صِلني يعمل بدون إنترنت. تقدر تسجّل تواصلك وتشوف بياناتك. لما يرجع الإنترنت، كل شي يتزامن تلقائياً.",
  },
  {
    question: "كيف التذكيرات تشتغل؟",
    answer: "تقدر تحدد لكل قريب جدول تذكير — يومي، أسبوعي، شهري، أو كل جمعة. التطبيق يرسلك إشعار في الوقت المناسب.",
  },
  {
    question: "ما هو المساعد الذكي؟",
    answer: "المساعد الذكي يستخدم الذكاء الاصطناعي ليساعدك تكتب رسائل، يقترح مواضيع للمحادثة، ويعطيك نصائح لتحسين علاقاتك. متاح في باقة ماكس.",
  },
  {
    question: "هل التطبيق متاح على أندرويد؟",
    answer: "حالياً صِلني متاح على iOS فقط (آيفون وآيباد). نسخة أندرويد قادمة قريباً إن شاء الله. سجّل بريدك عشان نبلّغك أول ما تنزل.",
  },
  {
    question: "كيف ألغي الاشتراك؟",
    answer: "تقدر تلغي اشتراكك في أي وقت من إعدادات App Store على جهازك. الإلغاء يسري نهاية الفترة الحالية.",
  },
  {
    question: "هل فيه تجربة مجانية لباقة ماكس؟",
    answer: "نعم! تقدر تجرّب باقة ماكس مجاناً لمدة أسبوع كامل. لو ما عجبتك، ألغِ قبل نهاية الأسبوع وما يتم خصم أي مبلغ.",
  },
];

export default function FaqPage() {
  return (
    <>
      <section className="relative gradient-hero text-white pt-[120px] pb-3xl overflow-hidden">
        <IslamicPattern color="#81C784" opacity={0.05} />
        <div className="max-w-4xl mx-auto px-md lg:px-xl relative z-10 text-center">
          <TextReveal text="الأسئلة الشائعة" as="h1" className="text-hero mb-md" />
        </div>
      </section>

      <section className="py-3xl bg-surface">
        <div className="max-w-7xl mx-auto px-md lg:px-xl">
          <FaqAccordion items={faqs} />
        </div>
      </section>
    </>
  );
}
```

**Step 3: Verify and Commit**

```bash
cd /Users/engammar/Apps/silni_app/silni-landing && npm run dev
# Navigate to /faq
cd /Users/engammar/Apps/silni_app && git add silni-landing/ && git commit -m "feat(landing): add FAQ page with animated accordion"
```

---

## Task 10: Blog Infrastructure + Sample Post

**Files:**
- Create: `silni-landing/lib/blog.ts`
- Create: `silni-landing/content/blog/silat-al-rahim-obligation.mdx`
- Create: `silni-landing/app/blog/page.tsx`
- Create: `silni-landing/app/blog/[slug]/page.tsx`
- Create: `silni-landing/components/ui/BlogCard.tsx`
- Create: `silni-landing/mdx-components.tsx`

**Step 1: Create `lib/blog.ts`**

```ts
import fs from "fs";
import path from "path";
import matter from "gray-matter";
import readingTime from "reading-time";

const BLOG_DIR = path.join(process.cwd(), "content/blog");

export interface BlogPost {
  slug: string;
  title: string;
  description: string;
  date: string;
  readingTime: string;
  image?: string;
}

export function getAllPosts(): BlogPost[] {
  if (!fs.existsSync(BLOG_DIR)) return [];

  const files = fs.readdirSync(BLOG_DIR).filter((f) => f.endsWith(".mdx"));

  const posts = files.map((file) => {
    const slug = file.replace(/\.mdx$/, "");
    const source = fs.readFileSync(path.join(BLOG_DIR, file), "utf8");
    const { data, content } = matter(source);
    const rt = readingTime(content);

    return {
      slug,
      title: data.title || "",
      description: data.description || "",
      date: data.date || "",
      readingTime: rt.text.replace("min read", "دقائق للقراءة"),
      image: data.image,
    };
  });

  return posts.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
}

export function getPostBySlug(slug: string) {
  const filePath = path.join(BLOG_DIR, `${slug}.mdx`);
  if (!fs.existsSync(filePath)) return null;

  const source = fs.readFileSync(filePath, "utf8");
  const { data, content } = matter(source);
  const rt = readingTime(content);

  return {
    slug,
    title: data.title || "",
    description: data.description || "",
    date: data.date || "",
    readingTime: rt.text.replace("min read", "دقائق للقراءة"),
    image: data.image,
    content,
  };
}
```

**Step 2: Create `mdx-components.tsx` at project root**

```tsx
import type { MDXComponents } from "mdx/types";

export function useMDXComponents(components: MDXComponents): MDXComponents {
  return {
    h1: ({ children }) => (
      <h1 className="text-headline-lg text-primary-deep mb-lg">{children}</h1>
    ),
    h2: ({ children }) => (
      <h2 className="text-headline-md text-primary-deep mt-2xl mb-md">{children}</h2>
    ),
    h3: ({ children }) => (
      <h3 className="text-headline-sm text-primary-deep mt-xl mb-sm">{children}</h3>
    ),
    p: ({ children }) => (
      <p className="text-body-lg text-text-secondary leading-relaxed mb-md">{children}</p>
    ),
    blockquote: ({ children }) => (
      <blockquote className="border-r-4 border-primary pr-lg my-lg text-primary-deep font-amiri text-xl leading-loose">
        {children}
      </blockquote>
    ),
    ul: ({ children }) => (
      <ul className="list-disc list-inside space-y-sm mb-md text-body-lg text-text-secondary">{children}</ul>
    ),
    ...components,
  };
}
```

**Step 3: Create sample blog post `content/blog/silat-al-rahim-obligation.mdx`**

```mdx
---
title: "صلة الرحم — لماذا هي فريضة وليست خياراً؟"
description: "تعرّف على أهمية صلة الرحم في الإسلام وكيف تحافظ عليها في عصرنا"
date: "2026-01-29"
---

صلة الرحم من أعظم الواجبات في ديننا الإسلامي. ليست مجرد عادة اجتماعية أو تقليد — بل هي فريضة أمر بها الله سبحانه وتعالى ووصّى بها نبيّنا ﷺ.

## الأدلة من القرآن والسنة

> «وَاتَّقُوا اللَّهَ الَّذِي تَسَاءَلُونَ بِهِ وَالْأَرْحَامَ» — النساء: ١

وفي الحديث الشريف:

> «مَن أَحَبَّ أن يُبسَط له في رِزقه، ويُنسأ له في أَثَره، فليَصِل رَحِمَه» — متفق عليه

## التحدي المعاصر

في عصرنا الحالي، أصبحت صلة الرحم تحدياً حقيقياً:

- المسافات البعيدة بين أفراد العائلة
- ضغوط العمل والحياة اليومية
- الانشغال بوسائل التواصل الاجتماعي عن التواصل الحقيقي
- نسيان المناسبات والمواعيد المهمة

## كيف تحافظ على صلة الرحم؟

الحل ليس معقداً. ابدأ بخطوات بسيطة:

- خصص وقتاً أسبوعياً للاتصال بأقاربك
- سجّل آخر مرة تواصلت مع كل قريب
- استخدم التذكيرات عشان ما تنسى
- اجعل صلة الرحم جزءاً من روتينك اليومي

صِلني صُمم خصيصاً ليساعدك في كل هذا — بطريقة بسيطة وعملية.
```

**Step 4: Create `BlogCard.tsx`**

```tsx
"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import type { BlogPost } from "@/lib/blog";

export default function BlogCard({ post }: { post: BlogPost }) {
  return (
    <Link href={`/blog/${post.slug}`}>
      <motion.article
        className="bg-white rounded-card overflow-hidden shadow-sm group"
        whileHover={{ y: -8, boxShadow: "0 20px 40px rgba(0,0,0,0.1)" }}
        transition={{ duration: 0.3 }}
      >
        {/* Gradient header */}
        <div className="h-3 gradient-primary" />

        <div className="p-xl">
          <div className="flex items-center gap-md text-body-md text-text-hint mb-md">
            <span>{new Date(post.date).toLocaleDateString("ar-SA")}</span>
            <span>·</span>
            <span>{post.readingTime}</span>
          </div>

          <h3 className="text-headline-sm text-primary-deep mb-sm group-hover:text-primary transition-colors">
            {post.title}
          </h3>

          <p className="text-body-lg text-text-secondary leading-relaxed line-clamp-2">
            {post.description}
          </p>

          <span className="inline-block mt-md text-primary text-label-lg group-hover:underline">
            اقرأ المزيد ←
          </span>
        </div>
      </motion.article>
    </Link>
  );
}
```

**Step 5: Create `app/blog/page.tsx`**

```tsx
import type { Metadata } from "next";
import { getAllPosts } from "@/lib/blog";
import TextReveal from "@/components/animations/TextReveal";
import IslamicPattern from "@/components/animations/IslamicPattern";
import StaggerChildren, { staggerItem } from "@/components/animations/StaggerChildren";
import BlogCard from "@/components/ui/BlogCard";
import { motion } from "framer-motion";

export const metadata: Metadata = {
  title: "مدونة صِلني — مقالات عن صلة الرحم والعائلة",
  description: "مقالات ونصائح عن صلة الرحم، العلاقات العائلية، والتواصل الفعّال.",
};

export default function BlogPage() {
  const posts = getAllPosts();

  return (
    <>
      <section className="relative gradient-hero text-white pt-[120px] pb-3xl overflow-hidden">
        <IslamicPattern color="#81C784" opacity={0.05} />
        <div className="max-w-4xl mx-auto px-md lg:px-xl relative z-10 text-center">
          <TextReveal text="المدونة" as="h1" className="text-hero mb-md" />
        </div>
      </section>

      <section className="py-3xl bg-surface">
        <div className="max-w-7xl mx-auto px-md lg:px-xl">
          {posts.length > 0 ? (
            <StaggerChildren className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-lg">
              {posts.map((post) => (
                <motion.div key={post.slug} variants={staggerItem}>
                  <BlogCard post={post} />
                </motion.div>
              ))}
            </StaggerChildren>
          ) : (
            <p className="text-center text-text-secondary text-body-lg">
              قريباً — مقالات جديدة عن صلة الرحم
            </p>
          )}
        </div>
      </section>
    </>
  );
}
```

**Step 6: Create `app/blog/[slug]/page.tsx`**

```tsx
import { notFound } from "next/navigation";
import { getAllPosts, getPostBySlug } from "@/lib/blog";
import ScrollReveal from "@/components/animations/ScrollReveal";
import TextReveal from "@/components/animations/TextReveal";
import IslamicPattern from "@/components/animations/IslamicPattern";

export async function generateStaticParams() {
  const posts = getAllPosts();
  return posts.map((post) => ({ slug: post.slug }));
}

export async function generateMetadata({ params }: { params: { slug: string } }) {
  const post = getPostBySlug(params.slug);
  if (!post) return {};
  return {
    title: `${post.title} — مدونة صِلني`,
    description: post.description,
  };
}

export default function BlogPostPage({ params }: { params: { slug: string } }) {
  const post = getPostBySlug(params.slug);
  if (!post) notFound();

  return (
    <>
      <section className="relative gradient-hero text-white pt-[120px] pb-3xl overflow-hidden">
        <IslamicPattern color="#81C784" opacity={0.05} />
        <div className="max-w-4xl mx-auto px-md lg:px-xl relative z-10 text-center">
          <TextReveal text={post.title} as="h1" className="text-dramatic mb-md" />
          <ScrollReveal delay={0.4}>
            <div className="flex items-center justify-center gap-md text-white/60 text-body-lg">
              <span>{new Date(post.date).toLocaleDateString("ar-SA")}</span>
              <span>·</span>
              <span>{post.readingTime}</span>
            </div>
          </ScrollReveal>
        </div>
      </section>

      <section className="py-3xl bg-surface">
        <ScrollReveal>
          <article className="max-w-3xl mx-auto px-md lg:px-xl prose-custom">
            {/* MDX content will be rendered here — requires dynamic MDX loading */}
            <div
              className="text-body-lg text-text-secondary leading-relaxed space-y-md"
              dangerouslySetInnerHTML={{ __html: "<!-- MDX rendering setup needed -->" }}
            />
          </article>
        </ScrollReveal>
      </section>
    </>
  );
}
```

> **Note for implementer:** The blog post rendering requires compiling MDX at build time. Use `next-mdx-remote` or adjust the `@next/mdx` config to handle dynamic slug-based MDX loading. The exact wiring depends on which approach works cleanest with the static export.

**Step 7: Verify and Commit**

```bash
cd /Users/engammar/Apps/silni_app/silni-landing && npm run dev
# Navigate to /blog
cd /Users/engammar/Apps/silni_app && git add silni-landing/ && git commit -m "feat(landing): add Blog with MDX infrastructure and sample post"
```

---

## Task 11: Final Polish — SEO, OG Images, Performance

**Files:**
- Create: `silni-landing/app/sitemap.ts`
- Create: `silni-landing/app/robots.ts`
- Create: `silni-landing/app/opengraph-image.tsx` (or static PNG)
- Modify: `silni-landing/app/layout.tsx` (add analytics placeholder)

**Step 1: Create `app/sitemap.ts`**

```ts
import type { MetadataRoute } from "next";
import { getAllPosts } from "@/lib/blog";

const BASE_URL = "https://silni.app"; // Update when domain is set

export default function sitemap(): MetadataRoute.Sitemap {
  const posts = getAllPosts();

  const blogUrls = posts.map((post) => ({
    url: `${BASE_URL}/blog/${post.slug}`,
    lastModified: new Date(post.date),
  }));

  return [
    { url: BASE_URL, lastModified: new Date(), changeFrequency: "weekly" as const, priority: 1 },
    { url: `${BASE_URL}/about`, lastModified: new Date(), priority: 0.8 },
    { url: `${BASE_URL}/features`, lastModified: new Date(), priority: 0.8 },
    { url: `${BASE_URL}/pricing`, lastModified: new Date(), priority: 0.8 },
    { url: `${BASE_URL}/faq`, lastModified: new Date(), priority: 0.7 },
    { url: `${BASE_URL}/blog`, lastModified: new Date(), priority: 0.7 },
    ...blogUrls,
  ];
}
```

**Step 2: Create `app/robots.ts`**

```ts
import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: "*", allow: "/" },
    sitemap: "https://silni.app/sitemap.xml",
  };
}
```

**Step 3: Update `layout.tsx` metadata with full SEO**

Add to the existing metadata in `app/layout.tsx`:

```ts
export const metadata: Metadata = {
  metadataBase: new URL("https://silni.app"),
  title: {
    default: "صِلني — حافظ على صلة الرحم",
    template: "%s | صِلني",
  },
  description: "صلة الرحم فريضة وصِلني يساعدك تحافظ عليها. تتبّع تواصلك مع أقاربك، تذكيرات ذكية، وإحصائيات تحفّزك.",
  keywords: ["صلة الرحم", "عائلة", "تواصل", "إسلام", "تطبيق", "صلني", "silni"],
  authors: [{ name: "صِلني" }],
  openGraph: {
    title: "صِلني — حافظ على صلة الرحم",
    description: "صلة الرحم فريضة وصِلني يساعدك تحافظ عليها.",
    locale: "ar_SA",
    type: "website",
    siteName: "صِلني",
  },
  twitter: {
    card: "summary_large_image",
    title: "صِلني — حافظ على صلة الرحم",
    description: "صلة الرحم فريضة وصِلني يساعدك تحافظ عليها.",
  },
  robots: { index: true, follow: true },
};
```

**Step 4: Build and verify static export**

```bash
cd /Users/engammar/Apps/silni_app/silni-landing
npm run build
```

Expected: Static export completes. All pages generated in `out/` directory.

**Step 5: Commit**

```bash
cd /Users/engammar/Apps/silni_app
git add silni-landing/
git commit -m "feat(landing): add SEO — sitemap, robots, OG metadata"
```

---

## Task 12: Deploy to Vercel

**Step 1: Initialize git in silni-landing (if separate repo) or push main repo**

Since `silni-landing/` is inside the main repo, configure Vercel to use a root directory:

```bash
cd /Users/engammar/Apps/silni_app/silni-landing
npx vercel --yes
```

During setup:
- **Framework:** Next.js
- **Root Directory:** `silni-landing`
- **Build Command:** `npm run build`
- **Output Directory:** `out`

**Step 2: Deploy**

```bash
cd /Users/engammar/Apps/silni_app/silni-landing
npx vercel --prod
```

**Step 3: Verify live site**

Open the Vercel URL. Check:
- All 6 pages load
- Animations play on scroll
- RTL layout correct
- Fonts load (Cairo, Poppins, Amiri Quran)
- Mobile responsive
- Nav works on mobile

**Step 4: Final commit**

```bash
cd /Users/engammar/Apps/silni_app
git add silni-landing/
git commit -m "feat(landing): Vercel deployment configuration"
```

---

## Summary

| Task | Description |
|------|-------------|
| 1 | Project scaffolding + design tokens |
| 2 | Animation infrastructure (Framer Motion, Lenis, Islamic pattern) |
| 3 | Shared layout (Navbar, Footer, Button, AppStoreBadge) |
| 4 | Home — Hero section |
| 5 | Home — Problem, Features, Social Proof, Newsletter |
| 6 | About page |
| 7 | Features page |
| 8 | Pricing page |
| 9 | FAQ page |
| 10 | Blog infrastructure + sample post |
| 11 | SEO (sitemap, robots, metadata) |
| 12 | Deploy to Vercel |

**Total commits:** 12
**Pages:** Home, About, Features, Pricing, FAQ, Blog (listing + post)
