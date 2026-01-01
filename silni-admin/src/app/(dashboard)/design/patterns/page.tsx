"use client";

import { useState } from "react";
import {
  usePatternAnimations,
  useUpdatePatternAnimation,
  useCreatePatternAnimation,
} from "@/hooks/use-design-system";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { Slider } from "@/components/ui/slider";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Pencil, Plus, Sparkles, Zap, Battery, Crown, Eye, EyeOff } from "lucide-react";
import type { AdminPatternAnimation } from "@/types/database";

const batteryImpactColors: Record<string, string> = {
  low: "bg-green-500/10 text-green-500 border-green-500/20",
  medium: "bg-yellow-500/10 text-yellow-500 border-yellow-500/20",
  high: "bg-red-500/10 text-red-500 border-red-500/20",
};

const batteryImpactLabels: Record<string, string> = {
  low: "منخفض",
  medium: "متوسط",
  high: "عالي",
};

export default function PatternAnimationsPage() {
  const { data: patterns, isLoading } = usePatternAnimations();
  const updatePattern = useUpdatePatternAnimation();
  const createPattern = useCreatePatternAnimation();

  const [editingPattern, setEditingPattern] = useState<AdminPatternAnimation | null>(null);
  const [isNew, setIsNew] = useState(false);
  const [formData, setFormData] = useState({
    effect_key: "",
    display_name_ar: "",
    display_name_en: "",
    description_ar: "",
    default_enabled: true,
    battery_impact: "low" as "low" | "medium" | "high",
    default_intensity: 0.5,
    settings_key: "",
    is_premium: false,
    is_active: true,
    sort_order: 0,
  });

  const handleOpenNew = () => {
    setIsNew(true);
    setFormData({
      effect_key: "",
      display_name_ar: "",
      display_name_en: "",
      description_ar: "",
      default_enabled: true,
      battery_impact: "low",
      default_intensity: 0.5,
      settings_key: "",
      is_premium: false,
      is_active: true,
      sort_order: (patterns?.length || 0) + 1,
    });
    setEditingPattern({} as AdminPatternAnimation);
  };

  const handleOpenEdit = (pattern: AdminPatternAnimation) => {
    setIsNew(false);
    setEditingPattern(pattern);
    setFormData({
      effect_key: pattern.effect_key,
      display_name_ar: pattern.display_name_ar,
      display_name_en: pattern.display_name_en || "",
      description_ar: pattern.description_ar || "",
      default_enabled: pattern.default_enabled,
      battery_impact: pattern.battery_impact,
      default_intensity: pattern.default_intensity,
      settings_key: pattern.settings_key,
      is_premium: pattern.is_premium,
      is_active: pattern.is_active,
      sort_order: pattern.sort_order,
    });
  };

  const handleSave = () => {
    if (isNew) {
      createPattern.mutate(formData, {
        onSuccess: () => setEditingPattern(null),
      });
    } else if (editingPattern?.id) {
      updatePattern.mutate(
        {
          id: editingPattern.id,
          ...formData,
        },
        { onSuccess: () => setEditingPattern(null) }
      );
    }
  };

  const togglePatternActive = (pattern: AdminPatternAnimation) => {
    updatePattern.mutate({
      id: pattern.id,
      is_active: !pattern.is_active,
    });
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <Skeleton key={i} className="h-48" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">تأثيرات الخلفية</h1>
          <p className="text-muted-foreground mt-1">
            إدارة تأثيرات الخلفية والأنماط المتحركة
          </p>
        </div>
        <Button onClick={handleOpenNew}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة تأثير
        </Button>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                <Sparkles className="h-5 w-5 text-primary" />
              </div>
              <div>
                <p className="text-2xl font-bold">{patterns?.length || 0}</p>
                <p className="text-sm text-muted-foreground">إجمالي التأثيرات</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-green-500/10 flex items-center justify-center">
                <Eye className="h-5 w-5 text-green-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">
                  {patterns?.filter((p) => p.is_active).length || 0}
                </p>
                <p className="text-sm text-muted-foreground">مفعلة</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-yellow-500/10 flex items-center justify-center">
                <Crown className="h-5 w-5 text-yellow-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">
                  {patterns?.filter((p) => p.is_premium).length || 0}
                </p>
                <p className="text-sm text-muted-foreground">مميزة (Premium)</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-red-500/10 flex items-center justify-center">
                <Battery className="h-5 w-5 text-red-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">
                  {patterns?.filter((p) => p.battery_impact === "high").length || 0}
                </p>
                <p className="text-sm text-muted-foreground">عالية الاستهلاك</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Patterns Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {patterns?.map((pattern) => (
          <Card
            key={pattern.id}
            className={`relative overflow-hidden transition-all ${
              !pattern.is_active ? "opacity-60" : ""
            }`}
          >
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                    <Zap className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-lg flex items-center gap-2">
                      {pattern.display_name_ar}
                      {pattern.is_premium && (
                        <Crown className="h-4 w-4 text-yellow-500" />
                      )}
                    </CardTitle>
                    <CardDescription>{pattern.effect_key}</CardDescription>
                  </div>
                </div>
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={() => handleOpenEdit(pattern)}
                >
                  <Pencil className="h-4 w-4" />
                </Button>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {pattern.description_ar && (
                <p className="text-sm text-muted-foreground">
                  {pattern.description_ar}
                </p>
              )}

              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">الشدة الافتراضية</span>
                <div className="flex items-center gap-2">
                  <div className="w-24 h-2 bg-muted rounded-full overflow-hidden">
                    <div
                      className="h-full bg-primary rounded-full"
                      style={{ width: `${pattern.default_intensity * 100}%` }}
                    />
                  </div>
                  <span className="text-sm font-medium">
                    {Math.round(pattern.default_intensity * 100)}%
                  </span>
                </div>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">استهلاك البطارية</span>
                <Badge
                  variant="outline"
                  className={batteryImpactColors[pattern.battery_impact]}
                >
                  <Battery className="h-3 w-3 ml-1" />
                  {batteryImpactLabels[pattern.battery_impact]}
                </Badge>
              </div>

              <div className="flex items-center justify-between pt-3 border-t">
                <div className="flex items-center gap-2">
                  {pattern.default_enabled ? (
                    <Badge variant="default" className="text-xs">مفعل افتراضياً</Badge>
                  ) : (
                    <Badge variant="secondary" className="text-xs">معطل افتراضياً</Badge>
                  )}
                </div>
                <Switch
                  checked={pattern.is_active}
                  onCheckedChange={() => togglePatternActive(pattern)}
                />
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {patterns?.length === 0 && (
        <Card>
          <CardContent className="pt-6 text-center text-muted-foreground">
            <Sparkles className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p>لا توجد تأثيرات خلفية. اضغط على &quot;إضافة تأثير&quot; للبدء.</p>
          </CardContent>
        </Card>
      )}

      {/* Edit/Create Dialog */}
      <Dialog open={!!editingPattern} onOpenChange={() => setEditingPattern(null)}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{isNew ? "إضافة تأثير جديد" : "تعديل التأثير"}</DialogTitle>
            <DialogDescription>
              {isNew ? "أضف تأثير خلفية جديد" : "تعديل إعدادات تأثير الخلفية"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>مفتاح التأثير</Label>
                <Input
                  value={formData.effect_key}
                  onChange={(e) => setFormData((f) => ({ ...f, effect_key: e.target.value }))}
                  placeholder="shimmer"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label>مفتاح الإعدادات</Label>
                <Input
                  value={formData.settings_key}
                  onChange={(e) => setFormData((f) => ({ ...f, settings_key: e.target.value }))}
                  placeholder="pattern_shimmer"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الاسم (عربي)</Label>
                <Input
                  value={formData.display_name_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_ar: e.target.value }))
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>الاسم (إنجليزي)</Label>
                <Input
                  value={formData.display_name_en}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_en: e.target.value }))
                  }
                  dir="ltr"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>الوصف</Label>
              <Textarea
                value={formData.description_ar}
                onChange={(e) =>
                  setFormData((f) => ({ ...f, description_ar: e.target.value }))
                }
                rows={2}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>استهلاك البطارية</Label>
                <Select
                  value={formData.battery_impact}
                  onValueChange={(v: "low" | "medium" | "high") =>
                    setFormData((f) => ({ ...f, battery_impact: v }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="low">منخفض</SelectItem>
                    <SelectItem value="medium">متوسط</SelectItem>
                    <SelectItem value="high">عالي</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>الترتيب</Label>
                <Input
                  type="number"
                  value={formData.sort_order}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, sort_order: parseInt(e.target.value) || 0 }))
                  }
                />
              </div>
            </div>

            <div className="space-y-3">
              <Label>الشدة الافتراضية: {Math.round(formData.default_intensity * 100)}%</Label>
              <Slider
                value={[formData.default_intensity]}
                onValueChange={([v]) => setFormData((f) => ({ ...f, default_intensity: v }))}
                min={0}
                max={1}
                step={0.1}
              />
            </div>

            <div className="grid grid-cols-2 gap-6 pt-2">
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <Label>مفعل افتراضياً</Label>
                  <Switch
                    checked={formData.default_enabled}
                    onCheckedChange={(c) => setFormData((f) => ({ ...f, default_enabled: c }))}
                  />
                </div>
                <div className="flex items-center justify-between">
                  <Label>مفعل</Label>
                  <Switch
                    checked={formData.is_active}
                    onCheckedChange={(c) => setFormData((f) => ({ ...f, is_active: c }))}
                  />
                </div>
              </div>
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <Label className="flex items-center gap-1">
                    <Crown className="h-4 w-4 text-yellow-500" />
                    تأثير مميز
                  </Label>
                  <Switch
                    checked={formData.is_premium}
                    onCheckedChange={(c) => setFormData((f) => ({ ...f, is_premium: c }))}
                  />
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setEditingPattern(null)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSave}
              disabled={createPattern.isPending || updatePattern.isPending}
            >
              {(createPattern.isPending || updatePattern.isPending)
                ? "جاري الحفظ..."
                : "حفظ"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
