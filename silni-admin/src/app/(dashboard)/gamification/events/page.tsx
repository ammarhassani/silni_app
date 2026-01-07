"use client";

import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Slider } from "@/components/ui/slider";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Checkbox } from "@/components/ui/checkbox";
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
  Sparkles,
  Plus,
  Pencil,
  Trash2,
  Calendar,
  Gift,
  Zap,
  Clock,
  TrendingUp,
} from "lucide-react";
import {
  usePointEvents,
  useActivePointEvent,
  useCreatePointEvent,
  useUpdatePointEvent,
  useDeletePointEvent,
  useTogglePointEventActive,
  actionTypeLabels,
  iconOptions,
  colorPresets,
  getEventStatus,
  formatMultiplier,
  PointEvent,
  PointEventInput,
} from "@/hooks/use-point-events";
import { format, formatDistanceToNow } from "date-fns";
import { ar } from "date-fns/locale";

const statusLabels = {
  active: "نشط الآن",
  upcoming: "قادم",
  past: "منتهي",
  disabled: "معطل",
};

const statusColors = {
  active: "bg-green-500",
  upcoming: "bg-blue-500",
  past: "bg-gray-500",
  disabled: "bg-red-500",
};

export default function PointEventsPage() {
  const { data: events, isLoading } = usePointEvents();
  const { data: activeEvent } = useActivePointEvent();
  const createEvent = useCreatePointEvent();
  const updateEvent = useUpdatePointEvent();
  const deleteEvent = useDeletePointEvent();
  const toggleActive = useTogglePointEventActive();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingEvent, setEditingEvent] = useState<PointEvent | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const [formData, setFormData] = useState<PointEventInput>({
    name: "",
    name_ar: "",
    description: null,
    description_ar: null,
    multiplier: 1.5,
    bonus_points: 0,
    start_date: new Date().toISOString(),
    end_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    applies_to: ["all"],
    icon: "gift",
    color: "#FFD700",
    banner_image_url: null,
    show_banner: true,
    is_active: true,
  });

  const resetForm = () => {
    setFormData({
      name: "",
      name_ar: "",
      description: null,
      description_ar: null,
      multiplier: 1.5,
      bonus_points: 0,
      start_date: new Date().toISOString(),
      end_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
      applies_to: ["all"],
      icon: "gift",
      color: "#FFD700",
      banner_image_url: null,
      show_banner: true,
      is_active: true,
    });
    setEditingEvent(null);
  };

  const openEditDialog = (event: PointEvent) => {
    setEditingEvent(event);
    setFormData({
      name: event.name,
      name_ar: event.name_ar,
      description: event.description,
      description_ar: event.description_ar,
      multiplier: event.multiplier,
      bonus_points: event.bonus_points,
      start_date: event.start_date,
      end_date: event.end_date,
      applies_to: event.applies_to,
      icon: event.icon,
      color: event.color,
      banner_image_url: event.banner_image_url,
      show_banner: event.show_banner,
      is_active: event.is_active,
    });
    setIsDialogOpen(true);
  };

  const handleSubmit = async () => {
    if (editingEvent) {
      await updateEvent.mutateAsync({ id: editingEvent.id, ...formData });
    } else {
      await createEvent.mutateAsync(formData);
    }
    setIsDialogOpen(false);
    resetForm();
  };

  const handleDelete = async () => {
    if (deleteId) {
      await deleteEvent.mutateAsync(deleteId);
      setDeleteId(null);
    }
  };

  const toggleActionType = (action: string) => {
    setFormData((prev) => {
      if (action === "all") {
        return { ...prev, applies_to: ["all"] };
      }

      let newAppliesTo = prev.applies_to.filter((a) => a !== "all");

      if (newAppliesTo.includes(action)) {
        newAppliesTo = newAppliesTo.filter((a) => a !== action);
      } else {
        newAppliesTo.push(action);
      }

      if (newAppliesTo.length === 0) {
        newAppliesTo = ["all"];
      }

      return { ...prev, applies_to: newAppliesTo };
    });
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-amber-500 to-orange-600 rounded-2xl flex items-center justify-center shadow-lg">
            <Sparkles className="h-7 w-7 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">أحداث مضاعفة النقاط</h1>
            <p className="text-muted-foreground mt-1">
              أحداث محدودة الوقت لتحفيز المستخدمين
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
              إضافة حدث
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>
                {editingEvent ? "تعديل الحدث" : "إضافة حدث جديد"}
              </DialogTitle>
              <DialogDescription>
                أحداث مضاعفة النقاط تشجع المستخدمين على التفاعل أكثر
              </DialogDescription>
            </DialogHeader>

            <div className="grid gap-4 py-4">
              {/* Names */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>الاسم (عربي) *</Label>
                  <Input
                    value={formData.name_ar}
                    onChange={(e) =>
                      setFormData({ ...formData, name_ar: e.target.value })
                    }
                    placeholder="مضاعفة رمضان"
                    dir="rtl"
                  />
                </div>
                <div className="space-y-2">
                  <Label>الاسم (إنجليزي)</Label>
                  <Input
                    value={formData.name}
                    onChange={(e) =>
                      setFormData({ ...formData, name: e.target.value })
                    }
                    placeholder="Ramadan Boost"
                    dir="ltr"
                  />
                </div>
              </div>

              {/* Description */}
              <div className="space-y-2">
                <Label>الوصف (عربي)</Label>
                <Textarea
                  value={formData.description_ar || ""}
                  onChange={(e) =>
                    setFormData({ ...formData, description_ar: e.target.value })
                  }
                  placeholder="نقاط مضاعفة خلال شهر رمضان المبارك"
                  dir="rtl"
                />
              </div>

              {/* Multiplier & Bonus */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>المضاعف: {formatMultiplier(formData.multiplier)}</Label>
                  <Slider
                    value={[formData.multiplier]}
                    onValueChange={(v) =>
                      setFormData({ ...formData, multiplier: v[0] })
                    }
                    min={1}
                    max={5}
                    step={0.1}
                  />
                  <p className="text-xs text-muted-foreground">
                    مثال: 100 نقطة × {formData.multiplier} ={" "}
                    {Math.round(100 * formData.multiplier)} نقطة
                  </p>
                </div>
                <div className="space-y-2">
                  <Label>نقاط إضافية ثابتة</Label>
                  <Input
                    type="number"
                    value={formData.bonus_points}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        bonus_points: parseInt(e.target.value) || 0,
                      })
                    }
                    min={0}
                  />
                  <p className="text-xs text-muted-foreground">
                    تضاف لكل إجراء بالإضافة للمضاعف
                  </p>
                </div>
              </div>

              {/* Dates */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>تاريخ البداية</Label>
                  <Input
                    type="datetime-local"
                    value={formData.start_date.slice(0, 16)}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        start_date: new Date(e.target.value).toISOString(),
                      })
                    }
                  />
                </div>
                <div className="space-y-2">
                  <Label>تاريخ النهاية</Label>
                  <Input
                    type="datetime-local"
                    value={formData.end_date.slice(0, 16)}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        end_date: new Date(e.target.value).toISOString(),
                      })
                    }
                  />
                </div>
              </div>

              {/* Action Types */}
              <div className="space-y-2">
                <Label>ينطبق على</Label>
                <div className="grid grid-cols-2 gap-2">
                  {Object.entries(actionTypeLabels).map(([key, label]) => (
                    <div key={key} className="flex items-center gap-2">
                      <Checkbox
                        id={key}
                        checked={formData.applies_to.includes(key)}
                        onCheckedChange={() => toggleActionType(key)}
                      />
                      <label
                        htmlFor={key}
                        className="text-sm cursor-pointer"
                      >
                        {label}
                      </label>
                    </div>
                  ))}
                </div>
              </div>

              {/* Icon & Color */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>الأيقونة</Label>
                  <Select
                    value={formData.icon}
                    onValueChange={(v) => setFormData({ ...formData, icon: v })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {iconOptions.map((icon) => (
                        <SelectItem key={icon.value} value={icon.value}>
                          {icon.emoji} {icon.label}
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
                      value={formData.color}
                      onChange={(e) =>
                        setFormData({ ...formData, color: e.target.value })
                      }
                      className="w-12 h-10 p-1 cursor-pointer"
                    />
                    <Select
                      value={formData.color}
                      onValueChange={(v) =>
                        setFormData({ ...formData, color: v })
                      }
                    >
                      <SelectTrigger className="flex-1">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {colorPresets.map((color) => (
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

              {/* Options */}
              <div className="flex items-center gap-6">
                <div className="flex items-center gap-2">
                  <Switch
                    id="show_banner"
                    checked={formData.show_banner}
                    onCheckedChange={(v) =>
                      setFormData({ ...formData, show_banner: v })
                    }
                  />
                  <Label htmlFor="show_banner">عرض بانر في الرئيسية</Label>
                </div>
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
                  !formData.name_ar ||
                  createEvent.isPending ||
                  updateEvent.isPending
                }
              >
                {editingEvent ? "تحديث" : "إنشاء"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      {/* Active Event Banner */}
      {activeEvent && (
        <Card
          className="border-2"
          style={{ borderColor: activeEvent.color }}
        >
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div
                  className="w-16 h-16 rounded-xl flex items-center justify-center text-3xl"
                  style={{ backgroundColor: `${activeEvent.color}20` }}
                >
                  {iconOptions.find((i) => i.value === activeEvent.icon)?.emoji ||
                    "🎁"}
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h2 className="text-xl font-bold">{activeEvent.name_ar}</h2>
                    <Badge className="bg-green-500">نشط الآن</Badge>
                  </div>
                  <p className="text-muted-foreground mt-1">
                    {activeEvent.description_ar}
                  </p>
                  <div className="flex items-center gap-4 mt-2 text-sm">
                    <span className="flex items-center gap-1">
                      <TrendingUp className="h-4 w-4" />
                      {formatMultiplier(activeEvent.multiplier)}
                    </span>
                    {activeEvent.bonus_points > 0 && (
                      <span className="flex items-center gap-1">
                        <Gift className="h-4 w-4" />+{activeEvent.bonus_points}
                      </span>
                    )}
                    <span className="flex items-center gap-1">
                      <Clock className="h-4 w-4" />
                      ينتهي{" "}
                      {formatDistanceToNow(new Date(activeEvent.end_date), {
                        addSuffix: true,
                        locale: ar,
                      })}
                    </span>
                  </div>
                </div>
              </div>
              <Button
                variant="outline"
                size="sm"
                onClick={() => openEditDialog(activeEvent)}
              >
                <Pencil className="h-4 w-4" />
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Events List */}
      <div className="grid gap-4">
        {isLoading ? (
          [...Array(3)].map((_, i) => (
            <Card key={i}>
              <CardContent className="pt-6">
                <div className="flex items-center gap-4">
                  <Skeleton className="w-14 h-14 rounded-xl" />
                  <div className="flex-1">
                    <Skeleton className="h-5 w-40 mb-2" />
                    <Skeleton className="h-4 w-64" />
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        ) : events?.length === 0 ? (
          <Card>
            <CardContent className="py-12 text-center">
              <Sparkles className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
              <p className="text-muted-foreground">لا توجد أحداث</p>
              <Button
                className="mt-4"
                onClick={() => setIsDialogOpen(true)}
              >
                إضافة حدث جديد
              </Button>
            </CardContent>
          </Card>
        ) : (
          events?.map((event) => {
            const status = getEventStatus(event);
            const isActive = status === "active";

            return (
              <Card
                key={event.id}
                className={!event.is_active ? "opacity-60" : ""}
              >
                <CardContent className="pt-6">
                  <div className="flex items-center gap-4">
                    {/* Icon */}
                    <div
                      className="w-14 h-14 rounded-xl flex items-center justify-center text-2xl shrink-0"
                      style={{ backgroundColor: `${event.color}20` }}
                    >
                      {iconOptions.find((i) => i.value === event.icon)?.emoji ||
                        "🎁"}
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold">{event.name_ar}</h3>
                        <Badge
                          className={`${statusColors[status]} text-white`}
                        >
                          {statusLabels[status]}
                        </Badge>
                      </div>
                      <p className="text-sm text-muted-foreground line-clamp-1">
                        {event.description_ar || "بدون وصف"}
                      </p>
                      <div className="flex items-center gap-4 mt-2 text-sm text-muted-foreground">
                        <span className="flex items-center gap-1">
                          <TrendingUp className="h-3 w-3" />
                          {formatMultiplier(event.multiplier)}
                        </span>
                        {event.bonus_points > 0 && (
                          <span className="flex items-center gap-1">
                            <Gift className="h-3 w-3" />+{event.bonus_points}
                          </span>
                        )}
                        <span className="flex items-center gap-1">
                          <Calendar className="h-3 w-3" />
                          {format(new Date(event.start_date), "dd/MM")} -{" "}
                          {format(new Date(event.end_date), "dd/MM/yyyy")}
                        </span>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-2">
                      <Switch
                        checked={event.is_active}
                        onCheckedChange={(checked) =>
                          toggleActive.mutate({
                            id: event.id,
                            is_active: checked,
                          })
                        }
                      />
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => openEditDialog(event)}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => setDeleteId(event.id)}
                      >
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })
        )}
      </div>

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteId} onOpenChange={() => setDeleteId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>حذف الحدث؟</AlertDialogTitle>
            <AlertDialogDescription>
              سيتم حذف هذا الحدث نهائياً. لا يمكن التراجع عن هذا الإجراء.
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
