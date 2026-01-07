"use client";

import { useState } from "react";
import {
  useUsers,
  useUserStats,
  useUpdateUserRole,
  roleLabels,
  type UserRole,
  type UserFilters,
} from "@/hooks/use-users";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Users,
  Shield,
  User,
  UserCog,
  Search,
  ChevronRight,
  ChevronLeft,
  MoreVertical,
  Calendar,
  TrendingUp,
  Clock,
} from "lucide-react";
import { toast } from "sonner";

export default function UsersPage() {
  const [filters, setFilters] = useState<UserFilters>({
    search: "",
    role: "all",
    sortBy: "created_at",
    sortOrder: "desc",
    page: 1,
    pageSize: 20,
  });

  const [roleDialog, setRoleDialog] = useState<{
    open: boolean;
    userId: string;
    currentRole: UserRole;
    newRole: UserRole;
    email: string;
  } | null>(null);

  const { data: usersData, isLoading } = useUsers(filters);
  const { data: stats, isLoading: statsLoading } = useUserStats();
  const updateRole = useUpdateUserRole();

  const handleSearch = (value: string) => {
    setFilters((f) => ({ ...f, search: value, page: 1 }));
  };

  const handleRoleFilter = (role: UserRole | "all") => {
    setFilters((f) => ({ ...f, role, page: 1 }));
  };

  const handleSort = (sortBy: UserFilters["sortBy"]) => {
    setFilters((f) => ({
      ...f,
      sortBy,
      sortOrder: f.sortBy === sortBy && f.sortOrder === "desc" ? "asc" : "desc",
    }));
  };

  const handlePageChange = (newPage: number) => {
    setFilters((f) => ({ ...f, page: newPage }));
  };

  const handleRoleChange = (userId: string, currentRole: UserRole, email: string) => (newRole: UserRole) => {
    if (newRole !== currentRole) {
      setRoleDialog({ open: true, userId, currentRole, newRole, email });
    }
  };

  const confirmRoleChange = () => {
    if (!roleDialog) return;

    updateRole.mutate(
      { userId: roleDialog.userId, role: roleDialog.newRole },
      {
        onSuccess: () => {
          toast.success(`تم تحديث صلاحية ${roleDialog.email} إلى ${roleLabels[roleDialog.newRole]}`);
          setRoleDialog(null);
        },
        onError: (error) => {
          toast.error("حدث خطأ أثناء تحديث الصلاحية");
          console.error(error);
        },
      }
    );
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("ar-SA", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  };

  const getRoleBadgeVariant = (role: UserRole) => {
    switch (role) {
      case "admin":
        return "destructive";
      case "moderator":
        return "default";
      default:
        return "secondary";
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold">دليل المستخدمين</h1>
        <p className="text-muted-foreground mt-1">
          عرض وإدارة جميع مستخدمي التطبيق
        </p>
      </div>

      {/* Debug Info - Auth vs Profiles */}
      {stats && (stats as any).auth_users !== undefined && (
        <Card className="border-yellow-500/50 bg-yellow-500/5">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-yellow-600">معلومات التصحيح</CardTitle>
          </CardHeader>
          <CardContent className="text-sm">
            <div className="flex gap-6">
              <div>
                <span className="text-muted-foreground">مستخدمو Auth: </span>
                <span className="font-bold">{(stats as any).auth_users}</span>
              </div>
              <div>
                <span className="text-muted-foreground">الملفات الشخصية: </span>
                <span className="font-bold">{stats.total_users}</span>
              </div>
              {(stats as any).auth_without_profile > 0 && (
                <div className="text-red-500">
                  <span>بدون ملف شخصي: </span>
                  <span className="font-bold">{(stats as any).auth_without_profile}</span>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">إجمالي المستخدمين</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <Skeleton className="h-8 w-20" />
            ) : (
              <div className="text-2xl font-bold">{stats?.total_users.toLocaleString("ar-SA")}</div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">جدد اليوم</CardTitle>
            <TrendingUp className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-2xl font-bold text-green-600">
                +{stats?.new_today.toLocaleString("ar-SA")}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">جدد هذا الأسبوع</CardTitle>
            <Calendar className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-2xl font-bold text-blue-600">
                +{stats?.new_this_week.toLocaleString("ar-SA")}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">جدد هذا الشهر</CardTitle>
            <Clock className="h-4 w-4 text-purple-500" />
          </CardHeader>
          <CardContent>
            {statsLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <div className="text-2xl font-bold text-purple-600">
                +{stats?.new_this_month.toLocaleString("ar-SA")}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Role Distribution */}
      <div className="grid gap-4 md:grid-cols-3">
        <Card className="cursor-pointer hover:bg-muted/50 transition-colors" onClick={() => handleRoleFilter("user")}>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-full bg-secondary">
                <User className="h-5 w-5 text-muted-foreground" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">مستخدمون</p>
                {statsLoading ? (
                  <Skeleton className="h-6 w-12 mt-1" />
                ) : (
                  <p className="text-xl font-bold">{stats?.users.toLocaleString("ar-SA")}</p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="cursor-pointer hover:bg-muted/50 transition-colors" onClick={() => handleRoleFilter("moderator")}>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-full bg-primary/10">
                <UserCog className="h-5 w-5 text-primary" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">مشرفون</p>
                {statsLoading ? (
                  <Skeleton className="h-6 w-12 mt-1" />
                ) : (
                  <p className="text-xl font-bold">{stats?.moderators.toLocaleString("ar-SA")}</p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="cursor-pointer hover:bg-muted/50 transition-colors" onClick={() => handleRoleFilter("admin")}>
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-full bg-destructive/10">
                <Shield className="h-5 w-5 text-destructive" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">مسؤولون</p>
                {statsLoading ? (
                  <Skeleton className="h-6 w-12 mt-1" />
                ) : (
                  <p className="text-xl font-bold">{stats?.admins.toLocaleString("ar-SA")}</p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle>قائمة المستخدمين</CardTitle>
          <CardDescription>
            {usersData?.total.toLocaleString("ar-SA")} مستخدم
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col md:flex-row gap-4 mb-6">
            <div className="relative flex-1">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="بحث بالبريد الإلكتروني أو الاسم..."
                value={filters.search}
                onChange={(e) => handleSearch(e.target.value)}
                className="pr-10"
              />
            </div>
            <Select value={filters.role} onValueChange={(v) => handleRoleFilter(v as UserRole | "all")}>
              <SelectTrigger className="w-full md:w-40">
                <SelectValue placeholder="الصلاحية" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">الكل</SelectItem>
                <SelectItem value="user">مستخدم</SelectItem>
                <SelectItem value="moderator">مشرف</SelectItem>
                <SelectItem value="admin">مسؤول</SelectItem>
              </SelectContent>
            </Select>
            <Select value={filters.sortBy} onValueChange={(v) => handleSort(v as UserFilters["sortBy"])}>
              <SelectTrigger className="w-full md:w-44">
                <SelectValue placeholder="ترتيب حسب" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="created_at">تاريخ الإنشاء</SelectItem>
                <SelectItem value="updated_at">آخر تحديث</SelectItem>
                <SelectItem value="email">البريد الإلكتروني</SelectItem>
                <SelectItem value="display_name">الاسم</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Users Table */}
          {isLoading ? (
            <div className="space-y-4">
              {[...Array(5)].map((_, i) => (
                <Skeleton key={i} className="h-16 w-full" />
              ))}
            </div>
          ) : (
            <>
              <div className="border rounded-lg overflow-hidden">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="w-12">#</TableHead>
                      <TableHead>المستخدم</TableHead>
                      <TableHead>البريد الإلكتروني</TableHead>
                      <TableHead>الصلاحية</TableHead>
                      <TableHead>تاريخ التسجيل</TableHead>
                      <TableHead className="w-12"></TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {usersData?.users.map((user, index) => (
                      <TableRow key={user.id}>
                        <TableCell className="text-muted-foreground">
                          {((filters.page || 1) - 1) * (filters.pageSize || 20) + index + 1}
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-3">
                            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary/20 to-primary/40 flex items-center justify-center text-sm font-medium">
                              {user.display_name?.[0] || user.email?.[0] || "?"}
                            </div>
                            <span className="font-medium">
                              {user.display_name || "—"}
                            </span>
                          </div>
                        </TableCell>
                        <TableCell className="text-muted-foreground font-mono text-sm">
                          {user.email || "—"}
                        </TableCell>
                        <TableCell>
                          <Badge variant={getRoleBadgeVariant(user.role)}>
                            {roleLabels[user.role]}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-muted-foreground text-sm">
                          {formatDate(user.created_at)}
                        </TableCell>
                        <TableCell>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" size="icon">
                                <MoreVertical className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuLabel>تغيير الصلاحية</DropdownMenuLabel>
                              <DropdownMenuSeparator />
                              <DropdownMenuItem
                                onClick={() => handleRoleChange(user.id, user.role, user.email || "")("user")}
                                disabled={user.role === "user"}
                              >
                                <User className="h-4 w-4 ml-2" />
                                مستخدم
                              </DropdownMenuItem>
                              <DropdownMenuItem
                                onClick={() => handleRoleChange(user.id, user.role, user.email || "")("moderator")}
                                disabled={user.role === "moderator"}
                              >
                                <UserCog className="h-4 w-4 ml-2" />
                                مشرف
                              </DropdownMenuItem>
                              <DropdownMenuItem
                                onClick={() => handleRoleChange(user.id, user.role, user.email || "")("admin")}
                                disabled={user.role === "admin"}
                              >
                                <Shield className="h-4 w-4 ml-2" />
                                مسؤول
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </TableCell>
                      </TableRow>
                    ))}
                    {usersData?.users.length === 0 && (
                      <TableRow>
                        <TableCell colSpan={6} className="text-center py-8 text-muted-foreground">
                          لا يوجد مستخدمون
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </div>

              {/* Pagination */}
              {usersData && usersData.totalPages > 1 && (
                <div className="flex items-center justify-between mt-4">
                  <p className="text-sm text-muted-foreground">
                    عرض {((filters.page || 1) - 1) * (filters.pageSize || 20) + 1} - {Math.min((filters.page || 1) * (filters.pageSize || 20), usersData.total)} من {usersData.total}
                  </p>
                  <div className="flex items-center gap-2">
                    <Button
                      variant="outline"
                      size="icon"
                      onClick={() => handlePageChange((filters.page || 1) - 1)}
                      disabled={(filters.page || 1) <= 1}
                    >
                      <ChevronRight className="h-4 w-4" />
                    </Button>
                    <span className="text-sm px-2">
                      {filters.page} / {usersData.totalPages}
                    </span>
                    <Button
                      variant="outline"
                      size="icon"
                      onClick={() => handlePageChange((filters.page || 1) + 1)}
                      disabled={(filters.page || 1) >= usersData.totalPages}
                    >
                      <ChevronLeft className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      {/* Role Change Confirmation Dialog */}
      <Dialog open={roleDialog?.open} onOpenChange={(open) => !open && setRoleDialog(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>تأكيد تغيير الصلاحية</DialogTitle>
            <DialogDescription>
              هل أنت متأكد من تغيير صلاحية <strong>{roleDialog?.email}</strong> من{" "}
              <Badge variant={getRoleBadgeVariant(roleDialog?.currentRole || "user")}>
                {roleLabels[roleDialog?.currentRole || "user"]}
              </Badge>{" "}
              إلى{" "}
              <Badge variant={getRoleBadgeVariant(roleDialog?.newRole || "user")}>
                {roleLabels[roleDialog?.newRole || "user"]}
              </Badge>
              ؟
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setRoleDialog(null)}>
              إلغاء
            </Button>
            <Button onClick={confirmRoleChange} disabled={updateRole.isPending}>
              {updateRole.isPending ? "جاري التحديث..." : "تأكيد"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
