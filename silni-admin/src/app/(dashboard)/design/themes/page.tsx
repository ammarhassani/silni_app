"use client";

import { useState } from "react";
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
import { Plus, Pencil, Trash2, Sun, Moon, Crown, Sparkles, Check } from "lucide-react";
import type { AdminTheme } from "@/types/database";

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
    let colors = {};
    let gradients = {};

    try {
      colors = JSON.parse(colorsJson);
    } catch {
      colors = {};
    }

    try {
      gradients = JSON.parse(gradientsJson);
    } catch {
      gradients = {};
    }

    const data = {
      ...formData,
      display_name_en: formData.display_name_en || null,
      colors,
      gradients,
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
                  value={formData.display_name_en}
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

            <div className="space-y-2">
              <Label>الألوان (JSON)</Label>
              <textarea
                className="w-full h-32 p-2 border rounded-md font-mono text-sm"
                value={colorsJson}
                onChange={(e) => setColorsJson(e.target.value)}
                dir="ltr"
                placeholder='{"primary": "#1A5F5B", "secondary": "#D4A853"}'
              />
            </div>

            <div className="space-y-2">
              <Label>التدرجات (JSON)</Label>
              <textarea
                className="w-full h-24 p-2 border rounded-md font-mono text-sm"
                value={gradientsJson}
                onChange={(e) => setGradientsJson(e.target.value)}
                dir="ltr"
                placeholder='{"header": {"start": "#1A5F5B", "end": "#D4A853"}}'
              />
            </div>

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
