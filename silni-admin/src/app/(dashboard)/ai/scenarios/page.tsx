"use client";

import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  MessageSquare,
  Plus,
  Pencil,
  Trash2,
  GripVertical,
} from "lucide-react";
import {
  useCommunicationScenarios,
  useCreateCommunicationScenario,
  useUpdateCommunicationScenario,
  useDeleteCommunicationScenario,
  useToggleCommunicationScenarioActive,
  scenarioEmojis,
  scenarioColors,
  CommunicationScenario,
  CommunicationScenarioInput,
} from "@/hooks/use-communication-scenarios";

export default function CommunicationScenariosPage() {
  const { data: scenarios, isLoading } = useCommunicationScenarios();
  const createScenario = useCreateCommunicationScenario();
  const updateScenario = useUpdateCommunicationScenario();
  const deleteScenario = useDeleteCommunicationScenario();
  const toggleActive = useToggleCommunicationScenarioActive();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingScenario, setEditingScenario] = useState<CommunicationScenario | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const [formData, setFormData] = useState<CommunicationScenarioInput>({
    scenario_key: "",
    title_ar: "",
    title_en: null,
    description_ar: "",
    description_en: null,
    emoji: "💬",
    color_hex: "#2196F3",
    prompt_context: null,
    sort_order: 0,
    is_active: true,
  });

  const resetForm = () => {
    setFormData({
      scenario_key: "",
      title_ar: "",
      title_en: null,
      description_ar: "",
      description_en: null,
      emoji: "💬",
      color_hex: "#2196F3",
      prompt_context: null,
      sort_order: scenarios?.length || 0,
      is_active: true,
    });
    setEditingScenario(null);
  };

  const openEditDialog = (scenario: CommunicationScenario) => {
    setEditingScenario(scenario);
    setFormData({
      scenario_key: scenario.scenario_key,
      title_ar: scenario.title_ar,
      title_en: scenario.title_en,
      description_ar: scenario.description_ar,
      description_en: scenario.description_en,
      emoji: scenario.emoji,
      color_hex: scenario.color_hex,
      prompt_context: scenario.prompt_context,
      sort_order: scenario.sort_order,
      is_active: scenario.is_active,
    });
    setIsDialogOpen(true);
  };

  const handleSubmit = async () => {
    if (editingScenario) {
      await updateScenario.mutateAsync({ id: editingScenario.id, ...formData });
    } else {
      await createScenario.mutateAsync(formData);
    }
    setIsDialogOpen(false);
    resetForm();
  };

  const handleDelete = async () => {
    if (deleteId) {
      await deleteScenario.mutateAsync(deleteId);
      setDeleteId(null);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-cyan-600 rounded-2xl flex items-center justify-center shadow-lg">
            <MessageSquare className="h-7 w-7 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">سيناريوهات التواصل</h1>
            <p className="text-muted-foreground mt-1">
              سيناريوهات محادثة مُعرّفة مسبقاً لمساعدة المستخدمين في صياغة رسائلهم
            </p>
          </div>
        </div>

        <Dialog open={isDialogOpen} onOpenChange={(open) => {
          setIsDialogOpen(open);
          if (!open) resetForm();
        }}>
          <DialogTrigger asChild>
            <Button className="gap-2">
              <Plus className="h-4 w-4" />
              إضافة سيناريو
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>
                {editingScenario ? "تعديل السيناريو" : "إضافة سيناريو جديد"}
              </DialogTitle>
              <DialogDescription>
                سيناريوهات التواصل تساعد المستخدمين على صياغة رسائل مناسبة للمناسبات المختلفة
              </DialogDescription>
            </DialogHeader>

            <div className="grid gap-4 py-4">
              {/* Scenario Key */}
              <div className="space-y-2">
                <Label>مفتاح السيناريو (بالإنجليزية) *</Label>
                <Input
                  value={formData.scenario_key}
                  onChange={(e) =>
                    setFormData({ ...formData, scenario_key: e.target.value.toLowerCase().replace(/\s+/g, '_') })
                  }
                  placeholder="apology"
                  dir="ltr"
                  disabled={!!editingScenario}
                />
                <p className="text-xs text-muted-foreground">
                  معرّف فريد للسيناريو (لا يمكن تغييره بعد الإنشاء)
                </p>
              </div>

              {/* Titles */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>العنوان (عربي) *</Label>
                  <Input
                    value={formData.title_ar}
                    onChange={(e) =>
                      setFormData({ ...formData, title_ar: e.target.value })
                    }
                    placeholder="طلب مسامحة"
                    dir="rtl"
                  />
                </div>
                <div className="space-y-2">
                  <Label>العنوان (إنجليزي)</Label>
                  <Input
                    value={formData.title_en || ""}
                    onChange={(e) =>
                      setFormData({ ...formData, title_en: e.target.value || null })
                    }
                    placeholder="Seeking Forgiveness"
                    dir="ltr"
                  />
                </div>
              </div>

              {/* Descriptions */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>الوصف (عربي) *</Label>
                  <Input
                    value={formData.description_ar}
                    onChange={(e) =>
                      setFormData({ ...formData, description_ar: e.target.value })
                    }
                    placeholder="بعد خلاف أو سوء تفاهم"
                    dir="rtl"
                  />
                </div>
                <div className="space-y-2">
                  <Label>الوصف (إنجليزي)</Label>
                  <Input
                    value={formData.description_en || ""}
                    onChange={(e) =>
                      setFormData({ ...formData, description_en: e.target.value || null })
                    }
                    placeholder="After a disagreement"
                    dir="ltr"
                  />
                </div>
              </div>

              {/* Emoji & Color */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>الرمز التعبيري</Label>
                  <Select
                    value={formData.emoji}
                    onValueChange={(v) => setFormData({ ...formData, emoji: v })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {scenarioEmojis.map((emoji) => (
                        <SelectItem key={emoji.value} value={emoji.value}>
                          {emoji.value} {emoji.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>اللون</Label>
                  <div className="flex gap-2">
                    <Input
                      type="color"
                      value={formData.color_hex}
                      onChange={(e) =>
                        setFormData({ ...formData, color_hex: e.target.value })
                      }
                      className="w-12 h-10 p-1 cursor-pointer"
                    />
                    <Select
                      value={formData.color_hex}
                      onValueChange={(v) =>
                        setFormData({ ...formData, color_hex: v })
                      }
                    >
                      <SelectTrigger className="flex-1">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {scenarioColors.map((color) => (
                          <SelectItem key={color.value} value={color.value}>
                            <div className="flex items-center gap-2">
                              <div
                                className="w-4 h-4 rounded"
                                style={{ backgroundColor: color.value }}
                              />
                              {color.label}
                            </div>
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </div>

              {/* Prompt Context */}
              <div className="space-y-2">
                <Label>سياق إضافي للذكاء الاصطناعي</Label>
                <Textarea
                  value={formData.prompt_context || ""}
                  onChange={(e) =>
                    setFormData({ ...formData, prompt_context: e.target.value || null })
                  }
                  placeholder="توجيهات إضافية للذكاء الاصطناعي عند استخدام هذا السيناريو..."
                  dir="rtl"
                  rows={3}
                />
                <p className="text-xs text-muted-foreground">
                  يُضاف إلى prompt الذكاء الاصطناعي لتخصيص الاستجابة
                </p>
              </div>

              {/* Active */}
              <div className="flex items-center gap-2">
                <Switch
                  id="is_active"
                  checked={formData.is_active}
                  onCheckedChange={(v) =>
                    setFormData({ ...formData, is_active: v })
                  }
                />
                <Label htmlFor="is_active">مفعّل</Label>
              </div>
            </div>

            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => {
                  setIsDialogOpen(false);
                  resetForm();
                }}
              >
                إلغاء
              </Button>
              <Button
                onClick={handleSubmit}
                disabled={
                  !formData.scenario_key ||
                  !formData.title_ar ||
                  !formData.description_ar ||
                  createScenario.isPending ||
                  updateScenario.isPending
                }
              >
                {editingScenario ? "تحديث" : "إنشاء"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      {/* Scenarios List */}
      <div className="grid gap-4">
        {isLoading ? (
          [...Array(4)].map((_, i) => (
            <Card key={i}>
              <CardContent className="pt-6">
                <div className="flex items-center gap-4">
                  <Skeleton className="w-12 h-12 rounded-xl" />
                  <div className="flex-1">
                    <Skeleton className="h-5 w-32 mb-2" />
                    <Skeleton className="h-4 w-48" />
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        ) : scenarios?.length === 0 ? (
          <Card>
            <CardContent className="py-12 text-center">
              <MessageSquare className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
              <p className="text-muted-foreground">لا توجد سيناريوهات</p>
              <Button
                className="mt-4"
                onClick={() => setIsDialogOpen(true)}
              >
                إضافة سيناريو جديد
              </Button>
            </CardContent>
          </Card>
        ) : (
          scenarios?.map((scenario) => (
            <Card
              key={scenario.id}
              className={!scenario.is_active ? "opacity-60" : ""}
            >
              <CardContent className="pt-6">
                <div className="flex items-center gap-4">
                  {/* Drag Handle */}
                  <div className="cursor-grab text-muted-foreground hover:text-foreground">
                    <GripVertical className="h-5 w-5" />
                  </div>

                  {/* Icon */}
                  <div
                    className="w-12 h-12 rounded-xl flex items-center justify-center text-2xl shrink-0"
                    style={{ backgroundColor: `${scenario.color_hex}20` }}
                  >
                    {scenario.emoji}
                  </div>

                  {/* Content */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-semibold">{scenario.title_ar}</h3>
                      <Badge variant="outline" className="text-xs">
                        {scenario.scenario_key}
                      </Badge>
                      {!scenario.is_active && (
                        <Badge variant="secondary">معطّل</Badge>
                      )}
                    </div>
                    <p className="text-sm text-muted-foreground line-clamp-1">
                      {scenario.description_ar}
                    </p>
                    {scenario.prompt_context && (
                      <p className="text-xs text-muted-foreground mt-1 line-clamp-1">
                        📝 {scenario.prompt_context}
                      </p>
                    )}
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-2">
                    <Switch
                      checked={scenario.is_active}
                      onCheckedChange={(checked) =>
                        toggleActive.mutate({
                          id: scenario.id,
                          is_active: checked,
                        })
                      }
                    />
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => openEditDialog(scenario)}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => setDeleteId(scenario.id)}
                    >
                      <Trash2 className="h-4 w-4 text-destructive" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        )}
      </div>

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteId} onOpenChange={() => setDeleteId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>حذف السيناريو؟</AlertDialogTitle>
            <AlertDialogDescription>
              سيتم حذف هذا السيناريو نهائياً. لا يمكن التراجع عن هذا الإجراء.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>إلغاء</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-destructive text-destructive-foreground"
            >
              حذف
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
