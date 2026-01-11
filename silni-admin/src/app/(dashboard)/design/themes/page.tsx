"use client";

import { useState, useEffect, useMemo } from "react";
import {
  useThemes,
  useCreateTheme,
  useUpdateTheme,
  useDeleteTheme,
} from "@/hooks/use-design-system";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Plus, Pencil, Trash2, Sun, Moon, Crown, Sparkles, Check, ChevronDown, Code, Copy, RotateCcw, Palette } from "lucide-react";
import type { AdminTheme } from "@/types/database";

// Color keys that match ThemeColors in Flutter app
const THEME_COLOR_KEYS = {
  main: [
    { key: "primary", label: "الأساسي", labelEn: "Primary" },
    { key: "primary_light", label: "الأساسي فاتح", labelEn: "Primary Light" },
    { key: "primary_dark", label: "الأساسي داكن", labelEn: "Primary Dark" },
    { key: "secondary", label: "الثانوي", labelEn: "Secondary" },
    { key: "accent", label: "التمييز", labelEn: "Accent" },
  ],
  background: [
    { key: "background_1", label: "الخلفية 1", labelEn: "Background 1" },
    { key: "background_2", label: "الخلفية 2", labelEn: "Background 2" },
    { key: "background_3", label: "الخلفية 3", labelEn: "Background 3" },
    { key: "surface", label: "السطح", labelEn: "Surface" },
    { key: "surface_variant", label: "السطح البديل", labelEn: "Surface Variant" },
  ],
  text: [
    { key: "text_primary", label: "النص الأساسي", labelEn: "Text Primary" },
    { key: "text_secondary", label: "النص الثانوي", labelEn: "Text Secondary" },
    { key: "text_hint", label: "النص التلميح", labelEn: "Text Hint" },
    { key: "text_on_gradient", label: "النص على التدرج", labelEn: "Text on Gradient" },
    { key: "on_primary", label: "على الأساسي", labelEn: "On Primary" },
    { key: "on_secondary", label: "على الثانوي", labelEn: "On Secondary" },
    { key: "on_surface", label: "على السطح", labelEn: "On Surface" },
    { key: "on_surface_variant", label: "على السطح البديل", labelEn: "On Surface Variant" },
  ],
  glass: [
    { key: "glass_background", label: "خلفية الزجاج", labelEn: "Glass Background" },
    { key: "glass_border", label: "حدود الزجاج", labelEn: "Glass Border" },
    { key: "glass_highlight", label: "توهج الزجاج", labelEn: "Glass Highlight" },
    { key: "card_background", label: "خلفية البطاقة", labelEn: "Card Background" },
    { key: "card_border", label: "حدود البطاقة", labelEn: "Card Border" },
  ],
  utility: [
    { key: "shimmer_base", label: "قاعدة اللمعان", labelEn: "Shimmer Base" },
    { key: "shimmer_highlight", label: "توهج اللمعان", labelEn: "Shimmer Highlight" },
    { key: "divider", label: "الفاصل", labelEn: "Divider" },
    { key: "disabled", label: "معطّل", labelEn: "Disabled" },
  ],
  status: [
    { key: "status_success", label: "نجاح", labelEn: "Success" },
    { key: "status_error", label: "خطأ", labelEn: "Error" },
    { key: "status_warning", label: "تحذير", labelEn: "Warning" },
    { key: "status_info", label: "معلومات", labelEn: "Info" },
  ],
  contact: [
    { key: "contact_excellent", label: "تواصل ممتاز", labelEn: "Excellent Contact" },
    { key: "contact_good", label: "تواصل جيد", labelEn: "Good Contact" },
    { key: "contact_normal", label: "تواصل عادي", labelEn: "Normal Contact" },
    { key: "contact_needs_care", label: "يحتاج رعاية", labelEn: "Needs Care" },
    { key: "contact_critical", label: "حرج", labelEn: "Critical" },
    { key: "contact_elderly", label: "مسن", labelEn: "Elderly" },
    { key: "contact_disabled", label: "ذوي احتياجات", labelEn: "Disabled" },
  ],
  mood: [
    { key: "mood_happy", label: "سعيد", labelEn: "Happy" },
    { key: "mood_neutral", label: "محايد", labelEn: "Neutral" },
    { key: "mood_sad", label: "حزين", labelEn: "Sad" },
    { key: "mood_excited", label: "متحمس", labelEn: "Excited" },
    { key: "mood_calm", label: "هادئ", labelEn: "Calm" },
    { key: "mood_worried", label: "قلق", labelEn: "Worried" },
  ],
  priority: [
    { key: "priority_high", label: "أولوية عالية", labelEn: "High Priority" },
    { key: "priority_medium", label: "أولوية متوسطة", labelEn: "Medium Priority" },
    { key: "priority_low", label: "أولوية منخفضة", labelEn: "Low Priority" },
  ],
  level: [
    { key: "level_1", label: "مستوى 1", labelEn: "Level 1" },
    { key: "level_2", label: "مستوى 2", labelEn: "Level 2" },
    { key: "level_3", label: "مستوى 3", labelEn: "Level 3" },
    { key: "level_4", label: "مستوى 4", labelEn: "Level 4" },
    { key: "level_5", label: "مستوى 5", labelEn: "Level 5" },
    { key: "level_max", label: "المستوى الأقصى", labelEn: "Max Level" },
  ],
};

const GRADIENT_KEYS = [
  { key: "primary", label: "التدرج الأساسي", labelEn: "Primary Gradient" },
  { key: "background", label: "تدرج الخلفية", labelEn: "Background Gradient" },
  { key: "golden", label: "التدرج الذهبي", labelEn: "Golden Gradient" },
  { key: "streak_fire", label: "تدرج النار", labelEn: "Streak Fire" },
  { key: "tier_legendary", label: "تدرج أسطوري", labelEn: "Legendary Tier" },
  { key: "tier_epic", label: "تدرج ملحمي", labelEn: "Epic Tier" },
  { key: "tier_rare", label: "تدرج نادر", labelEn: "Rare Tier" },
  { key: "tier_starter", label: "تدرج مبتدئ", labelEn: "Starter Tier" },
];

// Helper to extract preview colors from a theme
function getThemePreviewColors(theme: AdminTheme): string[] {
  const colors = theme.colors as Record<string, string>;
  const gradients = theme.gradients as Record<string, { colors?: string[] }>;

  // Try to get background gradient colors first
  if (gradients?.background?.colors?.length) {
    return gradients.background.colors.slice(0, 3);
  }

  // Fall back to main colors
  return [
    colors?.primary || colors?.background || "#1A5F5B",
    colors?.secondary || colors?.surface || "#D4A853",
    colors?.accent || colors?.text || "#FFFFFF",
  ];
}

// Color picker component
function ColorPicker({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
}) {
  return (
    <div className="flex items-center gap-2">
      <div className="relative">
        <input
          type="color"
          value={value || "#000000"}
          onChange={(e) => onChange(e.target.value)}
          className="w-10 h-10 rounded-lg border cursor-pointer"
        />
      </div>
      <div className="flex-1">
        <p className="text-sm font-medium">{label}</p>
        <Input
          value={value || ""}
          onChange={(e) => onChange(e.target.value)}
          placeholder="#000000"
          dir="ltr"
          className="h-8 text-xs font-mono mt-1"
        />
      </div>
    </div>
  );
}

// Gradient picker component
function GradientPicker({
  label,
  colors,
  onChange,
}: {
  label: string;
  colors: string[];
  onChange: (colors: string[]) => void;
}) {
  const updateColor = (index: number, value: string) => {
    const newColors = [...colors];
    newColors[index] = value;
    onChange(newColors);
  };

  const addColor = () => {
    onChange([...colors, "#808080"]);
  };

  const removeColor = (index: number) => {
    if (colors.length > 2) {
      onChange(colors.filter((_, i) => i !== index));
    }
  };

  return (
    <div className="space-y-2 p-3 border rounded-lg">
      <p className="text-sm font-medium">{label}</p>
      <div
        className="h-8 rounded-md mb-2"
        style={{
          background: `linear-gradient(to right, ${colors.join(", ")})`,
        }}
      />
      <div className="space-y-2">
        {colors.map((color, index) => (
          <div key={index} className="flex items-center gap-2">
            <input
              type="color"
              value={color}
              onChange={(e) => updateColor(index, e.target.value)}
              className="w-8 h-8 rounded cursor-pointer"
            />
            <Input
              value={color}
              onChange={(e) => updateColor(index, e.target.value)}
              placeholder="#000000"
              dir="ltr"
              className="h-8 text-xs font-mono flex-1"
            />
            {colors.length > 2 && (
              <Button
                variant="ghost"
                size="icon"
                className="h-8 w-8"
                onClick={() => removeColor(index)}
              >
                <Trash2 className="h-3 w-3" />
              </Button>
            )}
          </div>
        ))}
        <Button variant="outline" size="sm" onClick={addColor} className="w-full">
          <Plus className="h-3 w-3 mr-1" /> إضافة لون
        </Button>
      </div>
    </div>
  );
}

type ThemeFormData = Omit<AdminTheme, "id" | "created_at" | "updated_at">;

const defaultFormData: ThemeFormData = {
  theme_key: "",
  display_name_ar: "",
  display_name_en: "",
  is_dark: false,
  colors: {},
  gradients: {},
  shadows: {},
  is_premium: false,
  is_default: false,
  is_active: true,
  preview_image_url: null,
  sort_order: 0,
};

export default function ThemesPage() {
  const { data: themes, isLoading } = useThemes();
  const createTheme = useCreateTheme();
  const updateTheme = useUpdateTheme();
  const deleteTheme = useDeleteTheme();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingTheme, setEditingTheme] = useState<AdminTheme | null>(null);
  const [formData, setFormData] = useState<ThemeFormData>(defaultFormData);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const [colorsJson, setColorsJson] = useState("{}");
  const [gradientsJson, setGradientsJson] = useState("{}");
  const [showReference, setShowReference] = useState(false);
  const [selectedTemplateId, setSelectedTemplateId] = useState<string | null>(null);

  // Get selected template from themes
  const selectedTemplate = useMemo(() => {
    if (!themes || !selectedTemplateId) return themes?.[0] || null;
    return themes.find(t => t.id === selectedTemplateId) || themes[0] || null;
  }, [themes, selectedTemplateId]);

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  // Apply a database theme as a template
  const applyTemplate = (theme: AdminTheme) => {
    setFormData((f) => ({
      ...f,
      colors: { ...(theme.colors as Record<string, string>) },
      gradients: { ...(theme.gradients as Record<string, { colors?: string[] }>) },
    }));
    setColorsJson(JSON.stringify(theme.colors || {}, null, 2));
    setGradientsJson(JSON.stringify(theme.gradients || {}, null, 2));
  };

  // Sync JSON when formData changes (from color pickers)
  useEffect(() => {
    if (Object.keys(formData.colors || {}).length > 0) {
      setColorsJson(JSON.stringify(formData.colors, null, 2));
    }
  }, [formData.colors]);

  useEffect(() => {
    if (Object.keys(formData.gradients || {}).length > 0) {
      setGradientsJson(JSON.stringify(formData.gradients, null, 2));
    }
  }, [formData.gradients]);

  const handleOpenCreate = () => {
    setEditingTheme(null);
    setFormData(defaultFormData);
    setColorsJson("{}");
    setGradientsJson("{}");
    setIsDialogOpen(true);
  };

  const handleOpenEdit = (theme: AdminTheme) => {
    setEditingTheme(theme);
    setFormData({
      theme_key: theme.theme_key,
      display_name_ar: theme.display_name_ar,
      display_name_en: theme.display_name_en || "",
      is_dark: theme.is_dark,
      colors: theme.colors || {},
      gradients: theme.gradients || {},
      shadows: theme.shadows || {},
      is_premium: theme.is_premium,
      is_default: theme.is_default,
      is_active: theme.is_active,
      preview_image_url: theme.preview_image_url,
      sort_order: theme.sort_order,
    });
    setColorsJson(JSON.stringify(theme.colors || {}, null, 2));
    setGradientsJson(JSON.stringify(theme.gradients || {}, null, 2));
    setIsDialogOpen(true);
  };

  const handleSave = () => {
    // Use formData.colors and formData.gradients directly
    // They're already synced from either color pickers or JSON tab
    const data = {
      ...formData,
      display_name_en: formData.display_name_en || null,
    };

    if (editingTheme) {
      updateTheme.mutate(
        { id: editingTheme.id, ...data },
        { onSuccess: () => setIsDialogOpen(false) }
      );
    } else {
      createTheme.mutate(data, { onSuccess: () => setIsDialogOpen(false) });
    }
  };

  const handleDelete = (id: string) => {
    deleteTheme.mutate(id, { onSuccess: () => setDeleteConfirm(null) });
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-4 grid-cols-3">
          {[1, 2, 3].map((i) => (
            <Skeleton key={i} className="h-64" />
          ))}
        </div>
      </div>
    );
  }

  const lightThemes = themes?.filter((t) => !t.is_dark) || [];
  const darkThemes = themes?.filter((t) => t.is_dark) || [];

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">الثيمات</h1>
          <p className="text-muted-foreground mt-1">
            إدارة ثيمات التطبيق (فاتح/داكن)
          </p>
        </div>
        <Button onClick={handleOpenCreate}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة ثيم
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6 text-center">
            <Sun className="h-8 w-8 mx-auto text-yellow-500 mb-2" />
            <p className="text-2xl font-bold">{lightThemes.length}</p>
            <p className="text-sm text-muted-foreground">ثيمات فاتحة</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6 text-center">
            <Moon className="h-8 w-8 mx-auto text-indigo-500 mb-2" />
            <p className="text-2xl font-bold">{darkThemes.length}</p>
            <p className="text-sm text-muted-foreground">ثيمات داكنة</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6 text-center">
            <Crown className="h-8 w-8 mx-auto text-yellow-500 mb-2" />
            <p className="text-2xl font-bold">
              {themes?.filter((t) => t.is_premium).length || 0}
            </p>
            <p className="text-sm text-muted-foreground">ثيمات مميزة</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6 text-center">
            <Sparkles className="h-8 w-8 mx-auto text-blue-500 mb-2" />
            <p className="text-2xl font-bold">{themes?.length || 0}</p>
            <p className="text-sm text-muted-foreground">إجمالي الثيمات</p>
          </CardContent>
        </Card>
      </div>

      {/* Quick Reference - Database Themes */}
      {themes && themes.length > 0 && (
        <Collapsible open={showReference} onOpenChange={setShowReference}>
          <Card>
            <CollapsibleTrigger asChild>
              <CardHeader className="cursor-pointer hover:bg-muted/50 transition-colors">
                <CardTitle className="flex items-center gap-2">
                  <Palette className="h-5 w-5 text-blue-500" />
                  مرجع الثيمات المسجلة ({themes.length} ثيم)
                  <ChevronDown className={`h-4 w-4 mr-auto transition-transform ${showReference ? "rotate-180" : ""}`} />
                </CardTitle>
                <CardDescription>
                  اختر ثيم موجود كقالب أو انسخ ألوانه
                </CardDescription>
              </CardHeader>
            </CollapsibleTrigger>
            <CollapsibleContent>
              <CardContent className="space-y-4">
                {/* Theme Selector Grid - Dynamic from DB */}
                <div className="grid grid-cols-4 md:grid-cols-6 gap-2">
                  {themes.map((theme) => {
                    const previewColors = getThemePreviewColors(theme);
                    const isSelected = selectedTemplate?.id === theme.id;
                    return (
                      <div
                        key={theme.id}
                        className={`flex flex-col items-center p-3 border rounded-lg cursor-pointer transition-all ${
                          isSelected ? "ring-2 ring-primary bg-muted" : "hover:bg-muted/50"
                        }`}
                        onClick={() => setSelectedTemplateId(theme.id)}
                      >
                        {/* Gradient Preview */}
                        <div
                          className="w-full h-10 rounded-md mb-2"
                          style={{
                            background: `linear-gradient(to right, ${previewColors.join(", ")})`,
                          }}
                        />
                        <span className="text-xs font-medium text-center truncate w-full">{theme.display_name_ar}</span>
                        <span className="text-[10px] text-muted-foreground truncate w-full text-center">{theme.display_name_en || theme.theme_key}</span>
                        <div className="flex items-center gap-1 mt-1">
                          {theme.is_dark && <Moon className="h-3 w-3 text-muted-foreground" />}
                          {theme.is_premium && <Crown className="h-3 w-3 text-yellow-500" />}
                          {isSelected && <Check className="h-3 w-3 text-primary" />}
                        </div>
                      </div>
                    );
                  })}
                </div>

                {/* Selected Theme Colors */}
                {selectedTemplate && (
                  <div className="border-t pt-4">
                    <p className="text-sm font-medium mb-3">
                      ألوان {selectedTemplate.display_name_ar} ({selectedTemplate.display_name_en || selectedTemplate.theme_key})
                    </p>

                    {/* Show all available colors from this theme */}
                    <div className="grid grid-cols-5 md:grid-cols-8 gap-2">
                      {Object.entries((selectedTemplate.colors as Record<string, string>) || {}).map(([key, hex]) => (
                        <div
                          key={key}
                          className="flex flex-col items-center p-2 border rounded-lg cursor-pointer hover:bg-muted/50"
                          onClick={() => copyToClipboard(hex)}
                          title={`${key}: ${hex} - انقر للنسخ`}
                        >
                          <div
                            className="w-8 h-8 rounded-lg border mb-1"
                            style={{ backgroundColor: hex }}
                          />
                          <span className="text-[9px] font-mono truncate w-full text-center">{hex}</span>
                          <span className="text-[9px] text-muted-foreground truncate w-full text-center">{key}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Action Buttons */}
                {selectedTemplate && (
                  <div className="flex flex-wrap gap-2 pt-2 border-t">
                    <Button
                      variant="default"
                      size="sm"
                      onClick={() => {
                        applyTemplate(selectedTemplate);
                        setIsDialogOpen(true);
                      }}
                    >
                      <RotateCcw className="h-3 w-3 ml-1" />
                      استخدم كقالب جديد
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => copyToClipboard(JSON.stringify(selectedTemplate.colors, null, 2))}
                    >
                      <Copy className="h-3 w-3 ml-1" />
                      نسخ الألوان JSON
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => copyToClipboard(JSON.stringify(selectedTemplate.gradients, null, 2))}
                    >
                      <Copy className="h-3 w-3 ml-1" />
                      نسخ التدرجات JSON
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => copyToClipboard(JSON.stringify({
                        colors: selectedTemplate.colors,
                        gradients: selectedTemplate.gradients,
                      }, null, 2))}
                    >
                      <Copy className="h-3 w-3 ml-1" />
                      نسخ الكل
                    </Button>
                  </div>
                )}

                {/* Tips */}
                <div className="bg-muted/50 p-3 rounded-lg text-sm space-y-1">
                  <p className="font-medium">نصائح:</p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-1">
                    <li>التدرجات اختيارية - إذا لم تحددها، ستُولّد تلقائياً من الألوان</li>
                    <li>الشفافية: 26 = 15%، 33 = 20%، 4D = 30%، 80 = 50%، B3 = 70%</li>
                    <li>للثيمات الداكنة: استخدم ألوان أفتح للنصوص (عادة أبيض #FFFFFF)</li>
                  </ul>
                </div>
              </CardContent>
            </CollapsibleContent>
          </Card>
        </Collapsible>
      )}

      {/* Light Themes */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Sun className="h-5 w-5 text-yellow-500" />
            الثيمات الفاتحة
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-3 gap-4">
            {lightThemes.map((theme) => (
              <ThemeCard
                key={theme.id}
                theme={theme}
                onEdit={handleOpenEdit}
                onDelete={setDeleteConfirm}
              />
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Dark Themes */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Moon className="h-5 w-5 text-indigo-500" />
            الثيمات الداكنة
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-3 gap-4">
            {darkThemes.map((theme) => (
              <ThemeCard
                key={theme.id}
                theme={theme}
                onEdit={handleOpenEdit}
                onDelete={setDeleteConfirm}
              />
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Create/Edit Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {editingTheme ? "تعديل الثيم" : "إضافة ثيم جديد"}
            </DialogTitle>
            <DialogDescription>
              {editingTheme ? "تعديل إعدادات الثيم" : "إضافة ثيم جديد للتطبيق"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            {/* Basic Info */}
            <div className="space-y-2">
              <Label>المفتاح (theme_key)</Label>
              <Input
                value={formData.theme_key}
                onChange={(e) =>
                  setFormData((f) => ({ ...f, theme_key: e.target.value }))
                }
                placeholder="silni_light"
                dir="ltr"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الاسم (عربي)</Label>
                <Input
                  value={formData.display_name_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_ar: e.target.value }))
                  }
                  placeholder="صِلني الفاتح"
                />
              </div>
              <div className="space-y-2">
                <Label>الاسم (إنجليزي)</Label>
                <Input
                  value={formData.display_name_en || ""}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_en: e.target.value }))
                  }
                  placeholder="Silni Light"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>رابط صورة المعاينة</Label>
              <Input
                value={formData.preview_image_url || ""}
                onChange={(e) =>
                  setFormData((f) => ({
                    ...f,
                    preview_image_url: e.target.value || null,
                  }))
                }
                placeholder="https://..."
                dir="ltr"
              />
            </div>

            {/* Reset to Template - From Database */}
            {themes && themes.length > 0 && (
              <div className="border rounded-lg p-3 bg-muted/30">
                <div className="flex items-center gap-2 mb-2">
                  <RotateCcw className="h-4 w-4 text-muted-foreground" />
                  <Label className="text-sm font-medium">تحميل ألوان من ثيم موجود</Label>
                </div>
                <div className="flex items-center gap-2">
                  <div className="flex-1 grid grid-cols-4 md:grid-cols-7 gap-1">
                    {themes.map((theme) => {
                      const previewColors = getThemePreviewColors(theme);
                      return (
                        <div
                          key={theme.id}
                          className={`flex flex-col items-center p-1.5 border rounded cursor-pointer transition-all ${
                            selectedTemplate?.id === theme.id ? "ring-2 ring-primary bg-background" : "hover:bg-background"
                          }`}
                          onClick={() => setSelectedTemplateId(theme.id)}
                          title={theme.display_name_en || theme.theme_key}
                        >
                          <div
                            className="w-full h-4 rounded"
                            style={{
                              background: `linear-gradient(to right, ${previewColors.join(", ")})`,
                            }}
                          />
                          <span className="text-[9px] mt-0.5 truncate w-full text-center">{theme.display_name_ar}</span>
                        </div>
                      );
                    })}
                  </div>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => selectedTemplate && applyTemplate(selectedTemplate)}
                    disabled={!selectedTemplate}
                    className="whitespace-nowrap"
                  >
                    <Palette className="h-3 w-3 ml-1" />
                    تحميل
                  </Button>
                </div>
              </div>
            )}

            {/* Colors & Gradients Tabs */}
            <Tabs defaultValue="colors" className="w-full">
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="colors">الألوان</TabsTrigger>
                <TabsTrigger value="gradients">التدرجات</TabsTrigger>
                <TabsTrigger value="json">
                  <Code className="h-3 w-3 mr-1" />
                  JSON
                </TabsTrigger>
              </TabsList>

              {/* Colors Tab - Visual Color Pickers */}
              <TabsContent value="colors" className="space-y-4 max-h-[40vh] overflow-y-auto">
                {/* Main Colors */}
                <Collapsible defaultOpen>
                  <CollapsibleTrigger className="flex items-center gap-2 w-full p-2 bg-muted rounded-lg hover:bg-muted/80">
                    <ChevronDown className="h-4 w-4" />
                    <span className="font-medium">الألوان الأساسية</span>
                  </CollapsibleTrigger>
                  <CollapsibleContent className="grid grid-cols-2 gap-3 pt-3">
                    {THEME_COLOR_KEYS.main.map(({ key, label }) => (
                      <ColorPicker
                        key={key}
                        label={label}
                        value={(formData.colors as Record<string, string>)?.[key] || ""}
                        onChange={(value) =>
                          setFormData((f) => ({
                            ...f,
                            colors: { ...f.colors, [key]: value },
                          }))
                        }
                      />
                    ))}
                  </CollapsibleContent>
                </Collapsible>

                {/* Background Colors */}
                <Collapsible>
                  <CollapsibleTrigger className="flex items-center gap-2 w-full p-2 bg-muted rounded-lg hover:bg-muted/80">
                    <ChevronDown className="h-4 w-4" />
                    <span className="font-medium">ألوان الخلفية</span>
                  </CollapsibleTrigger>
                  <CollapsibleContent className="grid grid-cols-2 gap-3 pt-3">
                    {THEME_COLOR_KEYS.background.map(({ key, label }) => (
                      <ColorPicker
                        key={key}
                        label={label}
                        value={(formData.colors as Record<string, string>)?.[key] || ""}
                        onChange={(value) =>
                          setFormData((f) => ({
                            ...f,
                            colors: { ...f.colors, [key]: value },
                          }))
                        }
                      />
                    ))}
                  </CollapsibleContent>
                </Collapsible>

                {/* Text Colors */}
                <Collapsible>
                  <CollapsibleTrigger className="flex items-center gap-2 w-full p-2 bg-muted rounded-lg hover:bg-muted/80">
                    <ChevronDown className="h-4 w-4" />
                    <span className="font-medium">ألوان النص</span>
                  </CollapsibleTrigger>
                  <CollapsibleContent className="grid grid-cols-2 gap-3 pt-3">
                    {THEME_COLOR_KEYS.text.map(({ key, label }) => (
                      <ColorPicker
                        key={key}
                        label={label}
                        value={(formData.colors as Record<string, string>)?.[key] || ""}
                        onChange={(value) =>
                          setFormData((f) => ({
                            ...f,
                            colors: { ...f.colors, [key]: value },
                          }))
                        }
                      />
                    ))}
                  </CollapsibleContent>
                </Collapsible>

                {/* Glass & Card Colors */}
                <Collapsible>
                  <CollapsibleTrigger className="flex items-center gap-2 w-full p-2 bg-muted rounded-lg hover:bg-muted/80">
                    <ChevronDown className="h-4 w-4" />
                    <span className="font-medium">ألوان الزجاج والبطاقات</span>
                  </CollapsibleTrigger>
                  <CollapsibleContent className="grid grid-cols-2 gap-3 pt-3">
                    {THEME_COLOR_KEYS.glass.map(({ key, label }) => (
                      <ColorPicker
                        key={key}
                        label={label}
                        value={(formData.colors as Record<string, string>)?.[key] || ""}
                        onChange={(value) =>
                          setFormData((f) => ({
                            ...f,
                            colors: { ...f.colors, [key]: value },
                          }))
                        }
                      />
                    ))}
                  </CollapsibleContent>
                </Collapsible>

                {/* Utility Colors */}
                <Collapsible>
                  <CollapsibleTrigger className="flex items-center gap-2 w-full p-2 bg-muted rounded-lg hover:bg-muted/80">
                    <ChevronDown className="h-4 w-4" />
                    <span className="font-medium">ألوان أخرى</span>
                  </CollapsibleTrigger>
                  <CollapsibleContent className="grid grid-cols-2 gap-3 pt-3">
                    {THEME_COLOR_KEYS.utility.map(({ key, label }) => (
                      <ColorPicker
                        key={key}
                        label={label}
                        value={(formData.colors as Record<string, string>)?.[key] || ""}
                        onChange={(value) =>
                          setFormData((f) => ({
                            ...f,
                            colors: { ...f.colors, [key]: value },
                          }))
                        }
                      />
                    ))}
                  </CollapsibleContent>
                </Collapsible>

                {/* Status Colors */}
                <Collapsible>
                  <CollapsibleTrigger className="flex items-center gap-2 w-full p-2 bg-muted rounded-lg hover:bg-muted/80">
                    <ChevronDown className="h-4 w-4" />
                    <span className="font-medium">ألوان الحالة</span>
                  </CollapsibleTrigger>
                  <CollapsibleContent className="grid grid-cols-2 gap-3 pt-3">
                    {THEME_COLOR_KEYS.status.map(({ key, label }) => (
                      <ColorPicker
                        key={key}
                        label={label}
                        value={(formData.colors as Record<string, string>)?.[key] || ""}
                        onChange={(value) =>
                          setFormData((f) => ({
                            ...f,
                            colors: { ...f.colors, [key]: value },
                          }))
                        }
                      />
                    ))}
                  </CollapsibleContent>
                </Collapsible>

                {/* Contact Colors */}
                <Collapsible>
                  <CollapsibleTrigger className="flex items-center gap-2 w-full p-2 bg-muted rounded-lg hover:bg-muted/80">
                    <ChevronDown className="h-4 w-4" />
                    <span className="font-medium">ألوان التواصل</span>
                  </CollapsibleTrigger>
                  <CollapsibleContent className="grid grid-cols-2 gap-3 pt-3">
                    {THEME_COLOR_KEYS.contact.map(({ key, label }) => (
                      <ColorPicker
                        key={key}
                        label={label}
                        value={(formData.colors as Record<string, string>)?.[key] || ""}
                        onChange={(value) =>
                          setFormData((f) => ({
                            ...f,
                            colors: { ...f.colors, [key]: value },
                          }))
                        }
                      />
                    ))}
                  </CollapsibleContent>
                </Collapsible>

                {/* Mood Colors */}
                <Collapsible>
                  <CollapsibleTrigger className="flex items-center gap-2 w-full p-2 bg-muted rounded-lg hover:bg-muted/80">
                    <ChevronDown className="h-4 w-4" />
                    <span className="font-medium">ألوان المزاج</span>
                  </CollapsibleTrigger>
                  <CollapsibleContent className="grid grid-cols-2 gap-3 pt-3">
                    {THEME_COLOR_KEYS.mood.map(({ key, label }) => (
                      <ColorPicker
                        key={key}
                        label={label}
                        value={(formData.colors as Record<string, string>)?.[key] || ""}
                        onChange={(value) =>
                          setFormData((f) => ({
                            ...f,
                            colors: { ...f.colors, [key]: value },
                          }))
                        }
                      />
                    ))}
                  </CollapsibleContent>
                </Collapsible>

                {/* Priority Colors */}
                <Collapsible>
                  <CollapsibleTrigger className="flex items-center gap-2 w-full p-2 bg-muted rounded-lg hover:bg-muted/80">
                    <ChevronDown className="h-4 w-4" />
                    <span className="font-medium">ألوان الأولوية</span>
                  </CollapsibleTrigger>
                  <CollapsibleContent className="grid grid-cols-2 gap-3 pt-3">
                    {THEME_COLOR_KEYS.priority.map(({ key, label }) => (
                      <ColorPicker
                        key={key}
                        label={label}
                        value={(formData.colors as Record<string, string>)?.[key] || ""}
                        onChange={(value) =>
                          setFormData((f) => ({
                            ...f,
                            colors: { ...f.colors, [key]: value },
                          }))
                        }
                      />
                    ))}
                  </CollapsibleContent>
                </Collapsible>

                {/* Level Colors */}
                <Collapsible>
                  <CollapsibleTrigger className="flex items-center gap-2 w-full p-2 bg-muted rounded-lg hover:bg-muted/80">
                    <ChevronDown className="h-4 w-4" />
                    <span className="font-medium">ألوان المستوى</span>
                  </CollapsibleTrigger>
                  <CollapsibleContent className="grid grid-cols-2 gap-3 pt-3">
                    {THEME_COLOR_KEYS.level.map(({ key, label }) => (
                      <ColorPicker
                        key={key}
                        label={label}
                        value={(formData.colors as Record<string, string>)?.[key] || ""}
                        onChange={(value) =>
                          setFormData((f) => ({
                            ...f,
                            colors: { ...f.colors, [key]: value },
                          }))
                        }
                      />
                    ))}
                  </CollapsibleContent>
                </Collapsible>
              </TabsContent>

              {/* Gradients Tab */}
              <TabsContent value="gradients" className="space-y-4 max-h-[40vh] overflow-y-auto">
                {GRADIENT_KEYS.map(({ key, label }) => {
                  const gradientData = (formData.gradients as Record<string, { colors?: string[] }>)?.[key];
                  const colors = gradientData?.colors || ["#000000", "#808080", "#FFFFFF"];
                  return (
                    <GradientPicker
                      key={key}
                      label={label}
                      colors={colors}
                      onChange={(newColors) =>
                        setFormData((f) => ({
                          ...f,
                          gradients: {
                            ...f.gradients,
                            [key]: { colors: newColors },
                          },
                        }))
                      }
                    />
                  );
                })}
              </TabsContent>

              {/* JSON Tab - Advanced */}
              <TabsContent value="json" className="space-y-4">
                <div className="space-y-2">
                  <Label>الألوان (JSON)</Label>
                  <textarea
                    className="w-full h-32 p-2 border rounded-md font-mono text-sm"
                    value={colorsJson}
                    onChange={(e) => {
                      setColorsJson(e.target.value);
                      try {
                        const parsed = JSON.parse(e.target.value);
                        setFormData((f) => ({ ...f, colors: parsed }));
                      } catch {
                        // Invalid JSON, ignore
                      }
                    }}
                    dir="ltr"
                    placeholder='{"primary": "#1A5F5B", "secondary": "#D4A853"}'
                  />
                </div>

                <div className="space-y-2">
                  <Label>التدرجات (JSON)</Label>
                  <textarea
                    className="w-full h-24 p-2 border rounded-md font-mono text-sm"
                    value={gradientsJson}
                    onChange={(e) => {
                      setGradientsJson(e.target.value);
                      try {
                        const parsed = JSON.parse(e.target.value);
                        setFormData((f) => ({ ...f, gradients: parsed }));
                      } catch {
                        // Invalid JSON, ignore
                      }
                    }}
                    dir="ltr"
                    placeholder='{"primary": {"colors": ["#1A5F5B", "#D4A853"]}}'
                  />
                </div>

                <p className="text-xs text-muted-foreground">
                  ملاحظة: التعديلات في JSON ستُحدّث الألوان مباشرة
                </p>
              </TabsContent>
            </Tabs>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الترتيب</Label>
                <Input
                  type="number"
                  value={formData.sort_order}
                  onChange={(e) =>
                    setFormData((f) => ({
                      ...f,
                      sort_order: parseInt(e.target.value) || 0,
                    }))
                  }
                />
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-6">
              <div className="flex items-center gap-2">
                <Switch
                  checked={formData.is_dark}
                  onCheckedChange={(checked) =>
                    setFormData((f) => ({ ...f, is_dark: checked }))
                  }
                />
                <Label>ثيم داكن</Label>
              </div>
              <div className="flex items-center gap-2">
                <Switch
                  checked={formData.is_premium}
                  onCheckedChange={(checked) =>
                    setFormData((f) => ({ ...f, is_premium: checked }))
                  }
                />
                <Label>مميز (Premium)</Label>
              </div>
              <div className="flex items-center gap-2">
                <Switch
                  checked={formData.is_default}
                  onCheckedChange={(checked) =>
                    setFormData((f) => ({ ...f, is_default: checked }))
                  }
                />
                <Label>افتراضي</Label>
              </div>
              <div className="flex items-center gap-2">
                <Switch
                  checked={formData.is_active}
                  onCheckedChange={(checked) =>
                    setFormData((f) => ({ ...f, is_active: checked }))
                  }
                />
                <Label>نشط</Label>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSave}
              disabled={createTheme.isPending || updateTheme.isPending}
            >
              {createTheme.isPending || updateTheme.isPending
                ? "جاري الحفظ..."
                : editingTheme
                ? "تحديث"
                : "إضافة"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={!!deleteConfirm} onOpenChange={() => setDeleteConfirm(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>تأكيد الحذف</DialogTitle>
            <DialogDescription>
              هل أنت متأكد من حذف هذا الثيم؟ لا يمكن التراجع عن هذا الإجراء.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteConfirm(null)}>
              إلغاء
            </Button>
            <Button
              variant="destructive"
              onClick={() => deleteConfirm && handleDelete(deleteConfirm)}
              disabled={deleteTheme.isPending}
            >
              {deleteTheme.isPending ? "جاري الحذف..." : "حذف"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

interface ThemeCardProps {
  theme: AdminTheme;
  onEdit: (theme: AdminTheme) => void;
  onDelete: (id: string) => void;
}

function ThemeCard({ theme, onEdit, onDelete }: ThemeCardProps) {
  const colors = theme.colors as Record<string, string>;
  const primary = colors?.primary || colors?.silni_teal || "#1A5F5B";
  const secondary = colors?.secondary || colors?.silni_gold || "#D4A853";
  const background = theme.is_dark ? "#1a1a1a" : "#ffffff";

  return (
    <Card
      className={`overflow-hidden cursor-pointer hover:shadow-lg transition-shadow ${
        !theme.is_active ? "opacity-60" : ""
      }`}
      onClick={() => onEdit(theme)}
    >
      {/* Preview */}
      <div
        className="h-32 relative"
        style={{
          background: `linear-gradient(135deg, ${primary} 0%, ${secondary} 100%)`,
        }}
      >
        {/* Mock app preview */}
        <div
          className="absolute bottom-0 left-0 right-0 h-20 rounded-t-3xl shadow-lg"
          style={{ backgroundColor: background }}
        >
          <div className="flex gap-2 p-3">
            <div className="w-10 h-10 rounded-full" style={{ backgroundColor: primary }} />
            <div className="flex-1 space-y-2">
              <div
                className="h-3 rounded"
                style={{ backgroundColor: theme.is_dark ? "#333" : "#e5e5e5", width: "70%" }}
              />
              <div
                className="h-2 rounded"
                style={{ backgroundColor: theme.is_dark ? "#444" : "#f0f0f0", width: "50%" }}
              />
            </div>
          </div>
        </div>

        {/* Badges */}
        <div className="absolute top-2 left-2 flex gap-1">
          {theme.is_premium && (
            <Badge className="bg-yellow-500">
              <Crown className="h-3 w-3" />
            </Badge>
          )}
          {theme.is_default && (
            <Badge variant="secondary">
              <Check className="h-3 w-3" />
            </Badge>
          )}
        </div>
      </div>

      <CardContent className="pt-4">
        <div className="flex items-start justify-between">
          <div>
            <h4 className="font-semibold">{theme.display_name_ar}</h4>
            <p className="text-xs text-muted-foreground" dir="ltr">
              {theme.theme_key}
            </p>
          </div>
          <div className="flex gap-1">
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8"
              onClick={(e) => {
                e.stopPropagation();
                onEdit(theme);
              }}
            >
              <Pencil className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8"
              onClick={(e) => {
                e.stopPropagation();
                onDelete(theme.id);
              }}
            >
              <Trash2 className="h-4 w-4 text-destructive" />
            </Button>
          </div>
        </div>

        {/* Color swatches */}
        <div className="flex gap-1 mt-3">
          {Object.entries(colors || {})
            .slice(0, 5)
            .map(([key, value]) => (
              <div
                key={key}
                className="w-6 h-6 rounded-full border"
                style={{ backgroundColor: value }}
                title={`${key}: ${value}`}
              />
            ))}
        </div>
      </CardContent>
    </Card>
  );
}
