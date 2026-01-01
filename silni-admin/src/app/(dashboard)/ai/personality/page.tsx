"use client";

import { useState } from "react";
import { useAIPersonality, useUpdateAIPersonality } from "@/hooks/use-ai";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { Save, Brain, ChevronDown, ChevronUp, GripVertical } from "lucide-react";

export default function AIPersonalityPage() {
  const { data: sections, isLoading } = useAIPersonality();
  const updateSection = useUpdateAIPersonality();

  const [editingSection, setEditingSection] = useState<string | null>(null);
  const [sectionValues, setSectionValues] = useState<{
    section_name_ar: string;
    content_ar: string;
    content_en: string;
  }>({ section_name_ar: "", content_ar: "", content_en: "" });
  const [expandedSections, setExpandedSections] = useState<Set<string>>(new Set());

  const toggleSection = (id: string) => {
    setExpandedSections((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="space-y-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-24" />
          ))}
        </div>
      </div>
    );
  }

  const sortedSections = sections?.sort((a, b) => a.priority - b.priority) || [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">شخصية الذكاء الاصطناعي</h1>
        <p className="text-muted-foreground mt-1">
          تعديل أقسام الشخصية الأساسية للمساعد الذكي
        </p>
      </div>

      {/* Info Card */}
      <Card className="border-primary/20 bg-gradient-to-br from-primary/5 to-secondary/5">
        <CardContent className="pt-6">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-silni-teal to-silni-gold flex items-center justify-center">
              <Brain className="h-6 w-6 text-white" />
            </div>
            <div className="flex-1">
              <h3 className="font-semibold">نظام الشخصية</h3>
              <p className="text-muted-foreground text-sm mt-1">
                هذه الأقسام تُدمج معاً لتشكل شخصية واصل الكاملة. كل قسم يضيف جانباً مختلفاً
                من شخصيته وأسلوب تعامله مع المستخدمين.
              </p>
              <div className="flex gap-2 mt-3">
                <Badge variant="outline">{sortedSections.length} أقسام</Badge>
                <Badge variant="outline" className="bg-green-500/10 text-green-600">
                  {sortedSections.filter(s => s.is_active).length} نشط
                </Badge>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Personality Sections */}
      <div className="space-y-4">
        {sortedSections.map((section) => (
          <Card
            key={section.id}
            className={`transition-all ${!section.is_active ? "opacity-50" : ""}`}
          >
            <CardHeader
              className="cursor-pointer hover:bg-muted/50 transition-colors"
              onClick={() => toggleSection(section.id)}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="text-muted-foreground">
                    <GripVertical className="h-5 w-5" />
                  </div>
                  <div>
                    <CardTitle className="text-lg">{section.section_name_ar}</CardTitle>
                    <CardDescription className="flex items-center gap-2 mt-1">
                      <span>المفتاح: {section.section_key}</span>
                      <span>•</span>
                      <span>الأولوية: {section.priority}</span>
                    </CardDescription>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <Switch
                    checked={section.is_active}
                    onCheckedChange={(checked) => {
                      updateSection.mutate({ id: section.id, is_active: checked });
                    }}
                    onClick={(e) => e.stopPropagation()}
                  />
                  {expandedSections.has(section.id) ? (
                    <ChevronUp className="h-5 w-5 text-muted-foreground" />
                  ) : (
                    <ChevronDown className="h-5 w-5 text-muted-foreground" />
                  )}
                </div>
              </div>
            </CardHeader>

            {expandedSections.has(section.id) && (
              <CardContent className="pt-0">
                <div className="border-t pt-4 mt-2">
                  {editingSection === section.id ? (
                    <div className="space-y-4">
                      <div className="space-y-2">
                        <Label>اسم القسم (عربي)</Label>
                        <Input
                          value={sectionValues.section_name_ar}
                          onChange={(e) =>
                            setSectionValues((prev) => ({
                              ...prev,
                              section_name_ar: e.target.value,
                            }))
                          }
                        />
                      </div>
                      <div className="space-y-2">
                        <Label>المحتوى (عربي) *</Label>
                        <Textarea
                          value={sectionValues.content_ar}
                          onChange={(e) =>
                            setSectionValues((prev) => ({
                              ...prev,
                              content_ar: e.target.value,
                            }))
                          }
                          rows={8}
                          placeholder="تعليمات الشخصية لهذا القسم..."
                          className="font-mono text-sm"
                        />
                      </div>
                      <div className="space-y-2">
                        <Label>المحتوى (إنجليزي)</Label>
                        <Textarea
                          value={sectionValues.content_en}
                          onChange={(e) =>
                            setSectionValues((prev) => ({
                              ...prev,
                              content_en: e.target.value,
                            }))
                          }
                          rows={6}
                          placeholder="English personality instructions..."
                          dir="ltr"
                          className="font-mono text-sm"
                        />
                      </div>
                      <div className="flex gap-2 justify-end">
                        <Button
                          variant="outline"
                          onClick={() => setEditingSection(null)}
                        >
                          إلغاء
                        </Button>
                        <Button
                          onClick={() => {
                            updateSection.mutate({
                              id: section.id,
                              ...sectionValues,
                            });
                            setEditingSection(null);
                          }}
                          disabled={updateSection.isPending}
                        >
                          <Save className="h-4 w-4 ml-2" />
                          حفظ
                        </Button>
                      </div>
                    </div>
                  ) : (
                    <div className="space-y-4">
                      <div className="p-4 rounded-lg bg-muted/50 font-mono text-sm whitespace-pre-wrap max-h-64 overflow-y-auto">
                        {section.content_ar}
                      </div>
                      {section.content_en && (
                        <div className="p-4 rounded-lg bg-muted/30 font-mono text-sm whitespace-pre-wrap max-h-48 overflow-y-auto" dir="ltr">
                          {section.content_en}
                        </div>
                      )}
                      <Button
                        variant="outline"
                        onClick={() => {
                          setEditingSection(section.id);
                          setSectionValues({
                            section_name_ar: section.section_name_ar,
                            content_ar: section.content_ar,
                            content_en: section.content_en || "",
                          });
                        }}
                      >
                        تعديل المحتوى
                      </Button>
                    </div>
                  )}
                </div>
              </CardContent>
            )}
          </Card>
        ))}
      </div>

      {sortedSections.length === 0 && (
        <Card>
          <CardContent className="pt-6 text-center text-muted-foreground">
            <Brain className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p>لا توجد أقسام شخصية. يرجى إضافة أقسام في قاعدة البيانات.</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
