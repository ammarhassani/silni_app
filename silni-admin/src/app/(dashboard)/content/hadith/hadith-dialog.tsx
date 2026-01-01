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
import { useCreateHadith, useUpdateHadith } from "@/hooks/use-hadith";
import type { AdminHadith } from "@/types/database";

const hadithSchema = z.object({
  hadith_text: z.string().min(10, "نص الحديث مطلوب (10 أحرف على الأقل)"),
  source: z.string().min(1, "المصدر مطلوب"),
  narrator: z.string().optional(),
  grade: z.enum(["صحيح", "حسن", "ضعيف", "موضوع"]).optional(),
  category: z.string().default("general"),
  display_priority: z.number().default(0),
  is_active: z.boolean().default(true),
});

type HadithFormData = z.infer<typeof hadithSchema>;

interface HadithDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  hadith: AdminHadith | null;
}

export function HadithDialog({ open, onOpenChange, hadith }: HadithDialogProps) {
  const createHadith = useCreateHadith();
  const updateHadith = useUpdateHadith();

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<HadithFormData>({
    resolver: zodResolver(hadithSchema),
    defaultValues: {
      hadith_text: "",
      source: "",
      narrator: "",
      grade: undefined,
      category: "general",
      display_priority: 0,
      is_active: true,
    },
  });

  useEffect(() => {
    if (hadith) {
      reset({
        hadith_text: hadith.hadith_text,
        source: hadith.source,
        narrator: hadith.narrator || "",
        grade: hadith.grade || undefined,
        category: hadith.category,
        display_priority: hadith.display_priority,
        is_active: hadith.is_active,
      });
    } else {
      reset({
        hadith_text: "",
        source: "",
        narrator: "",
        grade: undefined,
        category: "general",
        display_priority: 0,
        is_active: true,
      });
    }
  }, [hadith, reset]);

  const onSubmit = async (data: HadithFormData) => {
    try {
      // Convert undefined to null for database compatibility
      const dbData = {
        ...data,
        narrator: data.narrator ?? null,
        grade: data.grade ?? null,
      };

      if (hadith) {
        await updateHadith.mutateAsync({
          id: hadith.id,
          ...dbData,
          tags: hadith.tags, // Keep existing tags
        });
      } else {
        await createHadith.mutateAsync({
          ...dbData,
          tags: [],
        });
      }
      onOpenChange(false);
    } catch (error) {
      // Error is handled by the mutation
    }
  };

  const gradeValue = watch("grade");

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>
            {hadith ? "تعديل الحديث" : "إضافة حديث جديد"}
          </DialogTitle>
          <DialogDescription>
            {hadith
              ? "قم بتعديل بيانات الحديث"
              : "أضف حديثاً جديداً لعرضه في التطبيق"}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="hadith_text">نص الحديث *</Label>
            <Textarea
              id="hadith_text"
              {...register("hadith_text")}
              placeholder="أدخل نص الحديث الشريف..."
              rows={4}
            />
            {errors.hadith_text && (
              <p className="text-sm text-destructive">{errors.hadith_text.message}</p>
            )}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="source">المصدر *</Label>
              <Input
                id="source"
                {...register("source")}
                placeholder="مثال: صحيح البخاري"
              />
              {errors.source && (
                <p className="text-sm text-destructive">{errors.source.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="narrator">الراوي</Label>
              <Input
                id="narrator"
                {...register("narrator")}
                placeholder="مثال: أبو هريرة رضي الله عنه"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>درجة الحديث</Label>
              <Select
                value={gradeValue || ""}
                onValueChange={(value) =>
                  setValue("grade", value as HadithFormData["grade"])
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="اختر الدرجة" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="صحيح">صحيح</SelectItem>
                  <SelectItem value="حسن">حسن</SelectItem>
                  <SelectItem value="ضعيف">ضعيف</SelectItem>
                  <SelectItem value="موضوع">موضوع</SelectItem>
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

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
            >
              إلغاء
            </Button>
            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting
                ? "جاري الحفظ..."
                : hadith
                ? "حفظ التعديلات"
                : "إضافة الحديث"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
