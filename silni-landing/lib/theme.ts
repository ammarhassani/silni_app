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
