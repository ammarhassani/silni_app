"use client";

import { useState } from "react";
import { useCounselingModes, useUpdateCounselingMode } from "@/hooks/use-ai";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle
} from "@/components/ui/dialog";
import { Save, MessageSquare, Settings2, Star } from "lucide-react";

// Icon mapping for mode icons
const iconMap: Record<string, React.ElementType> = {
  message_square: MessageSquare,
  settings: Settings2,
  star: Star,
};

export default function CounselingModesPage() {
  const { data: modes, isLoading } = useCounselingModes();
  const updateMode = useUpdateCounselingMode();

  const [editingMode, setEditingMode] = useState<string | null>(null);
  const [modeValues, setModeValues] = useState<{
    display_name_ar: string;
    display_name_en: string;
    description_ar: string;
    icon_name: string;
    color_hex: string;
    mode_instructions: string;
    is_default: boolean;
  }>({
    display_name_ar: "",
    display_name_en: "",
    description_ar: "",
    icon_name: "",
    color_hex: "",
    mode_instructions: "",
    is_default: false,
  });

  const selectedMode = modes?.find((m) => m.id === editingMode);

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid grid-cols-2 gap-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-40" />
          ))}
        </div>
      </div>
    );
  }

  const sortedModes = modes?.sort((a, b) => a.sort_order - b.sort_order) || [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">أوضاع الاستشارة</h1>
        <p className="text-muted-foreground mt-1">
          إدارة أوضاع المحادثة والاستشارة المختلفة
        </p>
      </div>

      {/* Info Card */}
      <Card className="border-blue-500/20 bg-gradient-to-br from-blue-500/5 to-cyan-500/5">
        <CardContent className="pt-6">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-cyan-500 flex items-center justify-center">
              <MessageSquare className="h-6 w-6 text-white" />
            </div>
            <div className="flex-1">
              <h3 className="font-semibold">نظام أوضاع الاستشارة</h3>
              <p className="text-muted-foreground text-sm mt-1">
                كل وضع يضيف تعليمات خاصة للذكاء الاصطناعي لتغيير طريقة تعامله مع المستخدم
                حسب سياق المحادثة.
              </p>
              <div className="flex gap-2 mt-3">
                <Badge variant="outline">{sortedModes.length} أوضاع</Badge>
                <Badge variant="outline" className="bg-green-500/10 text-green-600">
                  {sortedModes.filter(m => m.is_active).length} نشط
                </Badge>
                <Badge variant="outline" className="bg-yellow-500/10 text-yellow-600">
                  {sortedModes.find(m => m.is_default)?.display_name_ar || "لا يوجد"} افتراضي
                </Badge>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Modes Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {sortedModes.map((mode) => {
          const IconComponent = iconMap[mode.icon_name] || MessageSquare;

          return (
            <Card
              key={mode.id}
              className={`cursor-pointer transition-all hover:shadow-md hover:border-primary/50 ${
                !mode.is_active ? "opacity-50" : ""
              } ${mode.is_default ? "ring-2 ring-primary/30" : ""}`}
              onClick={() => {
                setEditingMode(mode.id);
                setModeValues({
                  display_name_ar: mode.display_name_ar,
                  display_name_en: mode.display_name_en || "",
                  description_ar: mode.description_ar || "",
                  icon_name: mode.icon_name,
                  color_hex: mode.color_hex,
                  mode_instructions: mode.mode_instructions,
                  is_default: mode.is_default,
                });
              }}
            >
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-12 h-12 rounded-xl flex items-center justify-center"
                      style={{ backgroundColor: `${mode.color_hex}20` }}
                    >
                      <IconComponent
                        className="h-6 w-6"
                        style={{ color: mode.color_hex }}
                      />
                    </div>
                    <div>
                      <CardTitle className="text-lg flex items-center gap-2">
                        {mode.display_name_ar}
                        {mode.is_default && (
                          <Badge variant="secondary" className="text-xs">
                            افتراضي
                          </Badge>
                        )}
                      </CardTitle>
                      <CardDescription>{mode.display_name_en}</CardDescription>
                    </div>
                  </div>
                  <Switch
                    checked={mode.is_active}
                    onCheckedChange={(checked) => {
                      updateMode.mutate({ id: mode.id, is_active: checked });
                    }}
                    onClick={(e) => e.stopPropagation()}
                  />
                </div>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-muted-foreground line-clamp-2">
                  {mode.description_ar || "لا يوجد وصف"}
                </p>
                <div className="flex items-center gap-2 mt-3">
                  <Badge variant="outline" className="text-xs">
                    {mode.mode_key}
                  </Badge>
                  <div
                    className="w-4 h-4 rounded-full border"
                    style={{ backgroundColor: mode.color_hex }}
                    title={mode.color_hex}
                  />
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {sortedModes.length === 0 && (
        <Card>
          <CardContent className="pt-6 text-center text-muted-foreground">
            <MessageSquare className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p>لا توجد أوضاع استشارة. يرجى إضافة أوضاع في قاعدة البيانات.</p>
          </CardContent>
        </Card>
      )}

      {/* Edit Mode Dialog */}
      <Dialog open={!!editingMode} onOpenChange={() => setEditingMode(null)}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>تعديل وضع الاستشارة</DialogTitle>
            <DialogDescription>
              تعديل إعدادات وتعليمات الوضع: {selectedMode?.display_name_ar}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            {/* Name Fields */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الاسم (عربي) *</Label>
                <Input
                  value={modeValues.display_name_ar}
                  onChange={(e) =>
                    setModeValues((prev) => ({
                      ...prev,
                      display_name_ar: e.target.value,
                    }))
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>الاسم (إنجليزي)</Label>
                <Input
                  value={modeValues.display_name_en}
                  onChange={(e) =>
                    setModeValues((prev) => ({
                      ...prev,
                      display_name_en: e.target.value,
                    }))
                  }
                  dir="ltr"
                />
              </div>
            </div>

            {/* Description */}
            <div className="space-y-2">
              <Label>الوصف (عربي)</Label>
              <Textarea
                value={modeValues.description_ar}
                onChange={(e) =>
                  setModeValues((prev) => ({
                    ...prev,
                    description_ar: e.target.value,
                  }))
                }
                rows={2}
                placeholder="وصف مختصر للوضع..."
              />
            </div>

            {/* Visual Settings */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>اسم الأيقونة</Label>
                <Input
                  value={modeValues.icon_name}
                  onChange={(e) =>
                    setModeValues((prev) => ({
                      ...prev,
                      icon_name: e.target.value,
                    }))
                  }
                  placeholder="message_square"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label>اللون</Label>
                <div className="flex gap-2">
                  <Input
                    type="color"
                    value={modeValues.color_hex}
                    onChange={(e) =>
                      setModeValues((prev) => ({
                        ...prev,
                        color_hex: e.target.value,
                      }))
                    }
                    className="w-16 h-10 p-1 cursor-pointer"
                  />
                  <Input
                    value={modeValues.color_hex}
                    onChange={(e) =>
                      setModeValues((prev) => ({
                        ...prev,
                        color_hex: e.target.value,
                      }))
                    }
                    placeholder="#3B82F6"
                    dir="ltr"
                    className="flex-1"
                  />
                </div>
              </div>
            </div>

            {/* Mode Instructions */}
            <div className="space-y-2">
              <Label>تعليمات الوضع *</Label>
              <p className="text-xs text-muted-foreground">
                هذه التعليمات تُضاف للذكاء الاصطناعي عند تفعيل هذا الوضع
              </p>
              <Textarea
                value={modeValues.mode_instructions}
                onChange={(e) =>
                  setModeValues((prev) => ({
                    ...prev,
                    mode_instructions: e.target.value,
                  }))
                }
                rows={8}
                placeholder="تعليمات خاصة للذكاء الاصطناعي في هذا الوضع..."
                className="font-mono text-sm"
              />
            </div>

            {/* Default Toggle */}
            <div className="flex items-center justify-between p-4 rounded-lg bg-muted/50">
              <div>
                <p className="font-medium">الوضع الافتراضي</p>
                <p className="text-sm text-muted-foreground">
                  هذا الوضع سيكون مفعلاً عند بدء المحادثة
                </p>
              </div>
              <Switch
                checked={modeValues.is_default}
                onCheckedChange={(checked) =>
                  setModeValues((prev) => ({
                    ...prev,
                    is_default: checked,
                  }))
                }
              />
            </div>
          </div>

          <div className="flex gap-2 justify-end">
            <Button variant="outline" onClick={() => setEditingMode(null)}>
              إلغاء
            </Button>
            <Button
              onClick={() => {
                if (editingMode) {
                  updateMode.mutate({
                    id: editingMode,
                    ...modeValues,
                  });
                  setEditingMode(null);
                }
              }}
              disabled={updateMode.isPending}
            >
              <Save className="h-4 w-4 ml-2" />
              حفظ التغييرات
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
