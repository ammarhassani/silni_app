"use client";

import { useState } from "react";
import { useBadges, useCreateBadge, useUpdateBadge, useDeleteBadge } from "@/hooks/use-gamification";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
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
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Plus, Pencil, Trash2, Award, Eye, EyeOff } from "lucide-react";
import type { AdminBadge } from "@/types/database";

const CATEGORIES = [
  { value: "streak", label: "سلسلة التواصل", color: "bg-orange-500" },
  { value: "volume", label: "عدد التفاعلات", color: "bg-blue-500" },
  { value: "variety", label: "التنوع", color: "bg-green-500" },
  { value: "special", label: "مميز", color: "bg-purple-500" },
  { value: "milestone", label: "إنجاز", color: "bg-yellow-500" },
];

const THRESHOLD_TYPES = [
  { value: "first_interaction", label: "أول تفاعل" },
  { value: "streak_days", label: "أيام السلسلة" },
  { value: "total_interactions", label: "إجمالي التفاعلات" },
  { value: "unique_interaction_types", label: "أنواع تفاعل مختلفة" },
  { value: "unique_relatives", label: "أقارب مختلفين" },
  { value: "gift_count", label: "عدد الهدايا" },
  { value: "event_count", label: "عدد المناسبات" },
  { value: "call_count", label: "عدد المكالمات" },
  { value: "visit_count", label: "عدد الزيارات" },
  { value: "custom", label: "مخصص" },
];

type BadgeFormData = Omit<AdminBadge, "id" | "created_at" | "updated_at">;

const defaultFormData: BadgeFormData = {
  badge_key: "",
  display_name_ar: "",
  display_name_en: "",
  description_ar: "",
  description_en: "",
  emoji: "🏆",
  category: "milestone",
  threshold_type: "total_interactions",
  threshold_value: 10,
  xp_reward: 50,
  is_secret: false,
  is_active: true,
  sort_order: 0,
};

export default function BadgesPage() {
  const { data: badges, isLoading } = useBadges();
  const createBadge = useCreateBadge();
  const updateBadge = useUpdateBadge();
  const deleteBadge = useDeleteBadge();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingBadge, setEditingBadge] = useState<AdminBadge | null>(null);
  const [formData, setFormData] = useState<BadgeFormData>(defaultFormData);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  const handleOpenCreate = () => {
    setEditingBadge(null);
    setFormData(defaultFormData);
    setIsDialogOpen(true);
  };

  const handleOpenEdit = (badge: AdminBadge) => {
    setEditingBadge(badge);
    setFormData({
      badge_key: badge.badge_key,
      display_name_ar: badge.display_name_ar,
      display_name_en: badge.display_name_en || "",
      description_ar: badge.description_ar,
      description_en: badge.description_en || "",
      emoji: badge.emoji,
      category: badge.category,
      threshold_type: badge.threshold_type,
      threshold_value: badge.threshold_value,
      xp_reward: badge.xp_reward,
      is_secret: badge.is_secret,
      is_active: badge.is_active,
      sort_order: badge.sort_order,
    });
    setIsDialogOpen(true);
  };

  const handleSave = () => {
    if (editingBadge) {
      updateBadge.mutate(
        { id: editingBadge.id, ...formData },
        { onSuccess: () => setIsDialogOpen(false) }
      );
    } else {
      createBadge.mutate(formData, { onSuccess: () => setIsDialogOpen(false) });
    }
  };

  const handleDelete = (id: string) => {
    deleteBadge.mutate(id, { onSuccess: () => setDeleteConfirm(null) });
  };

  const getCategoryBadge = (category: string) => {
    const cat = CATEGORIES.find((c) => c.value === category);
    return cat ? (
      <Badge className={`${cat.color} text-white`}>{cat.label}</Badge>
    ) : (
      <Badge>{category}</Badge>
    );
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-4 grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-32" />
          ))}
        </div>
        <Skeleton className="h-96" />
      </div>
    );
  }

  const groupedBadges = badges?.reduce((acc, badge) => {
    if (!acc[badge.category]) acc[badge.category] = [];
    acc[badge.category].push(badge);
    return acc;
  }, {} as Record<string, AdminBadge[]>) || {};

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">الأوسمة</h1>
          <p className="text-muted-foreground mt-1">
            إدارة أوسمة الإنجاز والمكافآت
          </p>
        </div>
        <Button onClick={handleOpenCreate}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة وسام
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-5 gap-4">
        {CATEGORIES.map((cat) => (
          <Card key={cat.value}>
            <CardContent className="pt-6 text-center">
              <div className={`h-10 w-10 mx-auto rounded-full ${cat.color} flex items-center justify-center mb-2`}>
                <Award className="h-5 w-5 text-white" />
              </div>
              <p className="text-2xl font-bold">{groupedBadges[cat.value]?.length || 0}</p>
              <p className="text-sm text-muted-foreground">{cat.label}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Badges Table */}
      <Card>
        <CardHeader>
          <CardTitle>قائمة الأوسمة</CardTitle>
          <CardDescription>
            {badges?.length || 0} وسام مُعرّف
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[50px]">الرمز</TableHead>
                <TableHead>الاسم</TableHead>
                <TableHead>الفئة</TableHead>
                <TableHead>الشرط</TableHead>
                <TableHead className="text-center">XP</TableHead>
                <TableHead className="text-center">سري</TableHead>
                <TableHead className="text-center">مفعل</TableHead>
                <TableHead className="w-[100px]">إجراءات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {badges?.map((badge) => (
                <TableRow key={badge.id}>
                  <TableCell className="text-2xl">{badge.emoji}</TableCell>
                  <TableCell>
                    <div>
                      <p className="font-medium">{badge.display_name_ar}</p>
                      <p className="text-xs text-muted-foreground">{badge.badge_key}</p>
                    </div>
                  </TableCell>
                  <TableCell>{getCategoryBadge(badge.category)}</TableCell>
                  <TableCell>
                    <div className="text-sm">
                      <p>{THRESHOLD_TYPES.find((t) => t.value === badge.threshold_type)?.label}</p>
                      <p className="text-muted-foreground">≥ {badge.threshold_value}</p>
                    </div>
                  </TableCell>
                  <TableCell className="text-center font-medium">{badge.xp_reward}</TableCell>
                  <TableCell className="text-center">
                    {badge.is_secret ? (
                      <EyeOff className="h-4 w-4 mx-auto text-muted-foreground" />
                    ) : (
                      <Eye className="h-4 w-4 mx-auto text-green-500" />
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    <Badge variant={badge.is_active ? "default" : "secondary"}>
                      {badge.is_active ? "مفعل" : "معطل"}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-1">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleOpenEdit(badge)}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => setDeleteConfirm(badge.id)}
                      >
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Create/Edit Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>
              {editingBadge ? "تعديل الوسام" : "إضافة وسام جديد"}
            </DialogTitle>
            <DialogDescription>
              {editingBadge ? "تعديل بيانات الوسام" : "إضافة وسام جديد للنظام"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>المفتاح (badge_key)</Label>
                <Input
                  value={formData.badge_key}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, badge_key: e.target.value }))
                  }
                  placeholder="streak_7_days"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label>الرمز التعبيري</Label>
                <Input
                  value={formData.emoji}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, emoji: e.target.value }))
                  }
                  className="text-2xl text-center"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الاسم (عربي)</Label>
                <Input
                  value={formData.display_name_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_ar: e.target.value }))
                  }
                  placeholder="واصل الأسبوع"
                />
              </div>
              <div className="space-y-2">
                <Label>الاسم (إنجليزي)</Label>
                <Input
                  value={formData.display_name_en || ""}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_en: e.target.value }))
                  }
                  placeholder="Week Connector"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الوصف (عربي)</Label>
                <Textarea
                  value={formData.description_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, description_ar: e.target.value }))
                  }
                  placeholder="أكمل 7 أيام متتالية من التواصل"
                />
              </div>
              <div className="space-y-2">
                <Label>الوصف (إنجليزي)</Label>
                <Textarea
                  value={formData.description_en || ""}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, description_en: e.target.value }))
                  }
                  placeholder="Complete 7 consecutive days of connection"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الفئة</Label>
                <Select
                  value={formData.category}
                  onValueChange={(v) =>
                    setFormData((f) => ({ ...f, category: v as AdminBadge["category"] }))
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
              <div className="space-y-2">
                <Label>نوع الشرط</Label>
                <Select
                  value={formData.threshold_type}
                  onValueChange={(v) =>
                    setFormData((f) => ({ ...f, threshold_type: v as AdminBadge["threshold_type"] }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {THRESHOLD_TYPES.map((type) => (
                      <SelectItem key={type.value} value={type.value}>
                        {type.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>قيمة الشرط</Label>
                <Input
                  type="number"
                  value={formData.threshold_value}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, threshold_value: parseInt(e.target.value) || 0 }))
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>مكافأة XP</Label>
                <Input
                  type="number"
                  value={formData.xp_reward}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, xp_reward: parseInt(e.target.value) || 0 }))
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>الترتيب</Label>
                <Input
                  type="number"
                  value={formData.sort_order}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, sort_order: parseInt(e.target.value) || 0 }))
                  }
                />
              </div>
            </div>

            <div className="flex items-center gap-8">
              <div className="flex items-center gap-2">
                <Switch
                  checked={formData.is_secret}
                  onCheckedChange={(checked) =>
                    setFormData((f) => ({ ...f, is_secret: checked }))
                  }
                />
                <Label>وسام سري</Label>
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
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSave}
              disabled={createBadge.isPending || updateBadge.isPending}
            >
              {createBadge.isPending || updateBadge.isPending
                ? "جاري الحفظ..."
                : editingBadge
                ? "تحديث"
                : "إضافة"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={!!deleteConfirm} onOpenChange={() => setDeleteConfirm(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>تأكيد الحذف</DialogTitle>
            <DialogDescription>
              هل أنت متأكد من حذف هذا الوسام؟ لا يمكن التراجع عن هذا الإجراء.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteConfirm(null)}>
              إلغاء
            </Button>
            <Button
              variant="destructive"
              onClick={() => deleteConfirm && handleDelete(deleteConfirm)}
              disabled={deleteBadge.isPending}
            >
              {deleteBadge.isPending ? "جاري الحذف..." : "حذف"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
