"use client";

import { useState } from "react";
import { useAIErrorMessages, useUpdateAIErrorMessage } from "@/hooks/use-ai";
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
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { AlertCircle, Pencil, RefreshCw, WifiOff, Clock, Server, Ban } from "lucide-react";
import type { AdminAIErrorMessage } from "@/hooks/use-ai";

const errorCodeIcons: Record<number, React.ReactNode> = {
  400: <Ban className="h-4 w-4" />,
  401: <Ban className="h-4 w-4" />,
  403: <Ban className="h-4 w-4" />,
  404: <AlertCircle className="h-4 w-4" />,
  408: <Clock className="h-4 w-4" />,
  429: <Clock className="h-4 w-4" />,
  500: <Server className="h-4 w-4" />,
  502: <Server className="h-4 w-4" />,
  503: <Server className="h-4 w-4" />,
  0: <WifiOff className="h-4 w-4" />,
};

const errorCodeDescriptions: Record<number, string> = {
  0: "لا يوجد اتصال بالإنترنت",
  400: "طلب غير صالح",
  401: "غير مصرح",
  403: "محظور",
  404: "غير موجود",
  408: "انتهاء المهلة",
  429: "تجاوز الحد المسموح",
  500: "خطأ في الخادم",
  502: "بوابة غير صالحة",
  503: "الخدمة غير متاحة",
};

export default function ErrorMessagesPage() {
  const { data: errorMessages, isLoading } = useAIErrorMessages();
  const updateError = useUpdateAIErrorMessage();

  const [editingError, setEditingError] = useState<AdminAIErrorMessage | null>(null);
  const [formData, setFormData] = useState({
    message_ar: "",
    message_en: "",
    show_retry_button: true,
  });

  const handleOpenEdit = (error: AdminAIErrorMessage) => {
    setEditingError(error);
    setFormData({
      message_ar: error.message_ar,
      message_en: error.message_en || "",
      show_retry_button: error.show_retry_button,
    });
  };

  const handleSave = () => {
    if (!editingError) return;
    updateError.mutate(
      {
        id: editingError.id,
        message_ar: formData.message_ar,
        message_en: formData.message_en || null,
        show_retry_button: formData.show_retry_button,
      },
      { onSuccess: () => setEditingError(null) }
    );
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <Skeleton className="h-96" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">رسائل الأخطاء</h1>
        <p className="text-muted-foreground mt-1">
          تخصيص رسائل الخطأ التي تظهر للمستخدمين عند حدوث مشاكل
        </p>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-red-500/10 flex items-center justify-center">
              <AlertCircle className="h-5 w-5 text-red-500" />
            </div>
            <div>
              <CardTitle>رسائل الأخطاء</CardTitle>
              <CardDescription>
                {errorMessages?.length || 0} رسالة خطأ مُعرّفة
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-24">كود الخطأ</TableHead>
                <TableHead>الوصف</TableHead>
                <TableHead>الرسالة (عربي)</TableHead>
                <TableHead className="w-32">زر إعادة المحاولة</TableHead>
                <TableHead className="w-20">إجراء</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {errorMessages?.map((error) => (
                <TableRow key={error.id}>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <div className="text-muted-foreground">
                        {errorCodeIcons[error.error_code] || <AlertCircle className="h-4 w-4" />}
                      </div>
                      <Badge
                        variant={error.error_code >= 500 ? "destructive" : "secondary"}
                        className="font-mono"
                      >
                        {error.error_code}
                      </Badge>
                    </div>
                  </TableCell>
                  <TableCell className="text-muted-foreground text-sm">
                    {errorCodeDescriptions[error.error_code] || "خطأ غير معروف"}
                  </TableCell>
                  <TableCell className="max-w-xs">
                    <p className="truncate" title={error.message_ar}>
                      {error.message_ar}
                    </p>
                  </TableCell>
                  <TableCell>
                    {error.show_retry_button ? (
                      <Badge variant="default" className="gap-1">
                        <RefreshCw className="h-3 w-3" />
                        نعم
                      </Badge>
                    ) : (
                      <Badge variant="secondary">لا</Badge>
                    )}
                  </TableCell>
                  <TableCell>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleOpenEdit(error)}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Preview Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {errorMessages?.slice(0, 3).map((error) => (
          <Card key={error.id} className="border-red-500/20">
            <CardContent className="pt-6">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-full bg-red-500/10 flex items-center justify-center shrink-0">
                  {errorCodeIcons[error.error_code] || <AlertCircle className="h-5 w-5 text-red-500" />}
                </div>
                <div className="flex-1">
                  <p className="font-medium text-red-500 mb-1">
                    خطأ {error.error_code}
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {error.message_ar}
                  </p>
                  {error.show_retry_button && (
                    <Button size="sm" variant="outline" className="mt-3">
                      <RefreshCw className="h-3 w-3 ml-2" />
                      إعادة المحاولة
                    </Button>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Edit Dialog */}
      <Dialog open={!!editingError} onOpenChange={() => setEditingError(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              تعديل رسالة الخطأ
              <Badge variant="secondary" className="font-mono">
                {editingError?.error_code}
              </Badge>
            </DialogTitle>
            <DialogDescription>
              {errorCodeDescriptions[editingError?.error_code || 0] || "خطأ غير معروف"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="space-y-2">
              <Label>الرسالة (عربي)</Label>
              <Textarea
                value={formData.message_ar}
                onChange={(e) => setFormData((f) => ({ ...f, message_ar: e.target.value }))}
                rows={3}
              />
            </div>

            <div className="space-y-2">
              <Label>الرسالة (إنجليزي) - اختياري</Label>
              <Textarea
                value={formData.message_en}
                onChange={(e) => setFormData((f) => ({ ...f, message_en: e.target.value }))}
                rows={3}
                dir="ltr"
              />
            </div>

            <div className="flex items-center justify-between p-3 border rounded-lg">
              <div className="flex items-center gap-2">
                <RefreshCw className="h-4 w-4 text-muted-foreground" />
                <div>
                  <p className="font-medium text-sm">إظهار زر إعادة المحاولة</p>
                  <p className="text-xs text-muted-foreground">
                    يسمح للمستخدم بإعادة محاولة الطلب
                  </p>
                </div>
              </div>
              <Switch
                checked={formData.show_retry_button}
                onCheckedChange={(c) => setFormData((f) => ({ ...f, show_retry_button: c }))}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setEditingError(null)}>
              إلغاء
            </Button>
            <Button onClick={handleSave} disabled={updateError.isPending}>
              {updateError.isPending ? "جاري الحفظ..." : "حفظ التغييرات"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
