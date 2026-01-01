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
import { useCreateQuote, useUpdateQuote } from "@/hooks/use-content";
import type { AdminQuote } from "@/types/database";
import { Loader2 } from "lucide-react";

const quoteSchema = z.object({
  quote_text: z.string().min(5, "نص الاقتباس مطلوب (5 أحرف على الأقل)"),
  author: z.string().optional().nullable(),
  source: z.string().optional().nullable(),
  category: z.string().default("general"),
  display_priority: z.number().default(0),
  is_active: z.boolean().default(true),
});

type QuoteFormData = z.infer<typeof quoteSchema>;

interface QuoteDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  quote: AdminQuote | null;
}

const categories = [
  { value: "wisdom", label: "حكمة" },
  { value: "motivation", label: "تحفيز" },
  { value: "family", label: "عائلة" },
  { value: "islamic", label: "إسلامي" },
  { value: "general", label: "عام" },
];

export function QuoteDialog({ open, onOpenChange, quote }: QuoteDialogProps) {
  const createQuote = useCreateQuote();
  const updateQuote = useUpdateQuote();

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<QuoteFormData>({
    resolver: zodResolver(quoteSchema),
    defaultValues: {
      quote_text: "",
      author: "",
      source: "",
      category: "general",
      display_priority: 0,
      is_active: true,
    },
  });

  const isSubmitting = createQuote.isPending || updateQuote.isPending;

  useEffect(() => {
    if (quote) {
      reset({
        quote_text: quote.quote_text,
        author: quote.author || "",
        source: quote.source || "",
        category: quote.category,
        display_priority: quote.display_priority,
        is_active: quote.is_active,
      });
    } else {
      reset({
        quote_text: "",
        author: "",
        source: "",
        category: "general",
        display_priority: 0,
        is_active: true,
      });
    }
  }, [quote, reset]);

  const onSubmit = async (data: QuoteFormData) => {
    try {
      // Convert undefined to null for database compatibility
      const dbData = {
        ...data,
        author: data.author ?? null,
        source: data.source ?? null,
      };

      if (quote) {
        await updateQuote.mutateAsync({
          id: quote.id,
          ...dbData,
        });
      } else {
        await createQuote.mutateAsync({
          ...dbData,
          tags: [],
        });
      }
      onOpenChange(false);
    } catch {
      // Error is handled by the mutation
    }
  };

  const categoryValue = watch("category");
  const isActiveValue = watch("is_active");

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>
            {quote ? "تعديل الاقتباس" : "إضافة اقتباس جديد"}
          </DialogTitle>
          <DialogDescription>
            {quote
              ? "قم بتعديل بيانات الاقتباس"
              : "أضف اقتباساً جديداً لعرضه في التطبيق"}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="quote_text">نص الاقتباس *</Label>
            <Textarea
              id="quote_text"
              {...register("quote_text")}
              placeholder="أدخل نص الاقتباس..."
              rows={4}
              className="resize-none"
            />
            {errors.quote_text && (
              <p className="text-sm text-destructive">{errors.quote_text.message}</p>
            )}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="author">المؤلف</Label>
              <Input
                id="author"
                {...register("author")}
                placeholder="مثال: الإمام الشافعي"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="source">المصدر</Label>
              <Input
                id="source"
                {...register("source")}
                placeholder="مثال: ديوان الشافعي"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>التصنيف</Label>
              <Select
                value={categoryValue}
                onValueChange={(value) => setValue("category", value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="اختر التصنيف" />
                </SelectTrigger>
                <SelectContent>
                  {categories.map((cat) => (
                    <SelectItem key={cat.value} value={cat.value}>
                      {cat.label}
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
              <p className="text-xs text-muted-foreground">
                الأعلى يظهر أولاً
              </p>
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
              ) : quote ? (
                "حفظ التعديلات"
              ) : (
                "إضافة الاقتباس"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
