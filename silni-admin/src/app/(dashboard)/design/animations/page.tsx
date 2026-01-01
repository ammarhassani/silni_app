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
import {
  Plus,
  Pencil,
  RotateCw,
  Sparkles,
  Smartphone,
  Hand,
  Waves,
  Zap,
  Battery,
  BatteryLow,
  BatteryWarning,
} from "lucide-react";
import type { AdminPatternAnimation } from "@/types/database";

const EFFECT_ICONS: Record<string, React.ComponentType<{ className?: string }>> = {
  rotation: RotateCw,
  pulse: Sparkles,
  parallax: Smartphone,
  shimmer: Waves,
  touchRipple: Hand,
  gyroscope: Smartphone,
  followTouch: Hand,
};

const BATTERY_COLORS: Record<string, { bg: string; text: string; icon: React.ComponentType<{ className?: string }> }> = {
  low: { bg: "bg-green-500/10", text: "text-green-500", icon: Battery },
  medium: { bg: "bg-yellow-500/10", text: "text-yellow-500", icon: BatteryWarning },
  high: { bg: "bg-red-500/10", text: "text-red-500", icon: BatteryLow },
};

type AnimationFormData = Omit<AdminPatternAnimation, "id" | "created_at" | "updated_at">;

const defaultFormData: AnimationFormData = {
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
  sort_order: 0,
};

export default function PatternAnimationsPage() {
  const { data: animations, isLoading } = usePatternAnimations();
  const updateAnimation = useUpdatePatternAnimation();
  const createAnimation = useCreatePatternAnimation();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingAnimation, setEditingAnimation] = useState<AdminPatternAnimation | null>(null);
  const [formData, setFormData] = useState<AnimationFormData>(defaultFormData);

  const handleOpenCreate = () => {
    setEditingAnimation(null);
    setFormData(defaultFormData);
    setIsDialogOpen(true);
  };

  const handleOpenEdit = (animation: AdminPatternAnimation) => {
    setEditingAnimation(animation);
    setFormData({
      effect_key: animation.effect_key,
      display_name_ar: animation.display_name_ar,
      display_name_en: animation.display_name_en || "",
      description_ar: animation.description_ar || "",
      default_enabled: animation.default_enabled,
      battery_impact: animation.battery_impact,
      default_intensity: animation.default_intensity,
      settings_key: animation.settings_key,
      is_premium: animation.is_premium,
      is_active: animation.is_active,
      sort_order: animation.sort_order,
    });
    setIsDialogOpen(true);
  };

  const handleSave = () => {
    const data = {
      ...formData,
      display_name_en: formData.display_name_en || null,
      description_ar: formData.description_ar || null,
    };

    if (editingAnimation) {
      updateAnimation.mutate(
        { id: editingAnimation.id, ...data },
        { onSuccess: () => setIsDialogOpen(false) }
      );
    } else {
      createAnimation.mutate(data, { onSuccess: () => setIsDialogOpen(false) });
    }
  };

  const toggleEnabled = (animation: AdminPatternAnimation) => {
    updateAnimation.mutate({
      id: animation.id,
      default_enabled: !animation.default_enabled,
    });
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-4 grid-cols-3">
          {[1, 2, 3].map((i) => (
            <Skeleton key={i} className="h-24" />
          ))}
        </div>
        <div className="grid gap-4 grid-cols-2">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-48" />
          ))}
        </div>
      </div>
    );
  }

  const enabledCount = animations?.filter((a) => a.default_enabled).length || 0;
  const premiumCount = animations?.filter((a) => a.is_premium).length || 0;
  const lowBatteryCount = animations?.filter((a) => a.battery_impact === "low").length || 0;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">تأثيرات الأنماط</h1>
          <p className="text-muted-foreground mt-1">
            إدارة تأثيرات حركة الخلفية الإسلامية
          </p>
        </div>
        <Button onClick={handleOpenCreate}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة تأثير
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6 text-center">
            <Sparkles className="h-8 w-8 mx-auto text-blue-500 mb-2" />
            <p className="text-2xl font-bold">{animations?.length || 0}</p>
            <p className="text-sm text-muted-foreground">إجمالي التأثيرات</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6 text-center">
            <Zap className="h-8 w-8 mx-auto text-green-500 mb-2" />
            <p className="text-2xl font-bold">{enabledCount}</p>
            <p className="text-sm text-muted-foreground">مفعلة افتراضياً</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6 text-center">
            <Battery className="h-8 w-8 mx-auto text-green-500 mb-2" />
            <p className="text-2xl font-bold">{lowBatteryCount}</p>
            <p className="text-sm text-muted-foreground">استهلاك منخفض</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6 text-center">
            <Sparkles className="h-8 w-8 mx-auto text-yellow-500 mb-2" />
            <p className="text-2xl font-bold">{premiumCount}</p>
            <p className="text-sm text-muted-foreground">تأثيرات مميزة</p>
          </CardContent>
        </Card>
      </div>

      {/* Animations Grid */}
      <div className="grid gap-4 md:grid-cols-2">
        {animations?.map((animation) => {
          const Icon = EFFECT_ICONS[animation.effect_key] || Sparkles;
          const batteryInfo = BATTERY_COLORS[animation.battery_impact];
          const BatteryIcon = batteryInfo?.icon || Battery;

          return (
            <Card
              key={animation.id}
              className={`overflow-hidden ${!animation.is_active ? "opacity-60" : ""}`}
            >
              <CardHeader className="pb-2">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-silni-teal/20 to-silni-gold/20 flex items-center justify-center">
                      <Icon className="h-6 w-6 text-silni-teal" />
                    </div>
                    <div>
                      <CardTitle className="text-lg flex items-center gap-2">
                        {animation.display_name_ar}
                        {animation.is_premium && (
                          <Badge className="bg-yellow-500 text-xs">مميز</Badge>
                        )}
                      </CardTitle>
                      <CardDescription dir="ltr">{animation.effect_key}</CardDescription>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleOpenEdit(animation)}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Switch
                      checked={animation.default_enabled}
                      onCheckedChange={() => toggleEnabled(animation)}
                    />
                  </div>
                </div>
              </CardHeader>

              <CardContent className="space-y-4">
                {animation.description_ar && (
                  <p className="text-sm text-muted-foreground">
                    {animation.description_ar}
                  </p>
                )}

                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className={`p-2 rounded-lg ${batteryInfo?.bg}`}>
                      <BatteryIcon className={`h-4 w-4 ${batteryInfo?.text}`} />
                    </div>
                    <div>
                      <p className="text-sm font-medium">استهلاك البطارية</p>
                      <p className={`text-xs ${batteryInfo?.text}`}>
                        {animation.battery_impact === "low" && "منخفض"}
                        {animation.battery_impact === "medium" && "متوسط"}
                        {animation.battery_impact === "high" && "مرتفع"}
                      </p>
                    </div>
                  </div>

                  <div className="text-left">
                    <p className="text-sm font-medium">الشدة الافتراضية</p>
                    <p className="text-lg font-bold">
                      {Math.round(animation.default_intensity * 100)}%
                    </p>
                  </div>
                </div>

                {/* Intensity Bar */}
                <div className="space-y-2">
                  <div className="flex justify-between text-xs text-muted-foreground">
                    <span>0%</span>
                    <span>100%</span>
                  </div>
                  <div className="h-2 bg-muted rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-silni-teal to-silni-gold transition-all"
                      style={{ width: `${animation.default_intensity * 100}%` }}
                    />
                  </div>
                </div>

                <div className="pt-2 border-t flex items-center justify-between text-xs text-muted-foreground">
                  <span dir="ltr">settings_key: {animation.settings_key}</span>
                  <Badge variant={animation.is_active ? "default" : "secondary"}>
                    {animation.is_active ? "نشط" : "معطل"}
                  </Badge>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Create/Edit Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>
              {editingAnimation ? "تعديل التأثير" : "إضافة تأثير جديد"}
            </DialogTitle>
            <DialogDescription>
              {editingAnimation
                ? "تعديل إعدادات التأثير"
                : "إضافة تأثير حركة جديد للخلفية"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>المفتاح (effect_key)</Label>
                <Input
                  value={formData.effect_key}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, effect_key: e.target.value }))
                  }
                  placeholder="rotation"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label>مفتاح الإعدادات</Label>
                <Input
                  value={formData.settings_key}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, settings_key: e.target.value }))
                  }
                  placeholder="pattern_rotation_enabled"
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
                  placeholder="الدوران"
                />
              </div>
              <div className="space-y-2">
                <Label>الاسم (إنجليزي)</Label>
                <Input
                  value={formData.display_name_en}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_en: e.target.value }))
                  }
                  placeholder="Rotation"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>الوصف (عربي)</Label>
              <Input
                value={formData.description_ar}
                onChange={(e) =>
                  setFormData((f) => ({ ...f, description_ar: e.target.value }))
                }
                placeholder="دوران بطيء ومستمر للنمط"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>استهلاك البطارية</Label>
                <Select
                  value={formData.battery_impact}
                  onValueChange={(v) =>
                    setFormData((f) => ({
                      ...f,
                      battery_impact: v as AdminPatternAnimation["battery_impact"],
                    }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="low">منخفض</SelectItem>
                    <SelectItem value="medium">متوسط</SelectItem>
                    <SelectItem value="high">مرتفع</SelectItem>
                  </SelectContent>
                </Select>
              </div>
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

            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <Label>الشدة الافتراضية</Label>
                <span className="text-sm font-medium">
                  {Math.round(formData.default_intensity * 100)}%
                </span>
              </div>
              <Slider
                value={[formData.default_intensity * 100]}
                onValueChange={([value]) =>
                  setFormData((f) => ({ ...f, default_intensity: value / 100 }))
                }
                max={100}
                step={5}
              />
            </div>

            <div className="flex flex-wrap items-center gap-6">
              <div className="flex items-center gap-2">
                <Switch
                  checked={formData.default_enabled}
                  onCheckedChange={(checked) =>
                    setFormData((f) => ({ ...f, default_enabled: checked }))
                  }
                />
                <Label>مفعل افتراضياً</Label>
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
              disabled={updateAnimation.isPending || createAnimation.isPending}
            >
              {updateAnimation.isPending || createAnimation.isPending
                ? "جاري الحفظ..."
                : editingAnimation
                ? "تحديث"
                : "إضافة"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
