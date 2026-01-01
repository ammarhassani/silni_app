"use client";

import { useState } from "react";
import {
  useNotificationTemplates,
  useCreateNotificationTemplate,
  useUpdateNotificationTemplate,
  useDeleteNotificationTemplate,
} from "@/hooks/use-notifications";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Plus,
  Pencil,
  Trash2,
  Bell,
  Clock,
  Award,
  TrendingUp,
  Target,
  Settings,
  Megaphone,
  Flame,
} from "lucide-react";
import type { AdminNotificationTemplate } from "@/types/database";

const CATEGORIES = [
  { value: "reminder", label: "التذكيرات", icon: Clock, color: "bg-blue-500" },
  { value: "streak", label: "السلسلة", icon: Flame, color: "bg-orange-500" },
  { value: "badge", label: "الأوسمة", icon: Award, color: "bg-yellow-500" },
  { value: "level", label: "المستويات", icon: TrendingUp, color: "bg-green-500" },
  { value: "challenge", label: "التحديات", icon: Target, color: "bg-purple-500" },
  { value: "system", label: "النظام", icon: Settings, color: "bg-gray-500" },
  { value: "promotional", label: "ترويجي", icon: Megaphone, color: "bg-pink-500" },
];

const PRIORITIES = [
  { value: "min", label: "أدنى" },
  { value: "low", label: "منخفض" },
  { value: "default", label: "افتراضي" },
  { value: "high", label: "مرتفع" },
  { value: "max", label: "أقصى" },
];

type TemplateFormData = Omit<AdminNotificationTemplate, "id" | "created_at" | "updated_at">;

const defaultFormData: TemplateFormData = {
  template_key: "",
  title_ar: "",
  title_en: "",
  body_ar: "",
  body_en: "",
  category: "reminder",
  variables: [],
  icon: null,
  sound: "default",
  channel_id: "default",
  priority: "default",
  is_active: true,
};

export default function NotificationTemplatesPage() {
  const { data: templates, isLoading } = useNotificationTemplates();
  const createTemplate = useCreateNotificationTemplate();
  const updateTemplate = useUpdateNotificationTemplate();
  const deleteTemplate = useDeleteNotificationTemplate();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingTemplate, setEditingTemplate] = useState<AdminNotificationTemplate | null>(null);
  const [formData, setFormData] = useState<TemplateFormData>(defaultFormData);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState("all");
  const [variablesInput, setVariablesInput] = useState("");

  const handleOpenCreate = () => {
    setEditingTemplate(null);
    setFormData(defaultFormData);
    setVariablesInput("");
    setIsDialogOpen(true);
  };

  const handleOpenEdit = (template: AdminNotificationTemplate) => {
    setEditingTemplate(template);
    setFormData({
      template_key: template.template_key,
      title_ar: template.title_ar,
      title_en: template.title_en || "",
      body_ar: template.body_ar,
      body_en: template.body_en || "",
      category: template.category,
      variables: template.variables || [],
      icon: template.icon,
      sound: template.sound,
      channel_id: template.channel_id,
      priority: template.priority,
      is_active: template.is_active,
    });
    setVariablesInput(template.variables?.join(", ") || "");
    setIsDialogOpen(true);
  };

  const handleSave = () => {
    const variables = variablesInput
      .split(",")
      .map((v) => v.trim())
      .filter(Boolean);

    const data = {
      ...formData,
      title_en: formData.title_en || null,
      body_en: formData.body_en || null,
      variables,
    };

    if (editingTemplate) {
      updateTemplate.mutate(
        { id: editingTemplate.id, ...data },
        { onSuccess: () => setIsDialogOpen(false) }
      );
    } else {
      createTemplate.mutate(data, { onSuccess: () => setIsDialogOpen(false) });
    }
  };

  const handleDelete = (id: string) => {
    deleteTemplate.mutate(id, { onSuccess: () => setDeleteConfirm(null) });
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-4 grid-cols-7">
          {[1, 2, 3, 4, 5, 6, 7].map((i) => (
            <Skeleton key={i} className="h-24" />
          ))}
        </div>
        <Skeleton className="h-96" />
      </div>
    );
  }

  const groupedTemplates = templates?.reduce((acc, t) => {
    if (!acc[t.category]) acc[t.category] = [];
    acc[t.category].push(t);
    return acc;
  }, {} as Record<string, AdminNotificationTemplate[]>) || {};

  const filteredTemplates =
    activeTab === "all"
      ? templates
      : templates?.filter((t) => t.category === activeTab);

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">قوالب الإشعارات</h1>
          <p className="text-muted-foreground mt-1">
            إدارة قوالب الإشعارات والرسائل
          </p>
        </div>
        <Button onClick={handleOpenCreate}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة قالب
        </Button>
      </div>

      {/* Category Stats */}
      <div className="grid grid-cols-7 gap-4">
        {CATEGORIES.map((cat) => {
          const Icon = cat.icon;
          return (
            <Card
              key={cat.value}
              className={`cursor-pointer transition-all hover:shadow-md ${
                activeTab === cat.value ? "ring-2 ring-primary" : ""
              }`}
              onClick={() => setActiveTab(cat.value)}
            >
              <CardContent className="pt-4 text-center">
                <div
                  className={`h-8 w-8 mx-auto rounded-full ${cat.color} flex items-center justify-center mb-2`}
                >
                  <Icon className="h-4 w-4 text-white" />
                </div>
                <p className="text-xl font-bold">{groupedTemplates[cat.value]?.length || 0}</p>
                <p className="text-xs text-muted-foreground">{cat.label}</p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Templates List */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>قائمة القوالب</CardTitle>
              <CardDescription>
                {templates?.length || 0} قالب إشعار
              </CardDescription>
            </div>
            <Button
              variant={activeTab === "all" ? "default" : "outline"}
              size="sm"
              onClick={() => setActiveTab("all")}
            >
              عرض الكل
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {!filteredTemplates?.length ? (
            <div className="text-center py-12 text-muted-foreground">
              <Bell className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>لا توجد قوالب</p>
            </div>
          ) : (
            <div className="space-y-4">
              {filteredTemplates.map((template) => {
                const cat = CATEGORIES.find((c) => c.value === template.category);
                const Icon = cat?.icon || Bell;

                return (
                  <Card key={template.id} className={!template.is_active ? "opacity-60" : ""}>
                    <CardContent className="pt-4">
                      <div className="flex items-start gap-4">
                        <div
                          className={`w-10 h-10 rounded-lg ${cat?.color || "bg-gray-500"} flex items-center justify-center flex-shrink-0`}
                        >
                          <Icon className="h-5 w-5 text-white" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <h4 className="font-semibold">{template.title_ar}</h4>
                            {!template.is_active && (
                              <Badge variant="secondary">معطل</Badge>
                            )}
                            <Badge variant="outline" className="text-xs">
                              {template.priority}
                            </Badge>
                          </div>
                          <p className="text-sm text-muted-foreground line-clamp-1">
                            {template.body_ar}
                          </p>
                          <div className="flex items-center gap-2 mt-2">
                            <code className="text-xs bg-muted px-2 py-1 rounded" dir="ltr">
                              {template.template_key}
                            </code>
                            {template.variables?.length > 0 && (
                              <span className="text-xs text-muted-foreground">
                                المتغيرات: {template.variables.join(", ")}
                              </span>
                            )}
                          </div>
                        </div>
                        <div className="flex gap-1">
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => handleOpenEdit(template)}
                          >
                            <Pencil className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => setDeleteConfirm(template.id)}
                          >
                            <Trash2 className="h-4 w-4 text-destructive" />
                          </Button>
                        </div>
                      </div>

                      {/* Preview */}
                      <div className="mt-4 p-3 bg-muted/50 rounded-lg">
                        <p className="text-xs text-muted-foreground mb-2">معاينة الإشعار:</p>
                        <div className="flex items-start gap-3 bg-background p-3 rounded-md border">
                          <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
                            <Bell className="h-4 w-4 text-primary" />
                          </div>
                          <div>
                            <p className="font-medium text-sm">{template.title_ar}</p>
                            <p className="text-xs text-muted-foreground">{template.body_ar}</p>
                          </div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Create/Edit Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {editingTemplate ? "تعديل القالب" : "إضافة قالب جديد"}
            </DialogTitle>
            <DialogDescription>
              {editingTemplate
                ? "تعديل محتوى قالب الإشعار"
                : "إضافة قالب إشعار جديد"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>مفتاح القالب (template_key)</Label>
                <Input
                  value={formData.template_key}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, template_key: e.target.value }))
                  }
                  placeholder="reminder_daily"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label>الفئة</Label>
                <Select
                  value={formData.category}
                  onValueChange={(v) =>
                    setFormData((f) => ({
                      ...f,
                      category: v as AdminNotificationTemplate["category"],
                    }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {CATEGORIES.map((cat) => (
                      <SelectItem key={cat.value} value={cat.value}>
                        {cat.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>العنوان (عربي)</Label>
                <Input
                  value={formData.title_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, title_ar: e.target.value }))
                  }
                  placeholder="حان وقت التواصل!"
                />
              </div>
              <div className="space-y-2">
                <Label>العنوان (إنجليزي)</Label>
                <Input
                  value={formData.title_en}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, title_en: e.target.value }))
                  }
                  placeholder="Time to connect!"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>النص (عربي)</Label>
                <Textarea
                  value={formData.body_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, body_ar: e.target.value }))
                  }
                  placeholder="لديك تذكير للتواصل مع {{relative_name}}"
                  rows={3}
                />
                <p className="text-xs text-muted-foreground">
                  استخدم {"{{variable}}"} للمتغيرات
                </p>
              </div>
              <div className="space-y-2">
                <Label>النص (إنجليزي)</Label>
                <Textarea
                  value={formData.body_en}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, body_en: e.target.value }))
                  }
                  placeholder="You have a reminder to connect with {{relative_name}}"
                  rows={3}
                  dir="ltr"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>المتغيرات (مفصولة بفاصلة)</Label>
              <Input
                value={variablesInput}
                onChange={(e) => setVariablesInput(e.target.value)}
                placeholder="relative_name, streak_count, points"
                dir="ltr"
              />
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>الأولوية</Label>
                <Select
                  value={formData.priority}
                  onValueChange={(v) =>
                    setFormData((f) => ({
                      ...f,
                      priority: v as AdminNotificationTemplate["priority"],
                    }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {PRIORITIES.map((p) => (
                      <SelectItem key={p.value} value={p.value}>
                        {p.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>الصوت</Label>
                <Input
                  value={formData.sound}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, sound: e.target.value }))
                  }
                  placeholder="default"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label>معرّف القناة</Label>
                <Input
                  value={formData.channel_id}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, channel_id: e.target.value }))
                  }
                  placeholder="default"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="flex items-center gap-2">
              <Switch
                checked={formData.is_active}
                onCheckedChange={(checked) =>
                  setFormData((f) => ({ ...f, is_active: checked }))
                }
              />
              <Label>مفعل</Label>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSave}
              disabled={createTemplate.isPending || updateTemplate.isPending}
            >
              {createTemplate.isPending || updateTemplate.isPending
                ? "جاري الحفظ..."
                : editingTemplate
                ? "تحديث"
                : "إضافة"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={!!deleteConfirm} onOpenChange={() => setDeleteConfirm(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>تأكيد الحذف</DialogTitle>
            <DialogDescription>
              هل أنت متأكد من حذف هذا القالب؟ لا يمكن التراجع عن هذا الإجراء.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteConfirm(null)}>
              إلغاء
            </Button>
            <Button
              variant="destructive"
              onClick={() => deleteConfirm && handleDelete(deleteConfirm)}
              disabled={deleteTemplate.isPending}
            >
              {deleteTemplate.isPending ? "جاري الحذف..." : "حذف"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
