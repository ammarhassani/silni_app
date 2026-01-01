"use client";

import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
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
  useApiKeys,
  useMarkKeyRotated,
  ApiKeyRecord,
  KeyCategory,
  getCategoryLabel,
  getCategoryIcon,
  getEnvironmentLabel,
  getUsageLocationLabel,
} from "@/hooks/use-api-keys";
import {
  Key,
  ExternalLink,
  RotateCcw,
  Clock,
  AlertTriangle,
  CheckCircle,
  Copy,
  Shield,
  Eye,
  Server,
  Smartphone,
  Cloud,
  Database,
  Lock,
  CreditCard,
  Bell,
  Bot,
  Activity,
  HardDrive,
  KeyRound,
  Search,
} from "lucide-react";
import { formatDistanceToNow, isPast, parseISO } from "date-fns";
import { ar } from "date-fns/locale";
import { Input } from "@/components/ui/input";

const CATEGORIES: KeyCategory[] = [
  "backend",
  "auth",
  "payments",
  "messaging",
  "ai",
  "monitoring",
  "storage",
  "signing",
];

const CATEGORY_ICONS: Record<KeyCategory, React.ElementType> = {
  backend: Database,
  auth: Lock,
  payments: CreditCard,
  messaging: Bell,
  ai: Bot,
  monitoring: Activity,
  storage: HardDrive,
  signing: KeyRound,
  other: Key,
};

const CATEGORY_COLORS: Record<KeyCategory, string> = {
  backend: "from-emerald-500 to-teal-600",
  auth: "from-violet-500 to-purple-600",
  payments: "from-amber-500 to-orange-600",
  messaging: "from-blue-500 to-cyan-600",
  ai: "from-pink-500 to-rose-600",
  monitoring: "from-lime-500 to-green-600",
  storage: "from-slate-500 to-zinc-600",
  signing: "from-red-500 to-rose-600",
  other: "from-gray-500 to-slate-600",
};

export default function ApiKeysPage() {
  const { data: keys, isLoading } = useApiKeys();
  const markRotated = useMarkKeyRotated();
  const [selectedKey, setSelectedKey] = useState<ApiKeyRecord | null>(null);
  const [showRotationDialog, setShowRotationDialog] = useState(false);
  const [keyToRotate, setKeyToRotate] = useState<ApiKeyRecord | null>(null);
  const [searchQuery, setSearchQuery] = useState("");

  // Group keys by category
  const keysByCategory = keys?.reduce((acc, key) => {
    if (!acc[key.category]) {
      acc[key.category] = [];
    }
    acc[key.category].push(key);
    return acc;
  }, {} as Record<KeyCategory, ApiKeyRecord[]>);

  // Get keys due for rotation
  const keysDueForRotation = keys?.filter(
    (key) => key.next_rotation_at && isPast(parseISO(key.next_rotation_at))
  );

  // Get secret keys count
  const secretKeysCount = keys?.filter((key) => key.is_secret).length || 0;

  // Filter keys by search
  const filteredKeys = keys?.filter(
    (key) =>
      key.service_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      key.key_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      key.description_ar?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Handle mark as rotated
  const handleMarkRotated = (key: ApiKeyRecord) => {
    const daysMap: Record<string, number> = {
      "90 days": 90,
      yearly: 365,
      never: 0,
    };
    const days = key.rotation_frequency ? daysMap[key.rotation_frequency] || 90 : 90;

    markRotated.mutate({
      id: key.id,
      nextRotationDays: days > 0 ? days : undefined,
    });
    setShowRotationDialog(false);
    setKeyToRotate(null);
  };

  // Copy to clipboard
  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  if (isLoading) {
    return (
      <div className="space-y-6 p-6">
        <div className="flex items-center gap-4">
          <Skeleton className="h-12 w-12 rounded-2xl" />
          <div className="space-y-2">
            <Skeleton className="h-8 w-64" />
            <Skeleton className="h-4 w-96" />
          </div>
        </div>
        <div className="grid grid-cols-4 gap-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-28 rounded-xl" />
          ))}
        </div>
        <div className="grid gap-4">
          {[1, 2, 3].map((i) => (
            <Skeleton key={i} className="h-24 rounded-xl" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 p-6" dir="rtl">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-silni-teal to-silni-gold rounded-2xl flex items-center justify-center shadow-lg">
            <Key className="h-7 w-7 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">سجل المفاتيح والأسرار</h1>
            <p className="text-muted-foreground mt-1">
              إدارة وتتبع جميع مفاتيح API والأسرار مع دليل التدوير
            </p>
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card className="bg-gradient-to-br from-emerald-500/10 to-teal-500/5 border-emerald-500/20">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">إجمالي المفاتيح</p>
                <p className="text-3xl font-bold text-emerald-600">{keys?.length || 0}</p>
              </div>
              <div className="w-12 h-12 bg-emerald-500/10 rounded-xl flex items-center justify-center">
                <Key className="h-6 w-6 text-emerald-500" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-red-500/10 to-rose-500/5 border-red-500/20">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">مفاتيح سرية</p>
                <p className="text-3xl font-bold text-red-600">{secretKeysCount}</p>
              </div>
              <div className="w-12 h-12 bg-red-500/10 rounded-xl flex items-center justify-center">
                <Shield className="h-6 w-6 text-red-500" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-amber-500/10 to-yellow-500/5 border-amber-500/20">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">تحتاج تدوير</p>
                <p className="text-3xl font-bold text-amber-600">{keysDueForRotation?.length || 0}</p>
              </div>
              <div className="w-12 h-12 bg-amber-500/10 rounded-xl flex items-center justify-center">
                <AlertTriangle className="h-6 w-6 text-amber-500" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-blue-500/10 to-cyan-500/5 border-blue-500/20">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">عدد الفئات</p>
                <p className="text-3xl font-bold text-blue-600">{CATEGORIES.length}</p>
              </div>
              <div className="w-12 h-12 bg-blue-500/10 rounded-xl flex items-center justify-center">
                <Database className="h-6 w-6 text-blue-500" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Rotation Alerts */}
      {keysDueForRotation && keysDueForRotation.length > 0 && (
        <Card className="border-2 border-amber-400/50 bg-gradient-to-r from-amber-50 to-yellow-50 dark:from-amber-950/30 dark:to-yellow-950/20 shadow-lg shadow-amber-500/10">
          <CardHeader className="pb-3">
            <CardTitle className="text-amber-700 dark:text-amber-400 flex items-center gap-3">
              <div className="w-10 h-10 bg-amber-500/20 rounded-xl flex items-center justify-center animate-pulse">
                <AlertTriangle className="h-5 w-5" />
              </div>
              <span>مفاتيح تحتاج تدوير عاجل ({keysDueForRotation.length})</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-2">
              {keysDueForRotation.map((key) => (
                <Badge
                  key={key.id}
                  variant="outline"
                  className="cursor-pointer hover:bg-amber-100 dark:hover:bg-amber-900/30 border-amber-400 text-amber-700 dark:text-amber-300 py-1.5 px-3 text-sm transition-all hover:scale-105"
                  onClick={() => setSelectedKey(key)}
                >
                  <RotateCcw className="h-3 w-3 ml-1" />
                  {key.service_name} - {key.key_name}
                </Badge>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Search */}
      <div className="relative max-w-md">
        <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="بحث في المفاتيح..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="pr-10"
        />
      </div>

      {/* Categories Tabs */}
      <Tabs defaultValue="backend" className="space-y-6">
        <TabsList className="flex flex-wrap h-auto gap-2 p-2 bg-muted/50 rounded-xl">
          {CATEGORIES.map((category) => {
            const IconComponent = CATEGORY_ICONS[category];
            return (
              <TabsTrigger
                key={category}
                value={category}
                className="flex items-center gap-2 px-4 py-2.5 rounded-lg data-[state=active]:shadow-md transition-all"
              >
                <IconComponent className="h-4 w-4" />
                <span className="font-medium">{getCategoryLabel(category)}</span>
                <Badge
                  variant="secondary"
                  className="mr-1 h-5 min-w-[20px] text-xs"
                >
                  {keysByCategory?.[category]?.length || 0}
                </Badge>
              </TabsTrigger>
            );
          })}
        </TabsList>

        {CATEGORIES.map((category) => (
          <TabsContent key={category} value={category} className="space-y-4 mt-6">
            {keysByCategory?.[category]?.length === 0 ? (
              <Card className="border-dashed">
                <CardContent className="py-12 text-center">
                  <div className="w-16 h-16 mx-auto mb-4 bg-muted rounded-2xl flex items-center justify-center">
                    {(() => {
                      const IconComponent = CATEGORY_ICONS[category];
                      return <IconComponent className="h-8 w-8 text-muted-foreground" />;
                    })()}
                  </div>
                  <p className="text-muted-foreground text-lg">لا توجد مفاتيح في هذه الفئة</p>
                </CardContent>
              </Card>
            ) : (
              <div className="grid gap-4">
                {(searchQuery
                  ? keysByCategory?.[category]?.filter(
                      (key) =>
                        key.service_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                        key.key_name.toLowerCase().includes(searchQuery.toLowerCase())
                    )
                  : keysByCategory?.[category]
                )?.map((key) => (
                  <KeyCard
                    key={key.id}
                    apiKey={key}
                    categoryColor={CATEGORY_COLORS[category]}
                    onViewDetails={() => setSelectedKey(key)}
                    onMarkRotated={() => {
                      setKeyToRotate(key);
                      setShowRotationDialog(true);
                    }}
                  />
                ))}
              </div>
            )}
          </TabsContent>
        ))}
      </Tabs>

      {/* Key Details Dialog */}
      <Dialog open={!!selectedKey} onOpenChange={() => setSelectedKey(null)}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto" dir="rtl">
          {selectedKey && (
            <>
              <DialogHeader>
                <DialogTitle className="flex items-center gap-2">
                  {getCategoryIcon(selectedKey.category)}
                  {selectedKey.service_name} - {selectedKey.key_name}
                </DialogTitle>
                <DialogDescription>
                  {selectedKey.purpose || selectedKey.description_ar}
                </DialogDescription>
              </DialogHeader>

              <div className="space-y-6">
                {/* Quick Info */}
                <div className="grid grid-cols-2 gap-4">
                  <InfoItem
                    label="المعرّف"
                    value={selectedKey.key_identifier || "-"}
                    copyable
                  />
                  <InfoItem
                    label="ملف الإعدادات"
                    value={selectedKey.config_file_path || "-"}
                    copyable
                  />
                  <InfoItem
                    label="اسم المتغير"
                    value={selectedKey.config_variable_name || "-"}
                    copyable
                  />
                  <InfoItem
                    label="البيئة"
                    value={getEnvironmentLabel(selectedKey.environment)}
                  />
                  <InfoItem
                    label="مكان الاستخدام"
                    value={getUsageLocationLabel(selectedKey.usage_location)}
                  />
                  <InfoItem
                    label="مستوى الكشف"
                    value={selectedKey.exposure_level}
                    icon={
                      selectedKey.is_secret ? (
                        <Shield className="h-4 w-4 text-red-500" />
                      ) : (
                        <Eye className="h-4 w-4 text-green-500" />
                      )
                    }
                  />
                </div>

                {/* Source Link */}
                {selectedKey.source_url && (
                  <div className="space-y-2">
                    <h4 className="font-semibold">مصدر المفتاح</h4>
                    <a
                      href={selectedKey.source_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center gap-2 text-blue-600 hover:underline"
                    >
                      <ExternalLink className="h-4 w-4" />
                      {selectedKey.source_path || selectedKey.source_url}
                    </a>
                  </div>
                )}

                {/* Rotation Guide */}
                {selectedKey.rotation_guide && (
                  <div className="space-y-2">
                    <h4 className="font-semibold flex items-center gap-2">
                      <RotateCcw className="h-4 w-4" />
                      دليل التدوير
                    </h4>
                    <pre className="bg-muted p-4 rounded-lg text-sm whitespace-pre-wrap font-mono">
                      {selectedKey.rotation_guide}
                    </pre>
                  </div>
                )}

                {/* Rotation Status */}
                <div className="flex items-center justify-between p-4 bg-muted rounded-lg">
                  <div>
                    <p className="text-sm text-muted-foreground">آخر تدوير</p>
                    <p className="font-medium">
                      {selectedKey.last_rotated_at
                        ? formatDistanceToNow(parseISO(selectedKey.last_rotated_at), {
                            addSuffix: true,
                            locale: ar,
                          })
                        : "لم يتم التدوير بعد"}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">التدوير القادم</p>
                    <p className="font-medium">
                      {selectedKey.rotation_frequency === "never"
                        ? "غير مطلوب"
                        : selectedKey.next_rotation_at
                        ? formatDistanceToNow(parseISO(selectedKey.next_rotation_at), {
                            addSuffix: true,
                            locale: ar,
                          })
                        : selectedKey.rotation_frequency || "-"}
                    </p>
                  </div>
                  <Button
                    onClick={() => {
                      setKeyToRotate(selectedKey);
                      setShowRotationDialog(true);
                    }}
                  >
                    <CheckCircle className="h-4 w-4 ml-2" />
                    تم التدوير
                  </Button>
                </div>

                {/* Notes */}
                {selectedKey.notes && (
                  <div className="space-y-2">
                    <h4 className="font-semibold">ملاحظات</h4>
                    <p className="text-muted-foreground">{selectedKey.notes}</p>
                  </div>
                )}
              </div>
            </>
          )}
        </DialogContent>
      </Dialog>

      {/* Rotation Confirmation Dialog */}
      <AlertDialog open={showRotationDialog} onOpenChange={setShowRotationDialog}>
        <AlertDialogContent dir="rtl">
          <AlertDialogHeader>
            <AlertDialogTitle>تأكيد تدوير المفتاح</AlertDialogTitle>
            <AlertDialogDescription>
              هل قمت بتدوير مفتاح {keyToRotate?.service_name} - {keyToRotate?.key_name}؟
              <br />
              سيتم تحديث تاريخ آخر تدوير وجدولة التدوير القادم.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter className="flex-row-reverse gap-2">
            <AlertDialogAction
              onClick={() => keyToRotate && handleMarkRotated(keyToRotate)}
            >
              نعم، تم التدوير
            </AlertDialogAction>
            <AlertDialogCancel>إلغاء</AlertDialogCancel>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}

// Key Card Component
function KeyCard({
  apiKey,
  categoryColor,
  onViewDetails,
  onMarkRotated,
}: {
  apiKey: ApiKeyRecord;
  categoryColor: string;
  onViewDetails: () => void;
  onMarkRotated: () => void;
}) {
  const isDue =
    apiKey.next_rotation_at && isPast(parseISO(apiKey.next_rotation_at));

  return (
    <Card
      className={`cursor-pointer hover:shadow-lg transition-all duration-200 hover:-translate-y-0.5 overflow-hidden group ${
        isDue ? "border-amber-400 ring-2 ring-amber-400/20" : "hover:border-primary/30"
      }`}
      onClick={onViewDetails}
    >
      <div className="flex">
        {/* Colored accent bar */}
        <div className={`w-1.5 bg-gradient-to-b ${categoryColor}`} />

        <div className="flex-1 p-4">
          {/* Header */}
          <div className="flex items-start justify-between mb-3">
            <div className="flex items-center gap-3">
              <div className={`w-10 h-10 rounded-xl bg-gradient-to-br ${categoryColor} flex items-center justify-center shadow-sm`}>
                <Key className="h-5 w-5 text-white" />
              </div>
              <div>
                <h3 className="font-semibold text-base group-hover:text-primary transition-colors">
                  {apiKey.service_name}
                </h3>
                <Badge variant="outline" className="mt-0.5 text-xs font-normal">
                  {apiKey.key_name}
                </Badge>
              </div>
            </div>
            <div className="flex items-center gap-2">
              {apiKey.is_secret && (
                <Badge className="bg-red-500/10 text-red-600 border-red-500/20 hover:bg-red-500/20">
                  <Shield className="h-3 w-3 ml-1" />
                  سري
                </Badge>
              )}
              <Badge variant="secondary" className="text-xs">
                {getEnvironmentLabel(apiKey.environment)}
              </Badge>
            </div>
          </div>

          {/* Description */}
          {(apiKey.purpose || apiKey.description_ar) && (
            <p className="text-sm text-muted-foreground mb-3 line-clamp-2">
              {apiKey.purpose || apiKey.description_ar}
            </p>
          )}

          {/* Footer */}
          <div className="flex items-center justify-between pt-3 border-t border-border/50">
            <div className="flex items-center gap-3 text-xs text-muted-foreground">
              <span className="flex items-center gap-1.5 bg-muted/50 px-2 py-1 rounded-md">
                {apiKey.usage_location === "flutter_app" ? (
                  <Smartphone className="h-3.5 w-3.5" />
                ) : apiKey.usage_location === "edge_functions" ? (
                  <Server className="h-3.5 w-3.5" />
                ) : (
                  <Cloud className="h-3.5 w-3.5" />
                )}
                {getUsageLocationLabel(apiKey.usage_location)}
              </span>
              {apiKey.config_variable_name && (
                <code className="bg-muted px-2 py-1 rounded-md font-mono text-[10px]">
                  {apiKey.config_variable_name}
                </code>
              )}
            </div>
            <div className="flex items-center gap-2">
              {isDue ? (
                <Badge className="bg-amber-500/10 text-amber-600 border-amber-500/20 animate-pulse">
                  <AlertTriangle className="h-3 w-3 ml-1" />
                  يحتاج تدوير
                </Badge>
              ) : apiKey.rotation_frequency === "never" ? (
                <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-500/20">
                  <CheckCircle className="h-3 w-3 ml-1" />
                  لا يحتاج تدوير
                </Badge>
              ) : apiKey.last_rotated_at ? (
                <span className="text-muted-foreground flex items-center gap-1.5 text-xs bg-muted/50 px-2 py-1 rounded-md">
                  <Clock className="h-3 w-3" />
                  {formatDistanceToNow(parseISO(apiKey.last_rotated_at), {
                    addSuffix: true,
                    locale: ar,
                  })}
                </span>
              ) : null}
              <Button
                variant="ghost"
                size="icon"
                className="h-8 w-8 hover:bg-primary/10"
                onClick={(e) => {
                  e.stopPropagation();
                  onMarkRotated();
                }}
              >
                <RotateCcw className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>
      </div>
    </Card>
  );
}

// Info Item Component
function InfoItem({
  label,
  value,
  copyable,
  icon,
}: {
  label: string;
  value: string;
  copyable?: boolean;
  icon?: React.ReactNode;
}) {
  return (
    <div className="space-y-1">
      <p className="text-sm text-muted-foreground">{label}</p>
      <div className="flex items-center gap-2">
        {icon}
        <p className="font-medium">{value}</p>
        {copyable && value !== "-" && (
          <Button
            variant="ghost"
            size="icon"
            className="h-6 w-6"
            onClick={() => navigator.clipboard.writeText(value)}
          >
            <Copy className="h-3 w-3" />
          </Button>
        )}
      </div>
    </div>
  );
}
