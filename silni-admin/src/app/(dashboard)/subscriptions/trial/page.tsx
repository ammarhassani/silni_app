"use client";

import { useState, useEffect } from "react";
import { useTrialConfig, useUpdateTrialConfig, useFeatures } from "@/hooks/use-subscriptions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { Check, Clock, Gift, Settings, Sparkles } from "lucide-react";
import type { AdminTrialConfig } from "@/types/database";

export default function TrialConfigPage() {
  const { data: config, isLoading } = useTrialConfig();
  const { data: features } = useFeatures();
  const updateConfig = useUpdateTrialConfig();

  const [formData, setFormData] = useState({
    trial_duration_days: 7,
    trial_tier: "max",
    features_during_trial: [] as string[],
    show_trial_prompt_after_days: 3,
    show_trial_prompt_on_screens: [] as string[],
    is_trial_enabled: true,
  });

  useEffect(() => {
    if (config) {
      setFormData({
        trial_duration_days: config.trial_duration_days,
        trial_tier: config.trial_tier,
        features_during_trial: config.features_during_trial || [],
        show_trial_prompt_after_days: config.show_trial_prompt_after_days || 3,
        show_trial_prompt_on_screens: config.show_trial_prompt_on_screens || [],
        is_trial_enabled: config.is_trial_enabled,
      });
    }
  }, [config]);

  const handleSave = () => {
    if (!config) return;
    updateConfig.mutate({
      id: config.id,
      trial_duration_days: formData.trial_duration_days,
      trial_tier: formData.trial_tier,
      features_during_trial: formData.features_during_trial.length > 0 ? formData.features_during_trial : null,
      show_trial_prompt_after_days: formData.show_trial_prompt_after_days,
      show_trial_prompt_on_screens: formData.show_trial_prompt_on_screens.length > 0 ? formData.show_trial_prompt_on_screens : null,
      is_trial_enabled: formData.is_trial_enabled,
    });
  };

  const toggleFeature = (featureId: string) => {
    setFormData((f) => ({
      ...f,
      features_during_trial: f.features_during_trial.includes(featureId)
        ? f.features_during_trial.filter((id) => id !== featureId)
        : [...f.features_during_trial, featureId],
    }));
  };

  const availableScreens = [
    { key: "home", label: "الرئيسية" },
    { key: "ai_chat", label: "محادثة الذكاء الاصطناعي" },
    { key: "profile", label: "الملف الشخصي" },
    { key: "settings", label: "الإعدادات" },
    { key: "reminders", label: "التذكيرات" },
    { key: "family_tree", label: "شجرة العائلة" },
  ];

  const toggleScreen = (screenKey: string) => {
    setFormData((f) => ({
      ...f,
      show_trial_prompt_on_screens: f.show_trial_prompt_on_screens.includes(screenKey)
        ? f.show_trial_prompt_on_screens.filter((s) => s !== screenKey)
        : [...f.show_trial_prompt_on_screens, screenKey],
    }));
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-6 md:grid-cols-2">
          <Skeleton className="h-96" />
          <Skeleton className="h-96" />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">الفترة التجريبية</h1>
          <p className="text-muted-foreground mt-1">
            إعدادات الفترة التجريبية للمستخدمين الجدد
          </p>
        </div>
        <Button onClick={handleSave} disabled={updateConfig.isPending}>
          {updateConfig.isPending ? "جاري الحفظ..." : "حفظ التغييرات"}
        </Button>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Main Settings Card */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                <Gift className="h-5 w-5 text-primary" />
              </div>
              <div>
                <CardTitle>إعدادات الفترة التجريبية</CardTitle>
                <CardDescription>تكوين مدة وخصائص الفترة التجريبية</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Enable/Disable Trial */}
            <div className="flex items-center justify-between p-4 border rounded-lg">
              <div className="flex items-center gap-3">
                <Settings className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="font-medium">تفعيل الفترة التجريبية</p>
                  <p className="text-sm text-muted-foreground">
                    السماح للمستخدمين الجدد بتجربة الميزات المميزة
                  </p>
                </div>
              </div>
              <Switch
                checked={formData.is_trial_enabled}
                onCheckedChange={(checked) =>
                  setFormData((f) => ({ ...f, is_trial_enabled: checked }))
                }
              />
            </div>

            {/* Trial Duration */}
            <div className="space-y-2">
              <Label className="flex items-center gap-2">
                <Clock className="h-4 w-4" />
                مدة الفترة التجريبية (بالأيام)
              </Label>
              <Input
                type="number"
                min={1}
                max={30}
                value={formData.trial_duration_days}
                onChange={(e) =>
                  setFormData((f) => ({
                    ...f,
                    trial_duration_days: parseInt(e.target.value) || 7,
                  }))
                }
              />
              <p className="text-xs text-muted-foreground">
                عدد الأيام التي يحصل فيها المستخدم على الميزات المميزة مجاناً
              </p>
            </div>

            {/* Trial Tier */}
            <div className="space-y-2">
              <Label className="flex items-center gap-2">
                <Sparkles className="h-4 w-4" />
                باقة الفترة التجريبية
              </Label>
              <div className="flex gap-2">
                <Button
                  variant={formData.trial_tier === "max" ? "default" : "outline"}
                  onClick={() => setFormData((f) => ({ ...f, trial_tier: "max" }))}
                  className="flex-1"
                >
                  MAX
                </Button>
                <Button
                  variant={formData.trial_tier === "free" ? "default" : "outline"}
                  onClick={() => setFormData((f) => ({ ...f, trial_tier: "free" }))}
                  className="flex-1"
                >
                  Free
                </Button>
              </div>
              <p className="text-xs text-muted-foreground">
                الباقة التي يحصل عليها المستخدم خلال الفترة التجريبية
              </p>
            </div>

            {/* Prompt Settings */}
            <div className="space-y-2">
              <Label>إظهار دعوة الاشتراك بعد (أيام)</Label>
              <Input
                type="number"
                min={0}
                max={formData.trial_duration_days}
                value={formData.show_trial_prompt_after_days}
                onChange={(e) =>
                  setFormData((f) => ({
                    ...f,
                    show_trial_prompt_after_days: parseInt(e.target.value) || 0,
                  }))
                }
              />
              <p className="text-xs text-muted-foreground">
                عدد الأيام قبل بدء إظهار رسائل الاشتراك للمستخدم
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Features Selection Card */}
        <Card>
          <CardHeader>
            <CardTitle>الميزات المتاحة في الفترة التجريبية</CardTitle>
            <CardDescription>
              {formData.features_during_trial.length === 0
                ? "كل ميزات الباقة المحددة (افتراضي)"
                : `${formData.features_during_trial.length} ميزة محددة`}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2 max-h-72 overflow-y-auto">
              {features?.filter((f) => f.is_active).map((feature) => (
                <div
                  key={feature.id}
                  className={`flex items-center gap-3 p-3 rounded-lg cursor-pointer transition-colors ${
                    formData.features_during_trial.includes(feature.feature_id)
                      ? "bg-primary/10 border border-primary/20"
                      : "hover:bg-muted border border-transparent"
                  }`}
                  onClick={() => toggleFeature(feature.feature_id)}
                >
                  <div
                    className={`w-5 h-5 rounded border flex items-center justify-center ${
                      formData.features_during_trial.includes(feature.feature_id)
                        ? "bg-primary border-primary"
                        : "border-muted-foreground"
                    }`}
                  >
                    {formData.features_during_trial.includes(feature.feature_id) && (
                      <Check className="h-3 w-3 text-white" />
                    )}
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-sm">{feature.display_name_ar}</p>
                    <p className="text-xs text-muted-foreground">{feature.description_ar}</p>
                  </div>
                  <Badge variant="secondary" className="text-xs">
                    {feature.minimum_tier}
                  </Badge>
                </div>
              ))}
            </div>
            <p className="text-xs text-muted-foreground mt-4">
              اتركها فارغة لإتاحة كل ميزات الباقة المحددة تلقائياً
            </p>
          </CardContent>
        </Card>

        {/* Screens Selection Card */}
        <Card className="md:col-span-2">
          <CardHeader>
            <CardTitle>شاشات عرض دعوة الاشتراك</CardTitle>
            <CardDescription>
              الشاشات التي سيظهر فيها دعوة الاشتراك عند اقتراب انتهاء الفترة التجريبية
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
              {availableScreens.map((screen) => (
                <div
                  key={screen.key}
                  className={`flex items-center gap-3 p-3 rounded-lg cursor-pointer transition-colors ${
                    formData.show_trial_prompt_on_screens.includes(screen.key)
                      ? "bg-primary/10 border border-primary/20"
                      : "hover:bg-muted border border-transparent"
                  }`}
                  onClick={() => toggleScreen(screen.key)}
                >
                  <div
                    className={`w-5 h-5 rounded border flex items-center justify-center ${
                      formData.show_trial_prompt_on_screens.includes(screen.key)
                        ? "bg-primary border-primary"
                        : "border-muted-foreground"
                    }`}
                  >
                    {formData.show_trial_prompt_on_screens.includes(screen.key) && (
                      <Check className="h-3 w-3 text-white" />
                    )}
                  </div>
                  <span className="text-sm">{screen.label}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
