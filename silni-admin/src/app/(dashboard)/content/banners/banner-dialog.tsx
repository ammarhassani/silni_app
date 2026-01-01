"use client";

import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useCreateBanner, useUpdateBanner } from "@/hooks/use-content";
import type { AdminBanner } from "@/types/database";
import { Loader2, Image, Palette } from "lucide-react";

const bannerSchema = z.object({
  title: z.string().min(3, "العنوان مطلوب (3 أحرف على الأقل)"),
  description: z.string().optional().nullable(),
  background_type: z.enum(["image", "gradient"]),
  image_url: z.string().optional().nullable(),
  background_start: z.string().default("#3B82F6"),
  background_end: z.string().default("#1D4ED8"),
  action_type: z.enum(["route", "url", "action", "none"]),
  action_value: z.string().optional().nullable(),
  position: z.enum(["home_top", "home_bottom", "profile", "reminders"]),
  target_audience: z.enum(["all", "free", "max", "new_users"]),
  start_date: z.string().optional().nullable(),
  end_date: z.string().optional().nullable(),
  display_priority: z.number().default(0),
  is_active: z.boolean().default(true),
});

type BannerFormData = z.infer<typeof bannerSchema>;

interface BannerDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  banner: AdminBanner | null;
}

const positions = [
  { value: "home_top", label: "أعلى الرئيسية" },
  { value: "home_bottom", label: "أسفل الرئيسية" },
  { value: "profile", label: "الملف الشخصي" },
  { value: "reminders", label: "التذكيرات" },
];

const audiences = [
  { value: "all", label: "الجميع" },
  { value: "free", label: "المجاني" },
  { value: "max", label: "MAX" },
  { value: "new_users", label: "مستخدمون جدد" },
];

const actionTypes = [
  { value: "route", label: "مسار داخلي", placeholder: "/subscription" },
  { value: "url", label: "رابط خارجي", placeholder: "https://..." },
  { value: "action", label: "إجراء", placeholder: "show_upgrade_dialog" },
  { value: "none", label: "بدون إجراء", placeholder: "" },
];

const gradientPresets = [
  { start: "#3B82F6", end: "#1D4ED8", label: "أزرق" },
  { start: "#10B981", end: "#059669", label: "أخضر" },
  { start: "#8B5CF6", end: "#6D28D9", label: "بنفسجي" },
  { start: "#F59E0B", end: "#D97706", label: "ذهبي" },
  { start: "#EC4899", end: "#BE185D", label: "وردي" },
  { start: "#EF4444", end: "#B91C1C", label: "أحمر" },
];

export function BannerDialog({ open, onOpenChange, banner }: BannerDialogProps) {
  const createBanner = useCreateBanner();
  const updateBanner = useUpdateBanner();

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<BannerFormData>({
    resolver: zodResolver(bannerSchema),
    defaultValues: {
      title: "",
      description: "",
      background_type: "gradient",
      image_url: "",
      background_start: "#3B82F6",
      background_end: "#1D4ED8",
      action_type: "none",
      action_value: "",
      position: "home_top",
      target_audience: "all",
      start_date: "",
      end_date: "",
      display_priority: 0,
      is_active: true,
    },
  });

  const isSubmitting = createBanner.isPending || updateBanner.isPending;

  useEffect(() => {
    if (banner) {
      const hasGradient = banner.background_gradient && !banner.image_url;
      reset({
        title: banner.title,
        description: banner.description || "",
        background_type: hasGradient ? "gradient" : "image",
        image_url: banner.image_url || "",
        background_start: banner.background_gradient?.start || "#3B82F6",
        background_end: banner.background_gradient?.end || "#1D4ED8",
        action_type: banner.action_type,
        action_value: banner.action_value || "",
        position: banner.position,
        target_audience: banner.target_audience,
        start_date: banner.start_date ? banner.start_date.split("T")[0] : "",
        end_date: banner.end_date ? banner.end_date.split("T")[0] : "",
        display_priority: banner.display_priority,
        is_active: banner.is_active,
      });
    } else {
      reset({
        title: "",
        description: "",
        background_type: "gradient",
        image_url: "",
        background_start: "#3B82F6",
        background_end: "#1D4ED8",
        action_type: "none",
        action_value: "",
        position: "home_top",
        target_audience: "all",
        start_date: "",
        end_date: "",
        display_priority: 0,
        is_active: true,
      });
    }
  }, [banner, reset]);

  const onSubmit = async (data: BannerFormData) => {
    try {
      const payload = {
        title: data.title,
        description: data.description || null,
        image_url: data.background_type === "image" ? data.image_url : null,
        background_gradient:
          data.background_type === "gradient"
            ? { start: data.background_start, end: data.background_end }
            : null,
        action_type: data.action_type,
        action_value: data.action_type !== "none" ? data.action_value : null,
        position: data.position,
        target_audience: data.target_audience,
        start_date: data.start_date || null,
        end_date: data.end_date || null,
        display_priority: data.display_priority,
        is_active: data.is_active,
      };

      if (banner) {
        await updateBanner.mutateAsync({ id: banner.id, ...payload });
      } else {
        await createBanner.mutateAsync(payload);
      }
      onOpenChange(false);
    } catch {
      // Error is handled by the mutation
    }
  };

  const backgroundType = watch("background_type");
  const backgroundStart = watch("background_start");
  const backgroundEnd = watch("background_end");
  const imageUrl = watch("image_url");
  const actionType = watch("action_type");
  const position = watch("position");
  const targetAudience = watch("target_audience");
  const isActiveValue = watch("is_active");

  const selectedActionType = actionTypes.find((a) => a.value === actionType);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {banner ? "تعديل البانر" : "إضافة بانر جديد"}
          </DialogTitle>
          <DialogDescription>
            {banner ? "قم بتعديل بيانات البانر" : "أضف بانر إعلاني جديد"}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
          {/* Preview */}
          <div
            className="p-6 rounded-xl text-white min-h-[100px] flex items-center"
            style={
              backgroundType === "image" && imageUrl
                ? {
                    backgroundImage: `url(${imageUrl})`,
                    backgroundSize: "cover",
                    backgroundPosition: "center",
                  }
                : {
                    background: `linear-gradient(135deg, ${backgroundStart}, ${backgroundEnd})`,
                  }
            }
          >
            <div
              className={
                backgroundType === "image" && imageUrl
                  ? "bg-black/40 p-4 rounded-lg backdrop-blur-sm"
                  : ""
              }
            >
              <p className="font-bold text-lg">{watch("title") || "عنوان البانر"}</p>
              {watch("description") && (
                <p className="text-sm opacity-90">{watch("description")}</p>
              )}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="title">العنوان *</Label>
              <Input
                id="title"
                {...register("title")}
                placeholder="مثال: اشترك في MAX الآن"
              />
              {errors.title && (
                <p className="text-sm text-destructive">{errors.title.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label>الموقع *</Label>
              <Select
                value={position}
                onValueChange={(value) => setValue("position", value as BannerFormData["position"])}
              >
                <SelectTrigger>
                  <SelectValue placeholder="اختر الموقع" />
                </SelectTrigger>
                <SelectContent>
                  {positions.map((pos) => (
                    <SelectItem key={pos.value} value={pos.value}>
                      {pos.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">الوصف (اختياري)</Label>
            <Textarea
              id="description"
              {...register("description")}
              placeholder="وصف مختصر للبانر..."
              rows={2}
              className="resize-none"
            />
          </div>

          {/* Background Type */}
          <div className="space-y-4">
            <Label>الخلفية</Label>
            <Tabs
              value={backgroundType}
              onValueChange={(v) => setValue("background_type", v as "image" | "gradient")}
            >
              <TabsList className="grid w-full grid-cols-2">
                <TabsTrigger value="gradient" className="gap-2">
                  <Palette className="h-4 w-4" />
                  تدرج لوني
                </TabsTrigger>
                <TabsTrigger value="image" className="gap-2">
                  <Image className="h-4 w-4" />
                  صورة
                </TabsTrigger>
              </TabsList>

              <TabsContent value="gradient" className="space-y-4">
                <div className="flex flex-wrap gap-2">
                  {gradientPresets.map((preset) => (
                    <button
                      key={preset.label}
                      type="button"
                      onClick={() => {
                        setValue("background_start", preset.start);
                        setValue("background_end", preset.end);
                      }}
                      className={`px-3 py-2 rounded-lg text-sm text-white transition-all ${
                        backgroundStart === preset.start && backgroundEnd === preset.end
                          ? "ring-2 ring-primary ring-offset-2"
                          : ""
                      }`}
                      style={{
                        background: `linear-gradient(135deg, ${preset.start}, ${preset.end})`,
                      }}
                    >
                      {preset.label}
                    </button>
                  ))}
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="flex items-center gap-2">
                    <Input
                      type="color"
                      {...register("background_start")}
                      className="w-12 h-8 p-0 border-0"
                    />
                    <Input
                      {...register("background_start")}
                      placeholder="#3B82F6"
                      className="flex-1"
                    />
                  </div>
                  <div className="flex items-center gap-2">
                    <Input
                      type="color"
                      {...register("background_end")}
                      className="w-12 h-8 p-0 border-0"
                    />
                    <Input
                      {...register("background_end")}
                      placeholder="#1D4ED8"
                      className="flex-1"
                    />
                  </div>
                </div>
              </TabsContent>

              <TabsContent value="image" className="space-y-2">
                <Label htmlFor="image_url">رابط الصورة</Label>
                <Input
                  id="image_url"
                  {...register("image_url")}
                  placeholder="https://example.com/banner.jpg"
                />
                <p className="text-xs text-muted-foreground">
                  يُفضل استخدام صورة بأبعاد 1200x400 بكسل
                </p>
              </TabsContent>
            </Tabs>
          </div>

          {/* Action */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>نوع الإجراء</Label>
              <Select
                value={actionType}
                onValueChange={(value) =>
                  setValue("action_type", value as BannerFormData["action_type"])
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="اختر نوع الإجراء" />
                </SelectTrigger>
                <SelectContent>
                  {actionTypes.map((action) => (
                    <SelectItem key={action.value} value={action.value}>
                      {action.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {actionType !== "none" && (
              <div className="space-y-2">
                <Label htmlFor="action_value">قيمة الإجراء</Label>
                <Input
                  id="action_value"
                  {...register("action_value")}
                  placeholder={selectedActionType?.placeholder || ""}
                />
              </div>
            )}
          </div>

          {/* Targeting */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>الجمهور المستهدف</Label>
              <Select
                value={targetAudience}
                onValueChange={(value) =>
                  setValue("target_audience", value as BannerFormData["target_audience"])
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="اختر الجمهور" />
                </SelectTrigger>
                <SelectContent>
                  {audiences.map((aud) => (
                    <SelectItem key={aud.value} value={aud.value}>
                      {aud.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="display_priority">أولوية العرض</Label>
              <Input
                id="display_priority"
                type="number"
                {...register("display_priority", { valueAsNumber: true })}
                placeholder="0"
              />
            </div>
          </div>

          {/* Schedule */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="start_date">تاريخ البدء</Label>
              <Input id="start_date" type="date" {...register("start_date")} />
            </div>

            <div className="space-y-2">
              <Label htmlFor="end_date">تاريخ الانتهاء</Label>
              <Input id="end_date" type="date" {...register("end_date")} />
            </div>
          </div>

          <div className="flex items-center gap-3 p-4 bg-muted/50 rounded-lg">
            <Switch
              id="is_active"
              checked={isActiveValue}
              onCheckedChange={(checked) => setValue("is_active", checked)}
            />
            <Label htmlFor="is_active" className="cursor-pointer">
              نشط - يظهر في التطبيق
            </Label>
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={isSubmitting}
            >
              إلغاء
            </Button>
            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting ? (
                <>
                  <Loader2 className="h-4 w-4 ml-2 animate-spin" />
                  جاري الحفظ...
                </>
              ) : banner ? (
                "حفظ التعديلات"
              ) : (
                "إضافة البانر"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
