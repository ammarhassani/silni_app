"use client";

import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Slider } from "@/components/ui/slider";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import {
  Database,
  RefreshCw,
  Save,
  Clock,
  Zap,
  Brain,
  Gamepad2,
  Bell,
  Palette,
  FileText,
  Route,
} from "lucide-react";
import {
  useCacheConfigs,
  useUpdateCacheConfig,
  useResetCacheDefaults,
  serviceLabels,
  formatDuration,
  CacheConfig,
} from "@/hooks/use-cache-config";

const serviceIcons: Record<string, React.ReactNode> = {
  feature_config: <Zap className="h-5 w-5" />,
  ai_config: <Brain className="h-5 w-5" />,
  gamification_config: <Gamepad2 className="h-5 w-5" />,
  notification_config: <Bell className="h-5 w-5" />,
  design_config: <Palette className="h-5 w-5" />,
  content_config: <FileText className="h-5 w-5" />,
  app_routes_config: <Route className="h-5 w-5" />,
};

export default function CacheConfigPage() {
  const { data: configs, isLoading } = useCacheConfigs();
  const updateConfig = useUpdateCacheConfig();
  const resetDefaults = useResetCacheDefaults();
  const [localChanges, setLocalChanges] = useState<Record<string, number>>({});

  const handleSliderChange = (id: string, value: number[]) => {
    setLocalChanges((prev) => ({ ...prev, [id]: value[0] }));
  };

  const handleSave = async (config: CacheConfig) => {
    const newValue = localChanges[config.id];
    if (newValue !== undefined && newValue !== config.cache_duration_seconds) {
      await updateConfig.mutateAsync({
        id: config.id,
        cache_duration_seconds: newValue,
      });
      setLocalChanges((prev) => {
        const next = { ...prev };
        delete next[config.id];
        return next;
      });
    }
  };

  const handleToggle = async (config: CacheConfig) => {
    await updateConfig.mutateAsync({
      id: config.id,
      is_active: !config.is_active,
    });
  };

  const getValue = (config: CacheConfig) => {
    return localChanges[config.id] ?? config.cache_duration_seconds;
  };

  const hasChanges = (config: CacheConfig) => {
    return (
      localChanges[config.id] !== undefined &&
      localChanges[config.id] !== config.cache_duration_seconds
    );
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-cyan-500 to-blue-600 rounded-2xl flex items-center justify-center shadow-lg">
            <Database className="h-7 w-7 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">إعدادات التخزين المؤقت</h1>
            <p className="text-muted-foreground mt-1">
              تحكم في مدة تخزين البيانات في تطبيق Flutter
            </p>
          </div>
        </div>

        <AlertDialog>
          <AlertDialogTrigger asChild>
            <Button variant="outline" className="gap-2">
              <RefreshCw className="h-4 w-4" />
              إعادة الضبط
            </Button>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>إعادة ضبط القيم الافتراضية؟</AlertDialogTitle>
              <AlertDialogDescription>
                سيتم إعادة جميع إعدادات التخزين المؤقت للقيم الافتراضية. لا يمكن
                التراجع عن هذا الإجراء.
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>إلغاء</AlertDialogCancel>
              <AlertDialogAction
                onClick={() => resetDefaults.mutate()}
                disabled={resetDefaults.isPending}
              >
                إعادة الضبط
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      </div>

      {/* Info Card */}
      <Card className="border-blue-500/20 bg-blue-500/5">
        <CardContent className="pt-6">
          <div className="flex items-start gap-3">
            <Clock className="h-5 w-5 text-blue-500 mt-0.5" />
            <div>
              <p className="font-medium">كيف يعمل التخزين المؤقت؟</p>
              <p className="text-sm text-muted-foreground mt-1">
                يقوم التطبيق بتخزين البيانات محلياً لتسريع التحميل. بعد انتهاء
                المدة المحددة، يقوم بجلب البيانات الجديدة من السيرفر. زيادة المدة
                تقلل استهلاك البيانات، وتقليلها يضمن تحديث أسرع للمحتوى.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Cache Configs Grid */}
      <div className="grid gap-4">
        {isLoading ? (
          [...Array(7)].map((_, i) => (
            <Card key={i}>
              <CardContent className="pt-6">
                <div className="flex items-center gap-4">
                  <Skeleton className="w-12 h-12 rounded-lg" />
                  <div className="flex-1">
                    <Skeleton className="h-5 w-32 mb-2" />
                    <Skeleton className="h-4 w-48" />
                  </div>
                  <Skeleton className="h-6 w-24" />
                </div>
              </CardContent>
            </Card>
          ))
        ) : (
          configs?.map((config) => (
            <Card
              key={config.id}
              className={!config.is_active ? "opacity-60" : ""}
            >
              <CardContent className="pt-6">
                <div className="flex items-start gap-4">
                  {/* Icon */}
                  <div
                    className={`w-12 h-12 rounded-lg flex items-center justify-center ${
                      config.is_active
                        ? "bg-gradient-to-br from-cyan-500/20 to-blue-500/20 text-blue-600"
                        : "bg-muted text-muted-foreground"
                    }`}
                  >
                    {serviceIcons[config.service_key] || (
                      <Database className="h-5 w-5" />
                    )}
                  </div>

                  {/* Content */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-semibold">
                        {serviceLabels[config.service_key] || config.service_key}
                      </h3>
                      {hasChanges(config) && (
                        <Badge variant="secondary" className="text-xs">
                          غير محفوظ
                        </Badge>
                      )}
                    </div>
                    <p className="text-sm text-muted-foreground mb-4">
                      {config.description_ar || config.description}
                    </p>

                    {/* Slider */}
                    <div className="flex items-center gap-4">
                      <div className="flex-1">
                        <Slider
                          value={[getValue(config)]}
                          onValueChange={(v) =>
                            handleSliderChange(config.id, v)
                          }
                          min={config.min_duration_seconds}
                          max={config.max_duration_seconds}
                          step={30}
                          disabled={!config.is_active}
                          className="cursor-pointer"
                        />
                      </div>
                      <div className="w-24 text-left font-mono text-sm">
                        {formatDuration(getValue(config))}
                      </div>
                    </div>

                    {/* Quick presets */}
                    <div className="flex gap-2 mt-3">
                      {[60, 300, 600, 1800].map((seconds) => (
                        <Button
                          key={seconds}
                          variant={
                            getValue(config) === seconds ? "default" : "ghost"
                          }
                          size="sm"
                          className="text-xs h-7"
                          disabled={!config.is_active}
                          onClick={() =>
                            handleSliderChange(config.id, [seconds])
                          }
                        >
                          {formatDuration(seconds)}
                        </Button>
                      ))}
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex flex-col items-end gap-3">
                    <Switch
                      checked={config.is_active}
                      onCheckedChange={() => handleToggle(config)}
                      disabled={updateConfig.isPending}
                    />
                    {hasChanges(config) && (
                      <Button
                        size="sm"
                        onClick={() => handleSave(config)}
                        disabled={updateConfig.isPending}
                        className="gap-1"
                      >
                        <Save className="h-3 w-3" />
                        حفظ
                      </Button>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        )}
      </div>

      {/* Footer Info */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">ملاحظات مهمة</CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="space-y-2 text-sm text-muted-foreground">
            <li className="flex items-start gap-2">
              <span className="text-primary">•</span>
              التغييرات تؤثر على جميع المستخدمين فور التطبيق
            </li>
            <li className="flex items-start gap-2">
              <span className="text-primary">•</span>
              يحتاج المستخدم لإعادة فتح التطبيق لتطبيق الإعدادات الجديدة
            </li>
            <li className="flex items-start gap-2">
              <span className="text-primary">•</span>
              تعطيل خدمة يعني استخدام القيمة الافتراضية (5 دقائق)
            </li>
            <li className="flex items-start gap-2">
              <span className="text-primary">•</span>
              القيم الموصى بها: 5 دقائق للبيانات المتغيرة، 10 دقائق للمحتوى
              الثابت
            </li>
          </ul>
        </CardContent>
      </Card>
    </div>
  );
}
