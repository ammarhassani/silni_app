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
import { useCreateMOTD, useUpdateMOTD } from "@/hooks/use-content";
import type { AdminMOTD } from "@/types/database";
import { Loader2 } from "lucide-react";
import { RouteSelector } from "@/components/ui/route-selector";

const motdSchema = z.object({
  title: z.string().min(3, "العنوان مطلوب (3 أحرف على الأقل)"),
  message: z.string().min(10, "الرسالة مطلوبة (10 أحرف على الأقل)"),
  type: z.enum(["tip", "motivation", "reminder", "announcement", "celebration"]),
  icon: z.string().min(1, "الأيقونة مطلوبة"),
  background_start: z.string().default("#10B981"),
  background_end: z.string().default("#059669"),
  action_text: z.string().optional().nullable(),
  action_route: z.string().optional().nullable(),
  start_date: z.string().optional().nullable(),
  end_date: z.string().optional().nullable(),
  display_priority: z.number().default(0),
  is_active: z.boolean().default(true),
});

type MOTDFormData = z.infer<typeof motdSchema>;

interface MOTDDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  motd: AdminMOTD | null;
}

const types = [
  { value: "tip", label: "نصيحة", icon: "💡" },
  { value: "motivation", label: "تحفيز", icon: "🌟" },
  { value: "reminder", label: "تذكير", icon: "⏰" },
  { value: "announcement", label: "إعلان", icon: "📢" },
  { value: "celebration", label: "احتفال", icon: "🎉" },
];

const suggestedIcons = ["💡", "🌟", "⏰", "📢", "🎉", "❤️", "🕌", "📖", "🤲", "👨‍👩‍👧‍👦", "🎯", "✨"];

const gradientPresets = [
  { start: "#10B981", end: "#059669", label: "أخضر" },
  { start: "#3B82F6", end: "#1D4ED8", label: "أزرق" },
  { start: "#8B5CF6", end: "#6D28D9", label: "بنفسجي" },
  { start: "#F59E0B", end: "#D97706", label: "ذهبي" },
  { start: "#EC4899", end: "#BE185D", label: "وردي" },
  { start: "#6B7280", end: "#374151", label: "رمادي" },
];

export function MOTDDialog({ open, onOpenChange, motd }: MOTDDialogProps) {
  const createMOTD = useCreateMOTD();
  const updateMOTD = useUpdateMOTD();

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<MOTDFormData>({
    resolver: zodResolver(motdSchema),
    defaultValues: {
      title: "",
      message: "",
      type: "tip",
      icon: "💡",
      background_start: "#10B981",
      background_end: "#059669",
      action_text: "",
      action_route: "",
      start_date: "",
      end_date: "",
      display_priority: 0,
      is_active: true,
    },
  });

  const isSubmitting = createMOTD.isPending || updateMOTD.isPending;

  useEffect(() => {
    if (motd) {
      reset({
        title: motd.title,
        message: motd.message,
        type: motd.type,
        icon: motd.icon,
        background_start: motd.background_gradient?.start || "#10B981",
        background_end: motd.background_gradient?.end || "#059669",
        action_text: motd.action_text || "",
        action_route: motd.action_route || "",
        start_date: motd.start_date ? motd.start_date.split("T")[0] : "",
        end_date: motd.end_date ? motd.end_date.split("T")[0] : "",
        display_priority: motd.display_priority,
        is_active: motd.is_active,
      });
    } else {
      reset({
        title: "",
        message: "",
        type: "tip",
        icon: "💡",
        background_start: "#10B981",
        background_end: "#059669",
        action_text: "",
        action_route: "",
        start_date: "",
        end_date: "",
        display_priority: 0,
        is_active: true,
      });
    }
  }, [motd, reset]);

  const onSubmit = async (data: MOTDFormData) => {
    try {
      const payload = {
        title: data.title,
        message: data.message,
        type: data.type,
        icon: data.icon,
        background_gradient: {
          start: data.background_start,
          end: data.background_end,
        },
        action_text: data.action_text || null,
        action_route: data.action_route || null,
        start_date: data.start_date || null,
        end_date: data.end_date || null,
        display_priority: data.display_priority,
        is_active: data.is_active,
      };

      if (motd) {
        await updateMOTD.mutateAsync({ id: motd.id, ...payload });
      } else {
        await createMOTD.mutateAsync(payload);
      }
      onOpenChange(false);
    } catch {
      // Error is handled by the mutation
    }
  };

  const typeValue = watch("type");
  const iconValue = watch("icon");
  const backgroundStart = watch("background_start");
  const backgroundEnd = watch("background_end");
  const isActiveValue = watch("is_active");

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {motd ? "تعديل الرسالة" : "إضافة رسالة جديدة"}
          </DialogTitle>
          <DialogDescription>
            {motd ? "قم بتعديل بيانات الرسالة" : "أضف رسالة يومية جديدة"}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
          {/* Preview */}
          <div
            className="p-4 rounded-xl text-white"
            style={{
              background: `linear-gradient(135deg, ${backgroundStart}, ${backgroundEnd})`,
            }}
          >
            <div className="flex items-start gap-3">
              <span className="text-2xl">{iconValue}</span>
              <div>
                <p className="font-bold">{watch("title") || "العنوان"}</p>
                <p className="text-sm opacity-90">{watch("message") || "نص الرسالة..."}</p>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="title">العنوان *</Label>
              <Input
                id="title"
                {...register("title")}
                placeholder="مثال: نصيحة اليوم"
              />
              {errors.title && (
                <p className="text-sm text-destructive">{errors.title.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label>النوع *</Label>
              <Select
                value={typeValue}
                onValueChange={(value) => setValue("type", value as MOTDFormData["type"])}
              >
                <SelectTrigger>
                  <SelectValue placeholder="اختر النوع" />
                </SelectTrigger>
                <SelectContent>
                  {types.map((type) => (
                    <SelectItem key={type.value} value={type.value}>
                      {type.icon} {type.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="message">الرسالة *</Label>
            <Textarea
              id="message"
              {...register("message")}
              placeholder="أدخل نص الرسالة..."
              rows={3}
              className="resize-none"
            />
            {errors.message && (
              <p className="text-sm text-destructive">{errors.message.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label>الأيقونة *</Label>
            <div className="flex flex-wrap gap-2">
              {suggestedIcons.map((icon) => (
                <button
                  key={icon}
                  type="button"
                  onClick={() => setValue("icon", icon)}
                  className={`w-10 h-10 rounded-lg text-xl flex items-center justify-center transition-all ${
                    iconValue === icon
                      ? "bg-primary text-primary-foreground ring-2 ring-primary"
                      : "bg-muted hover:bg-muted/80"
                  }`}
                >
                  {icon}
                </button>
              ))}
              <Input
                {...register("icon")}
                placeholder="أو اكتب"
                className="w-20"
              />
            </div>
            {errors.icon && (
              <p className="text-sm text-destructive">{errors.icon.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label>التدرج اللوني</Label>
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
            <div className="grid grid-cols-2 gap-4 mt-2">
              <div className="flex items-center gap-2">
                <Input
                  type="color"
                  {...register("background_start")}
                  className="w-12 h-8 p-0 border-0"
                />
                <Input
                  {...register("background_start")}
                  placeholder="#10B981"
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
                  placeholder="#059669"
                  className="flex-1"
                />
              </div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="action_text">نص الزر (اختياري)</Label>
              <Input
                id="action_text"
                {...register("action_text")}
                placeholder="مثال: المزيد"
              />
            </div>

            <div className="space-y-2">
              <Label>مسار الإجراء (اختياري)</Label>
              <RouteSelector
                value={watch("action_route")}
                onChange={(value) => setValue("action_route", value || null)}
                placeholder="اختر المسار المستهدف"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="start_date">تاريخ البدء</Label>
              <Input
                id="start_date"
                type="date"
                {...register("start_date")}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="end_date">تاريخ الانتهاء</Label>
              <Input
                id="end_date"
                type="date"
                {...register("end_date")}
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="display_priority">أولوية العرض</Label>
              <Input
                id="display_priority"
                type="number"
                {...register("display_priority", { valueAsNumber: true })}
                placeholder="0"
              />
            </div>

            <div className="flex items-center gap-3 p-4 bg-muted/50 rounded-lg">
              <Switch
                id="is_active"
                checked={isActiveValue}
                onCheckedChange={(checked) => setValue("is_active", checked)}
              />
              <Label htmlFor="is_active" className="cursor-pointer">
                نشط
              </Label>
            </div>
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
              ) : motd ? (
                "حفظ التعديلات"
              ) : (
                "إضافة الرسالة"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
