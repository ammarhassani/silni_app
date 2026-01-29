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
