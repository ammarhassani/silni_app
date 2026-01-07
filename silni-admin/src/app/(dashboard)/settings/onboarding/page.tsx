"use client";

import { useState } from "react";
import {
  useOnboardingScreens,
  useCreateOnboardingScreen,
  useUpdateOnboardingScreen,
  useDeleteOnboardingScreen,
  useReorderOnboardingScreens,
  useToggleOnboardingActive,
  useDuplicateOnboardingScreen,
  animationOptions,
  tierOptions,
  type OnboardingScreen,
  type OnboardingScreenInput,
} from "@/hooks/use-onboarding";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
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
  Sparkles,
  Plus,
  Edit2,
  Trash2,
  Copy,
  GripVertical,
  ChevronUp,
  ChevronDown,
  Eye,
  EyeOff,
  Image,
  Play,
  Smartphone,
} from "lucide-react";

export default function OnboardingPage() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [previewOpen, setPreviewOpen] = useState(false);
  const [editingScreen, setEditingScreen] = useState<OnboardingScreen | null>(null);
  const [screenToDelete, setScreenToDelete] = useState<OnboardingScreen | null>(null);
  const [previewIndex, setPreviewIndex] = useState(0);

  // Queries
  const { data: screens, isLoading } = useOnboardingScreens();

  // Mutations
  const createScreen = useCreateOnboardingScreen();
  const updateScreen = useUpdateOnboardingScreen();
  const deleteScreen = useDeleteOnboardingScreen();
  const reorderScreens = useReorderOnboardingScreens();
  const toggleActive = useToggleOnboardingActive();
  const duplicateScreen = useDuplicateOnboardingScreen();

  // Form state
  const [formData, setFormData] = useState<OnboardingScreenInput>({
    screen_order: 1,
    title_ar: "",
    title_en: null,
    subtitle_ar: null,
    subtitle_en: null,
    image_url: null,
    animation_name: null,
    background_color: "#FFFFFF",
    background_gradient_start: null,
    background_gradient_end: null,
    text_color: "#1F2937",
    accent_color: null,
    button_text_ar: "التالي",
    button_text_en: "Next",
    button_color: null,
    skip_enabled: true,
    auto_advance_seconds: null,
    show_for_tiers: ["free", "max"],
    is_active: true,
  });

  const handleOpenCreate = () => {
    const nextOrder = (screens?.length || 0) + 1;
    setEditingScreen(null);
    setFormData({
      screen_order: nextOrder,
      title_ar: "",
      title_en: null,
      subtitle_ar: null,
      subtitle_en: null,
      image_url: null,
      animation_name: null,
      background_color: "#FFFFFF",
      background_gradient_start: null,
      background_gradient_end: null,
      text_color: "#1F2937",
      accent_color: null,
      button_text_ar: "التالي",
      button_text_en: "Next",
      button_color: null,
      skip_enabled: true,
      auto_advance_seconds: null,
      show_for_tiers: ["free", "max"],
      is_active: true,
    });
    setDialogOpen(true);
  };

  const handleOpenEdit = (screen: OnboardingScreen) => {
    setEditingScreen(screen);
    setFormData({
      screen_order: screen.screen_order,
      title_ar: screen.title_ar,
      title_en: screen.title_en,
      subtitle_ar: screen.subtitle_ar,
      subtitle_en: screen.subtitle_en,
      image_url: screen.image_url,
      animation_name: screen.animation_name,
      background_color: screen.background_color,
      background_gradient_start: screen.background_gradient_start,
      background_gradient_end: screen.background_gradient_end,
      text_color: screen.text_color,
      accent_color: screen.accent_color,
      button_text_ar: screen.button_text_ar,
      button_text_en: screen.button_text_en,
      button_color: screen.button_color,
      skip_enabled: screen.skip_enabled,
      auto_advance_seconds: screen.auto_advance_seconds,
      show_for_tiers: screen.show_for_tiers,
      is_active: screen.is_active,
    });
    setDialogOpen(true);
  };

  const handleSubmit = async () => {
    if (editingScreen) {
      await updateScreen.mutateAsync({ id: editingScreen.id, ...formData });
    } else {
      await createScreen.mutateAsync(formData);
    }
    setDialogOpen(false);
  };

  const handleDelete = async () => {
    if (screenToDelete) {
      await deleteScreen.mutateAsync(screenToDelete.id);
      setDeleteDialogOpen(false);
      setScreenToDelete(null);
    }
  };

  const handleMoveUp = (screen: OnboardingScreen) => {
    if (screen.screen_order > 1) {
      reorderScreens.mutate({
        screenId: screen.id,
        newOrder: screen.screen_order - 1,
      });
    }
  };

  const handleMoveDown = (screen: OnboardingScreen) => {
    if (screens && screen.screen_order < screens.length) {
      reorderScreens.mutate({
        screenId: screen.id,
        newOrder: screen.screen_order + 1,
      });
    }
  };

  const activeScreens = screens?.filter((s) => s.is_active) || [];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">شاشات التأهيل</h1>
          <p className="text-muted-foreground">
            إدارة شاشات الترحيب والتأهيل للمستخدمين الجدد
          </p>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            onClick={() => {
              setPreviewIndex(0);
              setPreviewOpen(true);
            }}
            disabled={activeScreens.length === 0}
          >
            <Eye className="h-4 w-4 ml-2" />
            معاينة
          </Button>
          <Button onClick={handleOpenCreate}>
            <Plus className="h-4 w-4 ml-2" />
            إضافة شاشة
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-primary/10 rounded-lg">
                <Sparkles className="h-5 w-5 text-primary" />
              </div>
              <div>
                <p className="text-2xl font-bold">{screens?.length || 0}</p>
                <p className="text-sm text-muted-foreground">إجمالي الشاشات</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-green-500/10 rounded-lg">
                <Eye className="h-5 w-5 text-green-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">{activeScreens.length}</p>
                <p className="text-sm text-muted-foreground">شاشة نشطة</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-500/10 rounded-lg">
                <Play className="h-5 w-5 text-amber-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">
                  {screens?.filter((s) => s.animation_name).length || 0}
                </p>
                <p className="text-sm text-muted-foreground">شاشة متحركة</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Screens List */}
      <Card>
        <CardHeader>
          <CardTitle>ترتيب الشاشات</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-3">
              {[...Array(3)].map((_, i) => (
                <Skeleton key={i} className="h-24 w-full" />
              ))}
            </div>
          ) : !screens?.length ? (
            <div className="text-center py-12 text-muted-foreground">
              <Sparkles className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>لا توجد شاشات تأهيل</p>
              <Button className="mt-4" onClick={handleOpenCreate}>
                إضافة أول شاشة
              </Button>
            </div>
          ) : (
            <div className="space-y-3">
              {screens.map((screen, index) => (
                <div
                  key={screen.id}
                  className="flex items-center gap-4 p-4 border rounded-lg bg-card hover:bg-accent/50 transition-colors"
                >
                  {/* Drag Handle & Order */}
                  <div className="flex items-center gap-2 text-muted-foreground">
                    <GripVertical className="h-5 w-5" />
                    <span className="w-6 h-6 rounded-full bg-primary text-primary-foreground text-sm flex items-center justify-center font-medium">
                      {screen.screen_order}
                    </span>
                  </div>

                  {/* Preview */}
                  <div
                    className="w-16 h-24 rounded-lg flex items-center justify-center text-xs"
                    style={{
                      backgroundColor: screen.background_color,
                      background: screen.background_gradient_start
                        ? `linear-gradient(180deg, ${screen.background_gradient_start}, ${screen.background_gradient_end || screen.background_color})`
                        : screen.background_color,
                    }}
                  >
                    {screen.animation_name ? (
                      <Play className="h-6 w-6" style={{ color: screen.text_color }} />
                    ) : screen.image_url ? (
                      <Image className="h-6 w-6" style={{ color: screen.text_color }} />
                    ) : (
                      <Smartphone
                        className="h-6 w-6"
                        style={{ color: screen.text_color }}
                      />
                    )}
                  </div>

                  {/* Content */}
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-medium">{screen.title_ar}</h3>
                      {!screen.is_active && (
                        <Badge variant="secondary">معطلة</Badge>
                      )}
                    </div>
                    <p className="text-sm text-muted-foreground line-clamp-1">
                      {screen.subtitle_ar || "بدون وصف"}
                    </p>
                    <div className="flex gap-2 mt-2">
                      {screen.animation_name && (
                        <Badge variant="outline" className="text-xs">
                          {
                            animationOptions.find(
                              (a) => a.value === screen.animation_name
                            )?.label || screen.animation_name
                          }
                        </Badge>
                      )}
                      {screen.skip_enabled && (
                        <Badge variant="outline" className="text-xs">
                          قابل للتخطي
                        </Badge>
                      )}
                      {screen.auto_advance_seconds && (
                        <Badge variant="outline" className="text-xs">
                          تلقائي {screen.auto_advance_seconds}ث
                        </Badge>
                      )}
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-1">
                    <Switch
                      checked={screen.is_active}
                      onCheckedChange={(checked) =>
                        toggleActive.mutate({ id: screen.id, is_active: checked })
                      }
                    />
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleMoveUp(screen)}
                      disabled={index === 0}
                    >
                      <ChevronUp className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleMoveDown(screen)}
                      disabled={index === screens.length - 1}
                    >
                      <ChevronDown className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => duplicateScreen.mutate(screen)}
                    >
                      <Copy className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleOpenEdit(screen)}
                    >
                      <Edit2 className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => {
                        setScreenToDelete(screen);
                        setDeleteDialogOpen(true);
                      }}
                    >
                      <Trash2 className="h-4 w-4 text-destructive" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Create/Edit Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {editingScreen ? "تعديل الشاشة" : "إضافة شاشة جديدة"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-6">
            {/* Basic Info */}
            <div className="space-y-4">
              <h4 className="font-medium text-sm text-muted-foreground">
                المحتوى
              </h4>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>العنوان (عربي) *</Label>
                  <Input
                    value={formData.title_ar}
                    onChange={(e) =>
                      setFormData({ ...formData, title_ar: e.target.value })
                    }
                    placeholder="مرحباً بك..."
                  />
                </div>
                <div className="space-y-2">
                  <Label>العنوان (إنجليزي)</Label>
                  <Input
                    value={formData.title_en || ""}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        title_en: e.target.value || null,
                      })
                    }
                    placeholder="Welcome..."
                    dir="ltr"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>الوصف (عربي)</Label>
                  <Textarea
                    value={formData.subtitle_ar || ""}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        subtitle_ar: e.target.value || null,
                      })
                    }
                    placeholder="وصف مختصر..."
                    rows={2}
                  />
                </div>
                <div className="space-y-2">
                  <Label>الوصف (إنجليزي)</Label>
                  <Textarea
                    value={formData.subtitle_en || ""}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        subtitle_en: e.target.value || null,
                      })
                    }
                    placeholder="Short description..."
                    rows={2}
                    dir="ltr"
                  />
                </div>
              </div>
            </div>

            {/* Visual Content */}
            <div className="space-y-4">
              <h4 className="font-medium text-sm text-muted-foreground">
                المحتوى المرئي
              </h4>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>الرسوم المتحركة</Label>
                  <Select
                    value={formData.animation_name || "none"}
                    onValueChange={(value) =>
                      setFormData({
                        ...formData,
                        animation_name: value === "none" ? null : value,
                      })
                    }
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="اختر رسوم متحركة" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="none">بدون رسوم</SelectItem>
                      {animationOptions.map((anim) => (
                        <SelectItem key={anim.value} value={anim.value}>
                          {anim.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>رابط الصورة</Label>
                  <Input
                    value={formData.image_url || ""}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        image_url: e.target.value || null,
                      })
                    }
                    placeholder="https://..."
                    dir="ltr"
                  />
                </div>
              </div>
            </div>

            {/* Styling */}
            <div className="space-y-4">
              <h4 className="font-medium text-sm text-muted-foreground">
                التصميم
              </h4>
              <div className="grid grid-cols-4 gap-4">
                <div className="space-y-2">
                  <Label>لون الخلفية</Label>
                  <div className="flex gap-2">
                    <Input
                      type="color"
                      value={formData.background_color}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          background_color: e.target.value,
                        })
                      }
                      className="w-12 h-10 p-1"
                    />
                    <Input
                      value={formData.background_color}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          background_color: e.target.value,
                        })
                      }
                      className="flex-1 font-mono"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label>لون النص</Label>
                  <div className="flex gap-2">
                    <Input
                      type="color"
                      value={formData.text_color}
                      onChange={(e) =>
                        setFormData({ ...formData, text_color: e.target.value })
                      }
                      className="w-12 h-10 p-1"
                    />
                    <Input
                      value={formData.text_color}
                      onChange={(e) =>
                        setFormData({ ...formData, text_color: e.target.value })
                      }
                      className="flex-1 font-mono"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label>بداية التدرج</Label>
                  <Input
                    value={formData.background_gradient_start || ""}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        background_gradient_start: e.target.value || null,
                      })
                    }
                    placeholder="#000000"
                    className="font-mono"
                  />
                </div>
                <div className="space-y-2">
                  <Label>نهاية التدرج</Label>
                  <Input
                    value={formData.background_gradient_end || ""}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        background_gradient_end: e.target.value || null,
                      })
                    }
                    placeholder="#FFFFFF"
                    className="font-mono"
                  />
                </div>
              </div>
            </div>

            {/* Button */}
            <div className="space-y-4">
              <h4 className="font-medium text-sm text-muted-foreground">الزر</h4>
              <div className="grid grid-cols-3 gap-4">
                <div className="space-y-2">
                  <Label>نص الزر (عربي)</Label>
                  <Input
                    value={formData.button_text_ar}
                    onChange={(e) =>
                      setFormData({ ...formData, button_text_ar: e.target.value })
                    }
                    placeholder="التالي"
                  />
                </div>
                <div className="space-y-2">
                  <Label>نص الزر (إنجليزي)</Label>
                  <Input
                    value={formData.button_text_en || ""}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        button_text_en: e.target.value || null,
                      })
                    }
                    placeholder="Next"
                    dir="ltr"
                  />
                </div>
                <div className="space-y-2">
                  <Label>لون الزر</Label>
                  <Input
                    value={formData.button_color || ""}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        button_color: e.target.value || null,
                      })
                    }
                    placeholder="تلقائي"
                    className="font-mono"
                  />
                </div>
              </div>
            </div>

            {/* Options */}
            <div className="space-y-4">
              <h4 className="font-medium text-sm text-muted-foreground">
                الخيارات
              </h4>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>التقدم التلقائي (ثواني)</Label>
                  <Input
                    type="number"
                    value={formData.auto_advance_seconds || ""}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        auto_advance_seconds: e.target.value
                          ? parseInt(e.target.value)
                          : null,
                      })
                    }
                    placeholder="يدوي فقط"
                    min={0}
                    max={30}
                  />
                </div>
                <div className="space-y-2">
                  <Label>الباقات المستهدفة</Label>
                  <div className="flex gap-4 pt-2">
                    {tierOptions.map((tier) => (
                      <label
                        key={tier.value}
                        className="flex items-center gap-2"
                      >
                        <Checkbox
                          checked={formData.show_for_tiers.includes(tier.value)}
                          onCheckedChange={(checked) => {
                            if (checked) {
                              setFormData({
                                ...formData,
                                show_for_tiers: [
                                  ...formData.show_for_tiers,
                                  tier.value,
                                ],
                              });
                            } else {
                              setFormData({
                                ...formData,
                                show_for_tiers: formData.show_for_tiers.filter(
                                  (t) => t !== tier.value
                                ),
                              });
                            }
                          }}
                        />
                        <span className="text-sm">{tier.label}</span>
                      </label>
                    ))}
                  </div>
                </div>
              </div>
              <div className="flex gap-6">
                <div className="flex items-center gap-2">
                  <Switch
                    checked={formData.skip_enabled}
                    onCheckedChange={(checked) =>
                      setFormData({ ...formData, skip_enabled: checked })
                    }
                  />
                  <Label>السماح بالتخطي</Label>
                </div>
                <div className="flex items-center gap-2">
                  <Switch
                    checked={formData.is_active}
                    onCheckedChange={(checked) =>
                      setFormData({ ...formData, is_active: checked })
                    }
                  />
                  <Label>نشطة</Label>
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSubmit}
              disabled={
                !formData.title_ar ||
                createScreen.isPending ||
                updateScreen.isPending
              }
            >
              {editingScreen ? "حفظ التغييرات" : "إضافة"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Preview Dialog */}
      <Dialog open={previewOpen} onOpenChange={setPreviewOpen}>
        <DialogContent className="max-w-sm p-0 overflow-hidden">
          <div className="relative">
            {/* Phone Frame */}
            <div className="bg-black p-2 rounded-[2rem]">
              <div
                className="relative w-full aspect-[9/16] rounded-[1.5rem] overflow-hidden flex flex-col items-center justify-center p-6 text-center"
                style={{
                  backgroundColor: activeScreens[previewIndex]?.background_color,
                  background: activeScreens[previewIndex]?.background_gradient_start
                    ? `linear-gradient(180deg, ${activeScreens[previewIndex].background_gradient_start}, ${activeScreens[previewIndex].background_gradient_end || activeScreens[previewIndex].background_color})`
                    : activeScreens[previewIndex]?.background_color,
                }}
              >
                {/* Skip Button */}
                {activeScreens[previewIndex]?.skip_enabled && (
                  <button
                    className="absolute top-4 left-4 text-sm opacity-70"
                    style={{ color: activeScreens[previewIndex]?.text_color }}
                  >
                    تخطي
                  </button>
                )}

                {/* Animation/Image Placeholder */}
                <div className="w-32 h-32 mb-8 rounded-full bg-white/20 flex items-center justify-center">
                  {activeScreens[previewIndex]?.animation_name ? (
                    <Play
                      className="h-12 w-12"
                      style={{ color: activeScreens[previewIndex]?.text_color }}
                    />
                  ) : (
                    <Image
                      className="h-12 w-12"
                      style={{ color: activeScreens[previewIndex]?.text_color }}
                    />
                  )}
                </div>

                {/* Content */}
                <h2
                  className="text-2xl font-bold mb-2"
                  style={{ color: activeScreens[previewIndex]?.text_color }}
                >
                  {activeScreens[previewIndex]?.title_ar}
                </h2>
                <p
                  className="text-sm opacity-80 mb-8"
                  style={{ color: activeScreens[previewIndex]?.text_color }}
                >
                  {activeScreens[previewIndex]?.subtitle_ar}
                </p>

                {/* Dots */}
                <div className="flex gap-2 mb-6">
                  {activeScreens.map((_, i) => (
                    <button
                      key={i}
                      className="w-2 h-2 rounded-full transition-all"
                      style={{
                        backgroundColor:
                          i === previewIndex
                            ? activeScreens[previewIndex]?.text_color
                            : `${activeScreens[previewIndex]?.text_color}40`,
                      }}
                      onClick={() => setPreviewIndex(i)}
                    />
                  ))}
                </div>

                {/* Button */}
                <button
                  className="w-full py-3 rounded-xl font-medium"
                  style={{
                    backgroundColor:
                      activeScreens[previewIndex]?.button_color ||
                      activeScreens[previewIndex]?.text_color,
                    color: activeScreens[previewIndex]?.background_color,
                  }}
                >
                  {activeScreens[previewIndex]?.button_text_ar}
                </button>
              </div>
            </div>

            {/* Navigation */}
            <div className="absolute bottom-4 left-0 right-0 flex justify-center gap-4">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPreviewIndex((i) => Math.max(0, i - 1))}
                disabled={previewIndex === 0}
              >
                السابق
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() =>
                  setPreviewIndex((i) =>
                    Math.min(activeScreens.length - 1, i + 1)
                  )
                }
                disabled={previewIndex === activeScreens.length - 1}
              >
                التالي
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>حذف الشاشة</AlertDialogTitle>
            <AlertDialogDescription>
              هل أنت متأكد من حذف شاشة &quot;{screenToDelete?.title_ar}&quot;؟
              <br />
              لا يمكن التراجع عن هذا الإجراء.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>إلغاء</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              حذف
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
