"use client";

import { useState } from "react";
import {
  useColors,
  useCreateColor,
  useUpdateColor,
  useDeleteColor,
} from "@/hooks/use-design-system";
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
import { Plus, Pencil, Trash2, Palette, Copy, Check } from "lucide-react";
import type { AdminColor } from "@/types/database";
import { toast } from "sonner";

type ColorFormData = Omit<AdminColor, "id" | "created_at" | "updated_at">;

const defaultFormData: ColorFormData = {
  color_key: "",
  display_name_ar: "",
  display_name_en: "",
  hex_value: "#3B82F6",
  rgb_value: null,
  usage_context: "",
  is_primary: false,
  is_active: true,
  sort_order: 0,
};

function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result
    ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16),
      }
    : null;
}

export default function ColorsPage() {
  const { data: colors, isLoading } = useColors();
  const createColor = useCreateColor();
  const updateColor = useUpdateColor();
  const deleteColor = useDeleteColor();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingColor, setEditingColor] = useState<AdminColor | null>(null);
  const [formData, setFormData] = useState<ColorFormData>(defaultFormData);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const handleOpenCreate = () => {
    setEditingColor(null);
    setFormData(defaultFormData);
    setIsDialogOpen(true);
  };

  const handleOpenEdit = (color: AdminColor) => {
    setEditingColor(color);
    setFormData({
      color_key: color.color_key,
      display_name_ar: color.display_name_ar,
      display_name_en: color.display_name_en || "",
      hex_value: color.hex_value,
      rgb_value: color.rgb_value,
      usage_context: color.usage_context || "",
      is_primary: color.is_primary,
      is_active: color.is_active,
      sort_order: color.sort_order,
    });
    setIsDialogOpen(true);
  };

  const handleSave = () => {
    const rgb = hexToRgb(formData.hex_value);
    const data = {
      ...formData,
      display_name_en: formData.display_name_en || null,
      usage_context: formData.usage_context || null,
      rgb_value: rgb,
    };

    if (editingColor) {
      updateColor.mutate(
        { id: editingColor.id, ...data },
        { onSuccess: () => setIsDialogOpen(false) }
      );
    } else {
      createColor.mutate(data, { onSuccess: () => setIsDialogOpen(false) });
    }
  };

  const handleDelete = (id: string) => {
    deleteColor.mutate(id, { onSuccess: () => setDeleteConfirm(null) });
  };

  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    toast.success("تم نسخ اللون");
    setTimeout(() => setCopiedId(null), 2000);
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-4 grid-cols-6">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <Skeleton key={i} className="h-32" />
          ))}
        </div>
        <Skeleton className="h-96" />
      </div>
    );
  }

  const primaryColors = colors?.filter((c) => c.is_primary) || [];
  const secondaryColors = colors?.filter((c) => !c.is_primary) || [];

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">الألوان</h1>
          <p className="text-muted-foreground mt-1">
            إدارة لوحة الألوان للتطبيق
          </p>
        </div>
        <Button onClick={handleOpenCreate}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة لون
        </Button>
      </div>

      {/* Primary Colors */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Palette className="h-5 w-5" />
            الألوان الأساسية
          </CardTitle>
          <CardDescription>
            الألوان الرئيسية المستخدمة في التطبيق
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-6 gap-4">
            {primaryColors.map((color) => (
              <div key={color.id} className="space-y-2">
                <div
                  className="h-24 rounded-lg shadow-md cursor-pointer hover:scale-105 transition-transform relative group"
                  style={{ backgroundColor: color.hex_value }}
                  onClick={() => copyToClipboard(color.hex_value, color.id)}
                >
                  <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/20 rounded-lg">
                    {copiedId === color.id ? (
                      <Check className="h-6 w-6 text-white" />
                    ) : (
                      <Copy className="h-6 w-6 text-white" />
                    )}
                  </div>
                </div>
                <div className="text-center">
                  <p className="font-medium text-sm">{color.display_name_ar}</p>
                  <p className="text-xs text-muted-foreground font-mono" dir="ltr">
                    {color.hex_value}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Secondary Colors */}
      {secondaryColors.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>الألوان الثانوية</CardTitle>
            <CardDescription>
              ألوان إضافية للتطبيق
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-8 gap-4">
              {secondaryColors.map((color) => (
                <div key={color.id} className="space-y-2">
                  <div
                    className="h-16 rounded-lg shadow-sm cursor-pointer hover:scale-105 transition-transform relative group"
                    style={{ backgroundColor: color.hex_value }}
                    onClick={() => copyToClipboard(color.hex_value, color.id)}
                  >
                    <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/20 rounded-lg">
                      {copiedId === color.id ? (
                        <Check className="h-4 w-4 text-white" />
                      ) : (
                        <Copy className="h-4 w-4 text-white" />
                      )}
                    </div>
                  </div>
                  <p className="text-xs text-center text-muted-foreground truncate">
                    {color.display_name_ar}
                  </p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Colors Table */}
      <Card>
        <CardHeader>
          <CardTitle>جدول الألوان</CardTitle>
          <CardDescription>
            عرض تفصيلي لجميع الألوان
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[60px]">اللون</TableHead>
                <TableHead>المفتاح</TableHead>
                <TableHead>الاسم</TableHead>
                <TableHead className="text-center">HEX</TableHead>
                <TableHead className="text-center">RGB</TableHead>
                <TableHead>السياق</TableHead>
                <TableHead className="text-center">أساسي</TableHead>
                <TableHead className="text-center">الحالة</TableHead>
                <TableHead className="w-[100px]">إجراءات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {colors?.map((color) => (
                <TableRow key={color.id}>
                  <TableCell>
                    <div
                      className="w-10 h-10 rounded-lg shadow-sm border"
                      style={{ backgroundColor: color.hex_value }}
                    />
                  </TableCell>
                  <TableCell className="font-mono text-sm" dir="ltr">
                    {color.color_key}
                  </TableCell>
                  <TableCell>
                    <div>
                      <p className="font-medium">{color.display_name_ar}</p>
                      {color.display_name_en && (
                        <p className="text-xs text-muted-foreground" dir="ltr">
                          {color.display_name_en}
                        </p>
                      )}
                    </div>
                  </TableCell>
                  <TableCell className="text-center font-mono text-sm" dir="ltr">
                    {color.hex_value}
                  </TableCell>
                  <TableCell className="text-center font-mono text-sm" dir="ltr">
                    {color.rgb_value
                      ? `${color.rgb_value.r}, ${color.rgb_value.g}, ${color.rgb_value.b}`
                      : "-"}
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {color.usage_context || "-"}
                  </TableCell>
                  <TableCell className="text-center">
                    {color.is_primary ? (
                      <Badge>أساسي</Badge>
                    ) : (
                      <span className="text-muted-foreground">-</span>
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    <Badge variant={color.is_active ? "default" : "secondary"}>
                      {color.is_active ? "نشط" : "معطل"}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-1">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleOpenEdit(color)}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => setDeleteConfirm(color.id)}
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
              {editingColor ? "تعديل اللون" : "إضافة لون جديد"}
            </DialogTitle>
            <DialogDescription>
              {editingColor ? "تعديل إعدادات اللون" : "إضافة لون جديد للوحة الألوان"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="flex items-center gap-4">
              <div
                className="w-20 h-20 rounded-lg shadow-md border"
                style={{ backgroundColor: formData.hex_value }}
              />
              <div className="flex-1 space-y-2">
                <Label>قيمة HEX</Label>
                <div className="flex gap-2">
                  <Input
                    type="color"
                    value={formData.hex_value}
                    onChange={(e) =>
                      setFormData((f) => ({ ...f, hex_value: e.target.value }))
                    }
                    className="w-14 h-10 p-1"
                  />
                  <Input
                    value={formData.hex_value}
                    onChange={(e) =>
                      setFormData((f) => ({ ...f, hex_value: e.target.value }))
                    }
                    placeholder="#3B82F6"
                    dir="ltr"
                    className="flex-1"
                  />
                </div>
              </div>
            </div>

            <div className="space-y-2">
              <Label>المفتاح (color_key)</Label>
              <Input
                value={formData.color_key}
                onChange={(e) =>
                  setFormData((f) => ({ ...f, color_key: e.target.value }))
                }
                placeholder="primary_teal"
                dir="ltr"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الاسم (عربي)</Label>
                <Input
                  value={formData.display_name_ar ?? ""}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_ar: e.target.value }))
                  }
                  placeholder="أخضر مزرق"
                />
              </div>
              <div className="space-y-2">
                <Label>الاسم (إنجليزي)</Label>
                <Input
                  value={formData.display_name_en ?? ""}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_en: e.target.value }))
                  }
                  placeholder="Teal"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>سياق الاستخدام</Label>
                <Input
                  value={formData.usage_context ?? ""}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, usage_context: e.target.value }))
                  }
                  placeholder="أزرار، روابط"
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
                  checked={formData.is_primary}
                  onCheckedChange={(checked) =>
                    setFormData((f) => ({ ...f, is_primary: checked }))
                  }
                />
                <Label>لون أساسي</Label>
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
              disabled={createColor.isPending || updateColor.isPending}
            >
              {createColor.isPending || updateColor.isPending
                ? "جاري الحفظ..."
                : editingColor
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
              هل أنت متأكد من حذف هذا اللون؟ لا يمكن التراجع عن هذا الإجراء.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteConfirm(null)}>
              إلغاء
            </Button>
            <Button
              variant="destructive"
              onClick={() => deleteConfirm && handleDelete(deleteConfirm)}
              disabled={deleteColor.isPending}
            >
              {deleteColor.isPending ? "جاري الحذف..." : "حذف"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
