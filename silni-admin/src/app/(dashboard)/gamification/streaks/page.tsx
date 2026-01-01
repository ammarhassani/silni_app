"use client";

import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useStreakConfig, useUpdateStreakConfig } from "@/hooks/use-gamification";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Save, Flame, Clock, AlertTriangle, Snowflake } from "lucide-react";

const streakSchema = z.object({
  deadline_hours: z.number().min(1).max(48),
  endangered_threshold_hours: z.number().min(1).max(24),
  critical_threshold_minutes: z.number().min(1).max(120),
  grace_period_hours: z.number().min(0).max(12),
  max_freezes: z.number().min(0).max(10),
  freeze_cost_points: z.number().min(0),
  streak_restore_enabled: z.boolean(),
  streak_restore_cost_points: z.number().min(0),
});

type StreakFormData = z.infer<typeof streakSchema>;

export default function StreakConfigPage() {
  const { data: config, isLoading } = useStreakConfig();
  const updateConfig = useUpdateStreakConfig();

  const {
    register,
    handleSubmit,
    reset,
    watch,
    setValue,
    formState: { errors, isDirty },
  } = useForm<StreakFormData>({
    resolver: zodResolver(streakSchema),
  });

  const streakRestoreEnabled = watch("streak_restore_enabled");

  useEffect(() => {
    if (config) {
      reset({
        deadline_hours: config.deadline_hours,
        endangered_threshold_hours: config.endangered_threshold_hours,
        critical_threshold_minutes: config.critical_threshold_minutes,
        grace_period_hours: config.grace_period_hours,
        max_freezes: config.max_freezes,
        freeze_cost_points: config.freeze_cost_points,
        streak_restore_enabled: config.streak_restore_enabled,
        streak_restore_cost_points: config.streak_restore_cost_points,
      });
    }
  }, [config, reset]);

  const onSubmit = (data: StreakFormData) => {
    updateConfig.mutate(data);
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-4">
          {[1, 2, 3].map((i) => (
            <Card key={i}>
              <CardContent className="pt-6">
                <Skeleton className="h-24 w-full" />
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">إعدادات السلسلة</h1>
        <p className="text-muted-foreground mt-1">
          ضبط مواعيد وقواعد سلسلة التواصل
        </p>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        {/* Current Status */}
        <div className="grid grid-cols-4 gap-4">
          <Card className="bg-gradient-to-br from-orange-500/10 to-red-500/10 border-orange-200">
            <CardContent className="pt-6 text-center">
              <Flame className="h-8 w-8 mx-auto text-orange-500 mb-2" />
              <p className="text-2xl font-bold">{config?.deadline_hours}h</p>
              <p className="text-sm text-muted-foreground">الموعد النهائي</p>
            </CardContent>
          </Card>
          <Card className="bg-gradient-to-br from-yellow-500/10 to-orange-500/10 border-yellow-200">
            <CardContent className="pt-6 text-center">
              <AlertTriangle className="h-8 w-8 mx-auto text-yellow-500 mb-2" />
              <p className="text-2xl font-bold">{config?.endangered_threshold_hours}h</p>
              <p className="text-sm text-muted-foreground">عتبة الخطر</p>
            </CardContent>
          </Card>
          <Card className="bg-gradient-to-br from-red-500/10 to-pink-500/10 border-red-200">
            <CardContent className="pt-6 text-center">
              <Clock className="h-8 w-8 mx-auto text-red-500 mb-2" />
              <p className="text-2xl font-bold">{config?.critical_threshold_minutes}m</p>
              <p className="text-sm text-muted-foreground">العتبة الحرجة</p>
            </CardContent>
          </Card>
          <Card className="bg-gradient-to-br from-blue-500/10 to-cyan-500/10 border-blue-200">
            <CardContent className="pt-6 text-center">
              <Snowflake className="h-8 w-8 mx-auto text-blue-500 mb-2" />
              <p className="text-2xl font-bold">{config?.max_freezes}</p>
              <p className="text-sm text-muted-foreground">التجميد المتاح</p>
            </CardContent>
          </Card>
        </div>

        {/* Timing Settings */}
        <Card>
          <CardHeader>
            <CardTitle>إعدادات التوقيت</CardTitle>
            <CardDescription>
              تحديد مواعيد انتهاء السلسلة وعتبات التحذير
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="deadline_hours">الموعد النهائي (ساعات)</Label>
                <Input
                  id="deadline_hours"
                  type="number"
                  {...register("deadline_hours", { valueAsNumber: true })}
                />
                <p className="text-xs text-muted-foreground">
                  عدد الساعات المسموحة بين التفاعلات (26 = يوم + ساعتين)
                </p>
                {errors.deadline_hours && (
                  <p className="text-sm text-destructive">{errors.deadline_hours.message}</p>
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="grace_period_hours">فترة السماح (ساعات)</Label>
                <Input
                  id="grace_period_hours"
                  type="number"
                  {...register("grace_period_hours", { valueAsNumber: true })}
                />
                <p className="text-xs text-muted-foreground">
                  وقت إضافي بعد الموعد النهائي
                </p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="endangered_threshold_hours">عتبة الخطر (ساعات)</Label>
                <Input
                  id="endangered_threshold_hours"
                  type="number"
                  {...register("endangered_threshold_hours", { valueAsNumber: true })}
                />
                <p className="text-xs text-muted-foreground">
                  متى تظهر تحذيرات "السلسلة في خطر"
                </p>
              </div>
              <div className="space-y-2">
                <Label htmlFor="critical_threshold_minutes">العتبة الحرجة (دقائق)</Label>
                <Input
                  id="critical_threshold_minutes"
                  type="number"
                  {...register("critical_threshold_minutes", { valueAsNumber: true })}
                />
                <p className="text-xs text-muted-foreground">
                  متى تظهر تحذيرات "دقائق متبقية"
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Freeze Settings */}
        <Card>
          <CardHeader>
            <CardTitle>إعدادات التجميد</CardTitle>
            <CardDescription>
              التحكم في ميزة تجميد السلسلة
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="max_freezes">الحد الأقصى للتجميد</Label>
                <Input
                  id="max_freezes"
                  type="number"
                  {...register("max_freezes", { valueAsNumber: true })}
                />
                <p className="text-xs text-muted-foreground">
                  عدد مرات التجميد المتاحة للمستخدم
                </p>
              </div>
              <div className="space-y-2">
                <Label htmlFor="freeze_cost_points">تكلفة التجميد (نقاط)</Label>
                <Input
                  id="freeze_cost_points"
                  type="number"
                  {...register("freeze_cost_points", { valueAsNumber: true })}
                />
                <p className="text-xs text-muted-foreground">
                  0 = مجاني، أو حدد عدد النقاط المطلوبة
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Restore Settings */}
        <Card>
          <CardHeader>
            <CardTitle>إعدادات استعادة السلسلة</CardTitle>
            <CardDescription>
              السماح للمستخدمين باستعادة السلسلة المفقودة
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <Label>تفعيل استعادة السلسلة</Label>
                <p className="text-xs text-muted-foreground">
                  السماح للمستخدمين بدفع نقاط لاستعادة السلسلة
                </p>
              </div>
              <Switch
                checked={streakRestoreEnabled}
                onCheckedChange={(checked) => setValue("streak_restore_enabled", checked)}
              />
            </div>

            {streakRestoreEnabled && (
              <div className="space-y-2">
                <Label htmlFor="streak_restore_cost_points">تكلفة الاستعادة (نقاط)</Label>
                <Input
                  id="streak_restore_cost_points"
                  type="number"
                  {...register("streak_restore_cost_points", { valueAsNumber: true })}
                />
              </div>
            )}
          </CardContent>
        </Card>

        {/* Save Button */}
        <div className="flex justify-end">
          <Button
            type="submit"
            disabled={!isDirty || updateConfig.isPending}
            className="min-w-[120px]"
          >
            <Save className="h-4 w-4 ml-2" />
            {updateConfig.isPending ? "جاري الحفظ..." : "حفظ التغييرات"}
          </Button>
        </div>
      </form>
    </div>
  );
}
