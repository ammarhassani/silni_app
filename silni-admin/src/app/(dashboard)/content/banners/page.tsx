"use client";

import { useState, useMemo } from "react";
import { useBannersList, useDeleteBanner, useUpdateBanner } from "@/hooks/use-content";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Plus,
  MoreHorizontal,
  Pencil,
  Trash2,
  Eye,
  EyeOff,
  Image,
  Calendar,
  MousePointerClick,
  BarChart3,
} from "lucide-react";
import { BannerDialog } from "./banner-dialog";
import type { AdminBanner } from "@/types/database";
import { truncate } from "@/lib/utils";
import { format } from "date-fns";
import { ar } from "date-fns/locale";

export default function BannersPage() {
  const [positionFilter, setPositionFilter] = useState<string>("all");
  const [activeFilter, setActiveFilter] = useState<string>("all");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedBanner, setSelectedBanner] = useState<AdminBanner | null>(null);

  const filters = useMemo(() => ({
    position: positionFilter !== "all" ? positionFilter : undefined,
    active: activeFilter === "all" ? undefined : activeFilter === "active",
  }), [positionFilter, activeFilter]);

  const { data: bannersList, isLoading } = useBannersList(filters);
  const deleteBanner = useDeleteBanner();
  const updateBanner = useUpdateBanner();

  const handleEdit = (banner: AdminBanner) => {
    setSelectedBanner(banner);
    setDialogOpen(true);
  };

  const handleCreate = () => {
    setSelectedBanner(null);
    setDialogOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (confirm("هل أنت متأكد من حذف هذا البانر؟")) {
      deleteBanner.mutate(id);
    }
  };

  const handleToggleActive = (banner: AdminBanner) => {
    updateBanner.mutate({
      id: banner.id,
      is_active: !banner.is_active,
    });
  };

  const positionLabels: Record<string, string> = {
    home_top: "أعلى الرئيسية",
    home_bottom: "أسفل الرئيسية",
    profile: "الملف الشخصي",
    reminders: "التذكيرات",
  };

  const audienceLabels: Record<string, { label: string; color: string }> = {
    all: { label: "الجميع", color: "bg-gray-500/10 text-gray-600" },
    free: { label: "المجاني", color: "bg-blue-500/10 text-blue-600" },
    max: { label: "MAX", color: "bg-purple-500/10 text-purple-600" },
    new_users: { label: "مستخدمون جدد", color: "bg-green-500/10 text-green-600" },
  };

  const actionTypeLabels: Record<string, string> = {
    route: "مسار داخلي",
    url: "رابط خارجي",
    action: "إجراء",
    none: "بدون إجراء",
  };

  const isWithinDateRange = (banner: AdminBanner) => {
    const now = new Date();
    if (banner.start_date && new Date(banner.start_date) > now) return false;
    if (banner.end_date && new Date(banner.end_date) < now) return false;
    return true;
  };

  const activeCount = bannersList?.filter((b) => b.is_active && isWithinDateRange(b)).length ?? 0;
  const totalImpressions = bannersList?.reduce((sum, b) => sum + b.impressions, 0) ?? 0;
  const totalClicks = bannersList?.reduce((sum, b) => sum + b.clicks, 0) ?? 0;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">البانرات الإعلانية</h1>
          <p className="text-muted-foreground mt-1">
            إدارة البانرات والإعلانات الترويجية في التطبيق
          </p>
        </div>
        <Button onClick={handleCreate}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة بانر
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">نشط الآن</p>
                <p className="text-2xl font-bold">{activeCount}</p>
              </div>
              <Eye className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">إجمالي البانرات</p>
                <p className="text-2xl font-bold">{bannersList?.length ?? 0}</p>
              </div>
              <Image className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">المشاهدات</p>
                <p className="text-2xl font-bold">{totalImpressions.toLocaleString()}</p>
              </div>
              <BarChart3 className="h-8 w-8 text-purple-500" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">النقرات</p>
                <p className="text-2xl font-bold">
                  {totalClicks.toLocaleString()}
                  {totalImpressions > 0 && (
                    <span className="text-sm font-normal text-muted-foreground mr-2">
                      ({((totalClicks / totalImpressions) * 100).toFixed(1)}%)
                    </span>
                  )}
                </p>
              </div>
              <MousePointerClick className="h-8 w-8 text-orange-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-4">
            <Select value={positionFilter} onValueChange={setPositionFilter}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="جميع المواقع" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">جميع المواقع</SelectItem>
                {Object.entries(positionLabels).map(([value, label]) => (
                  <SelectItem key={value} value={value}>
                    {label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={activeFilter} onValueChange={setActiveFilter}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="جميع الحالات" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">جميع الحالات</SelectItem>
                <SelectItem value="active">نشط فقط</SelectItem>
                <SelectItem value="inactive">غير نشط</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-4">
              {[...Array(5)].map((_, i) => (
                <Skeleton key={i} className="h-20 w-full" />
              ))}
            </div>
          ) : !bannersList || bannersList.length === 0 ? (
            <div className="text-center py-12">
              <Image className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">لا توجد بانرات</p>
              <Button variant="outline" className="mt-4" onClick={handleCreate}>
                <Plus className="h-4 w-4 ml-2" />
                إضافة أول بانر
              </Button>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>المعاينة</TableHead>
                  <TableHead className="w-[250px]">العنوان والوصف</TableHead>
                  <TableHead>الموقع</TableHead>
                  <TableHead>الجمهور</TableHead>
                  <TableHead>الفترة</TableHead>
                  <TableHead>الأداء</TableHead>
                  <TableHead>الحالة</TableHead>
                  <TableHead className="w-[100px]">الإجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {bannersList.map((banner) => {
                  const isInRange = isWithinDateRange(banner);
                  const ctr = banner.impressions > 0
                    ? ((banner.clicks / banner.impressions) * 100).toFixed(1)
                    : "0";
                  return (
                    <TableRow key={banner.id} className={!isInRange ? "opacity-50" : ""}>
                      <TableCell>
                        {banner.image_url ? (
                          <img
                            src={banner.image_url}
                            alt={banner.title}
                            className="w-20 h-12 object-cover rounded"
                          />
                        ) : banner.background_gradient ? (
                          <div
                            className="w-20 h-12 rounded flex items-center justify-center text-white text-xs font-medium"
                            style={{
                              background: `linear-gradient(135deg, ${banner.background_gradient.start}, ${banner.background_gradient.end})`,
                            }}
                          >
                            تدرج
                          </div>
                        ) : (
                          <div className="w-20 h-12 bg-muted rounded flex items-center justify-center">
                            <Image className="h-4 w-4 text-muted-foreground" />
                          </div>
                        )}
                      </TableCell>
                      <TableCell>
                        <div>
                          <p className="font-medium">{banner.title}</p>
                          {banner.description && (
                            <p className="text-sm text-muted-foreground">
                              {truncate(banner.description, 50)}
                            </p>
                          )}
                          <Badge variant="outline" className="mt-1 text-xs">
                            {actionTypeLabels[banner.action_type]}
                          </Badge>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant="secondary">
                          {positionLabels[banner.position]}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <Badge className={audienceLabels[banner.target_audience]?.color || ""}>
                          {audienceLabels[banner.target_audience]?.label || banner.target_audience}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        {banner.start_date || banner.end_date ? (
                          <div className="flex items-center gap-1 text-sm">
                            <Calendar className="h-3 w-3" />
                            <span>
                              {banner.start_date
                                ? format(new Date(banner.start_date), "d MMM", { locale: ar })
                                : "∞"}{" "}
                              -{" "}
                              {banner.end_date
                                ? format(new Date(banner.end_date), "d MMM", { locale: ar })
                                : "∞"}
                            </span>
                          </div>
                        ) : (
                          <span className="text-muted-foreground">دائم</span>
                        )}
                      </TableCell>
                      <TableCell>
                        <div className="text-sm">
                          <div className="flex items-center gap-1">
                            <Eye className="h-3 w-3" />
                            {banner.impressions.toLocaleString()}
                          </div>
                          <div className="flex items-center gap-1 text-muted-foreground">
                            <MousePointerClick className="h-3 w-3" />
                            {banner.clicks.toLocaleString()} ({ctr}%)
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Switch
                            checked={banner.is_active}
                            onCheckedChange={() => handleToggleActive(banner)}
                            disabled={updateBanner.isPending}
                          />
                          {!isInRange && banner.is_active && (
                            <Badge variant="secondary" className="text-xs">
                              خارج الفترة
                            </Badge>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="icon">
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="start">
                            <DropdownMenuItem onClick={() => handleEdit(banner)}>
                              <Pencil className="h-4 w-4 ml-2" />
                              تعديل
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={() => handleToggleActive(banner)}>
                              {banner.is_active ? (
                                <>
                                  <EyeOff className="h-4 w-4 ml-2" />
                                  إخفاء
                                </>
                              ) : (
                                <>
                                  <Eye className="h-4 w-4 ml-2" />
                                  إظهار
                                </>
                              )}
                            </DropdownMenuItem>
                            <DropdownMenuItem
                              onClick={() => handleDelete(banner.id)}
                              className="text-destructive"
                            >
                              <Trash2 className="h-4 w-4 ml-2" />
                              حذف
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <BannerDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        banner={selectedBanner}
      />
    </div>
  );
}
