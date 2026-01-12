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

// Phone dimensions (iPhone 14 logical pixels @ 0.5x scale for preview)
// Original: 390 × 844px, displayed at: 195 × 422px
const PHONE_WIDTH = 195;
const PHONE_HEIGHT = 422;

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
  const getBackgroundStyle = () => {
    if (isThemeMode) {
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
  const getTextColor = () => {
    if (isThemeMode) {
      return selectedTheme?.text || "#ffffff";
    }
    return data.text_color || "#ffffff";
  };

  const bgStyle = getBackgroundStyle();
  const textColor = getTextColor();

  // Phone Frame Preview Wrapper - no transform, all dimensions pre-halved
  const PhoneFrame = ({
    children,
    label,
    dimensionLabel,
    position = "top", // top, center, bottom
  }: {
    children: React.ReactNode;
    label: string;
    dimensionLabel: string;
    position?: "top" | "center" | "bottom";
  }) => {
    const screenBg = isThemeMode && selectedTheme ? selectedTheme.bg : "#f5f5f5";

    return (
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

        {/* Phone frame container */}
        <div className="flex justify-center">
          <div
            className="relative bg-gray-900 shadow-2xl"
            style={{
              width: PHONE_WIDTH + 16,
              height: PHONE_HEIGHT + 16,
              borderRadius: 20,
              padding: 8,
            }}
          >
            {/* Dynamic Island */}
            <div
              className="absolute bg-black rounded-full z-10"
              style={{
                width: 30,
                height: 10,
                top: 14,
                left: "50%",
                transform: "translateX(-50%)",
              }}
            />

            {/* Screen */}
            <div
              style={{
                width: PHONE_WIDTH,
                height: PHONE_HEIGHT,
                borderRadius: 16,
                overflow: "hidden",
                background: screenBg,
              }}
            >
              {/* Safe area + content positioning */}
              <div
                className="h-full flex flex-col"
                style={{
                  paddingTop: 30, // 60 * 0.5
                  paddingBottom: 17, // 34 * 0.5
                  paddingLeft: 8, // 16 * 0.5
                  paddingRight: 8,
                }}
              >
                {position === "top" && (
                  <div className="w-full">{children}</div>
                )}
                {position === "center" && (
                  <div className="flex-1 flex items-center justify-center">
                    {children}
                  </div>
                )}
                {position === "bottom" && (
                  <div className="flex-1 flex items-end pb-2">
                    <div className="w-full">{children}</div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Dimension info */}
        <p className="text-xs text-muted-foreground text-center">
          {dimensionLabel}
        </p>
      </div>
    );
  };

  // Banner preview - 60px height (120 * 0.5), full width
  if (data.message_type === "banner") {
    // Image banner variant
    if (data.image_url) {
      return (
        <PhoneFrame label="معاينة البانر" dimensionLabel="358 × 120px" position="top">
          <div
            className="w-full overflow-hidden relative"
            style={{ height: 60, borderRadius: 6 }}
          >
            <img
              src={data.image_url}
              alt=""
              className="w-full h-full object-cover"
            />
            {(data.image_overlay_opacity ?? 0) > 0 && (
              <div
                className="absolute inset-0"
                style={{
                  background: `linear-gradient(to top, rgba(0,0,0,${(data.image_overlay_opacity ?? 0.3) * 2}) 0%, rgba(0,0,0,${(data.image_overlay_opacity ?? 0.3) * 0.5}) 100%)`,
                }}
              />
            )}
            <div className="absolute bottom-0 left-0 right-0 p-1.5">
              <p className="text-[10px] font-bold text-white leading-tight">
                {data.title_ar || "عنوان البانر"}
              </p>
              {data.body_ar && (
                <p className="text-[8px] text-white/90 mt-0.5 leading-tight">{data.body_ar}</p>
              )}
            </div>
            {data.is_dismissible && (
              <button className="absolute top-1 right-1 p-0.5 bg-black/40 rounded-full">
                <X className="h-2 w-2 text-white/90" />
              </button>
            )}
          </div>
        </PhoneFrame>
      );
    }

    // Glassmorphic banner variant
    return (
      <PhoneFrame label="معاينة البانر" dimensionLabel="358 × auto" position="top">
        <div
          className="w-full flex items-center gap-1.5"
          style={{
            ...bgStyle,
            padding: "6px 7px",
            borderRadius: 6,
          }}
        >
          <div
            className="rounded-full bg-white/20 flex items-center justify-center shrink-0"
            style={{ width: 18, height: 18 }}
          >
            <Icon style={{ width: 9, height: 9 }} color={textColor} />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-[10px] font-semibold leading-tight" style={{ color: textColor }}>
              {data.title_ar || "عنوان البانر"}
            </p>
            {data.body_ar && (
              <p className="text-[8px] opacity-80 leading-tight" style={{ color: textColor }}>
                {data.body_ar}
              </p>
            )}
          </div>
          <ChevronLeft style={{ width: 8, height: 8, opacity: 0.6 }} color={textColor} />
        </div>
      </PhoneFrame>
    );
  }

  // Tooltip preview - pill shape (halved dimensions)
  if (data.message_type === "tooltip") {
    return (
      <PhoneFrame label="معاينة التلميح" dimensionLabel="auto × auto" position="top">
        <div className="flex justify-center">
          <div
            className="inline-flex items-center gap-1"
            style={{
              ...bgStyle,
              padding: "5px 7px",
              borderRadius: 25,
            }}
          >
            <Icon style={{ width: 9, height: 9 }} color={textColor} />
            <span className="text-[7px] font-medium" style={{ color: textColor }}>
              {data.title_ar || "نص التلميح"}
            </span>
          </div>
        </div>
      </PhoneFrame>
    );
  }

  // Modal preview - 160px width (320 * 0.5), centered
  if (data.message_type === "modal") {
    return (
      <PhoneFrame label="معاينة النافذة المنبثقة" dimensionLabel="320 × auto" position="center">
        <div
          className="bg-white dark:bg-gray-900 relative overflow-hidden shadow-xl"
          style={{ width: 160, borderRadius: 14 }}
        >
          {/* Banner image - 64px (128 * 0.5) */}
          {data.image_url && (
            <div className="w-full relative overflow-hidden" style={{ height: 64 }}>
              <img
                src={data.image_url}
                alt=""
                className="w-full h-full object-cover"
              />
              {(data.image_overlay_opacity ?? 0) > 0 && (
                <div
                  className="absolute inset-0 bg-black"
                  style={{ opacity: data.image_overlay_opacity ?? 0.3 }}
                />
              )}
            </div>
          )}
          {data.is_dismissible && (
            <button
              className="absolute p-1 rounded-full bg-gray-100 dark:bg-gray-800"
              style={{ top: 6, left: 6 }}
            >
              <X style={{ width: 9, height: 9 }} className="text-gray-500" />
            </button>
          )}
          <div className="flex flex-col items-center gap-2 p-3">
            {/* Hero icon - 44px (88 * 0.5) */}
            {data.graphic_type === "illustration" && data.illustration_url ? (
              <div className="rounded-lg overflow-hidden" style={{ width: 44, height: 44 }}>
                <img
                  src={data.illustration_url}
                  alt=""
                  className="w-full h-full object-cover"
                />
              </div>
            ) : (
              <div
                className="rounded-lg flex items-center justify-center"
                style={{ ...bgStyle, width: 44, height: 44 }}
              >
                <Icon style={{ width: 22, height: 22 }} color={textColor} />
              </div>
            )}
            <h3 className="text-[9px] font-semibold text-center text-gray-900 dark:text-white">
              {data.title_ar || "عنوان النافذة"}
            </h3>
            {data.body_ar && (
              <p className="text-[7px] text-gray-500 dark:text-gray-400 text-center">
                {data.body_ar}
              </p>
            )}
            {data.cta_text_ar && (
              <button
                className="w-full py-1.5 rounded-md text-[7px] font-medium"
                style={bgStyle}
              >
                <span style={{ color: textColor }}>{data.cta_text_ar}</span>
              </button>
            )}
          </div>
        </div>
      </PhoneFrame>
    );
  }

  // Bottom sheet preview - full width (halved dimensions)
  if (data.message_type === "bottom_sheet") {
    return (
      <PhoneFrame label="معاينة الشريط السفلي" dimensionLabel="390 × auto" position="bottom">
        <div
          className="bg-white dark:bg-gray-900 overflow-hidden shadow-xl"
          style={{ borderTopLeftRadius: 12, borderTopRightRadius: 12 }}
        >
          {/* Banner image - 48px (96 * 0.5) */}
          {data.image_url && (
            <div className="w-full relative overflow-hidden" style={{ height: 48 }}>
              <img
                src={data.image_url}
                alt=""
                className="w-full h-full object-cover"
              />
              {(data.image_overlay_opacity ?? 0) > 0 && (
                <div
                  className="absolute inset-0 bg-black"
                  style={{ opacity: data.image_overlay_opacity ?? 0.3 }}
                />
              )}
            </div>
          )}
          <div style={{ padding: 10 }}>
            {/* Drag handle - 18x2 (36x4 * 0.5) */}
            <div className="flex justify-center mb-2">
              <div
                className="bg-gray-300 dark:bg-gray-600 rounded-full"
                style={{ width: 18, height: 2 }}
              />
            </div>
            <div className="flex items-start gap-2">
              {/* Icon - 28px (56 * 0.5) */}
              {data.graphic_type === "illustration" && data.illustration_url ? (
                <div className="rounded-md overflow-hidden shrink-0" style={{ width: 28, height: 28 }}>
                  <img
                    src={data.illustration_url}
                    alt=""
                    className="w-full h-full object-cover"
                  />
                </div>
              ) : (
                <div
                  className="rounded-md flex items-center justify-center shrink-0"
                  style={{ ...bgStyle, width: 28, height: 28 }}
                >
                  <Icon style={{ width: 14, height: 14 }} color={textColor} />
                </div>
              )}
              <div className="flex-1 min-w-0">
                <h3 className="text-[8px] font-semibold text-gray-900 dark:text-white">
                  {data.title_ar || "عنوان الشريط"}
                </h3>
                {data.body_ar && (
                  <p className="text-[7px] text-gray-500 dark:text-gray-400 mt-0.5 truncate">
                    {data.body_ar}
                  </p>
                )}
              </div>
            </div>
            {data.cta_text_ar && (
              <button
                className="w-full mt-2 rounded-md text-[7px] font-medium flex items-center justify-center"
                style={{ ...bgStyle, height: 26 }}
              >
                <span style={{ color: textColor }}>{data.cta_text_ar}</span>
              </button>
            )}
          </div>
        </div>
      </PhoneFrame>
    );
  }

  // MOTD preview (halved dimensions)
  if (data.message_type === "motd") {
    return (
      <PhoneFrame label="معاينة رسالة اليوم" dimensionLabel="358 × auto" position="top">
        <div
          className="bg-white dark:bg-gray-900 rounded-lg shadow-sm"
          style={{ borderRight: "2px solid var(--primary, #22c55e)", padding: 10 }}
        >
          <div className="flex items-start gap-1.5">
            <Icon
              style={{ width: 12, height: 12, marginTop: 1 }}
              className="text-primary shrink-0"
            />
            <div>
              <p className="text-[8px] font-semibold text-gray-900 dark:text-white">
                {data.title_ar || "رسالة اليوم"}
              </p>
              {data.body_ar && (
                <p className="text-[7px] text-gray-500 dark:text-gray-400 mt-0.5">
                  {data.body_ar}
                </p>
              )}
            </div>
          </div>
        </div>
      </PhoneFrame>
    );
  }

  // Full screen preview - fills entire phone (halved dimensions)
  if (data.message_type === "full_screen") {
    const fullScreenBg = data.image_url
      ? "#000"
      : isThemeMode && selectedTheme
        ? selectedTheme.bg
        : (data.background_gradient
          ? `linear-gradient(135deg, ${data.background_gradient.start}, ${data.background_gradient.end})`
          : data.background_color || "#1B5E20");

    return (
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <p className="text-sm font-medium">معاينة ملء الشاشة</p>
          {isThemeMode && (
            <span className="text-xs text-emerald-600 bg-emerald-500/10 px-2 py-1 rounded-full">
              يتكيف مع الثيم
            </span>
          )}
        </div>

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

        <div className="flex justify-center">
          <div
            className="relative bg-gray-900 shadow-2xl"
            style={{
              width: PHONE_WIDTH + 16,
              height: PHONE_HEIGHT + 16,
              borderRadius: 20,
              padding: 8,
            }}
          >
            {/* Dynamic Island */}
            <div
              className="absolute bg-black rounded-full z-10"
              style={{
                width: 30,
                height: 10,
                top: 14,
                left: "50%",
                transform: "translateX(-50%)",
              }}
            />

            {/* Screen container - fills entire phone with fullscreen bg */}
            <div
              style={{
                width: PHONE_WIDTH,
                height: PHONE_HEIGHT,
                borderRadius: 16,
                overflow: "hidden",
                background: fullScreenBg,
                position: "relative",
              }}
            >
              {/* Background image */}
              {data.image_url && (
                <>
                  <img
                    src={data.image_url}
                    alt=""
                    style={{
                      position: "absolute",
                      inset: 0,
                      width: "100%",
                      height: "100%",
                      objectFit: "cover",
                    }}
                  />
                  {(data.image_overlay_opacity ?? 0) > 0 && (
                    <div
                      style={{
                        position: "absolute",
                        inset: 0,
                        background: "black",
                        opacity: data.image_overlay_opacity ?? 0.3,
                      }}
                    />
                  )}
                </>
              )}

              {/* Content - all dimensions halved */}
              <div
                className="h-full flex flex-col items-center justify-center relative"
                style={{ padding: "0 16px" }}
              >
                {/* Close button - 22px (44 * 0.5) */}
                <button
                  className="absolute rounded-full bg-white/20 backdrop-blur flex items-center justify-center"
                  style={{ top: 30, left: 8, width: 22, height: 22 }}
                >
                  <X style={{ width: 11, height: 11 }} color="white" />
                </button>

                {/* Hero icon - 60px (120 * 0.5) */}
                {data.graphic_type === "illustration" && data.illustration_url ? (
                  <div className="rounded-full overflow-hidden mb-4" style={{ width: 60, height: 60 }}>
                    <img
                      src={data.illustration_url}
                      alt=""
                      className="w-full h-full object-cover"
                    />
                  </div>
                ) : (
                  <div
                    className="rounded-full bg-white/20 flex items-center justify-center mb-4"
                    style={{ width: 60, height: 60 }}
                  >
                    <Icon style={{ width: 30, height: 30 }} color={textColor} />
                  </div>
                )}

                <h2
                  className="text-[12px] font-bold text-center mb-2"
                  style={{ color: textColor }}
                >
                  {data.title_ar || "عنوان الشاشة"}
                </h2>
                {data.body_ar && (
                  <p
                    className="text-[8px] text-center opacity-90 mb-4"
                    style={{ color: textColor }}
                  >
                    {data.body_ar}
                  </p>
                )}

                {/* CTA Button - 28px height (56 * 0.5) */}
                {data.cta_text_ar && (
                  <button
                    className="w-full rounded-lg bg-white/25 backdrop-blur flex items-center justify-center"
                    style={{ height: 28 }}
                  >
                    <span className="text-[8px] font-bold" style={{ color: textColor }}>
                      {data.cta_text_ar}
                    </span>
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>

        <p className="text-xs text-muted-foreground text-center">
          390 × 844px (ملء الشاشة)
        </p>
      </div>
    );
  }

  // Default fallback (halved dimensions)
  return (
    <PhoneFrame label="معاينة" dimensionLabel="358 × auto" position="top">
      <div className="bg-white dark:bg-gray-900 rounded-md p-2 flex items-center gap-1.5 shadow-sm">
        <Icon style={{ width: 12, height: 12 }} className="text-gray-400" />
        <span className="text-[8px] text-gray-900 dark:text-white">
          {data.title_ar || "عنوان الرسالة"}
        </span>
      </div>
    </PhoneFrame>
  );
}
