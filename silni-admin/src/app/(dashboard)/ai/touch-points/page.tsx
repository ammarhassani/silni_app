"use client";

import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Slider } from "@/components/ui/slider";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Sparkles,
  Plus,
  Pencil,
  Trash2,
  Home,
  User,
  Bell,
  Activity,
  BarChart3,
  Zap,
  Clock,
} from "lucide-react";
import {
  useAITouchPoints,
  useCreateAITouchPoint,
  useUpdateAITouchPoint,
  useDeleteAITouchPoint,
  useToggleAITouchPointEnabled,
  useAIGenerationStats,
  screenOptions,
  contextFieldOptions,
  iconOptions,
  AITouchPoint,
  AITouchPointInput,
} from "@/hooks/use-ai-touch-points";

// Screen icon mapping
const screenIcons: Record<string, typeof Home> = {
  home: Home,
  relative_detail: User,
  reminders: Bell,
  gamification: Activity,
  interactions: BarChart3,
};

export default function AITouchPointsPage() {
  const { data: touchPoints, isLoading } = useAITouchPoints();
  const { data: stats } = useAIGenerationStats();
  const createTouchPoint = useCreateAITouchPoint();
  const updateTouchPoint = useUpdateAITouchPoint();
  const deleteTouchPoint = useDeleteAITouchPoint();
  const toggleEnabled = useToggleAITouchPointEnabled();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingTouchPoint, setEditingTouchPoint] = useState<AITouchPoint | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [selectedScreen, setSelectedScreen] = useState<string>("all");

  const [formData, setFormData] = useState<AITouchPointInput>({
    screen_key: "home",
    touch_point_key: "",
    name_ar: "",
    name_en: null,
    description_ar: null,
    is_enabled: true,
    prompt_template: "",
    context_fields: [],
    display_config: { icon: "sparkles", position: "default" },
    cache_duration_seconds: 300,
    priority: 0,
    temperature: 0.7,
    max_tokens: 150,
  });

  const resetForm = () => {
    setFormData({
      screen_key: "home",
      touch_point_key: "",
      name_ar: "",
      name_en: null,
      description_ar: null,
      is_enabled: true,
      prompt_template: "",
      context_fields: [],
      display_config: { icon: "sparkles", position: "default" },
      cache_duration_seconds: 300,
      priority: 0,
      temperature: 0.7,
      max_tokens: 150,
    });
    setEditingTouchPoint(null);
  };

  const openEditDialog = (tp: AITouchPoint) => {
    setEditingTouchPoint(tp);
    setFormData({
      screen_key: tp.screen_key,
      touch_point_key: tp.touch_point_key,
      name_ar: tp.name_ar,
      name_en: tp.name_en,
      description_ar: tp.description_ar,
      is_enabled: tp.is_enabled,
      prompt_template: tp.prompt_template,
      context_fields: tp.context_fields,
      display_config: tp.display_config,
      cache_duration_seconds: tp.cache_duration_seconds,
      priority: tp.priority,
      temperature: tp.temperature,
      max_tokens: tp.max_tokens,
    });
    setIsDialogOpen(true);
  };

  const handleSubmit = async () => {
    if (editingTouchPoint) {
      await updateTouchPoint.mutateAsync({ id: editingTouchPoint.id, ...formData });
    } else {
      await createTouchPoint.mutateAsync(formData);
    }
    setIsDialogOpen(false);
    resetForm();
  };

  const handleDelete = async () => {
    if (deleteId) {
      await deleteTouchPoint.mutateAsync(deleteId);
      setDeleteId(null);
    }
  };

  const toggleContextField = (field: string) => {
    const current = formData.context_fields;
    if (current.includes(field)) {
      setFormData({ ...formData, context_fields: current.filter((f) => f !== field) });
    } else {
      setFormData({ ...formData, context_fields: [...current, field] });
    }
  };

  // Group touch points by screen
  const groupedTouchPoints = touchPoints?.reduce((acc, tp) => {
    if (!acc[tp.screen_key]) acc[tp.screen_key] = [];
    acc[tp.screen_key].push(tp);
    return acc;
  }, {} as Record<string, AITouchPoint[]>);

  const filteredTouchPoints = selectedScreen === "all"
    ? touchPoints
    : touchPoints?.filter((tp) => tp.screen_key === selectedScreen);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-violet-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
            <Sparkles className="h-7 w-7 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">نقاط الذكاء الاصطناعي</h1>
            <p className="text-muted-foreground mt-1">
              أماكن حقن الذكاء الاصطناعي في التطبيق - كل نقطة قابلة للتكوين
            </p>
          </div>
        </div>

        <Dialog open={isDialogOpen} onOpenChange={(open) => {
          setIsDialogOpen(open);
          if (!open) resetForm();
        }}>
          <DialogTrigger asChild>
            <Button className="gap-2">
              <Plus className="h-4 w-4" />
              إضافة نقطة
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>
                {editingTouchPoint ? "تعديل نقطة الذكاء الاصطناعي" : "إضافة نقطة جديدة"}
              </DialogTitle>
              <DialogDescription>
                كل نقطة تحدد مكان وكيفية ظهور محتوى الذكاء الاصطناعي في التطبيق
              </DialogDescription>
            </DialogHeader>

            <Tabs defaultValue="basic" className="mt-4">
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="basic">الأساسيات</TabsTrigger>
                <TabsTrigger value="prompt">القالب</TabsTrigger>
                <TabsTrigger value="settings">الإعدادات</TabsTrigger>
              </TabsList>

              {/* Basic Tab */}
              <TabsContent value="basic" className="space-y-4 mt-4">
                {/* Screen & Key */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>الشاشة *</Label>
                    <Select
                      value={formData.screen_key}
                      onValueChange={(v) => setFormData({ ...formData, screen_key: v })}
                      disabled={!!editingTouchPoint}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {screenOptions.map((screen) => (
                          <SelectItem key={screen.value} value={screen.value}>
                            {screen.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label>مفتاح النقطة (بالإنجليزية) *</Label>
                    <Input
                      value={formData.touch_point_key}
                      onChange={(e) =>
                        setFormData({ ...formData, touch_point_key: e.target.value.toLowerCase().replace(/\s+/g, '_') })
                      }
                      placeholder="greeting"
                      dir="ltr"
                      disabled={!!editingTouchPoint}
                    />
                  </div>
                </div>

                {/* Names */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>الاسم (عربي) *</Label>
                    <Input
                      value={formData.name_ar}
                      onChange={(e) => setFormData({ ...formData, name_ar: e.target.value })}
                      placeholder="التحية الذكية"
                      dir="rtl"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>الاسم (إنجليزي)</Label>
                    <Input
                      value={formData.name_en || ""}
                      onChange={(e) => setFormData({ ...formData, name_en: e.target.value || null })}
                      placeholder="AI Greeting"
                      dir="ltr"
                    />
                  </div>
                </div>

                {/* Description */}
                <div className="space-y-2">
                  <Label>الوصف</Label>
                  <Input
                    value={formData.description_ar || ""}
                    onChange={(e) => setFormData({ ...formData, description_ar: e.target.value || null })}
                    placeholder="وصف قصير لهذه النقطة..."
                    dir="rtl"
                  />
                </div>

                {/* Icon & Position */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>الأيقونة</Label>
                    <Select
                      value={(formData.display_config as Record<string, string>).icon || "sparkles"}
                      onValueChange={(v) =>
                        setFormData({
                          ...formData,
                          display_config: { ...formData.display_config, icon: v },
                        })
                      }
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {iconOptions.map((icon) => (
                          <SelectItem key={icon.value} value={icon.value}>
                            {icon.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label>الموضع</Label>
                    <Select
                      value={(formData.display_config as Record<string, string>).position || "default"}
                      onValueChange={(v) =>
                        setFormData({
                          ...formData,
                          display_config: { ...formData.display_config, position: v },
                        })
                      }
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="top">أعلى</SelectItem>
                        <SelectItem value="main">رئيسي</SelectItem>
                        <SelectItem value="bottom">أسفل</SelectItem>
                        <SelectItem value="default">افتراضي</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                {/* Context Fields */}
                <div className="space-y-2">
                  <Label>حقول السياق (البيانات المتاحة للقالب)</Label>
                  <div className="flex flex-wrap gap-2">
                    {contextFieldOptions.map((field) => (
                      <Badge
                        key={field.value}
                        variant={formData.context_fields.includes(field.value) ? "default" : "outline"}
                        className="cursor-pointer"
                        onClick={() => toggleContextField(field.value)}
                      >
                        {field.label}
                      </Badge>
                    ))}
                  </div>
                </div>
              </TabsContent>

              {/* Prompt Tab */}
              <TabsContent value="prompt" className="space-y-4 mt-4">
                <div className="space-y-2">
                  <Label>قالب الـ Prompt *</Label>
                  <Textarea
                    value={formData.prompt_template}
                    onChange={(e) => setFormData({ ...formData, prompt_template: e.target.value })}
                    placeholder="أنت واصل، مساعد صلة الرحم. اكتب تحية قصيرة..."
                    dir="rtl"
                    rows={12}
                    className="font-mono text-sm"
                  />
                  <p className="text-xs text-muted-foreground">
                    المتغيرات المتاحة: {"{{time_of_day}}"}, {"{{active_streaks}}"}, {"{{at_risk_count}}"}, {"{{relatives_data}}"}, {"{{streaks_data}}"}, {"{{occasions_data}}"}, {"{{relative_name}}"}, {"{{memories}}"}
                  </p>
                </div>
              </TabsContent>

              {/* Settings Tab */}
              <TabsContent value="settings" className="space-y-4 mt-4">
                {/* Temperature */}
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <Label>درجة الحرارة (الإبداعية)</Label>
                    <span className="text-sm text-muted-foreground">{formData.temperature}</span>
                  </div>
                  <Slider
                    value={[formData.temperature]}
                    onValueChange={([v]) => setFormData({ ...formData, temperature: v })}
                    min={0}
                    max={1}
                    step={0.1}
                  />
                  <p className="text-xs text-muted-foreground">
                    0 = دقيق ومحافظ، 1 = إبداعي ومتنوع
                  </p>
                </div>

                {/* Max Tokens */}
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <Label>الحد الأقصى للكلمات</Label>
                    <span className="text-sm text-muted-foreground">{formData.max_tokens}</span>
                  </div>
                  <Slider
                    value={[formData.max_tokens]}
                    onValueChange={([v]) => setFormData({ ...formData, max_tokens: v })}
                    min={50}
                    max={500}
                    step={10}
                  />
                </div>

                {/* Cache Duration */}
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <Label>مدة التخزين المؤقت (ثواني)</Label>
                    <span className="text-sm text-muted-foreground">{formData.cache_duration_seconds}s</span>
                  </div>
                  <Slider
                    value={[formData.cache_duration_seconds]}
                    onValueChange={([v]) => setFormData({ ...formData, cache_duration_seconds: v })}
                    min={60}
                    max={3600}
                    step={60}
                  />
                </div>

                {/* Priority */}
                <div className="space-y-2">
                  <Label>الأولوية</Label>
                  <Input
                    type="number"
                    value={formData.priority}
                    onChange={(e) => setFormData({ ...formData, priority: parseInt(e.target.value) || 0 })}
                    min={0}
                  />
                  <p className="text-xs text-muted-foreground">
                    الأقل = يظهر أولاً
                  </p>
                </div>

                {/* Enabled */}
                <div className="flex items-center gap-2">
                  <Switch
                    id="is_enabled"
                    checked={formData.is_enabled}
                    onCheckedChange={(v) => setFormData({ ...formData, is_enabled: v })}
                  />
                  <Label htmlFor="is_enabled">مفعّل</Label>
                </div>
              </TabsContent>
            </Tabs>

            <DialogFooter className="mt-6">
              <Button variant="outline" onClick={() => { setIsDialogOpen(false); resetForm(); }}>
                إلغاء
              </Button>
              <Button
                onClick={handleSubmit}
                disabled={
                  !formData.screen_key ||
                  !formData.touch_point_key ||
                  !formData.name_ar ||
                  !formData.prompt_template ||
                  createTouchPoint.isPending ||
                  updateTouchPoint.isPending
                }
              >
                {editingTouchPoint ? "تحديث" : "إنشاء"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-violet-100 dark:bg-violet-900/30 flex items-center justify-center">
                <Sparkles className="h-6 w-6 text-violet-600" />
              </div>
              <div>
                <p className="text-2xl font-bold">{touchPoints?.length || 0}</p>
                <p className="text-sm text-muted-foreground">نقاط مكونة</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
                <Zap className="h-6 w-6 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold">{touchPoints?.filter((t) => t.is_enabled).length || 0}</p>
                <p className="text-sm text-muted-foreground">نقاط مفعّلة</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                <BarChart3 className="h-6 w-6 text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold">{stats?.total_generations || 0}</p>
                <p className="text-sm text-muted-foreground">إجمالي التوليدات</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center">
                <Clock className="h-6 w-6 text-orange-600" />
              </div>
              <div>
                <p className="text-2xl font-bold">{stats?.avg_latency_ms || 0}ms</p>
                <p className="text-sm text-muted-foreground">متوسط الاستجابة</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Screen Filter */}
      <div className="flex gap-2 flex-wrap">
        <Button
          variant={selectedScreen === "all" ? "default" : "outline"}
          size="sm"
          onClick={() => setSelectedScreen("all")}
        >
          الكل
        </Button>
        {screenOptions.map((screen) => {
          const Icon = screenIcons[screen.value] || Home;
          return (
            <Button
              key={screen.value}
              variant={selectedScreen === screen.value ? "default" : "outline"}
              size="sm"
              onClick={() => setSelectedScreen(screen.value)}
              className="gap-2"
            >
              <Icon className="h-4 w-4" />
              {screen.label}
            </Button>
          );
        })}
      </div>

      {/* Touch Points List */}
      <div className="grid gap-4">
        {isLoading ? (
          [...Array(4)].map((_, i) => (
            <Card key={i}>
              <CardContent className="pt-6">
                <div className="flex items-center gap-4">
                  <Skeleton className="w-12 h-12 rounded-xl" />
                  <div className="flex-1">
                    <Skeleton className="h-5 w-32 mb-2" />
                    <Skeleton className="h-4 w-48" />
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        ) : filteredTouchPoints?.length === 0 ? (
          <Card>
            <CardContent className="py-12 text-center">
              <Sparkles className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
              <p className="text-muted-foreground">لا توجد نقاط ذكاء اصطناعي</p>
              <Button className="mt-4" onClick={() => setIsDialogOpen(true)}>
                إضافة نقطة جديدة
              </Button>
            </CardContent>
          </Card>
        ) : (
          filteredTouchPoints?.map((tp) => {
            const ScreenIcon = screenIcons[tp.screen_key] || Home;
            const screenLabel = screenOptions.find((s) => s.value === tp.screen_key)?.label || tp.screen_key;

            return (
              <Card key={tp.id} className={!tp.is_enabled ? "opacity-60" : ""}>
                <CardContent className="pt-6">
                  <div className="flex items-center gap-4">
                    {/* Icon */}
                    <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-violet-500/20 to-purple-500/20 flex items-center justify-center">
                      <ScreenIcon className="h-6 w-6 text-violet-600" />
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold">{tp.name_ar}</h3>
                        <Badge variant="outline" className="text-xs">
                          {tp.screen_key}:{tp.touch_point_key}
                        </Badge>
                        <Badge variant="secondary" className="text-xs">
                          {screenLabel}
                        </Badge>
                        {!tp.is_enabled && <Badge variant="destructive">معطّل</Badge>}
                      </div>
                      <p className="text-sm text-muted-foreground line-clamp-1">
                        {tp.description_ar || tp.prompt_template.substring(0, 80) + "..."}
                      </p>
                      <div className="flex items-center gap-4 mt-2 text-xs text-muted-foreground">
                        <span>🌡️ {tp.temperature}</span>
                        <span>📝 {tp.max_tokens} tokens</span>
                        <span>⏱️ {tp.cache_duration_seconds}s cache</span>
                        <span>📊 {tp.context_fields.length} حقول</span>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-2">
                      <Switch
                        checked={tp.is_enabled}
                        onCheckedChange={(checked) =>
                          toggleEnabled.mutate({ id: tp.id, is_enabled: checked })
                        }
                      />
                      <Button variant="ghost" size="icon" onClick={() => openEditDialog(tp)}>
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => setDeleteId(tp.id)}>
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })
        )}
      </div>

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteId} onOpenChange={() => setDeleteId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>حذف نقطة الذكاء الاصطناعي؟</AlertDialogTitle>
            <AlertDialogDescription>
              سيتم حذف هذه النقطة نهائياً. لا يمكن التراجع عن هذا الإجراء.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>إلغاء</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-destructive text-destructive-foreground"
            >
              حذف
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
