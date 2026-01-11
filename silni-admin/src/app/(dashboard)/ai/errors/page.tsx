"use client";

import { useState } from "react";
import { useAIErrorMessages, useUpdateAIErrorMessage } from "@/hooks/use-ai";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { AlertCircle, Pencil, RefreshCw, WifiOff, Clock, Server, Ban, ShieldX, KeyRound, Search } from "lucide-react";
import type { AdminAIErrorMessage } from "@/hooks/use-ai";

// Error categories with user-friendly names and icons
const ERROR_CONFIG: Record<number, { icon: React.ReactNode; label: string; description: string; color: string }> = {
  0: {
    icon: <WifiOff className="h-5 w-5" />,
    label: "لا يوجد اتصال",
    description: "المستخدم غير متصل بالإنترنت",
    color: "bg-slate-500"
  },
  400: {
    icon: <Ban className="h-5 w-5" />,
    label: "طلب غير صالح",
    description: "خطأ في صيغة الطلب",
    color: "bg-orange-500"
  },
  401: {
    icon: <KeyRound className="h-5 w-5" />,
    label: "غير مصرح",
    description: "انتهت صلاحية الجلسة",
    color: "bg-amber-500"
  },
  403: {
    icon: <ShieldX className="h-5 w-5" />,
    label: "محظور",
    description: "ليس لديه صلاحية",
    color: "bg-red-500"
  },
  404: {
    icon: <Search className="h-5 w-5" />,
    label: "غير موجود",
    description: "المورد المطلوب غير متاح",
    color: "bg-blue-500"
  },
  408: {
    icon: <Clock className="h-5 w-5" />,
    label: "انتهاء المهلة",
    description: "استغرق الطلب وقتاً طويلاً",
    color: "bg-yellow-500"
  },
  429: {
    icon: <Clock className="h-5 w-5" />,
    label: "كثرة الطلبات",
    description: "تجاوز المستخدم الحد المسموح",
    color: "bg-purple-500"
  },
  500: {
    icon: <Server className="h-5 w-5" />,
    label: "خطأ في الخادم",
    description: "مشكلة داخلية في السيرفر",
    color: "bg-red-600"
  },
  502: {
    icon: <Server className="h-5 w-5" />,
    label: "بوابة غير صالحة",
    description: "خطأ في الاتصال بالخادم",
    color: "bg-red-500"
  },
  503: {
    icon: <Server className="h-5 w-5" />,
    label: "الخدمة غير متاحة",
    description: "الخادم مشغول أو تحت الصيانة",
    color: "bg-gray-600"
  },
};

export default function ErrorMessagesPage() {
  const { data: errorMessages, isLoading } = useAIErrorMessages();
  const updateError = useUpdateAIErrorMessage();

  const [editingError, setEditingError] = useState<AdminAIErrorMessage | null>(null);
  const [messageText, setMessageText] = useState("");
  const [showRetry, setShowRetry] = useState(true);

  const handleOpenEdit = (error: AdminAIErrorMessage) => {
    setEditingError(error);
    setMessageText(error.message_ar);
    setShowRetry(error.show_retry_button);
  };

  const handleSave = () => {
    if (!editingError) return;
    updateError.mutate(
      {
        id: editingError.id,
        message_ar: messageText,
        show_retry_button: showRetry,
      },
      { onSuccess: () => setEditingError(null) }
    );
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-4 md:grid-cols-2">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-32" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">رسائل الأخطاء</h1>
        <p className="text-muted-foreground mt-1">
          تخصيص الرسائل التي تظهر للمستخدم عند حدوث مشكلة
        </p>
      </div>

      {/* Error Cards Grid */}
      <div className="grid gap-4 md:grid-cols-2">
        {errorMessages?.map((error) => {
          const config = ERROR_CONFIG[error.error_code] || {
            icon: <AlertCircle className="h-5 w-5" />,
            label: `خطأ ${error.error_code}`,
            description: "خطأ غير معروف",
            color: "bg-gray-500"
          };

          return (
            <Card
              key={error.id}
              className="overflow-hidden hover:shadow-md transition-shadow cursor-pointer group"
              onClick={() => handleOpenEdit(error)}
            >
              <CardContent className="p-0">
                <div className="flex">
                  {/* Left color bar with icon */}
                  <div className={`${config.color} w-16 flex flex-col items-center justify-center text-white`}>
                    {config.icon}
                    <span className="text-xs font-bold mt-1">{error.error_code}</span>
                  </div>

                  {/* Content */}
                  <div className="flex-1 p-4">
                    <div className="flex items-start justify-between">
                      <div>
                        <h3 className="font-semibold">{config.label}</h3>
                        <p className="text-xs text-muted-foreground mb-2">{config.description}</p>
                      </div>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8 opacity-0 group-hover:opacity-100 transition-opacity"
                        onClick={(e) => {
                          e.stopPropagation();
                          handleOpenEdit(error);
                        }}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                    </div>

                    {/* Message Preview */}
                    <p className="text-sm text-muted-foreground line-clamp-2 bg-muted/50 p-2 rounded-md">
                      {error.message_ar}
                    </p>

                    {/* Retry Badge */}
                    {error.show_retry_button && (
                      <div className="flex items-center gap-1 mt-2 text-xs text-muted-foreground">
                        <RefreshCw className="h-3 w-3" />
                        <span>يمكن إعادة المحاولة</span>
                      </div>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Edit Dialog - Simplified */}
      <Dialog open={!!editingError} onOpenChange={() => setEditingError(null)}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-3">
              <div className={`${ERROR_CONFIG[editingError?.error_code || 0]?.color || "bg-gray-500"} w-10 h-10 rounded-lg flex items-center justify-center text-white`}>
                {ERROR_CONFIG[editingError?.error_code || 0]?.icon || <AlertCircle className="h-5 w-5" />}
              </div>
              <div>
                <p>{ERROR_CONFIG[editingError?.error_code || 0]?.label || "خطأ"}</p>
                <p className="text-xs text-muted-foreground font-normal">
                  {ERROR_CONFIG[editingError?.error_code || 0]?.description}
                </p>
              </div>
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4 py-4">
            {/* Message */}
            <div className="space-y-2">
              <p className="text-sm font-medium">الرسالة للمستخدم</p>
              <Textarea
                value={messageText}
                onChange={(e) => setMessageText(e.target.value)}
                rows={3}
                placeholder="أدخل الرسالة التي ستظهر للمستخدم..."
              />
            </div>

            {/* Retry Toggle */}
            <div
              className="flex items-center justify-between p-3 bg-muted/50 rounded-lg cursor-pointer"
              onClick={() => setShowRetry(!showRetry)}
            >
              <div className="flex items-center gap-3">
                <RefreshCw className={`h-4 w-4 ${showRetry ? "text-primary" : "text-muted-foreground"}`} />
                <div>
                  <p className="text-sm font-medium">السماح بإعادة المحاولة</p>
                  <p className="text-xs text-muted-foreground">
                    إظهار زر "حاول مرة أخرى"
                  </p>
                </div>
              </div>
              <Switch
                checked={showRetry}
                onCheckedChange={setShowRetry}
              />
            </div>

            {/* Preview */}
            <div className="border rounded-lg p-4 bg-red-50 dark:bg-red-950/20">
              <p className="text-xs text-muted-foreground mb-2">معاينة:</p>
              <div className="flex items-start gap-3">
                <div className={`${ERROR_CONFIG[editingError?.error_code || 0]?.color || "bg-gray-500"} w-8 h-8 rounded-full flex items-center justify-center text-white shrink-0`}>
                  {ERROR_CONFIG[editingError?.error_code || 0]?.icon || <AlertCircle className="h-4 w-4" />}
                </div>
                <div>
                  <p className="text-sm">{messageText || "..."}</p>
                  {showRetry && (
                    <Button size="sm" variant="outline" className="mt-2 h-7 text-xs">
                      <RefreshCw className="h-3 w-3 ml-1" />
                      إعادة المحاولة
                    </Button>
                  )}
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setEditingError(null)}>
              إلغاء
            </Button>
            <Button onClick={handleSave} disabled={updateError.isPending}>
              {updateError.isPending ? "جاري الحفظ..." : "حفظ"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
