"use client";

import { useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
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
  Bell,
  Plus,
  Pencil,
  Trash2,
  Clock,
  Users,
} from "lucide-react";
import {
  useReminderTemplates,
  useCreateReminderTemplate,
  useUpdateReminderTemplate,
  useDeleteReminderTemplate,
  useToggleReminderTemplateActive,
  frequencyOptions,
  templateEmojis,
  timePresets,
  ReminderTemplate,
  ReminderTemplateInput,
} from "@/hooks/use-reminder-templates";

export default function ReminderTemplatesPage() {
  const { data: templates, isLoading } = useReminderTemplates();
  const createTemplate = useCreateReminderTemplate();
  const updateTemplate = useUpdateReminderTemplate();
  const deleteTemplate = useDeleteReminderTemplate();
  const toggleActive = useToggleReminderTemplateActive();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingTemplate, setEditingTemplate] = useState<ReminderTemplate | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const [formData, setFormData] = useState<ReminderTemplateInput>({
    template_key: "",
    frequency: "daily",
    title_ar: "",
    title_en: null,
    description_ar: "",
    description_en: null,
    suggested_relationships_ar: "",
    suggested_relationships_en: null,
    default_time: "09:00",
    emoji: "📅",
    sort_order: 0,
    is_active: true,
  });

  const resetForm = () => {
    setFormData({
      template_key: "",
      frequency: "daily",
      title_ar: "",
      title_en: null,
      description_ar: "",
      description_en: null,
      suggested_relationships_ar: "",
      suggested_relationships_en: null,
      default_time: "09:00",
      emoji: "📅",
      sort_order: templates?.length || 0,
      is_active: true,
    });
    setEditingTemplate(null);
  };

  const openEditDialog = (template: ReminderTemplate) => {
    setEditingTemplate(template);
    setFormData({
      template_key: template.template_key,
      frequency: template.frequency,
      title_ar: template.title_ar,
      title_en: template.title_en,
      description_ar: template.description_ar,
      description_en: template.description_en,
      suggested_relationships_ar: template.suggested_relationships_ar,
      suggested_relationships_en: template.suggested_relationships_en,
      default_time: template.default_time,
      emoji: template.emoji,
      sort_order: template.sort_order,
      is_active: template.is_active,
    });
    setIsDialogOpen(true);
  };

  const handleSubmit = async () => {
    if (editingTemplate) {
      await updateTemplate.mutateAsync({ id: editingTemplate.id, ...formData });
    } else {
      await createTemplate.mutateAsync(formData);
    }
    setIsDialogOpen(false);
    resetForm();
  };

  const handleDelete = async () => {
    if (deleteId) {
      await deleteTemplate.mutateAsync(deleteId);
      setDeleteId(null);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center shadow-lg">
            <Bell className="h-7 w-7 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">قوالب التذكيرات</h1>
            <p className="text-muted-foreground mt-1">
              قوالب محددة مسبقاً لمساعدة المستخدمين في إنشاء تذكيرات
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
              إضافة قالب
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>
                {editingTemplate ? "تعديل القالب" : "إضافة قالب جديد"}
              </DialogTitle>
              <DialogDescription>
                قوالب التذكيرات تظهر للمستخدم عند إنشاء تذكير جديد
              </DialogDescription>
            </DialogHeader>

            <div className="grid gap-4 py-4">
              {/* Template Key & Frequency */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>مفتاح القالب *</Label>
                  <Input
                    value={formData.template_key}
                    onChange={(e) =>
                      setFormData({ ...formData, template_key: e.target.value.toLowerCase().replace(/\s+/g, '_') })
                    }
                    placeholder="daily"
                    dir="ltr"
                    disabled={!!editingTemplate}
                  />
                </div>
                <div className="space-y-2">
                  <Label>التكرار *</Label>
                  <Select
                    value={formData.frequency}
                    onValueChange={(v: ReminderTemplateInput['frequency']) => setFormData({ ...formData, frequency: v })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {frequencyOptions.map((opt) => (
                        <SelectItem key={opt.value} value={opt.value}>
                          {opt.emoji} {opt.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {/* Titles */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>العنوان (عربي) *</Label>
                  <Input
                    value={formData.title_ar}
                    onChange={(e) => setFormData({ ...formData, title_ar: e.target.value })}
                    placeholder="تذكير يومي"
                    dir="rtl"
                  />
                </div>
                <div className="space-y-2">
                  <Label>العنوان (إنجليزي)</Label>
                  <Input
                    value={formData.title_en || ""}
                    onChange={(e) => setFormData({ ...formData, title_en: e.target.value || null })}
                    placeholder="Daily Reminder"
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
                    onChange={(e) => setFormData({ ...formData, description_ar: e.target.value })}
                    placeholder="للأقارب الأقرب"
                    dir="rtl"
                  />
                </div>
                <div className="space-y-2">
                  <Label>الوصف (إنجليزي)</Label>
                  <Input
                    value={formData.description_en || ""}
                    onChange={(e) => setFormData({ ...formData, description_en: e.target.value || null })}
                    placeholder="For closest relatives"
                    dir="ltr"
                  />
                </div>
              </div>

              {/* Suggested Relationships */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>العلاقات المقترحة (عربي) *</Label>
                  <Input
                    value={formData.suggested_relationships_ar}
                    onChange={(e) => setFormData({ ...formData, suggested_relationships_ar: e.target.value })}
                    placeholder="أب، أم، زوج، زوجة"
                    dir="rtl"
                  />
                </div>
                <div className="space-y-2">
                  <Label>العلاقات المقترحة (إنجليزي)</Label>
                  <Input
                    value={formData.suggested_relationships_en || ""}
                    onChange={(e) => setFormData({ ...formData, suggested_relationships_en: e.target.value || null })}
                    placeholder="Father, Mother, Spouse"
                    dir="ltr"
                  />
                </div>
              </div>

              {/* Emoji, Time & Sort Order */}
              <div className="grid grid-cols-3 gap-4">
                <div className="space-y-2">
                  <Label>الرمز</Label>
                  <Select
                    value={formData.emoji}
                    onValueChange={(v) => setFormData({ ...formData, emoji: v })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {templateEmojis.map((emoji) => (
                        <SelectItem key={emoji.value} value={emoji.value}>
                          {emoji.value} {emoji.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>الوقت الافتراضي</Label>
                  <Select
                    value={formData.default_time}
                    onValueChange={(v) => setFormData({ ...formData, default_time: v })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {timePresets.map((time) => (
                        <SelectItem key={time.value} value={time.value}>
                          {time.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>الترتيب</Label>
                  <Input
                    type="number"
                    value={formData.sort_order}
                    onChange={(e) => setFormData({ ...formData, sort_order: parseInt(e.target.value) || 0 })}
                    min={0}
                  />
                </div>
              </div>

              {/* Active */}
              <div className="flex items-center gap-2">
                <Switch
                  id="is_active"
                  checked={formData.is_active}
                  onCheckedChange={(v) => setFormData({ ...formData, is_active: v })}
                />
                <Label htmlFor="is_active">مفعّل</Label>
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => { setIsDialogOpen(false); resetForm(); }}>
                إلغاء
              </Button>
              <Button
                onClick={handleSubmit}
                disabled={
                  !formData.template_key ||
                  !formData.title_ar ||
                  !formData.description_ar ||
                  !formData.suggested_relationships_ar ||
                  createTemplate.isPending ||
                  updateTemplate.isPending
                }
              >
                {editingTemplate ? "تحديث" : "إنشاء"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      {/* Templates List */}
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
        ) : templates?.length === 0 ? (
          <Card>
            <CardContent className="py-12 text-center">
              <Bell className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
              <p className="text-muted-foreground">لا توجد قوالب</p>
              <Button className="mt-4" onClick={() => setIsDialogOpen(true)}>
                إضافة قالب جديد
              </Button>
            </CardContent>
          </Card>
        ) : (
          templates?.map((template) => (
            <Card key={template.id} className={!template.is_active ? "opacity-60" : ""}>
              <CardContent className="pt-6">
                <div className="flex items-center gap-4">
                  {/* Icon */}
                  <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center text-2xl shrink-0">
                    {template.emoji}
                  </div>

                  {/* Content */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-semibold">{template.title_ar}</h3>
                      <Badge variant="outline">
                        {frequencyOptions.find(f => f.value === template.frequency)?.label}
                      </Badge>
                      {!template.is_active && <Badge variant="secondary">معطّل</Badge>}
                    </div>
                    <p className="text-sm text-muted-foreground">{template.description_ar}</p>
                    <div className="flex items-center gap-4 mt-2 text-xs text-muted-foreground">
                      <span className="flex items-center gap-1">
                        <Clock className="h-3 w-3" />
                        {template.default_time}
                      </span>
                      <span className="flex items-center gap-1">
                        <Users className="h-3 w-3" />
                        {template.suggested_relationships_ar}
                      </span>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-2">
                    <Switch
                      checked={template.is_active}
                      onCheckedChange={(checked) =>
                        toggleActive.mutate({ id: template.id, is_active: checked })
                      }
                    />
                    <Button variant="ghost" size="icon" onClick={() => openEditDialog(template)}>
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button variant="ghost" size="icon" onClick={() => setDeleteId(template.id)}>
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
            <AlertDialogTitle>حذف القالب؟</AlertDialogTitle>
            <AlertDialogDescription>
              سيتم حذف هذا القالب نهائياً. لا يمكن التراجع عن هذا الإجراء.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>إلغاء</AlertDialogCancel>
            <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground">
              حذف
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
