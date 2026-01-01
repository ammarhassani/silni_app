"use client";

import { useState } from "react";
import { useMessageOccasions, useUpdateMessageOccasion, useMessageTones, useUpdateMessageTone } from "@/hooks/use-ai";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Save, Calendar, MessageCircle } from "lucide-react";

export default function OccasionsPage() {
  const { data: occasions, isLoading: loadingOccasions } = useMessageOccasions();
  const { data: tones, isLoading: loadingTones } = useMessageTones();
  const updateOccasion = useUpdateMessageOccasion();
  const updateTone = useUpdateMessageTone();

  const [editingOccasion, setEditingOccasion] = useState<string | null>(null);
  const [editingTone, setEditingTone] = useState<string | null>(null);
  const [occasionValues, setOccasionValues] = useState<Record<string, string>>({});
  const [toneValues, setToneValues] = useState<Record<string, string>>({});

  const isLoading = loadingOccasions || loadingTones;

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <Skeleton key={i} className="h-32" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">المناسبات والنبرات</h1>
        <p className="text-muted-foreground mt-1">
          إدارة مناسبات الرسائل ونبرات التواصل
        </p>
      </div>

      <Tabs defaultValue="occasions">
        <TabsList>
          <TabsTrigger value="occasions" className="gap-2">
            <Calendar className="h-4 w-4" />
            المناسبات ({occasions?.length})
          </TabsTrigger>
          <TabsTrigger value="tones" className="gap-2">
            <MessageCircle className="h-4 w-4" />
            النبرات ({tones?.length})
          </TabsTrigger>
        </TabsList>

        <TabsContent value="occasions" className="mt-6">
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {occasions?.map((occasion) => (
              <Card
                key={occasion.id}
                className={`cursor-pointer transition-all hover:shadow-md ${
                  !occasion.is_active ? "opacity-50" : ""
                }`}
                onClick={() => {
                  setEditingOccasion(occasion.id);
                  setOccasionValues({
                    display_name_ar: occasion.display_name_ar,
                    emoji: occasion.emoji,
                    prompt_addition: occasion.prompt_addition || "",
                  });
                }}
              >
                <CardContent className="pt-6 text-center">
                  <div className="text-4xl mb-2">{occasion.emoji}</div>
                  <p className="font-medium">{occasion.display_name_ar}</p>
                  <p className="text-xs text-muted-foreground mt-1">
                    {occasion.display_name_en}
                  </p>
                  <div className="mt-3">
                    <Switch
                      checked={occasion.is_active}
                      onCheckedChange={(checked) => {
                        updateOccasion.mutate({ id: occasion.id, is_active: checked });
                      }}
                      onClick={(e) => e.stopPropagation()}
                    />
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Edit Occasion Dialog */}
          {editingOccasion && (
            <Card className="mt-6">
              <CardHeader>
                <CardTitle>تعديل المناسبة</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>الاسم (عربي)</Label>
                    <Input
                      value={occasionValues.display_name_ar || ""}
                      onChange={(e) =>
                        setOccasionValues((prev) => ({
                          ...prev,
                          display_name_ar: e.target.value,
                        }))
                      }
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>الرمز التعبيري</Label>
                    <Input
                      value={occasionValues.emoji || ""}
                      onChange={(e) =>
                        setOccasionValues((prev) => ({
                          ...prev,
                          emoji: e.target.value,
                        }))
                      }
                      className="text-center text-2xl"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label>إضافة للتعليمات</Label>
                  <Textarea
                    value={occasionValues.prompt_addition || ""}
                    onChange={(e) =>
                      setOccasionValues((prev) => ({
                        ...prev,
                        prompt_addition: e.target.value,
                      }))
                    }
                    placeholder="تعليمات إضافية للذكاء الاصطناعي عند هذه المناسبة..."
                    rows={3}
                  />
                </div>
                <div className="flex gap-2 justify-end">
                  <Button variant="outline" onClick={() => setEditingOccasion(null)}>
                    إلغاء
                  </Button>
                  <Button
                    onClick={() => {
                      updateOccasion.mutate({
                        id: editingOccasion,
                        ...occasionValues,
                      });
                      setEditingOccasion(null);
                    }}
                  >
                    <Save className="h-4 w-4 ml-2" />
                    حفظ
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="tones" className="mt-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {tones?.map((tone) => (
              <Card
                key={tone.id}
                className={`cursor-pointer transition-all hover:shadow-md ${
                  !tone.is_active ? "opacity-50" : ""
                }`}
                onClick={() => {
                  setEditingTone(tone.id);
                  setToneValues({
                    display_name_ar: tone.display_name_ar,
                    emoji: tone.emoji,
                    prompt_modifier: tone.prompt_modifier || "",
                  });
                }}
              >
                <CardContent className="pt-6 text-center">
                  <div className="text-4xl mb-2">{tone.emoji}</div>
                  <p className="font-medium">{tone.display_name_ar}</p>
                  <p className="text-xs text-muted-foreground mt-1">
                    {tone.display_name_en}
                  </p>
                  <div className="mt-3">
                    <Switch
                      checked={tone.is_active}
                      onCheckedChange={(checked) => {
                        updateTone.mutate({ id: tone.id, is_active: checked });
                      }}
                      onClick={(e) => e.stopPropagation()}
                    />
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Edit Tone Dialog */}
          {editingTone && (
            <Card className="mt-6">
              <CardHeader>
                <CardTitle>تعديل النبرة</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>الاسم (عربي)</Label>
                    <Input
                      value={toneValues.display_name_ar || ""}
                      onChange={(e) =>
                        setToneValues((prev) => ({
                          ...prev,
                          display_name_ar: e.target.value,
                        }))
                      }
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>الرمز التعبيري</Label>
                    <Input
                      value={toneValues.emoji || ""}
                      onChange={(e) =>
                        setToneValues((prev) => ({
                          ...prev,
                          emoji: e.target.value,
                        }))
                      }
                      className="text-center text-2xl"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label>تعديل التعليمات</Label>
                  <Textarea
                    value={toneValues.prompt_modifier || ""}
                    onChange={(e) =>
                      setToneValues((prev) => ({
                        ...prev,
                        prompt_modifier: e.target.value,
                      }))
                    }
                    placeholder="كيف يجب أن يعدل الذكاء الاصطناعي أسلوبه..."
                    rows={3}
                  />
                </div>
                <div className="flex gap-2 justify-end">
                  <Button variant="outline" onClick={() => setEditingTone(null)}>
                    إلغاء
                  </Button>
                  <Button
                    onClick={() => {
                      updateTone.mutate({
                        id: editingTone,
                        ...toneValues,
                      });
                      setEditingTone(null);
                    }}
                  >
                    <Save className="h-4 w-4 ml-2" />
                    حفظ
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
}
