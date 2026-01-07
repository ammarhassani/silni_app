"use client";

import { useState, useMemo } from "react";
import { type InAppMessageInput } from "@/hooks/use-in-app-messages";
import { useThemes, themeToPreviewFormat } from "@/hooks/use-themes";
import {
  Bell,
  Megaphone,
  AlertTriangle,
  Info,
  Star,
  Sparkles,
  PartyPopper,
  Gift,
  Trophy,
  Crown,
  Rocket,
  Zap,
  Flame,
  Heart,
  Users,
  TreeDeciduous,
  Check,
  AlertCircle,
  Lightbulb,
  Moon,
  Sun,
  ChevronLeft,
  X,
  Loader2,
  type LucideIcon,
} from "lucide-react";

// Icon mapping
const iconMap: Record<string, LucideIcon> = {
  bell: Bell,
  megaphone: Megaphone,
  alert: AlertTriangle,
  info: Info,
  star: Star,
  sparkles: Sparkles,
  party: PartyPopper,
  gift: Gift,
  trophy: Trophy,
  crown: Crown,
  rocket: Rocket,
  zap: Zap,
  fire: Flame,
  heart: Heart,
  users: Users,
  tree: TreeDeciduous,
  check: Check,
  warning: AlertCircle,
  tip: Lightbulb,
  moon: Moon,
  sun: Sun,
};

interface MessagePreviewProps {
  data: InAppMessageInput;
}

export function MessagePreview({ data }: MessagePreviewProps) {
  const Icon = iconMap[data.icon_name || "bell"] || Bell;
  const { data: themesData, isLoading: themesLoading } = useThemes();

  // Convert fetched themes to preview format
  const appThemes = useMemo(() => {
    if (!themesData || themesData.length === 0) return [];
    return themesData.map(themeToPreviewFormat);
  }, [themesData]);

  const [selectedThemeIndex, setSelectedThemeIndex] = useState(0);
  const selectedTheme = appThemes[selectedThemeIndex] || appThemes[0];

  // Check if using theme mode
  const isThemeMode = data.color_mode === "theme";

  // Get background style based on theme mode
  const getBackgroundStyle = (theme: typeof appThemes[0] | undefined) => {
    if (isThemeMode) {
      // Glassmorphic style that adapts to theme - clear glass effect
      // Use higher opacity for better visibility in preview
      return {
        background: "rgba(255, 255, 255, 0.2)",
        backdropFilter: "blur(16px)",
        WebkitBackdropFilter: "blur(16px)",
        border: "1px solid rgba(255, 255, 255, 0.3)",
        boxShadow: "0 8px 32px rgba(0, 0, 0, 0.12)",
      };
    }
    if (data.background_gradient) {
      return {
        background: `linear-gradient(135deg, ${data.background_gradient.start}, ${data.background_gradient.end})`,
      };
    }
    return {
      background: data.background_color || "#1B5E20",
    };
  };

  // Text color based on theme mode
  const getTextColor = (theme: typeof appThemes[0] | undefined) => {
    if (isThemeMode) {
      // In theme mode, use white text (most themes have light text on gradient backgrounds)
      return theme?.text || "#ffffff";
    }
    return data.text_color || "#ffffff";
  };

  const bgStyle = getBackgroundStyle(selectedTheme);
  const textColor = getTextColor(selectedTheme);

  // Preview wrapper with theme selector
  const PreviewWrapper = ({ children, label }: { children: React.ReactNode; label: string }) => (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <p className="text-sm font-medium">{label}</p>
        {isThemeMode && (
          <span className="text-xs text-emerald-600 bg-emerald-500/10 px-2 py-1 rounded-full">
            يتكيف مع الثيم
          </span>
        )}
      </div>

      {/* Theme selector - only for theme mode */}
      {isThemeMode && (
        <div className="flex gap-2 flex-wrap">
          {themesLoading ? (
            <div className="flex items-center gap-2 text-muted-foreground text-xs">
              <Loader2 className="h-3 w-3 animate-spin" />
              <span>جاري تحميل الثيمات...</span>
            </div>
          ) : appThemes.length === 0 ? (
            <span className="text-xs text-muted-foreground">لا توجد ثيمات</span>
          ) : (
            appThemes.map((theme, index) => (
              <button
                key={theme.id}
                onClick={() => setSelectedThemeIndex(index)}
                className={`px-3 py-1.5 text-xs rounded-lg transition-all ${
                  selectedThemeIndex === index
                    ? "ring-2 ring-primary ring-offset-2"
                    : "opacity-70 hover:opacity-100"
                }`}
                style={{ background: theme.bg, color: theme.text }}
              >
                {theme.name}
              </button>
            ))
          )}
        </div>
      )}

      {/* Preview container */}
      <div
        className="rounded-2xl p-6 min-h-[120px] flex items-center justify-center"
        style={{
          background: isThemeMode && selectedTheme ? selectedTheme.bg : "var(--background)",
        }}
      >
        {children}
      </div>
    </div>
  );

  // Banner preview - larger size
  if (data.message_type === "banner") {
    return (
      <PreviewWrapper label="معاينة البانر">
        <div
          className="w-full flex items-center gap-4 px-5 py-4 rounded-2xl"
          style={bgStyle}
        >
          <div className="w-12 h-12 rounded-full bg-white/20 flex items-center justify-center shrink-0">
            <Icon className="h-6 w-6" color={textColor} />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-base font-semibold" style={{ color: textColor }}>
              {data.title_ar || "عنوان البانر"}
            </p>
            {data.body_ar && (
              <p className="text-sm opacity-80 mt-0.5" style={{ color: textColor }}>
                {data.body_ar}
              </p>
            )}
          </div>
          <ChevronLeft className="h-5 w-5 opacity-60 shrink-0" color={textColor} />
        </div>
      </PreviewWrapper>
    );
  }

  // Tooltip preview - simple pill shape, no X button (auto-dismissing)
  if (data.message_type === "tooltip") {
    return (
      <PreviewWrapper label="معاينة التلميح">
        <div className="flex justify-center">
          <div
            className="inline-flex items-center gap-3 px-5 py-3 rounded-full"
            style={bgStyle}
          >
            <Icon className="h-5 w-5" color={textColor} />
            <span className="text-base font-medium" style={{ color: textColor }}>
              {data.title_ar || "نص التلميح"}
            </span>
          </div>
        </div>
      </PreviewWrapper>
    );
  }

  // Modal preview
  if (data.message_type === "modal") {
    return (
      <PreviewWrapper label="معاينة النافذة المنبثقة">
        <div className="border rounded-2xl p-6 bg-card relative min-w-[280px]">
          {data.is_dismissible && (
            <button className="absolute top-3 left-3 p-1.5 hover:bg-muted rounded-full">
              <X className="h-5 w-5 text-muted-foreground" />
            </button>
          )}
          <div className="flex flex-col items-center gap-4 pt-2">
            <div
              className="w-20 h-20 rounded-2xl flex items-center justify-center"
              style={bgStyle}
            >
              <Icon className="h-10 w-10" color={textColor} />
            </div>
            <h3 className="text-lg font-semibold text-center">
              {data.title_ar || "عنوان النافذة"}
            </h3>
            {data.body_ar && (
              <p className="text-base text-muted-foreground text-center">
                {data.body_ar}
              </p>
            )}
            {data.cta_text_ar && (
              <button
                className="w-full py-3 px-5 rounded-xl text-base font-medium"
                style={bgStyle}
              >
                <span style={{ color: textColor }}>{data.cta_text_ar}</span>
              </button>
            )}
          </div>
        </div>
      </PreviewWrapper>
    );
  }

  // Bottom sheet preview
  if (data.message_type === "bottom_sheet") {
    return (
      <PreviewWrapper label="معاينة الشريط السفلي">
        <div className="border rounded-t-2xl p-5 bg-card min-w-[280px]">
          <div className="flex justify-center mb-4">
            <div className="w-12 h-1.5 bg-muted-foreground/30 rounded-full" />
          </div>
          <div className="flex items-start gap-4">
            <div
              className="w-14 h-14 rounded-xl flex items-center justify-center shrink-0"
              style={bgStyle}
            >
              <Icon className="h-7 w-7" color={textColor} />
            </div>
            <div className="flex-1">
              <h3 className="text-base font-semibold">
                {data.title_ar || "عنوان الشريط"}
              </h3>
              {data.body_ar && (
                <p className="text-sm text-muted-foreground mt-1.5">
                  {data.body_ar}
                </p>
              )}
            </div>
          </div>
          {data.cta_text_ar && (
            <button
              className="w-full mt-5 py-3 px-5 rounded-xl text-base font-medium"
              style={bgStyle}
            >
              <span style={{ color: textColor }}>{data.cta_text_ar}</span>
            </button>
          )}
        </div>
      </PreviewWrapper>
    );
  }

  // MOTD (Message of the Day) preview
  if (data.message_type === "motd") {
    return (
      <PreviewWrapper label="معاينة رسالة اليوم">
        <div className="border-r-4 border-primary/50 bg-muted/30 rounded-xl p-5 min-w-[280px]">
          <div className="flex items-start gap-4">
            <Icon className="h-6 w-6 text-primary shrink-0 mt-0.5" />
            <div>
              <p className="text-base font-semibold">
                {data.title_ar || "رسالة اليوم"}
              </p>
              {data.body_ar && (
                <p className="text-sm text-muted-foreground mt-1.5">
                  {data.body_ar}
                </p>
              )}
            </div>
          </div>
        </div>
      </PreviewWrapper>
    );
  }

  // Full screen preview
  if (data.message_type === "full_screen") {
    return (
      <PreviewWrapper label="معاينة ملء الشاشة">
        <div
          className="rounded-2xl p-8 min-h-[280px] min-w-[280px] flex flex-col items-center justify-center"
          style={bgStyle}
        >
          <div className="w-24 h-24 rounded-full bg-white/20 flex items-center justify-center mb-5">
            <Icon className="h-12 w-12" color={textColor} />
          </div>
          <h2 className="text-xl font-bold text-center mb-3" style={{ color: textColor }}>
            {data.title_ar || "عنوان الشاشة"}
          </h2>
          {data.body_ar && (
            <p className="text-base text-center opacity-80 mb-5" style={{ color: textColor }}>
              {data.body_ar}
            </p>
          )}
          {data.cta_text_ar && (
            <button className="px-8 py-3 bg-white/20 rounded-xl text-base font-medium">
              <span style={{ color: textColor }}>{data.cta_text_ar}</span>
            </button>
          )}
        </div>
      </PreviewWrapper>
    );
  }

  // Default fallback
  return (
    <PreviewWrapper label="معاينة">
      <div className="border rounded-xl p-5 flex items-center gap-4 min-w-[280px]">
        <Icon className="h-6 w-6 text-muted-foreground" />
        <span className="text-base">{data.title_ar || "عنوان الرسالة"}</span>
      </div>
    </PreviewWrapper>
  );
}
