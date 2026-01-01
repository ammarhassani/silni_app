"use client";

import { useState } from "react";
import {
  useReminderTimeSlots,
  useCreateReminderTimeSlot,
  useUpdateReminderTimeSlot,
  useDeleteReminderTimeSlot,
} from "@/hooks/use-notifications";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
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
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Plus, Pencil, Trash2, Clock, Sun, Sunrise, Sunset, Moon } from "lucide-react";
import type { AdminReminderTimeSlot } from "@/types/database";

const TIME_ICONS: Record<string, React.ComponentType<{ className?: string }>> = {
  morning: Sunrise,
  afternoon: Sun,
  evening: Sunset,
  night: Moon,
};

const TIME_COLORS: Record<string, string> = {
  morning: "from-orange-400 to-yellow-400",
  afternoon: "from-yellow-400 to-orange-400",
  evening: "from-orange-500 to-red-500",
  night: "from-indigo-600 to-purple-600",
};

type TimeSlotFormData = Omit<AdminReminderTimeSlot, "id" | "created_at" | "updated_at">;

const defaultFormData: TimeSlotFormData = {
  slot_key: "",
  display_name_ar: "",
  display_name_en: "",
  start_hour: 9,
  end_hour: 12,
  icon: null,
  is_default: false,
  is_active: true,
  sort_order: 0,
};

export default function ReminderTimeSlotsPage() {
  const { data: timeSlots, isLoading } = useReminderTimeSlots();
  const createSlot = useCreateReminderTimeSlot();
  const updateSlot = useUpdateReminderTimeSlot();
  const deleteSlot = useDeleteReminderTimeSlot();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingSlot, setEditingSlot] = useState<AdminReminderTimeSlot | null>(null);
  const [formData, setFormData] = useState<TimeSlotFormData>(defaultFormData);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  const handleOpenCreate = () => {
    setEditingSlot(null);
    setFormData(defaultFormData);
    setIsDialogOpen(true);
  };

  const handleOpenEdit = (slot: AdminReminderTimeSlot) => {
    setEditingSlot(slot);
    setFormData({
      slot_key: slot.slot_key,
      display_name_ar: slot.display_name_ar,
      display_name_en: slot.display_name_en || "",
      start_hour: slot.start_hour,
      end_hour: slot.end_hour,
      icon: slot.icon,
      is_default: slot.is_default,
      is_active: slot.is_active,
      sort_order: slot.sort_order,
    });
    setIsDialogOpen(true);
  };

  const handleSave = () => {
    const data = {
      ...formData,
      display_name_en: formData.display_name_en || null,
    };

    if (editingSlot) {
      updateSlot.mutate(
        { id: editingSlot.id, ...data },
        { onSuccess: () => setIsDialogOpen(false) }
      );
    } else {
      createSlot.mutate(data, { onSuccess: () => setIsDialogOpen(false) });
    }
  };

  const handleDelete = (id: string) => {
    deleteSlot.mutate(id, { onSuccess: () => setDeleteConfirm(null) });
  };

  const formatHour = (hour: number) => {
    if (hour === 0) return "12:00 AM";
    if (hour === 12) return "12:00 PM";
    if (hour < 12) return `${hour}:00 AM`;
    return `${hour - 12}:00 PM`;
  };

  const formatHourAr = (hour: number) => {
    if (hour === 0) return "12:00 ص";
    if (hour === 12) return "12:00 م";
    if (hour < 12) return `${hour}:00 ص`;
    return `${hour - 12}:00 م`;
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

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">الفترات الزمنية</h1>
          <p className="text-muted-foreground mt-1">
            إدارة فترات التذكير المتاحة للمستخدمين
          </p>
        </div>
        <Button onClick={handleOpenCreate}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة فترة
        </Button>
      </div>

      {/* Visual Timeline */}
      <Card>
        <CardHeader>
          <CardTitle>الجدول الزمني</CardTitle>
          <CardDescription>
            عرض مرئي للفترات الزمنية على مدار اليوم
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="relative">
            {/* 24-hour timeline */}
            <div className="flex h-16 rounded-lg overflow-hidden bg-gradient-to-r from-indigo-900 via-orange-300 via-yellow-200 via-orange-400 to-indigo-900">
              {timeSlots?.map((slot) => {
                const startPercent = (slot.start_hour / 24) * 100;
                const widthPercent = ((slot.end_hour - slot.start_hour) / 24) * 100;
                const Icon = TIME_ICONS[slot.slot_key] || Clock;
                const gradient = TIME_COLORS[slot.slot_key] || "from-blue-500 to-blue-600";

                return (
                  <div
                    key={slot.id}
                    className={`absolute h-full flex items-center justify-center bg-gradient-to-r ${gradient} border-x-2 border-white/30 opacity-90`}
                    style={{
                      left: `${startPercent}%`,
                      width: `${widthPercent}%`,
                    }}
                  >
                    <div className="text-white text-center">
                      <Icon className="h-5 w-5 mx-auto mb-1" />
                      <p className="text-xs font-medium">{slot.display_name_ar}</p>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Hour markers */}
            <div className="flex justify-between mt-2 text-xs text-muted-foreground">
              {[0, 6, 12, 18, 24].map((hour) => (
                <span key={hour}>{hour === 24 ? "00:00" : `${hour}:00`}</span>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Time Slots Cards */}
      <div className="grid grid-cols-4 gap-4">
        {timeSlots?.map((slot) => {
          const Icon = TIME_ICONS[slot.slot_key] || Clock;
          const gradient = TIME_COLORS[slot.slot_key] || "from-blue-500 to-blue-600";

          return (
            <Card
              key={slot.id}
              className={`overflow-hidden ${!slot.is_active ? "opacity-60" : ""}`}
            >
              <div className={`h-2 bg-gradient-to-r ${gradient}`} />
              <CardContent className="pt-4">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className={`w-10 h-10 rounded-full bg-gradient-to-r ${gradient} flex items-center justify-center`}>
                      <Icon className="h-5 w-5 text-white" />
                    </div>
                    <div>
                      <h4 className="font-semibold flex items-center gap-2">
                        {slot.display_name_ar}
                        {slot.is_default && (
                          <Badge variant="secondary" className="text-xs">افتراضي</Badge>
                        )}
                      </h4>
                      <p className="text-sm text-muted-foreground" dir="ltr">
                        {slot.slot_key}
                      </p>
                    </div>
                  </div>
                  <div className="flex gap-1">
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8"
                      onClick={() => handleOpenEdit(slot)}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8"
                      onClick={() => setDeleteConfirm(slot.id)}
                    >
                      <Trash2 className="h-4 w-4 text-destructive" />
                    </Button>
                  </div>
                </div>

                <div className="mt-4 p-3 bg-muted/50 rounded-lg">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">من</span>
                    <span className="font-medium">{formatHourAr(slot.start_hour)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm mt-1">
                    <span className="text-muted-foreground">إلى</span>
                    <span className="font-medium">{formatHourAr(slot.end_hour)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm mt-1">
                    <span className="text-muted-foreground">المدة</span>
                    <span className="font-medium">{slot.end_hour - slot.start_hour} ساعات</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Time Slots Table */}
      <Card>
        <CardHeader>
          <CardTitle>جدول الفترات</CardTitle>
          <CardDescription>
            عرض تفصيلي لجميع الفترات الزمنية
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>المفتاح</TableHead>
                <TableHead>الاسم</TableHead>
                <TableHead className="text-center">البداية</TableHead>
                <TableHead className="text-center">النهاية</TableHead>
                <TableHead className="text-center">المدة</TableHead>
                <TableHead className="text-center">افتراضي</TableHead>
                <TableHead className="text-center">الحالة</TableHead>
                <TableHead className="w-[100px]">إجراءات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {timeSlots?.map((slot) => (
                <TableRow key={slot.id}>
                  <TableCell className="font-mono text-sm" dir="ltr">
                    {slot.slot_key}
                  </TableCell>
                  <TableCell>
                    <div>
                      <p className="font-medium">{slot.display_name_ar}</p>
                      {slot.display_name_en && (
                        <p className="text-xs text-muted-foreground" dir="ltr">
                          {slot.display_name_en}
                        </p>
                      )}
                    </div>
                  </TableCell>
                  <TableCell className="text-center">
                    {formatHour(slot.start_hour)}
                  </TableCell>
                  <TableCell className="text-center">
                    {formatHour(slot.end_hour)}
                  </TableCell>
                  <TableCell className="text-center">
                    {slot.end_hour - slot.start_hour}h
                  </TableCell>
                  <TableCell className="text-center">
                    {slot.is_default ? (
                      <Badge variant="default">افتراضي</Badge>
                    ) : (
                      <span className="text-muted-foreground">-</span>
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    <Badge variant={slot.is_active ? "default" : "secondary"}>
                      {slot.is_active ? "نشط" : "معطل"}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-1">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleOpenEdit(slot)}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => setDeleteConfirm(slot.id)}
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
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {editingSlot ? "تعديل الفترة الزمنية" : "إضافة فترة زمنية"}
            </DialogTitle>
            <DialogDescription>
              {editingSlot
                ? "تعديل إعدادات الفترة الزمنية"
                : "إضافة فترة زمنية جديدة للتذكيرات"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="space-y-2">
              <Label>المفتاح (slot_key)</Label>
              <Input
                value={formData.slot_key}
                onChange={(e) =>
                  setFormData((f) => ({ ...f, slot_key: e.target.value }))
                }
                placeholder="morning"
                dir="ltr"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الاسم (عربي)</Label>
                <Input
                  value={formData.display_name_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_ar: e.target.value }))
                  }
                  placeholder="الصباح"
                />
              </div>
              <div className="space-y-2">
                <Label>الاسم (إنجليزي)</Label>
                <Input
                  value={formData.display_name_en}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_en: e.target.value }))
                  }
                  placeholder="Morning"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>ساعة البداية (0-23)</Label>
                <Input
                  type="number"
                  min={0}
                  max={23}
                  value={formData.start_hour}
                  onChange={(e) =>
                    setFormData((f) => ({
                      ...f,
                      start_hour: parseInt(e.target.value) || 0,
                    }))
                  }
                />
                <p className="text-xs text-muted-foreground">
                  {formatHour(formData.start_hour)}
                </p>
              </div>
              <div className="space-y-2">
                <Label>ساعة النهاية (0-23)</Label>
                <Input
                  type="number"
                  min={0}
                  max={24}
                  value={formData.end_hour}
                  onChange={(e) =>
                    setFormData((f) => ({
                      ...f,
                      end_hour: parseInt(e.target.value) || 0,
                    }))
                  }
                />
                <p className="text-xs text-muted-foreground">
                  {formatHour(formData.end_hour)}
                </p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الأيقونة</Label>
                <Input
                  value={formData.icon || ""}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, icon: e.target.value || null }))
                  }
                  placeholder="sunrise"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label>الترتيب</Label>
                <Input
                  type="number"
                  value={formData.sort_order}
                  onChange={(e) =>
                    setFormData((f) => ({
                      ...f,
                      sort_order: parseInt(e.target.value) || 0,
                    }))
                  }
                />
              </div>
            </div>

            <div className="flex items-center gap-8">
              <div className="flex items-center gap-2">
                <Switch
                  checked={formData.is_default}
                  onCheckedChange={(checked) =>
                    setFormData((f) => ({ ...f, is_default: checked }))
                  }
                />
                <Label>فترة افتراضية</Label>
              </div>
              <div className="flex items-center gap-2">
                <Switch
                  checked={formData.is_active}
                  onCheckedChange={(checked) =>
                    setFormData((f) => ({ ...f, is_active: checked }))
                  }
                />
                <Label>نشط</Label>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSave}
              disabled={createSlot.isPending || updateSlot.isPending}
            >
              {createSlot.isPending || updateSlot.isPending
                ? "جاري الحفظ..."
                : editingSlot
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
              هل أنت متأكد من حذف هذه الفترة الزمنية؟ لا يمكن التراجع عن هذا الإجراء.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteConfirm(null)}>
              إلغاء
            </Button>
            <Button
              variant="destructive"
              onClick={() => deleteConfirm && handleDelete(deleteConfirm)}
              disabled={deleteSlot.isPending}
            >
              {deleteSlot.isPending ? "جاري الحذف..." : "حذف"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
