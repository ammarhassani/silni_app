"use client";

import { useState } from "react";
import {
  useAuditLogs,
  useAuditStats,
  AuditActionType,
  AuditResourceType,
  actionLabels,
  actionColors,
  resourceLabels,
  AuditLogFilters,
  AuditLogEntry,
} from "@/hooks/use-audit-log";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
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
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  History,
  Search,
  Calendar,
  User,
  Activity,
  Plus,
  Pencil,
  Trash2,
  Eye,
  Send,
  LogIn,
  LogOut,
  MoreHorizontal,
  RefreshCw,
  Filter,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import { formatDistanceToNow, format } from "date-fns";
import { ar } from "date-fns/locale";

const ACTION_ICONS: Record<AuditActionType, React.ElementType> = {
  create: Plus,
  update: Pencil,
  delete: Trash2,
  view: Eye,
  export: MoreHorizontal,
  send: Send,
  login: LogIn,
  logout: LogOut,
  other: Activity,
};

const PAGE_SIZE = 50;

export default function AuditLogPage() {
  const [filters, setFilters] = useState<AuditLogFilters>({
    limit: PAGE_SIZE,
    offset: 0,
  });
  const [selectedLog, setSelectedLog] = useState<AuditLogEntry | null>(null);

  const { data: logs, isLoading, refetch } = useAuditLogs(filters);
  const { data: stats } = useAuditStats();

  const updateFilter = (key: keyof AuditLogFilters, value: string | undefined) => {
    setFilters((prev) => ({
      ...prev,
      [key]: value === "all" ? undefined : value,
      offset: 0, // Reset pagination when filter changes
    }));
  };

  const nextPage = () => {
    setFilters((prev) => ({
      ...prev,
      offset: (prev.offset || 0) + PAGE_SIZE,
    }));
  };

  const prevPage = () => {
    setFilters((prev) => ({
      ...prev,
      offset: Math.max(0, (prev.offset || 0) - PAGE_SIZE),
    }));
  };

  return (
    <div className="space-y-6 p-6" dir="rtl">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
            <History className="h-7 w-7 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">سجل العمليات</h1>
            <p className="text-muted-foreground mt-1">
              تتبع جميع الإجراءات في لوحة التحكم
            </p>
          </div>
        </div>
        <Button variant="outline" onClick={() => refetch()}>
          <RefreshCw className="h-4 w-4 ml-2" />
          تحديث
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card className="bg-gradient-to-br from-blue-500/10 to-cyan-500/5 border-blue-500/20">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">إجمالي العمليات</p>
                <p className="text-3xl font-bold text-blue-600">
                  {stats?.total?.toLocaleString() || 0}
                </p>
              </div>
              <div className="w-12 h-12 bg-blue-500/10 rounded-xl flex items-center justify-center">
                <Activity className="h-6 w-6 text-blue-500" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-green-500/10 to-emerald-500/5 border-green-500/20">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">اليوم</p>
                <p className="text-3xl font-bold text-green-600">
                  {stats?.today?.toLocaleString() || 0}
                </p>
              </div>
              <div className="w-12 h-12 bg-green-500/10 rounded-xl flex items-center justify-center">
                <Calendar className="h-6 w-6 text-green-500" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-purple-500/10 to-pink-500/5 border-purple-500/20">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">هذا الأسبوع</p>
                <p className="text-3xl font-bold text-purple-600">
                  {stats?.thisWeek?.toLocaleString() || 0}
                </p>
              </div>
              <div className="w-12 h-12 bg-purple-500/10 rounded-xl flex items-center justify-center">
                <History className="h-6 w-6 text-purple-500" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-orange-500/10 to-amber-500/5 border-orange-500/20">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">الإجراء الأكثر</p>
                <p className="text-xl font-bold text-orange-600">
                  {stats?.byAction
                    ? actionLabels[
                        Object.entries(stats.byAction).sort((a, b) => b[1] - a[1])[0]?.[0] as AuditActionType
                      ] || "-"
                    : "-"}
                </p>
              </div>
              <div className="w-12 h-12 bg-orange-500/10 rounded-xl flex items-center justify-center">
                <Pencil className="h-6 w-6 text-orange-500" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <Card>
        <CardHeader className="pb-4">
          <div className="flex items-center gap-2">
            <Filter className="h-5 w-5 text-muted-foreground" />
            <CardTitle className="text-lg">تصفية النتائج</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            {/* Search */}
            <div className="relative col-span-2">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="بحث في الوصف أو اسم المورد..."
                value={filters.search || ""}
                onChange={(e) => updateFilter("search", e.target.value || undefined)}
                className="pr-10"
              />
            </div>

            {/* Action Type */}
            <Select
              value={filters.action || "all"}
              onValueChange={(v) => updateFilter("action", v)}
            >
              <SelectTrigger>
                <SelectValue placeholder="نوع الإجراء" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">جميع الإجراءات</SelectItem>
                {Object.entries(actionLabels).map(([key, label]) => (
                  <SelectItem key={key} value={key}>
                    {label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            {/* Resource Type */}
            <Select
              value={filters.resource_type || "all"}
              onValueChange={(v) => updateFilter("resource_type", v)}
            >
              <SelectTrigger>
                <SelectValue placeholder="نوع المورد" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">جميع الموارد</SelectItem>
                {Object.entries(resourceLabels).map(([key, label]) => (
                  <SelectItem key={key} value={key}>
                    {label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            {/* Admin Email */}
            <Input
              placeholder="البريد الإلكتروني للمشرف"
              value={filters.admin_email || ""}
              onChange={(e) => updateFilter("admin_email", e.target.value || undefined)}
              dir="ltr"
            />
          </div>
        </CardContent>
      </Card>

      {/* Logs Table */}
      <Card>
        <CardHeader>
          <CardTitle>سجل العمليات</CardTitle>
          <CardDescription>
            {logs?.length || 0} سجل
            {(filters.offset || 0) > 0 && ` (الصفحة ${Math.floor((filters.offset || 0) / PAGE_SIZE) + 1})`}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-4">
              {[...Array(10)].map((_, i) => (
                <Skeleton key={i} className="h-16 w-full" />
              ))}
            </div>
          ) : !logs || logs.length === 0 ? (
            <div className="text-center py-12">
              <History className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">لا توجد سجلات</p>
            </div>
          ) : (
            <>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-[180px]">الوقت</TableHead>
                    <TableHead>المشرف</TableHead>
                    <TableHead>الإجراء</TableHead>
                    <TableHead>المورد</TableHead>
                    <TableHead>الوصف</TableHead>
                    <TableHead className="w-[80px]">التفاصيل</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {logs.map((log) => {
                    const ActionIcon = ACTION_ICONS[log.action];
                    return (
                      <TableRow key={log.id} className="hover:bg-muted/50">
                        <TableCell>
                          <div className="text-sm">
                            <p className="font-medium">
                              {formatDistanceToNow(new Date(log.created_at), {
                                addSuffix: true,
                                locale: ar,
                              })}
                            </p>
                            <p className="text-xs text-muted-foreground" dir="ltr">
                              {format(new Date(log.created_at), "yyyy-MM-dd HH:mm:ss")}
                            </p>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <div className="w-8 h-8 bg-muted rounded-full flex items-center justify-center">
                              <User className="h-4 w-4 text-muted-foreground" />
                            </div>
                            <span className="text-sm" dir="ltr">
                              {log.admin_email.split("@")[0]}
                            </span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge className={actionColors[log.action]}>
                            <ActionIcon className="h-3 w-3 ml-1" />
                            {actionLabels[log.action]}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <div>
                            <Badge variant="outline" className="text-xs">
                              {resourceLabels[log.resource_type]}
                            </Badge>
                            {log.resource_name && (
                              <p className="text-xs text-muted-foreground mt-1 max-w-[150px] truncate">
                                {log.resource_name}
                              </p>
                            )}
                          </div>
                        </TableCell>
                        <TableCell>
                          <p className="text-sm text-muted-foreground max-w-[300px] truncate">
                            {log.description || "-"}
                          </p>
                        </TableCell>
                        <TableCell>
                          {(log.changes || log.metadata) && (
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => setSelectedLog(log)}
                            >
                              <Eye className="h-4 w-4" />
                            </Button>
                          )}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>

              {/* Pagination */}
              <div className="flex items-center justify-between mt-4 pt-4 border-t">
                <Button
                  variant="outline"
                  onClick={prevPage}
                  disabled={(filters.offset || 0) === 0}
                >
                  <ChevronRight className="h-4 w-4 ml-2" />
                  السابق
                </Button>
                <span className="text-sm text-muted-foreground">
                  عرض {(filters.offset || 0) + 1} - {(filters.offset || 0) + (logs?.length || 0)}
                </span>
                <Button
                  variant="outline"
                  onClick={nextPage}
                  disabled={(logs?.length || 0) < PAGE_SIZE}
                >
                  التالي
                  <ChevronLeft className="h-4 w-4 mr-2" />
                </Button>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {/* Details Dialog */}
      <Dialog open={!!selectedLog} onOpenChange={() => setSelectedLog(null)}>
        <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto" dir="rtl">
          {selectedLog && (
            <>
              <DialogHeader>
                <DialogTitle className="flex items-center gap-2">
                  <Badge className={actionColors[selectedLog.action]}>
                    {actionLabels[selectedLog.action]}
                  </Badge>
                  <span>{resourceLabels[selectedLog.resource_type]}</span>
                </DialogTitle>
                <DialogDescription>
                  {format(new Date(selectedLog.created_at), "yyyy-MM-dd HH:mm:ss")}
                </DialogDescription>
              </DialogHeader>

              <div className="space-y-6">
                {/* Basic Info */}
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground">المشرف</p>
                    <p className="font-medium" dir="ltr">{selectedLog.admin_email}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">معرف المورد</p>
                    <p className="font-mono text-sm" dir="ltr">
                      {selectedLog.resource_id || "-"}
                    </p>
                  </div>
                  {selectedLog.resource_name && (
                    <div className="col-span-2">
                      <p className="text-sm text-muted-foreground">اسم المورد</p>
                      <p className="font-medium">{selectedLog.resource_name}</p>
                    </div>
                  )}
                  {selectedLog.description && (
                    <div className="col-span-2">
                      <p className="text-sm text-muted-foreground">الوصف</p>
                      <p>{selectedLog.description}</p>
                    </div>
                  )}
                </div>

                {/* Changes */}
                {selectedLog.changes && (
                  <div>
                    <p className="text-sm font-medium mb-2">التغييرات</p>
                    <pre className="bg-muted p-4 rounded-lg text-sm overflow-x-auto" dir="ltr">
                      {JSON.stringify(selectedLog.changes, null, 2)}
                    </pre>
                  </div>
                )}

                {/* Metadata */}
                {selectedLog.metadata && (
                  <div>
                    <p className="text-sm font-medium mb-2">بيانات إضافية</p>
                    <pre className="bg-muted p-4 rounded-lg text-sm overflow-x-auto" dir="ltr">
                      {JSON.stringify(selectedLog.metadata, null, 2)}
                    </pre>
                  </div>
                )}

                {/* Request Info */}
                {(selectedLog.ip_address || selectedLog.user_agent) && (
                  <div>
                    <p className="text-sm font-medium mb-2">معلومات الطلب</p>
                    <div className="bg-muted p-4 rounded-lg text-sm space-y-1" dir="ltr">
                      {selectedLog.ip_address && <p>IP: {selectedLog.ip_address}</p>}
                      {selectedLog.user_agent && (
                        <p className="text-xs text-muted-foreground truncate">
                          {selectedLog.user_agent}
                        </p>
                      )}
                    </div>
                  </div>
                )}
              </div>
            </>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
