"use client";

import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useAIIdentity, useUpdateAIIdentity } from "@/hooks/use-ai";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Bot, Save } from "lucide-react";

const identitySchema = z.object({
  ai_name: z.string().min(1, "اسم الذكاء الاصطناعي مطلوب"),
  ai_name_en: z.string().optional(),
  ai_role_ar: z.string().min(1, "الدور مطلوب"),
  ai_role_en: z.string().optional(),
  greeting_message_ar: z.string().min(1, "رسالة الترحيب مطلوبة"),
  greeting_message_en: z.string().optional(),
  dialect: z.string().default("saudi_arabic"),
  personality_summary_ar: z.string().optional(),
});

type IdentityFormData = z.infer<typeof identitySchema>;

export default function AIIdentityPage() {
  const { data: identity, isLoading } = useAIIdentity();
  const updateIdentity = useUpdateAIIdentity();

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isDirty },
  } = useForm<IdentityFormData>({
    resolver: zodResolver(identitySchema),
  });

  useEffect(() => {
    if (identity) {
      reset({
        ai_name: identity.ai_name,
        ai_name_en: identity.ai_name_en || "",
        ai_role_ar: identity.ai_role_ar,
        ai_role_en: identity.ai_role_en || "",
        greeting_message_ar: identity.greeting_message_ar,
        greeting_message_en: identity.greeting_message_en || "",
        dialect: identity.dialect,
        personality_summary_ar: identity.personality_summary_ar || "",
      });
    }
  }, [identity, reset]);

  const onSubmit = async (data: IdentityFormData) => {
    updateIdentity.mutate(data);
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <Card>
          <CardHeader>
            <Skeleton className="h-6 w-48" />
          </CardHeader>
          <CardContent className="space-y-4">
            <Skeleton className="h-10 w-full" />
            <Skeleton className="h-10 w-full" />
            <Skeleton className="h-24 w-full" />
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">هوية الذكاء الاصطناعي</h1>
          <p className="text-muted-foreground mt-1">
            إعداد اسم ودور وشخصية المساعد الذكي
          </p>
        </div>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        {/* Preview Card */}
        <Card className="border-primary/20 bg-gradient-to-br from-primary/5 to-secondary/5">
          <CardContent className="pt-6">
            <div className="flex items-start gap-4">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-silni-teal to-silni-gold flex items-center justify-center">
                <Bot className="h-8 w-8 text-white" />
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-bold">{identity?.ai_name || "واصل"}</h3>
                <p className="text-muted-foreground text-sm">{identity?.ai_role_ar}</p>
                <div className="mt-3 p-3 rounded-lg bg-background/80 border">
                  <p className="text-sm">{identity?.greeting_message_ar}</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Identity Settings */}
        <Card>
          <CardHeader>
            <CardTitle>الاسم والدور</CardTitle>
            <CardDescription>
              تعريف هوية المساعد الذكي
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="ai_name">الاسم (عربي) *</Label>
                <Input
                  id="ai_name"
                  {...register("ai_name")}
                  placeholder="واصل"
                />
                {errors.ai_name && (
                  <p className="text-sm text-destructive">{errors.ai_name.message}</p>
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="ai_name_en">الاسم (إنجليزي)</Label>
                <Input
                  id="ai_name_en"
                  {...register("ai_name_en")}
                  placeholder="Wasel"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="ai_role_ar">الدور (عربي) *</Label>
              <Input
                id="ai_role_ar"
                {...register("ai_role_ar")}
                placeholder="مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية"
              />
              {errors.ai_role_ar && (
                <p className="text-sm text-destructive">{errors.ai_role_ar.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="ai_role_en">الدور (إنجليزي)</Label>
              <Input
                id="ai_role_en"
                {...register("ai_role_en")}
                placeholder="Smart assistant specialized in family connections"
                dir="ltr"
              />
            </div>
          </CardContent>
        </Card>

        {/* Greeting Message */}
        <Card>
          <CardHeader>
            <CardTitle>رسالة الترحيب</CardTitle>
            <CardDescription>
              الرسالة التي يظهرها المساعد عند بدء المحادثة
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="greeting_message_ar">رسالة الترحيب (عربي) *</Label>
              <Textarea
                id="greeting_message_ar"
                {...register("greeting_message_ar")}
                rows={3}
                placeholder="السلام عليكم! أنا واصل، مساعدك الشخصي لصلة الرحم..."
              />
              {errors.greeting_message_ar && (
                <p className="text-sm text-destructive">{errors.greeting_message_ar.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="greeting_message_en">رسالة الترحيب (إنجليزي)</Label>
              <Textarea
                id="greeting_message_en"
                {...register("greeting_message_en")}
                rows={3}
                placeholder="Hello! I'm Wasel, your personal assistant for family connections..."
                dir="ltr"
              />
            </div>
          </CardContent>
        </Card>

        {/* Personality Summary */}
        <Card>
          <CardHeader>
            <CardTitle>ملخص الشخصية</CardTitle>
            <CardDescription>
              وصف موجز لشخصية المساعد
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <Label htmlFor="personality_summary_ar">الملخص</Label>
              <Textarea
                id="personality_summary_ar"
                {...register("personality_summary_ar")}
                rows={4}
                placeholder="يتميز واصل بأسلوبه الودي والمحترم، ويستند في نصائحه إلى القيم الإسلامية..."
              />
            </div>
          </CardContent>
        </Card>

        {/* Save Button */}
        <div className="flex justify-end">
          <Button
            type="submit"
            disabled={!isDirty || updateIdentity.isPending}
            className="min-w-[120px]"
          >
            <Save className="h-4 w-4 ml-2" />
            {updateIdentity.isPending ? "جاري الحفظ..." : "حفظ التغييرات"}
          </Button>
        </div>
      </form>
    </div>
  );
}
