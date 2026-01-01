"use client";

import { useState } from "react";
import { useAIParameters, useUpdateAIParameters } from "@/hooks/use-ai";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Slider } from "@/components/ui/slider";
import { Save, Thermometer, Hash, Clock, Zap } from "lucide-react";
import type { AdminAIParameters } from "@/types/database";

export default function AIParametersPage() {
  const { data: parameters, isLoading } = useAIParameters();
  const updateParams = useUpdateAIParameters();
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editValues, setEditValues] = useState<Partial<AdminAIParameters>>({});

  const handleEdit = (param: AdminAIParameters) => {
    setEditingId(param.id);
    setEditValues({
      temperature: param.temperature,
      max_tokens: param.max_tokens,
      timeout_seconds: param.timeout_seconds,
      stream_enabled: param.stream_enabled,
    });
  };

  const handleSave = (id: string) => {
    updateParams.mutate({ id, ...editValues });
    setEditingId(null);
  };

  const handleCancel = () => {
    setEditingId(null);
    setEditValues({});
  };

  const featureLabels: Record<string, { name: string; icon: React.ReactNode; description: string }> = {
    chat: {
      name: "المحادثة",
      icon: <Zap className="h-5 w-5" />,
      description: "محادثة المستشار الذكي الرئيسية",
    },
    message_generation: {
      name: "توليد الرسائل",
      icon: <Zap className="h-5 w-5" />,
      description: "إنشاء رسائل للمناسبات والتواصل",
    },
    relationship_analysis: {
      name: "تحليل العلاقات",
      icon: <Zap className="h-5 w-5" />,
      description: "تحليل العلاقات الأسرية وتقديم التوصيات",
    },
    smart_reminders: {
      name: "التذكيرات الذكية",
      icon: <Zap className="h-5 w-5" />,
      description: "اقتراحات التذكيرات المخصصة",
    },
    memory_extraction: {
      name: "استخراج الذاكرة",
      icon: <Zap className="h-5 w-5" />,
      description: "استخراج المعلومات من المحادثات",
    },
    weekly_report: {
      name: "التقرير الأسبوعي",
      icon: <Zap className="h-5 w-5" />,
      description: "ملخص النشاط والتشجيع",
    },
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-4">
          {[1, 2, 3].map((i) => (
            <Card key={i}>
              <CardHeader>
                <Skeleton className="h-6 w-48" />
              </CardHeader>
              <CardContent>
                <Skeleton className="h-24 w-full" />
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">معاملات الذكاء الاصطناعي</h1>
        <p className="text-muted-foreground mt-1">
          ضبط درجة الحرارة والرموز لكل ميزة
        </p>
      </div>

      {/* Info Card */}
      <Card className="border-blue-200 bg-blue-50/50 dark:border-blue-900 dark:bg-blue-950/20">
        <CardContent className="pt-6">
          <div className="flex gap-4">
            <Thermometer className="h-6 w-6 text-blue-600 shrink-0" />
            <div className="space-y-1">
              <p className="font-medium">درجة الحرارة (Temperature)</p>
              <p className="text-sm text-muted-foreground">
                • <strong>0.0 - 0.3:</strong> دقيق ومتسق (مناسب لاستخراج البيانات)
                <br />
                • <strong>0.4 - 0.7:</strong> متوازن (مناسب للمحادثات)
                <br />
                • <strong>0.8 - 1.0:</strong> إبداعي ومتنوع (مناسب لتوليد الرسائل)
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Parameters Cards */}
      <div className="grid gap-4">
        {parameters?.map((param) => {
          const feature = featureLabels[param.feature_key] || {
            name: param.feature_key,
            icon: <Zap className="h-5 w-5" />,
            description: param.description || "",
          };
          const isEditing = editingId === param.id;

          return (
            <Card key={param.id}>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center text-primary">
                      {feature.icon}
                    </div>
                    <div>
                      <CardTitle className="text-lg">{feature.name}</CardTitle>
                      <CardDescription>{feature.description}</CardDescription>
                    </div>
                  </div>
                  {!isEditing && (
                    <Button variant="outline" size="sm" onClick={() => handleEdit(param)}>
                      تعديل
                    </Button>
                  )}
                </div>
              </CardHeader>
              <CardContent>
                {isEditing ? (
                  <div className="space-y-6">
                    {/* Temperature Slider */}
                    <div className="space-y-3">
                      <div className="flex items-center justify-between">
                        <Label className="flex items-center gap-2">
                          <Thermometer className="h-4 w-4" />
                          درجة الحرارة
                        </Label>
                        <span className="text-sm font-mono bg-muted px-2 py-1 rounded">
                          {editValues.temperature?.toFixed(2)}
                        </span>
                      </div>
                      <Slider
                        value={[editValues.temperature || 0.7]}
                        onValueChange={([value]) =>
                          setEditValues((prev) => ({ ...prev, temperature: value }))
                        }
                        min={0}
                        max={1}
                        step={0.05}
                      />
                    </div>

                    {/* Max Tokens */}
                    <div className="space-y-2">
                      <Label className="flex items-center gap-2">
                        <Hash className="h-4 w-4" />
                        الحد الأقصى للرموز
                      </Label>
                      <Input
                        type="number"
                        value={editValues.max_tokens || 2048}
                        onChange={(e) =>
                          setEditValues((prev) => ({
                            ...prev,
                            max_tokens: parseInt(e.target.value),
                          }))
                        }
                        min={100}
                        max={8000}
                      />
                    </div>

                    {/* Timeout */}
                    <div className="space-y-2">
                      <Label className="flex items-center gap-2">
                        <Clock className="h-4 w-4" />
                        المهلة (ثواني)
                      </Label>
                      <Input
                        type="number"
                        value={editValues.timeout_seconds || 30}
                        onChange={(e) =>
                          setEditValues((prev) => ({
                            ...prev,
                            timeout_seconds: parseInt(e.target.value),
                          }))
                        }
                        min={5}
                        max={120}
                      />
                    </div>

                    {/* Stream Enabled */}
                    <div className="flex items-center justify-between">
                      <Label>تفعيل البث المباشر</Label>
                      <Switch
                        checked={editValues.stream_enabled ?? true}
                        onCheckedChange={(checked) =>
                          setEditValues((prev) => ({ ...prev, stream_enabled: checked }))
                        }
                      />
                    </div>

                    {/* Actions */}
                    <div className="flex gap-2 justify-end">
                      <Button variant="outline" onClick={handleCancel}>
                        إلغاء
                      </Button>
                      <Button
                        onClick={() => handleSave(param.id)}
                        disabled={updateParams.isPending}
                      >
                        <Save className="h-4 w-4 ml-2" />
                        حفظ
                      </Button>
                    </div>
                  </div>
                ) : (
                  <div className="grid grid-cols-4 gap-4">
                    <div className="text-center p-3 rounded-lg bg-muted/50">
                      <p className="text-2xl font-bold text-primary">
                        {param.temperature.toFixed(2)}
                      </p>
                      <p className="text-xs text-muted-foreground">الحرارة</p>
                    </div>
                    <div className="text-center p-3 rounded-lg bg-muted/50">
                      <p className="text-2xl font-bold">{param.max_tokens}</p>
                      <p className="text-xs text-muted-foreground">الرموز</p>
                    </div>
                    <div className="text-center p-3 rounded-lg bg-muted/50">
                      <p className="text-2xl font-bold">{param.timeout_seconds}s</p>
                      <p className="text-xs text-muted-foreground">المهلة</p>
                    </div>
                    <div className="text-center p-3 rounded-lg bg-muted/50">
                      <p className="text-2xl font-bold">
                        {param.stream_enabled ? "✓" : "✗"}
                      </p>
                      <p className="text-xs text-muted-foreground">البث</p>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
