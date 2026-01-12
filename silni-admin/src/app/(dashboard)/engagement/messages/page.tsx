"use client";

import { useState, useMemo, useEffect } from "react";
import {
  useInAppMessages,
  useCreateInAppMessage,
  useUpdateInAppMessage,
  useDeleteInAppMessage,
  useToggleInAppMessageActive,
  useDuplicateInAppMessage,
  useResetMessageImpressions,
  messageTypeLabels,
  frequencyLabels,
  iconStyleLabels,
  colorModeLabels,
  availableLotties,
  type InAppMessage,
  type InAppMessageInput,
} from "@/hooks/use-in-app-messages";
import { MessagePreview } from "@/components/preview/MessagePreview";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Checkbox } from "@/components/ui/checkbox";
import { RouteSelector } from "@/components/ui/route-selector";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
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
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import {
  MessageSquare,
  Plus,
  Edit2,
  Trash2,
  Copy,
  Eye,
  MousePointerClick,
  Users,
  Filter,
  ChevronDown,
  MapPin,
  Settings2,
  RotateCcw,
} from "lucide-react";

// Trigger type options - when/how the message appears
const triggerTypeOptions = [
  { value: "app_open", label: "عند فتح التطبيق", description: "يظهر عند فتح التطبيق" },
  { value: "screen_view", label: "عند زيارة شاشة", description: "يظهر عند فتح شاشة معينة" },
  { value: "position", label: "موقع ثابت (بانر)", description: "يظهر في موقع محدد بالشاشة" },
];

// Position options for banner placement
const positionOptions = [
  { value: "home_top", label: "أعلى الشاشة الرئيسية" },
  { value: "home_bottom", label: "أسفل الشاشة الرئيسية" },
  { value: "profile_top", label: "أعلى صفحة الملف الشخصي" },
  { value: "settings_top", label: "أعلى صفحة الإعدادات" },
];

// Grouped icons with emojis for the consolidated icon picker
const groupedIcons = [
  { group: "إشعارات", items: [
    { value: "bell", label: "🔔 جرس" },
    { value: "megaphone", label: "📢 مكبر صوت" },
    { value: "alert", label: "⚠️ تنبيه" },
    { value: "info", label: "ℹ️ معلومات" },
  ]},
  { group: "احتفالات", items: [
    { value: "star", label: "⭐ نجمة" },
    { value: "sparkles", label: "✨ بريق" },
    { value: "party", label: "🎉 احتفال" },
    { value: "gift", label: "🎁 هدية" },
    { value: "trophy", label: "🏆 كأس" },
  ]},
  { group: "إجراءات", items: [
    { value: "crown", label: "👑 تاج" },
    { value: "rocket", label: "🚀 صاروخ" },
    { value: "zap", label: "⚡ برق" },
    { value: "fire", label: "🔥 نار" },
  ]},
  { group: "تفاعل", items: [
    { value: "heart", label: "❤️ قلب" },
    { value: "users", label: "👥 مستخدمين" },
    { value: "tree", label: "🌳 شجرة" },
  ]},
  { group: "نظام", items: [
    { value: "check", label: "✅ صح" },
    { value: "warning", label: "⚠️ تحذير" },
    { value: "tip", label: "💡 نصيحة" },
    { value: "moon", label: "🌙 قمر" },
    { value: "sun", label: "☀️ شمس" },
  ]},
];

// Helper to format date for datetime-local input (YYYY-MM-DDTHH:mm in local time)
const toLocalDateTimeString = (date: Date): string => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  return `${year}-${month}-${day}T${hours}:${minutes}`;
};

// Helper to get current datetime in local format for datetime-local input
const getCurrentDateTime = () => toLocalDateTimeString(new Date());

// Helper to get datetime 30 days from now
const getEndDateTime = () => {
  const date = new Date();
  date.setDate(date.getDate() + 30);
  return toLocalDateTimeString(date);
};

// Convert ISO string to local datetime format for datetime-local input
const isoToLocalDateTime = (isoStr: string | null): string => {
  if (!isoStr) return "";
  try {
    const date = new Date(isoStr);
    return toLocalDateTimeString(date);
  } catch {
    // If already in local format or invalid, return as-is
    return isoStr.slice(0, 16);
  }
};

// Format date for display in Arabic (e.g., "4 يناير 2026، 12:30 م")
const formatDateArabic = (dateStr: string | null): string => {
  if (!dateStr) return "—";
  try {
    const date = new Date(dateStr);
    return new Intl.DateTimeFormat('ar-SA', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(date);
  } catch {
    return dateStr;
  }
};

// Smart defaults based on message type
const typeDefaults: Record<string, Partial<InAppMessageInput>> = {
  banner: {
    display_frequency: "always",
    is_dismissible: true,
    delay_seconds: 0,
  },
  modal: {
    display_frequency: "once",
    is_dismissible: true,
    delay_seconds: 1,
  },
  bottom_sheet: {
    display_frequency: "once",
    is_dismissible: true,
    delay_seconds: 0,
  },
  motd: {
    display_frequency: "daily",
    is_dismissible: true,
    delay_seconds: 0,
  },
  full_screen: {
    display_frequency: "once",
    is_dismissible: false,
    delay_seconds: 2,
  },
  tooltip: {
    display_frequency: "once",
    is_dismissible: true,
    delay_seconds: 0,
  },
};

const defaultMessage: InAppMessageInput = {
  name: "",
  name_ar: null,
  message_type: "banner",
  title_ar: "",
  title_en: null,
  body_ar: null,
  body_en: null,
  cta_text_ar: null,
  cta_text_en: null,
  cta_action: null,
  cta_action_type: "route",
  image_url: null,
  icon_name: "bell",
  // Enhanced graphics
  graphic_type: "icon",
  lottie_name: null,
  illustration_url: null,
  icon_style: "default",
  // Color mode
  color_mode: "theme",
  background_color: "#1E3A5F",
  text_color: "#FFFFFF",
  accent_color: null,
  background_gradient: { start: "#1E3A5F", end: "#0F2744" },
  trigger_type: "app_open",
  trigger_value: null,
  display_frequency: "once",
  max_impressions: null,
  delay_seconds: 0,
  start_date: null,
  end_date: null,
  target_tiers: ["free", "max"],
  target_platforms: ["ios", "android"],
  target_user_segment: null,
  min_app_version: null,
  priority: 0,
  is_active: false,
  is_dismissible: true,
  impressions: 0,
  clicks: 0,
};

// Helper to get trigger label for display
function getTriggerLabel(trigger_type: string, trigger_value: string | null): string {
  if (trigger_type === "app_open") return "عند فتح التطبيق";
  if (trigger_type === "position") {
    const pos = positionOptions.find(p => p.value === trigger_value);
    return pos?.label || trigger_value || "موقع ثابت";
  }
  if (trigger_type === "screen_view") {
    return trigger_value || "شاشة";
  }
  return "غير محدد";
}

export default function InAppMessagesPage() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [editingMessage, setEditingMessage] = useState<InAppMessage | null>(null);
  const [messageToDelete, setMessageToDelete] = useState<InAppMessage | null>(null);
  const [advancedOpen, setAdvancedOpen] = useState(false);

  // Filters
  const [typeFilter, setTypeFilter] = useState<string>("all");
  const [statusFilter, setStatusFilter] = useState<string>("all");

  // Build filters object
  const filters = useMemo(() => ({
    messageType: typeFilter !== "all" ? typeFilter : undefined,
    isActive: statusFilter === "all" ? undefined : statusFilter === "active",
  }), [typeFilter, statusFilter]);

  // Queries
  const { data: messages, isLoading } = useInAppMessages(filters);

  // Mutations
  const createMessage = useCreateInAppMessage();
  const updateMessage = useUpdateInAppMessage();
  const deleteMessage = useDeleteInAppMessage();
  const toggleActive = useToggleInAppMessageActive();
  const duplicateMessage = useDuplicateInAppMessage();
  const resetImpressions = useResetMessageImpressions();

  // Form state
  const [formData, setFormData] = useState<InAppMessageInput>(defaultMessage);

  // Auto-generate admin name from Arabic title
  useEffect(() => {
    if (formData.title_ar && !formData.name && !editingMessage) {
      setFormData(prev => ({ ...prev, name: formData.title_ar.slice(0, 50) }));
    }
  }, [formData.title_ar, formData.name, editingMessage]);

  const handleOpenCreate = () => {
    setEditingMessage(null);
    // Initialize with current datetime and 30 days end date
    setFormData({
      ...defaultMessage,
      start_date: getCurrentDateTime(),
      end_date: getEndDateTime(),
    });
    setAdvancedOpen(false);
    setDialogOpen(true);
  };

  const handleOpenEdit = (message: InAppMessage) => {
    setEditingMessage(message);
    setFormData({
      name: message.name,
      name_ar: message.name_ar,
      message_type: message.message_type,
      title_ar: message.title_ar,
      title_en: message.title_en,
      body_ar: message.body_ar,
      body_en: message.body_en,
      cta_text_ar: message.cta_text_ar,
      cta_text_en: message.cta_text_en,
      cta_action: message.cta_action,
      cta_action_type: message.cta_action_type,
      image_url: message.image_url,
      icon_name: message.icon_name,
      // Enhanced graphics
      graphic_type: message.graphic_type || "icon",
      lottie_name: message.lottie_name,
      illustration_url: message.illustration_url,
      icon_style: message.icon_style || "default",
      // Color mode
      color_mode: message.color_mode || "theme",
      background_color: message.background_color,
      text_color: message.text_color,
      accent_color: message.accent_color,
      background_gradient: message.background_gradient,
      trigger_type: message.trigger_type,
      trigger_value: message.trigger_value,
      display_frequency: message.display_frequency,
      max_impressions: message.max_impressions,
      delay_seconds: message.delay_seconds,
      start_date: isoToLocalDateTime(message.start_date),
      end_date: isoToLocalDateTime(message.end_date),
      target_tiers: message.target_tiers,
      target_platforms: message.target_platforms,
      target_user_segment: message.target_user_segment,
      min_app_version: message.min_app_version,
      priority: message.priority,
      is_active: message.is_active,
      is_dismissible: message.is_dismissible,
      impressions: message.impressions,
      clicks: message.clicks,
    });
    setAdvancedOpen(false);
    setDialogOpen(true);
  };

  const handleTriggerTypeChange = (value: string) => {
    // Reset trigger_value when changing trigger type
    setFormData({
      ...formData,
      trigger_type: value as InAppMessageInput["trigger_type"],
      trigger_value: value === "app_open" ? null : formData.trigger_value,
    });
  };

  const handleTypeChange = (value: string) => {
    const defaults = typeDefaults[value] || {};
    setFormData({
      ...formData,
      message_type: value as InAppMessageInput["message_type"],
      ...defaults,
    });
  };

  const handleSubmit = async () => {
    let submitData = { ...formData };

    // Convert local datetime strings to ISO for database storage
    if (submitData.start_date) {
      submitData.start_date = new Date(submitData.start_date).toISOString();
    }
    if (submitData.end_date) {
      submitData.end_date = new Date(submitData.end_date).toISOString();
    }

    if (editingMessage) {
      await updateMessage.mutateAsync({ id: editingMessage.id, ...submitData });
    } else {
      await createMessage.mutateAsync(submitData);
    }
    setDialogOpen(false);
  };

  const handleDelete = async () => {
    if (messageToDelete) {
      await deleteMessage.mutateAsync(messageToDelete.id);
      setDeleteDialogOpen(false);
      setMessageToDelete(null);
    }
  };

  // Stats summary
  const activeMessages = messages?.filter((m) => m.is_active).length || 0;
  const totalMessages = messages?.length || 0;
  const totalImpressions = messages?.reduce((sum, m) => sum + (m.impressions || 0), 0) || 0;
  const totalClicks = messages?.reduce((sum, m) => sum + (m.clicks || 0), 0) || 0;
  const overallCTR = totalImpressions > 0 ? ((totalClicks / totalImpressions) * 100).toFixed(1) : "0";

  // Get human-readable location - uses the helper function
  const getLocationLabel = (message: InAppMessage) => {
    return getTriggerLabel(message.trigger_type, message.trigger_value);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center shadow-lg">
            <MessageSquare className="h-7 w-7 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">الرسائل</h1>
            <p className="text-muted-foreground mt-1">
              رسائل ترويجية وإعلانات داخل التطبيق
            </p>
          </div>
        </div>
        <Button onClick={handleOpenCreate} size="lg">
          <Plus className="h-5 w-5 ml-2" />
          رسالة جديدة
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-primary/10 rounded-lg">
                <MessageSquare className="h-5 w-5 text-primary" />
              </div>
              <div>
                <p className="text-2xl font-bold">{totalMessages}</p>
                <p className="text-sm text-muted-foreground">إجمالي</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-green-500/10 rounded-lg">
                <Eye className="h-5 w-5 text-green-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">{activeMessages}</p>
                <p className="text-sm text-muted-foreground">نشطة</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-500/10 rounded-lg">
                <Users className="h-5 w-5 text-blue-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">{totalImpressions.toLocaleString()}</p>
                <p className="text-sm text-muted-foreground">مشاهدة</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-500/10 rounded-lg">
                <MousePointerClick className="h-5 w-5 text-amber-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">{overallCTR}%</p>
                <p className="text-sm text-muted-foreground">نقرات ({totalClicks})</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Messages List */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>قائمة الرسائل</CardTitle>
            <div className="flex items-center gap-3">
              <Select value={typeFilter} onValueChange={setTypeFilter}>
                <SelectTrigger className="w-[140px]">
                  <Filter className="h-4 w-4 ml-2" />
                  <SelectValue placeholder="النوع" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">كل الأنواع</SelectItem>
                  {Object.entries(messageTypeLabels).map(([key, label]) => (
                    <SelectItem key={key} value={key}>
                      {label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>

              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger className="w-[120px]">
                  <SelectValue placeholder="الحالة" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">الكل</SelectItem>
                  <SelectItem value="active">نشط</SelectItem>
                  <SelectItem value="inactive">معطل</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-3">
              {[...Array(3)].map((_, i) => (
                <Skeleton key={i} className="h-20 w-full" />
              ))}
            </div>
          ) : !messages?.length ? (
            <div className="text-center py-12 text-muted-foreground">
              <MessageSquare className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p className="mb-4">لا توجد رسائل بعد</p>
              <Button onClick={handleOpenCreate}>
                إنشاء أول رسالة
              </Button>
            </div>
          ) : (
            <div className="space-y-3">
              {messages.map((message) => {
                const ctr = message.impressions > 0
                  ? ((message.clicks / message.impressions) * 100).toFixed(1)
                  : "0";
                return (
                  <div
                    key={message.id}
                    className="flex items-center gap-4 p-4 border rounded-lg bg-card hover:bg-accent/50 transition-colors"
                  >
                    {/* Preview */}
                    <div
                      className="w-12 h-12 rounded-lg flex items-center justify-center shrink-0"
                      style={
                        message.background_gradient
                          ? {
                              background: `linear-gradient(135deg, ${message.background_gradient.start}, ${message.background_gradient.end})`,
                            }
                          : {
                              backgroundColor: message.background_color,
                            }
                      }
                    >
                      <MessageSquare
                        className="h-6 w-6"
                        style={{ color: message.text_color }}
                      />
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1 flex-wrap">
                        <h3 className="font-medium">{message.title_ar || message.name}</h3>
                        <Badge variant="outline" className="text-xs">
                          {messageTypeLabels[message.message_type]}
                        </Badge>
                        {!message.is_active && (
                          <Badge variant="secondary" className="text-xs">معطلة</Badge>
                        )}
                      </div>
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <MapPin className="h-3 w-3" />
                        <span>{getLocationLabel(message)}</span>
                        <span className="mx-1">•</span>
                        <span>{frequencyLabels[message.display_frequency]}</span>
                      </div>
                    </div>

                    {/* Analytics */}
                    <div className="text-sm text-muted-foreground shrink-0 text-left min-w-[80px]">
                      <div className="flex items-center gap-1">
                        <Eye className="h-3 w-3" />
                        <span>{(message.impressions || 0).toLocaleString()}</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <MousePointerClick className="h-3 w-3" />
                        <span>{ctr}%</span>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-1 shrink-0">
                      <Switch
                        checked={message.is_active}
                        onCheckedChange={(checked) =>
                          toggleActive.mutate({
                            id: message.id,
                            is_active: checked,
                          })
                        }
                      />
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => duplicateMessage.mutate(message)}
                        title="نسخ"
                      >
                        <Copy className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => resetImpressions.mutate(message.id)}
                        title="إعادة تعيين الانطباعات"
                      >
                        <RotateCcw className="h-4 w-4 text-amber-500" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleOpenEdit(message)}
                        title="تعديل"
                      >
                        <Edit2 className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => {
                          setMessageToDelete(message);
                          setDeleteDialogOpen(true);
                        }}
                        title="حذف"
                      >
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Create/Edit Dialog - SIMPLIFIED */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {editingMessage ? "تعديل الرسالة" : "رسالة جديدة"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-6">
            {/* BASIC FIELDS - Always visible */}
            <div className="space-y-4">
              {/* Row 1: Message Type */}
              <div className="space-y-2">
                <Label>نوع الرسالة</Label>
                <Select
                  key={formData.message_type}
                  value={formData.message_type}
                  onValueChange={handleTypeChange}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="اختر النوع">
                      {messageTypeLabels[formData.message_type] || formData.message_type}
                    </SelectValue>
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="banner">بانر (شريط)</SelectItem>
                    <SelectItem value="modal">نافذة منبثقة</SelectItem>
                    <SelectItem value="bottom_sheet">شريط سفلي</SelectItem>
                    <SelectItem value="motd">رسالة اليوم</SelectItem>
                    <SelectItem value="full_screen">ملء الشاشة</SelectItem>
                    <SelectItem value="tooltip">تلميح</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Row 2: Trigger Configuration - User-friendly section */}
              <div className="p-4 border rounded-lg bg-muted/20 space-y-4">
                <Label className="flex items-center gap-2 text-base font-medium">
                  <MapPin className="h-4 w-4" />
                  متى وأين تظهر الرسالة؟
                </Label>

                {/* Trigger Type Selection */}
                <div className="grid grid-cols-3 gap-2">
                  {triggerTypeOptions.map((opt) => (
                    <Button
                      key={opt.value}
                      type="button"
                      variant={formData.trigger_type === opt.value ? "default" : "outline"}
                      size="sm"
                      onClick={() => handleTriggerTypeChange(opt.value)}
                      className="flex flex-col h-auto py-3 px-2"
                    >
                      <span className="text-sm font-medium">{opt.label}</span>
                      <span className="text-[10px] opacity-70 mt-1">{opt.description}</span>
                    </Button>
                  ))}
                </div>

                {/* Screen Selection - Dynamic from database */}
                {formData.trigger_type === "screen_view" && (
                  <div className="space-y-2">
                    <Label className="text-sm">اختر الشاشة التي ستظهر فيها الرسالة</Label>
                    <RouteSelector
                      value={formData.trigger_value}
                      onChange={(value) =>
                        setFormData({
                          ...formData,
                          trigger_value: value || null,
                        })
                      }
                      placeholder="اختر شاشة من التطبيق..."
                    />
                    <p className="text-xs text-muted-foreground">
                      يتم جلب الشاشات تلقائياً من قاعدة البيانات - أي شاشة جديدة تضيفها ستظهر هنا
                    </p>
                  </div>
                )}

                {/* Position Selection */}
                {formData.trigger_type === "position" && (
                  <div className="space-y-2">
                    <Label className="text-sm">اختر موقع البانر</Label>
                    <Select
                      value={formData.trigger_value || ""}
                      onValueChange={(value) =>
                        setFormData({
                          ...formData,
                          trigger_value: value,
                        })
                      }
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="اختر الموقع" />
                      </SelectTrigger>
                      <SelectContent>
                        {positionOptions.map((pos) => (
                          <SelectItem key={pos.value} value={pos.value}>
                            {pos.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                )}

                {/* App Open - No additional config needed */}
                {formData.trigger_type === "app_open" && (
                  <p className="text-sm text-muted-foreground bg-blue-50 dark:bg-blue-950 p-3 rounded-lg">
                    ℹ️ ستظهر الرسالة مباشرة عند فتح التطبيق
                  </p>
                )}
              </div>

              {/* Row 2: Title */}
              <div className="space-y-2">
                <Label>العنوان *</Label>
                <Input
                  value={formData.title_ar}
                  onChange={(e) =>
                    setFormData({ ...formData, title_ar: e.target.value })
                  }
                  placeholder="عنوان الرسالة"
                />
              </div>

              {/* Row 3: Body */}
              <div className="space-y-2">
                <Label>نص الرسالة</Label>
                <Textarea
                  value={formData.body_ar || ""}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      body_ar: e.target.value || null,
                    })
                  }
                  placeholder="محتوى الرسالة (اختياري)"
                  rows={2}
                />
              </div>

              {/* Row 4: Icon + Icon Style (consolidated single row) */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>الأيقونة</Label>
                  <Select
                    value={formData.icon_name || "bell"}
                    onValueChange={(value) =>
                      setFormData({ ...formData, icon_name: value, graphic_type: "icon" })
                    }
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {groupedIcons.map((group) => (
                        <div key={group.group}>
                          <div className="px-2 py-1.5 text-xs font-semibold text-muted-foreground">
                            {group.group}
                          </div>
                          {group.items.map((icon) => (
                            <SelectItem key={icon.value} value={icon.value}>
                              {icon.label}
                            </SelectItem>
                          ))}
                        </div>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>نمط الأيقونة</Label>
                  <Select
                    value={formData.icon_style || "default"}
                    onValueChange={(value) =>
                      setFormData({ ...formData, icon_style: value as InAppMessageInput["icon_style"] })
                    }
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {Object.entries(iconStyleLabels).map(([key, label]) => (
                        <SelectItem key={key} value={key}>
                          {label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {/* Row 5: CTA Button - Enhanced */}
              <div className="p-4 border rounded-lg bg-muted/20 space-y-4">
                <Label className="flex items-center gap-2 text-base font-medium">
                  <MousePointerClick className="h-4 w-4" />
                  زر الإجراء (CTA)
                </Label>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-sm">نص الزر</Label>
                    <Input
                      value={formData.cta_text_ar || ""}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          cta_text_ar: e.target.value || null,
                        })
                      }
                      placeholder="مثال: اشترك الآن"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label className="text-sm">أين ينقل الزر المستخدم؟</Label>
                    <RouteSelector
                      value={formData.cta_action}
                      onChange={(value) =>
                        setFormData({
                          ...formData,
                          cta_action: value || null,
                          cta_action_type: "route",
                        })
                      }
                      placeholder="اختر الشاشة المستهدفة..."
                    />
                  </div>
                </div>
                {formData.cta_text_ar && !formData.cta_action && (
                  <p className="text-xs text-amber-600 bg-amber-50 dark:bg-amber-950 p-2 rounded">
                    ⚠️ أضفت نص للزر لكن لم تحدد وجهته - الزر سيغلق الرسالة فقط
                  </p>
                )}
              </div>

              {/* Row 6: Schedule + Frequency (3 cols) */}
              <div className="grid grid-cols-3 gap-4">
                <div className="space-y-2">
                  <Label className="text-xs">تاريخ البدء</Label>
                  <Input
                    type="datetime-local"
                    value={formData.start_date || ""}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        start_date: e.target.value || null,
                      })
                    }
                    className="text-sm"
                  />
                </div>
                <div className="space-y-2">
                  <Label className="text-xs">تاريخ الانتهاء</Label>
                  <Input
                    type="datetime-local"
                    value={formData.end_date || ""}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        end_date: e.target.value || null,
                      })
                    }
                    className="text-sm"
                  />
                </div>
                <div className="space-y-2">
                  <Label className="text-xs">تكرار العرض</Label>
                  <Select
                    value={formData.display_frequency}
                    onValueChange={(value) =>
                      setFormData({
                        ...formData,
                        display_frequency:
                          value as InAppMessageInput["display_frequency"],
                      })
                    }
                  >
                    <SelectTrigger className="text-sm">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {Object.entries(frequencyLabels).map(([key, label]) => (
                        <SelectItem key={key} value={key}>
                          {label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {/* Row 7: Active toggle (prominent) */}
              <div className="flex items-center justify-between p-3 border rounded-lg bg-muted/30">
                <div className="flex items-center gap-2">
                  <Eye className="h-4 w-4 text-muted-foreground" />
                  <Label className="font-medium">تفعيل الرسالة</Label>
                </div>
                <Switch
                  checked={formData.is_active}
                  onCheckedChange={(checked) =>
                    setFormData({ ...formData, is_active: checked })
                  }
                />
              </div>
            </div>

            {/* ADVANCED SETTINGS - Collapsible */}
            <Collapsible open={advancedOpen} onOpenChange={setAdvancedOpen}>
              <CollapsibleTrigger asChild>
                <Button variant="ghost" className="w-full justify-between">
                  <span className="flex items-center gap-2">
                    <Settings2 className="h-4 w-4" />
                    إعدادات متقدمة
                  </span>
                  <ChevronDown className={`h-4 w-4 transition-transform ${advancedOpen ? "rotate-180" : ""}`} />
                </Button>
              </CollapsibleTrigger>
              <CollapsibleContent className="space-y-4 pt-4">
                {/* Name for admin */}
                <div className="space-y-2">
                  <Label>اسم الرسالة (للإدارة)</Label>
                  <Input
                    value={formData.name}
                    onChange={(e) =>
                      setFormData({ ...formData, name: e.target.value })
                    }
                    placeholder="يتم إنشاؤه تلقائياً من العنوان"
                  />
                  <p className="text-xs text-muted-foreground">
                    يتم إنشاؤه تلقائياً من العنوان إذا تُرك فارغاً
                  </p>
                </div>

                {/* Alternative Graphics (Lottie/Illustration) */}
                <div className="space-y-3 p-3 border rounded-lg bg-muted/20">
                  <Label className="text-sm font-medium">رسومات متقدمة (بديل للأيقونات)</Label>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label className="text-xs text-muted-foreground">رسوم متحركة (Lottie)</Label>
                      <Select
                        value={formData.lottie_name || "none"}
                        onValueChange={(value) =>
                          setFormData({
                            ...formData,
                            lottie_name: value === "none" ? null : value,
                            graphic_type: value !== "none" ? "lottie" : formData.graphic_type
                          })
                        }
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="اختر رسوم متحركة" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="none">بدون</SelectItem>
                          {availableLotties.map((lottie) => (
                            <SelectItem key={lottie.value} value={lottie.value}>
                              {lottie.label}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="space-y-2">
                      <Label className="text-xs text-muted-foreground">صورة توضيحية</Label>
                      <Input
                        value={formData.illustration_url || ""}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            illustration_url: e.target.value || null,
                            graphic_type: e.target.value ? "illustration" : formData.graphic_type,
                          })
                        }
                        placeholder="https://..."
                      />
                    </div>
                  </div>
                </div>

                {/* Targeting */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>الباقات</Label>
                    <div className="flex gap-4">
                      {["free", "max"].map((tier) => (
                        <label key={tier} className="flex items-center gap-2">
                          <Checkbox
                            checked={formData.target_tiers.includes(tier)}
                            onCheckedChange={(checked) => {
                              if (checked) {
                                setFormData({
                                  ...formData,
                                  target_tiers: [...formData.target_tiers, tier],
                                });
                              } else {
                                setFormData({
                                  ...formData,
                                  target_tiers: formData.target_tiers.filter(
                                    (t) => t !== tier
                                  ),
                                });
                              }
                            }}
                          />
                          <span className="text-sm">{tier === "free" ? "مجاني" : "ماكس"}</span>
                        </label>
                      ))}
                    </div>
                  </div>
                  <div className="space-y-2">
                    <Label>المنصات</Label>
                    <div className="flex gap-4">
                      {["ios", "android"].map((platform) => (
                        <label key={platform} className="flex items-center gap-2">
                          <Checkbox
                            checked={formData.target_platforms.includes(platform)}
                            onCheckedChange={(checked) => {
                              if (checked) {
                                setFormData({
                                  ...formData,
                                  target_platforms: [
                                    ...formData.target_platforms,
                                    platform,
                                  ],
                                });
                              } else {
                                setFormData({
                                  ...formData,
                                  target_platforms:
                                    formData.target_platforms.filter(
                                      (p) => p !== platform
                                    ),
                                });
                              }
                            }}
                          />
                          <span className="text-sm">{platform === "ios" ? "iOS" : "Android"}</span>
                        </label>
                      ))}
                    </div>
                  </div>
                </div>

                {/* Color Mode */}
                <div className="space-y-2">
                  <Label>نمط الألوان</Label>
                  <div className="flex gap-2">
                    {Object.entries(colorModeLabels).map(([value, label]) => (
                      <Button
                        key={value}
                        type="button"
                        variant={formData.color_mode === value ? "default" : "outline"}
                        size="sm"
                        onClick={() =>
                          setFormData({ ...formData, color_mode: value as "theme" | "custom" })
                        }
                        className="flex-1"
                      >
                        {label}
                      </Button>
                    ))}
                  </div>
                  <p className="text-xs text-muted-foreground">
                    {formData.color_mode === "theme"
                      ? "الألوان ستتكيف تلقائياً مع ثيم المستخدم"
                      : "استخدم الألوان المخصصة أدناه"}
                  </p>
                </div>

                {/* Colors - only show when custom mode */}
                {formData.color_mode === "custom" && (
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>لون الخلفية</Label>
                    <div className="flex gap-2">
                      <Input
                        type="color"
                        value={formData.background_gradient?.start || formData.background_color}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            background_color: e.target.value,
                            background_gradient: formData.background_gradient
                              ? { ...formData.background_gradient, start: e.target.value }
                              : null,
                          })
                        }
                        className="w-12 h-10 p-1"
                      />
                      <Input
                        type="color"
                        value={formData.background_gradient?.end || formData.background_color}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            background_gradient: {
                              start: formData.background_gradient?.start || formData.background_color,
                              end: e.target.value,
                            },
                          })
                        }
                        className="w-12 h-10 p-1"
                      />
                      <div
                        className="flex-1 rounded-lg border"
                        style={{
                          background: formData.background_gradient
                            ? `linear-gradient(135deg, ${formData.background_gradient.start}, ${formData.background_gradient.end})`
                            : formData.background_color,
                        }}
                      />
                    </div>
                  </div>
                  <div className="space-y-2">
                    <Label>لون النص</Label>
                    <div className="flex gap-2">
                      <Input
                        type="color"
                        value={formData.text_color}
                        onChange={(e) =>
                          setFormData({ ...formData, text_color: e.target.value })
                        }
                        className="w-12 h-10 p-1"
                      />
                      <Input
                        value={formData.text_color}
                        onChange={(e) =>
                          setFormData({ ...formData, text_color: e.target.value })
                        }
                        className="flex-1 font-mono text-sm"
                      />
                    </div>
                  </div>
                </div>
                )}

                {/* Priority, Delay, Max impressions, Dismissible */}
                <div className="grid grid-cols-4 gap-4">
                  <div className="space-y-2">
                    <Label className="text-xs">الأولوية</Label>
                    <Input
                      type="number"
                      value={formData.priority}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          priority: parseInt(e.target.value) || 0,
                        })
                      }
                      min={0}
                      max={100}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label className="text-xs">تأخير (ثواني)</Label>
                    <Input
                      type="number"
                      value={formData.delay_seconds}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          delay_seconds: parseInt(e.target.value) || 0,
                        })
                      }
                      min={0}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label className="text-xs">حد المشاهدات</Label>
                    <Input
                      type="number"
                      value={formData.max_impressions || ""}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          max_impressions: e.target.value
                            ? parseInt(e.target.value)
                            : null,
                        })
                      }
                      placeholder="∞"
                      min={1}
                    />
                  </div>
                  <div className="space-y-2 flex flex-col justify-end">
                    <label className="flex items-center gap-2">
                      <Switch
                        checked={formData.is_dismissible}
                        onCheckedChange={(checked) =>
                          setFormData({ ...formData, is_dismissible: checked })
                        }
                      />
                      <span className="text-xs">قابلة للإغلاق</span>
                    </label>
                  </div>
                </div>
              </CollapsibleContent>
            </Collapsible>

            {/* Live Preview */}
            <div className="border-t pt-4">
              <MessagePreview data={formData} />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSubmit}
              disabled={
                !formData.title_ar ||
                createMessage.isPending ||
                updateMessage.isPending
              }
            >
              {editingMessage ? "حفظ" : "إنشاء"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>حذف الرسالة</AlertDialogTitle>
            <AlertDialogDescription>
              هل أنت متأكد من حذف &quot;{messageToDelete?.title_ar || messageToDelete?.name}&quot;؟
              <br />
              لا يمكن التراجع عن هذا الإجراء.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>إلغاء</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              حذف
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
