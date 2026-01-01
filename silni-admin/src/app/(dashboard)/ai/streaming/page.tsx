"use client";

import { useState, useEffect } from "react";
import { useAIStreamingConfig, useUpdateAIStreamingConfig } from "@/hooks/use-ai";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Slider } from "@/components/ui/slider";
import { Badge } from "@/components/ui/badge";
import { Zap, Clock, Type, Pause, Play, RotateCcw } from "lucide-react";

export default function StreamingConfigPage() {
  const { data: config, isLoading } = useAIStreamingConfig();
  const updateConfig = useUpdateAIStreamingConfig();

  const [formData, setFormData] = useState({
    sentence_end_delay_ms: 10,
    comma_delay_ms: 6,
    newline_delay_ms: 12,
    space_delay_ms: 2,
    word_min_delay_ms: 3,
    word_max_delay_ms: 5,
    is_streaming_enabled: true,
  });

  const [previewText, setPreviewText] = useState("");
  const [isPreviewRunning, setIsPreviewRunning] = useState(false);

  useEffect(() => {
    if (config) {
      setFormData({
        sentence_end_delay_ms: config.sentence_end_delay_ms,
        comma_delay_ms: config.comma_delay_ms,
        newline_delay_ms: config.newline_delay_ms,
        space_delay_ms: config.space_delay_ms,
        word_min_delay_ms: config.word_min_delay_ms,
        word_max_delay_ms: config.word_max_delay_ms,
        is_streaming_enabled: config.is_streaming_enabled,
      });
    }
  }, [config]);

  const handleSave = () => {
    updateConfig.mutate(formData);
  };

  const handleReset = () => {
    setFormData({
      sentence_end_delay_ms: 10,
      comma_delay_ms: 6,
      newline_delay_ms: 12,
      space_delay_ms: 2,
      word_min_delay_ms: 3,
      word_max_delay_ms: 5,
      is_streaming_enabled: true,
    });
  };

  const sampleText = "السلام عليكم! أنا واصل، مساعدك الشخصي. كيف يمكنني مساعدتك اليوم؟";

  const runPreview = async () => {
    setIsPreviewRunning(true);
    setPreviewText("");

    const words = sampleText.split(" ");
    let currentText = "";

    for (let i = 0; i < words.length; i++) {
      const word = words[i];

      for (let j = 0; j < word.length; j++) {
        const char = word[j];
        currentText += char;
        setPreviewText(currentText);

        // Calculate delay
        let delay = Math.random() * (formData.word_max_delay_ms - formData.word_min_delay_ms) + formData.word_min_delay_ms;

        if (char === "." || char === "!" || char === "؟") {
          delay = formData.sentence_end_delay_ms;
        } else if (char === "،" || char === ",") {
          delay = formData.comma_delay_ms;
        }

        await new Promise((r) => setTimeout(r, delay));
      }

      if (i < words.length - 1) {
        currentText += " ";
        setPreviewText(currentText);
        await new Promise((r) => setTimeout(r, formData.space_delay_ms));
      }
    }

    setIsPreviewRunning(false);
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
          <h1 className="text-3xl font-bold">إعدادات البث المباشر</h1>
          <p className="text-muted-foreground mt-1">
            تخصيص سرعة وتأخير ظهور النص أثناء استجابة الذكاء الاصطناعي
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={handleReset}>
            <RotateCcw className="h-4 w-4 ml-2" />
            إعادة الافتراضي
          </Button>
          <Button onClick={handleSave} disabled={updateConfig.isPending}>
            {updateConfig.isPending ? "جاري الحفظ..." : "حفظ التغييرات"}
          </Button>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Settings Card */}
        <Card>
          <CardHeader>
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                <Zap className="h-5 w-5 text-primary" />
              </div>
              <div>
                <CardTitle>إعدادات التأخير</CardTitle>
                <CardDescription>تحكم في سرعة ظهور النص (بالميلي ثانية)</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Enable Streaming */}
            <div className="flex items-center justify-between p-4 border rounded-lg">
              <div className="flex items-center gap-3">
                <Zap className="h-5 w-5 text-muted-foreground" />
                <div>
                  <p className="font-medium">تفعيل البث المباشر</p>
                  <p className="text-sm text-muted-foreground">
                    إظهار النص تدريجياً أثناء الاستجابة
                  </p>
                </div>
              </div>
              <Switch
                checked={formData.is_streaming_enabled}
                onCheckedChange={(c) => setFormData((f) => ({ ...f, is_streaming_enabled: c }))}
              />
            </div>

            {/* Word Delay Range */}
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <Label className="flex items-center gap-2">
                  <Type className="h-4 w-4" />
                  تأخير الحروف
                </Label>
                <Badge variant="secondary">
                  {formData.word_min_delay_ms} - {formData.word_max_delay_ms} مللي ثانية
                </Badge>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label className="text-xs text-muted-foreground">الحد الأدنى</Label>
                  <Input
                    type="number"
                    min={0}
                    max={100}
                    value={formData.word_min_delay_ms}
                    onChange={(e) =>
                      setFormData((f) => ({ ...f, word_min_delay_ms: parseInt(e.target.value) || 0 }))
                    }
                  />
                </div>
                <div className="space-y-2">
                  <Label className="text-xs text-muted-foreground">الحد الأقصى</Label>
                  <Input
                    type="number"
                    min={0}
                    max={100}
                    value={formData.word_max_delay_ms}
                    onChange={(e) =>
                      setFormData((f) => ({ ...f, word_max_delay_ms: parseInt(e.target.value) || 0 }))
                    }
                  />
                </div>
              </div>
            </div>

            {/* Punctuation Delays */}
            <div className="space-y-4">
              <Label className="flex items-center gap-2">
                <Pause className="h-4 w-4" />
                تأخير علامات الترقيم
              </Label>

              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm">نهاية الجملة (. ! ؟)</span>
                  <div className="flex items-center gap-2">
                    <Slider
                      value={[formData.sentence_end_delay_ms]}
                      onValueChange={([v]) => setFormData((f) => ({ ...f, sentence_end_delay_ms: v }))}
                      min={0}
                      max={50}
                      step={1}
                      className="w-32"
                    />
                    <span className="text-sm w-12 text-left">{formData.sentence_end_delay_ms}ms</span>
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <span className="text-sm">الفاصلة (، ,)</span>
                  <div className="flex items-center gap-2">
                    <Slider
                      value={[formData.comma_delay_ms]}
                      onValueChange={([v]) => setFormData((f) => ({ ...f, comma_delay_ms: v }))}
                      min={0}
                      max={30}
                      step={1}
                      className="w-32"
                    />
                    <span className="text-sm w-12 text-left">{formData.comma_delay_ms}ms</span>
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <span className="text-sm">سطر جديد</span>
                  <div className="flex items-center gap-2">
                    <Slider
                      value={[formData.newline_delay_ms]}
                      onValueChange={([v]) => setFormData((f) => ({ ...f, newline_delay_ms: v }))}
                      min={0}
                      max={50}
                      step={1}
                      className="w-32"
                    />
                    <span className="text-sm w-12 text-left">{formData.newline_delay_ms}ms</span>
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <span className="text-sm">المسافة</span>
                  <div className="flex items-center gap-2">
                    <Slider
                      value={[formData.space_delay_ms]}
                      onValueChange={([v]) => setFormData((f) => ({ ...f, space_delay_ms: v }))}
                      min={0}
                      max={20}
                      step={1}
                      className="w-32"
                    />
                    <span className="text-sm w-12 text-left">{formData.space_delay_ms}ms</span>
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Preview Card */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-green-500/10 flex items-center justify-center">
                  <Play className="h-5 w-5 text-green-500" />
                </div>
                <div>
                  <CardTitle>معاينة البث</CardTitle>
                  <CardDescription>شاهد كيف سيظهر النص للمستخدم</CardDescription>
                </div>
              </div>
              <Button
                variant="outline"
                onClick={runPreview}
                disabled={isPreviewRunning || !formData.is_streaming_enabled}
              >
                {isPreviewRunning ? (
                  <>
                    <Clock className="h-4 w-4 ml-2 animate-spin" />
                    جاري العرض...
                  </>
                ) : (
                  <>
                    <Play className="h-4 w-4 ml-2" />
                    تشغيل المعاينة
                  </>
                )}
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            <div className="min-h-40 p-4 bg-muted/50 rounded-lg border">
              <div className="flex items-start gap-3">
                <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center shrink-0">
                  <span className="text-white text-sm">و</span>
                </div>
                <div className="flex-1">
                  <p className="font-medium text-sm mb-1">واصل</p>
                  <p className="text-base leading-relaxed">
                    {previewText || (
                      <span className="text-muted-foreground">
                        اضغط على &quot;تشغيل المعاينة&quot; لمشاهدة كيف سيظهر النص
                      </span>
                    )}
                    {isPreviewRunning && (
                      <span className="inline-block w-2 h-4 bg-primary animate-pulse mr-1" />
                    )}
                  </p>
                </div>
              </div>
            </div>

            <div className="mt-4 p-3 bg-blue-500/10 border border-blue-500/20 rounded-lg">
              <p className="text-sm text-blue-500">
                <strong>ملاحظة:</strong> القيم الأقل تعني سرعة أعلى في ظهور النص.
                القيم المنخفضة جداً قد تجعل النص يظهر بسرعة كبيرة، بينما القيم
                العالية تجعل التجربة أبطأ وأكثر طبيعية.
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
