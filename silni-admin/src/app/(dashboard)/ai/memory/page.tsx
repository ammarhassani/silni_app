"use client";

import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
  useAIMemoryConfig,
  useUpdateAIMemoryConfig,
  useMemoryCategories,
  useUpdateMemoryCategory,
} from "@/hooks/use-ai";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { Slider } from "@/components/ui/slider";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Save, Brain, Database, Settings, FolderOpen, ShieldAlert, XCircle, CheckCircle, Plus, X } from "lucide-react";
import { Textarea } from "@/components/ui/textarea";

const memoryConfigSchema = z.object({
  max_memories_per_context: z.number().min(1).max(100),
  max_memories_for_relative: z.number().min(1).max(50),
  max_insights_displayed: z.number().min(1).max(20),
  importance_default: z.number().min(1).max(10),
  importance_min: z.number().min(1).max(5),
  importance_max: z.number().min(5).max(10),
  duplicate_match_threshold: z.number().min(0.1).max(1),
  cache_duration_minutes: z.number().min(1).max(1440),
  auto_cleanup_days: z.number().min(30).max(730),
});

type MemoryConfigFormData = z.infer<typeof memoryConfigSchema>;

export default function AIMemoryPage() {
  const { data: memoryConfig, isLoading: loadingConfig } = useAIMemoryConfig();
  const { data: categories, isLoading: loadingCategories } = useMemoryCategories();
  const updateConfig = useUpdateAIMemoryConfig();
  const updateCategory = useUpdateMemoryCategory();

  const [editingCategory, setEditingCategory] = useState<string | null>(null);
  const [categoryValues, setCategoryValues] = useState<{
    display_name_ar: string;
    display_name_en: string;
    icon_name: string;
    default_importance: number;
    auto_extract: boolean;
  }>({
    display_name_ar: "",
    display_name_en: "",
    icon_name: "",
    default_importance: 5,
    auto_extract: true,
  });

  // Extraction rules state
  const [extractionRules, setExtractionRules] = useState({
    skip_relative_facts: true,
    skip_keywords: [] as string[],
    extraction_instructions_ar: "",
    extraction_examples_ignore: [] as string[],
    extraction_examples_extract: [] as string[],
  });
  const [newKeyword, setNewKeyword] = useState("");
  const [newIgnoreExample, setNewIgnoreExample] = useState("");
  const [newExtractExample, setNewExtractExample] = useState("");
  const [extractionDirty, setExtractionDirty] = useState(false);

  // Load extraction rules from config
  useEffect(() => {
    if (memoryConfig) {
      setExtractionRules({
        skip_relative_facts: memoryConfig.skip_relative_facts ?? true,
        skip_keywords: memoryConfig.skip_keywords ?? [],
        extraction_instructions_ar: memoryConfig.extraction_instructions_ar ?? "",
        extraction_examples_ignore: memoryConfig.extraction_examples_ignore ?? [],
        extraction_examples_extract: memoryConfig.extraction_examples_extract ?? [],
      });
    }
  }, [memoryConfig]);

  const {
    register,
    handleSubmit,
    reset,
    watch,
    setValue,
    formState: { errors, isDirty },
  } = useForm<MemoryConfigFormData>({
    resolver: zodResolver(memoryConfigSchema),
  });

  const watchedValues = watch();

  useEffect(() => {
    if (memoryConfig) {
      reset({
        max_memories_per_context: memoryConfig.max_memories_per_context,
        max_memories_for_relative: memoryConfig.max_memories_for_relative,
        max_insights_displayed: memoryConfig.max_insights_displayed,
        importance_default: memoryConfig.importance_default,
        importance_min: memoryConfig.importance_min,
        importance_max: memoryConfig.importance_max,
        duplicate_match_threshold: memoryConfig.duplicate_match_threshold,
        cache_duration_minutes: memoryConfig.cache_duration_minutes,
        auto_cleanup_days: memoryConfig.auto_cleanup_days,
      });
    }
  }, [memoryConfig, reset]);

  const onSubmit = async (data: MemoryConfigFormData) => {
    updateConfig.mutate(data);
  };

  const isLoading = loadingConfig || loadingCategories;

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid grid-cols-2 gap-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-40" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">ذاكرة الذكاء الاصطناعي</h1>
        <p className="text-muted-foreground mt-1">
          إعدادات نظام ذاكرة واصل وفئات المعلومات
        </p>
      </div>

      <Tabs defaultValue="config">
        <TabsList>
          <TabsTrigger value="config" className="gap-2">
            <Settings className="h-4 w-4" />
            الإعدادات العامة
          </TabsTrigger>
          <TabsTrigger value="extraction" className="gap-2">
            <ShieldAlert className="h-4 w-4" />
            قواعد الاستخراج
          </TabsTrigger>
          <TabsTrigger value="categories" className="gap-2">
            <FolderOpen className="h-4 w-4" />
            فئات الذاكرة ({categories?.length})
          </TabsTrigger>
        </TabsList>

        <TabsContent value="config" className="mt-6">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            {/* Memory Limits */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Database className="h-5 w-5" />
                  حدود الذاكرة
                </CardTitle>
                <CardDescription>
                  تحديد كمية المعلومات التي يحتفظ بها واصل
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="grid grid-cols-3 gap-6">
                  <div className="space-y-2">
                    <Label>الذكريات لكل سياق</Label>
                    <Input
                      type="number"
                      {...register("max_memories_per_context", { valueAsNumber: true })}
                    />
                    <p className="text-xs text-muted-foreground">
                      الحد الأقصى للذكريات في المحادثة
                    </p>
                    {errors.max_memories_per_context && (
                      <p className="text-sm text-destructive">{errors.max_memories_per_context.message}</p>
                    )}
                  </div>
                  <div className="space-y-2">
                    <Label>الذكريات لكل قريب</Label>
                    <Input
                      type="number"
                      {...register("max_memories_for_relative", { valueAsNumber: true })}
                    />
                    <p className="text-xs text-muted-foreground">
                      ذكريات خاصة بكل قريب
                    </p>
                  </div>
                  <div className="space-y-2">
                    <Label>الرؤى المعروضة</Label>
                    <Input
                      type="number"
                      {...register("max_insights_displayed", { valueAsNumber: true })}
                    />
                    <p className="text-xs text-muted-foreground">
                      عدد الرؤى في واجهة المستخدم
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Importance Settings */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Brain className="h-5 w-5" />
                  نظام الأهمية
                </CardTitle>
                <CardDescription>
                  تحديد مقياس أهمية الذكريات
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="grid grid-cols-3 gap-6">
                  <div className="space-y-2">
                    <Label>الأهمية الافتراضية: {watchedValues.importance_default}</Label>
                    <Slider
                      value={[watchedValues.importance_default || 5]}
                      onValueChange={([value]) => setValue("importance_default", value, { shouldDirty: true })}
                      min={1}
                      max={10}
                      step={1}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>الحد الأدنى: {watchedValues.importance_min}</Label>
                    <Slider
                      value={[watchedValues.importance_min || 1]}
                      onValueChange={([value]) => setValue("importance_min", value, { shouldDirty: true })}
                      min={1}
                      max={5}
                      step={1}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>الحد الأقصى: {watchedValues.importance_max}</Label>
                    <Slider
                      value={[watchedValues.importance_max || 10]}
                      onValueChange={([value]) => setValue("importance_max", value, { shouldDirty: true })}
                      min={5}
                      max={10}
                      step={1}
                    />
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Performance Settings */}
            <Card>
              <CardHeader>
                <CardTitle>إعدادات الأداء</CardTitle>
                <CardDescription>
                  التخزين المؤقت والتنظيف
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="grid grid-cols-3 gap-6">
                  <div className="space-y-2">
                    <Label>عتبة التطابق للتكرار</Label>
                    <div className="flex items-center gap-2">
                      <Input
                        type="number"
                        step="0.1"
                        {...register("duplicate_match_threshold", { valueAsNumber: true })}
                      />
                      <span className="text-muted-foreground">%</span>
                    </div>
                    <p className="text-xs text-muted-foreground">
                      نسبة التشابه لاعتبار الذاكرة مكررة
                    </p>
                  </div>
                  <div className="space-y-2">
                    <Label>مدة التخزين المؤقت (دقائق)</Label>
                    <Input
                      type="number"
                      {...register("cache_duration_minutes", { valueAsNumber: true })}
                    />
                    <p className="text-xs text-muted-foreground">
                      مدة الاحتفاظ بالذاكرة في الكاش
                    </p>
                  </div>
                  <div className="space-y-2">
                    <Label>التنظيف التلقائي (أيام)</Label>
                    <Input
                      type="number"
                      {...register("auto_cleanup_days", { valueAsNumber: true })}
                    />
                    <p className="text-xs text-muted-foreground">
                      حذف الذكريات القديمة بعد
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Save Button */}
            <div className="flex justify-end">
              <Button
                type="submit"
                disabled={!isDirty || updateConfig.isPending}
                className="min-w-[120px]"
              >
                <Save className="h-4 w-4 ml-2" />
                {updateConfig.isPending ? "جاري الحفظ..." : "حفظ التغييرات"}
              </Button>
            </div>
          </form>
        </TabsContent>

        <TabsContent value="extraction" className="mt-6">
          <div className="space-y-6">
            {/* Skip Relative Facts Toggle */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <ShieldAlert className="h-5 w-5" />
                  تخطي معلومات الأقارب
                </CardTitle>
                <CardDescription>
                  تلقائياً يتم تجاهل استخراج أسماء الأقارب وصلات القرابة (البيانات موجودة في جدول الأقارب)
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex items-center justify-between p-4 rounded-lg bg-muted/50">
                  <div>
                    <p className="font-medium">تفعيل تخطي معلومات الأقارب</p>
                    <p className="text-sm text-muted-foreground">
                      لن يتم استخراج أسماء الأقارب وصلات القرابة لأنها موجودة بالفعل
                    </p>
                  </div>
                  <Switch
                    checked={extractionRules.skip_relative_facts}
                    onCheckedChange={(checked) => {
                      setExtractionRules(prev => ({ ...prev, skip_relative_facts: checked }));
                      setExtractionDirty(true);
                    }}
                  />
                </div>
              </CardContent>
            </Card>

            {/* Skip Keywords */}
            <Card>
              <CardHeader>
                <CardTitle>الكلمات المفتاحية للتخطي</CardTitle>
                <CardDescription>
                  إذا احتوت الذاكرة على أي من هذه الكلمات مع نمط "اسم هو/هي" سيتم تخطيها
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex flex-wrap gap-2">
                  {extractionRules.skip_keywords.map((keyword, index) => (
                    <Badge key={index} variant="secondary" className="gap-1 px-3 py-1">
                      {keyword}
                      <button
                        onClick={() => {
                          const newKeywords = extractionRules.skip_keywords.filter((_, i) => i !== index);
                          setExtractionRules(prev => ({ ...prev, skip_keywords: newKeywords }));
                          setExtractionDirty(true);
                        }}
                        className="hover:text-destructive"
                      >
                        <X className="h-3 w-3" />
                      </button>
                    </Badge>
                  ))}
                </div>
                <div className="flex gap-2">
                  <Input
                    placeholder="أضف كلمة مفتاحية..."
                    value={newKeyword}
                    onChange={(e) => setNewKeyword(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' && newKeyword.trim()) {
                        e.preventDefault();
                        setExtractionRules(prev => ({
                          ...prev,
                          skip_keywords: [...prev.skip_keywords, newKeyword.trim()]
                        }));
                        setNewKeyword("");
                        setExtractionDirty(true);
                      }
                    }}
                  />
                  <Button
                    variant="outline"
                    onClick={() => {
                      if (newKeyword.trim()) {
                        setExtractionRules(prev => ({
                          ...prev,
                          skip_keywords: [...prev.skip_keywords, newKeyword.trim()]
                        }));
                        setNewKeyword("");
                        setExtractionDirty(true);
                      }
                    }}
                  >
                    <Plus className="h-4 w-4" />
                  </Button>
                </div>
              </CardContent>
            </Card>

            {/* Extraction Instructions */}
            <Card>
              <CardHeader>
                <CardTitle>تعليمات الاستخراج</CardTitle>
                <CardDescription>
                  هذه التعليمات تُضاف لموجه الذكاء الاصطناعي عند استخراج الذكريات
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Textarea
                  value={extractionRules.extraction_instructions_ar}
                  onChange={(e) => {
                    setExtractionRules(prev => ({ ...prev, extraction_instructions_ar: e.target.value }));
                    setExtractionDirty(true);
                  }}
                  className="min-h-[200px] font-mono text-sm"
                  dir="rtl"
                />
              </CardContent>
            </Card>

            {/* Examples */}
            <div className="grid grid-cols-2 gap-6">
              {/* Ignore Examples */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-red-500">
                    <XCircle className="h-5 w-5" />
                    أمثلة للتجاهل
                  </CardTitle>
                  <CardDescription>
                    أمثلة على معلومات يجب عدم استخراجها
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-2">
                    {extractionRules.extraction_examples_ignore.map((example, index) => (
                      <div key={index} className="flex items-center gap-2 p-2 bg-red-500/10 rounded text-sm">
                        <span className="flex-1">{example}</span>
                        <button
                          onClick={() => {
                            const newExamples = extractionRules.extraction_examples_ignore.filter((_, i) => i !== index);
                            setExtractionRules(prev => ({ ...prev, extraction_examples_ignore: newExamples }));
                            setExtractionDirty(true);
                          }}
                          className="hover:text-destructive"
                        >
                          <X className="h-4 w-4" />
                        </button>
                      </div>
                    ))}
                  </div>
                  <div className="flex gap-2">
                    <Input
                      placeholder="أضف مثال..."
                      value={newIgnoreExample}
                      onChange={(e) => setNewIgnoreExample(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' && newIgnoreExample.trim()) {
                          e.preventDefault();
                          setExtractionRules(prev => ({
                            ...prev,
                            extraction_examples_ignore: [...prev.extraction_examples_ignore, newIgnoreExample.trim()]
                          }));
                          setNewIgnoreExample("");
                          setExtractionDirty(true);
                        }
                      }}
                    />
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => {
                        if (newIgnoreExample.trim()) {
                          setExtractionRules(prev => ({
                            ...prev,
                            extraction_examples_ignore: [...prev.extraction_examples_ignore, newIgnoreExample.trim()]
                          }));
                          setNewIgnoreExample("");
                          setExtractionDirty(true);
                        }
                      }}
                    >
                      <Plus className="h-4 w-4" />
                    </Button>
                  </div>
                </CardContent>
              </Card>

              {/* Extract Examples */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-green-500">
                    <CheckCircle className="h-5 w-5" />
                    أمثلة للاستخراج
                  </CardTitle>
                  <CardDescription>
                    أمثلة على معلومات يجب استخراجها
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-2">
                    {extractionRules.extraction_examples_extract.map((example, index) => (
                      <div key={index} className="flex items-center gap-2 p-2 bg-green-500/10 rounded text-sm">
                        <span className="flex-1">{example}</span>
                        <button
                          onClick={() => {
                            const newExamples = extractionRules.extraction_examples_extract.filter((_, i) => i !== index);
                            setExtractionRules(prev => ({ ...prev, extraction_examples_extract: newExamples }));
                            setExtractionDirty(true);
                          }}
                          className="hover:text-destructive"
                        >
                          <X className="h-4 w-4" />
                        </button>
                      </div>
                    ))}
                  </div>
                  <div className="flex gap-2">
                    <Input
                      placeholder="أضف مثال..."
                      value={newExtractExample}
                      onChange={(e) => setNewExtractExample(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' && newExtractExample.trim()) {
                          e.preventDefault();
                          setExtractionRules(prev => ({
                            ...prev,
                            extraction_examples_extract: [...prev.extraction_examples_extract, newExtractExample.trim()]
                          }));
                          setNewExtractExample("");
                          setExtractionDirty(true);
                        }
                      }}
                    />
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => {
                        if (newExtractExample.trim()) {
                          setExtractionRules(prev => ({
                            ...prev,
                            extraction_examples_extract: [...prev.extraction_examples_extract, newExtractExample.trim()]
                          }));
                          setNewExtractExample("");
                          setExtractionDirty(true);
                        }
                      }}
                    >
                      <Plus className="h-4 w-4" />
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Save Button */}
            <div className="flex justify-end">
              <Button
                onClick={() => {
                  updateConfig.mutate(extractionRules);
                  setExtractionDirty(false);
                }}
                disabled={!extractionDirty || updateConfig.isPending}
                className="min-w-[120px]"
              >
                <Save className="h-4 w-4 ml-2" />
                {updateConfig.isPending ? "جاري الحفظ..." : "حفظ قواعد الاستخراج"}
              </Button>
            </div>
          </div>
        </TabsContent>

        <TabsContent value="categories" className="mt-6">
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {categories?.map((category) => (
              <Card
                key={category.id}
                className={`cursor-pointer transition-all hover:shadow-md ${
                  !category.is_active ? "opacity-50" : ""
                }`}
                onClick={() => {
                  setEditingCategory(category.id);
                  setCategoryValues({
                    display_name_ar: category.display_name_ar,
                    display_name_en: category.display_name_en || "",
                    icon_name: category.icon_name,
                    default_importance: category.default_importance,
                    auto_extract: category.auto_extract,
                  });
                }}
              >
                <CardContent className="pt-6">
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="font-semibold">{category.display_name_ar}</h3>
                      <p className="text-sm text-muted-foreground">
                        {category.display_name_en}
                      </p>
                      <div className="flex gap-2 mt-3">
                        <Badge variant="outline">{category.category_key}</Badge>
                        <Badge variant="secondary">
                          أهمية: {category.default_importance}
                        </Badge>
                      </div>
                    </div>
                    <Switch
                      checked={category.is_active}
                      onCheckedChange={(checked) => {
                        updateCategory.mutate({ id: category.id, is_active: checked });
                      }}
                      onClick={(e) => e.stopPropagation()}
                    />
                  </div>
                  <div className="flex items-center gap-2 mt-3 text-xs text-muted-foreground">
                    {category.auto_extract ? (
                      <Badge variant="outline" className="bg-green-500/10 text-green-600">
                        استخراج تلقائي
                      </Badge>
                    ) : (
                      <Badge variant="outline">يدوي</Badge>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Edit Category Dialog */}
          {editingCategory && (
            <Card className="mt-6">
              <CardHeader>
                <CardTitle>تعديل فئة الذاكرة</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>الاسم (عربي)</Label>
                    <Input
                      value={categoryValues.display_name_ar}
                      onChange={(e) =>
                        setCategoryValues((prev) => ({
                          ...prev,
                          display_name_ar: e.target.value,
                        }))
                      }
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>الاسم (إنجليزي)</Label>
                    <Input
                      value={categoryValues.display_name_en}
                      onChange={(e) =>
                        setCategoryValues((prev) => ({
                          ...prev,
                          display_name_en: e.target.value,
                        }))
                      }
                      dir="ltr"
                    />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>الأيقونة</Label>
                    <Input
                      value={categoryValues.icon_name}
                      onChange={(e) =>
                        setCategoryValues((prev) => ({
                          ...prev,
                          icon_name: e.target.value,
                        }))
                      }
                      placeholder="brain"
                      dir="ltr"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>الأهمية الافتراضية: {categoryValues.default_importance}</Label>
                    <Slider
                      value={[categoryValues.default_importance]}
                      onValueChange={([value]) =>
                        setCategoryValues((prev) => ({
                          ...prev,
                          default_importance: value,
                        }))
                      }
                      min={1}
                      max={10}
                      step={1}
                    />
                  </div>
                </div>
                <div className="flex items-center justify-between p-4 rounded-lg bg-muted/50">
                  <div>
                    <p className="font-medium">الاستخراج التلقائي</p>
                    <p className="text-sm text-muted-foreground">
                      استخراج هذه الفئة تلقائياً من المحادثات
                    </p>
                  </div>
                  <Switch
                    checked={categoryValues.auto_extract}
                    onCheckedChange={(checked) =>
                      setCategoryValues((prev) => ({
                        ...prev,
                        auto_extract: checked,
                      }))
                    }
                  />
                </div>
                <div className="flex gap-2 justify-end">
                  <Button variant="outline" onClick={() => setEditingCategory(null)}>
                    إلغاء
                  </Button>
                  <Button
                    onClick={() => {
                      updateCategory.mutate({
                        id: editingCategory,
                        ...categoryValues,
                      });
                      setEditingCategory(null);
                    }}
                  >
                    <Save className="h-4 w-4 ml-2" />
                    حفظ
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

          {categories?.length === 0 && (
            <Card>
              <CardContent className="pt-6 text-center text-muted-foreground">
                <FolderOpen className="h-12 w-12 mx-auto mb-4 opacity-50" />
                <p>لا توجد فئات ذاكرة. يرجى إضافة فئات في قاعدة البيانات.</p>
              </CardContent>
            </Card>
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
}
