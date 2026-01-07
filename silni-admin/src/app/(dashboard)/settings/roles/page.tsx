"use client";

import { useState } from "react";
import {
  usePermissions,
  useRolePermissions,
  useAdmins,
  useUpdateAdminRole,
  useDemoteAdmin,
  roleLabels,
  roleDescriptions,
  roleColors,
  categoryLabels,
  AdminRoleType,
} from "@/hooks/use-roles";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
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
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import {
  Shield,
  Users,
  Check,
  X,
  Crown,
  Eye,
  Pencil,
  Trash2,
  UserMinus,
  AlertTriangle,
} from "lucide-react";

const allRoles: AdminRoleType[] = [
  "super_admin",
  "content_admin",
  "ai_admin",
  "marketing",
  "support",
  "viewer",
];

export default function RolesPage() {
  const { data: permissions, isLoading: permissionsLoading } = usePermissions();
  const { data: rolePermissions, isLoading: rolePermissionsLoading } = useRolePermissions();
  const { data: admins, isLoading: adminsLoading } = useAdmins();
  const updateRole = useUpdateAdminRole();
  const demoteAdmin = useDemoteAdmin();

  const [selectedRole, setSelectedRole] = useState<AdminRoleType>("super_admin");
  const [demoteDialog, setDemoteDialog] = useState<{ open: boolean; userId: string; email: string } | null>(null);

  // Group permissions by category
  const permissionsByCategory = permissions?.reduce((acc, perm) => {
    if (!acc[perm.category]) acc[perm.category] = [];
    acc[perm.category].push(perm);
    return acc;
  }, {} as Record<string, typeof permissions>);

  // Get permissions for a role
  const getRolePermissionKeys = (role: AdminRoleType) => {
    if (role === "super_admin") {
      return permissions?.map((p) => p.permission_key) || [];
    }
    return rolePermissions?.filter((rp) => rp.role === role).map((rp) => rp.permission_key) || [];
  };

  const handleRoleChange = (userId: string, newRole: AdminRoleType) => {
    updateRole.mutate({ userId, adminRole: newRole });
  };

  const handleDemote = () => {
    if (demoteDialog) {
      demoteAdmin.mutate(demoteDialog.userId);
      setDemoteDialog(null);
    }
  };

  const getRoleBadgeVariant = (role: AdminRoleType) => {
    return roleColors[role] as "default" | "secondary" | "destructive" | "outline";
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <div className="w-14 h-14 bg-gradient-to-br from-violet-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
          <Shield className="h-7 w-7 text-white" />
        </div>
        <div>
          <h1 className="text-3xl font-bold">إدارة الصلاحيات</h1>
          <p className="text-muted-foreground mt-1">
            تحكم في صلاحيات المسؤولين ونظام الأدوار
          </p>
        </div>
      </div>

      <Tabs defaultValue="admins" className="space-y-6">
        <TabsList>
          <TabsTrigger value="admins" className="gap-2">
            <Users className="h-4 w-4" />
            المسؤولون
          </TabsTrigger>
          <TabsTrigger value="roles" className="gap-2">
            <Crown className="h-4 w-4" />
            الأدوار والصلاحيات
          </TabsTrigger>
        </TabsList>

        {/* Admins Tab */}
        <TabsContent value="admins" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>المسؤولون الحاليون</CardTitle>
              <CardDescription>
                {admins?.length || 0} مسؤول في النظام
              </CardDescription>
            </CardHeader>
            <CardContent>
              {adminsLoading ? (
                <div className="space-y-4">
                  {[...Array(3)].map((_, i) => (
                    <Skeleton key={i} className="h-16 w-full" />
                  ))}
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>المسؤول</TableHead>
                      <TableHead>البريد الإلكتروني</TableHead>
                      <TableHead>الدور</TableHead>
                      <TableHead>تاريخ الإضافة</TableHead>
                      <TableHead className="w-12"></TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {admins?.map((admin) => (
                      <TableRow key={admin.id}>
                        <TableCell>
                          <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-violet-500/20 to-purple-500/40 flex items-center justify-center font-medium">
                              {admin.display_name?.[0] || admin.email?.[0] || "?"}
                            </div>
                            <span className="font-medium">{admin.display_name || "—"}</span>
                          </div>
                        </TableCell>
                        <TableCell className="font-mono text-sm text-muted-foreground">
                          {admin.email}
                        </TableCell>
                        <TableCell>
                          <Select
                            value={admin.admin_role || "super_admin"}
                            onValueChange={(value) => handleRoleChange(admin.id, value as AdminRoleType)}
                            disabled={updateRole.isPending}
                          >
                            <SelectTrigger className="w-40">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              {allRoles.map((role) => (
                                <SelectItem key={role} value={role}>
                                  <div className="flex items-center gap-2">
                                    <Badge variant={getRoleBadgeVariant(role)} className="text-xs">
                                      {roleLabels[role]}
                                    </Badge>
                                  </div>
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {new Date(admin.created_at).toLocaleDateString("ar-SA")}
                        </TableCell>
                        <TableCell>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="text-destructive hover:text-destructive"
                            onClick={() => setDemoteDialog({
                              open: true,
                              userId: admin.id,
                              email: admin.email,
                            })}
                          >
                            <UserMinus className="h-4 w-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                    {admins?.length === 0 && (
                      <TableRow>
                        <TableCell colSpan={5} className="text-center py-8 text-muted-foreground">
                          لا يوجد مسؤولون
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>

          {/* Info Cards */}
          <div className="grid gap-4 md:grid-cols-3">
            {allRoles.slice(0, 3).map((role) => (
              <Card key={role} className="border-r-4" style={{ borderRightColor: role === "super_admin" ? "#ef4444" : role === "content_admin" ? "#8b5cf6" : "#3b82f6" }}>
                <CardHeader className="pb-2">
                  <CardTitle className="text-lg flex items-center gap-2">
                    <Badge variant={getRoleBadgeVariant(role)}>{roleLabels[role]}</Badge>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground">{roleDescriptions[role]}</p>
                  <p className="text-xs mt-2 text-muted-foreground">
                    {admins?.filter((a) => a.admin_role === role).length || 0} مسؤول
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Roles Tab */}
        <TabsContent value="roles" className="space-y-6">
          <div className="grid gap-6 lg:grid-cols-3">
            {/* Role Selector */}
            <Card>
              <CardHeader>
                <CardTitle>الأدوار</CardTitle>
                <CardDescription>اختر دوراً لعرض صلاحياته</CardDescription>
              </CardHeader>
              <CardContent className="space-y-2">
                {allRoles.map((role) => (
                  <button
                    key={role}
                    onClick={() => setSelectedRole(role)}
                    className={`w-full p-3 rounded-lg text-right transition-colors ${
                      selectedRole === role
                        ? "bg-primary text-primary-foreground"
                        : "hover:bg-muted"
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <Badge variant={selectedRole === role ? "secondary" : getRoleBadgeVariant(role)}>
                        {roleLabels[role]}
                      </Badge>
                      <span className="text-xs opacity-70">
                        {getRolePermissionKeys(role).length} صلاحية
                      </span>
                    </div>
                    <p className={`text-xs mt-1 ${selectedRole === role ? "text-primary-foreground/70" : "text-muted-foreground"}`}>
                      {roleDescriptions[role]}
                    </p>
                  </button>
                ))}
              </CardContent>
            </Card>

            {/* Permissions Matrix */}
            <Card className="lg:col-span-2">
              <CardHeader>
                <CardTitle>صلاحيات {roleLabels[selectedRole]}</CardTitle>
                <CardDescription>
                  {selectedRole === "super_admin"
                    ? "المسؤول الكامل لديه جميع الصلاحيات"
                    : `${getRolePermissionKeys(selectedRole).length} صلاحية متاحة`}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {permissionsLoading || rolePermissionsLoading ? (
                  <div className="space-y-4">
                    {[...Array(4)].map((_, i) => (
                      <Skeleton key={i} className="h-24 w-full" />
                    ))}
                  </div>
                ) : (
                  <div className="space-y-6">
                    {Object.entries(permissionsByCategory || {}).map(([category, perms]) => {
                      const rolePerms = getRolePermissionKeys(selectedRole);
                      const categoryPerms = perms?.map((p) => p.permission_key) || [];
                      const hasAll = categoryPerms.every((p) => rolePerms.includes(p));
                      const hasNone = categoryPerms.every((p) => !rolePerms.includes(p));

                      return (
                        <div key={category} className="space-y-2">
                          <div className="flex items-center justify-between">
                            <h4 className="font-medium flex items-center gap-2">
                              {categoryLabels[category] || category}
                              {hasAll && <Check className="h-4 w-4 text-green-500" />}
                              {hasNone && <X className="h-4 w-4 text-red-500" />}
                            </h4>
                            <span className="text-xs text-muted-foreground">
                              {categoryPerms.filter((p) => rolePerms.includes(p)).length}/{categoryPerms.length}
                            </span>
                          </div>
                          <div className="grid grid-cols-2 gap-2">
                            {perms?.map((perm) => {
                              const hasPermission = rolePerms.includes(perm.permission_key);
                              return (
                                <div
                                  key={perm.id}
                                  className={`flex items-center gap-2 p-2 rounded-lg text-sm ${
                                    hasPermission
                                      ? "bg-green-50 dark:bg-green-950 text-green-700 dark:text-green-300"
                                      : "bg-muted/50 text-muted-foreground"
                                  }`}
                                >
                                  {hasPermission ? (
                                    <Check className="h-4 w-4 text-green-500 flex-shrink-0" />
                                  ) : (
                                    <X className="h-4 w-4 text-muted-foreground flex-shrink-0" />
                                  )}
                                  <span className="truncate">{perm.display_name_ar}</span>
                                </div>
                              );
                            })}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          {/* Roles Comparison Table */}
          <Card>
            <CardHeader>
              <CardTitle>مقارنة الأدوار</CardTitle>
              <CardDescription>عرض شامل لجميع الصلاحيات حسب الدور</CardDescription>
            </CardHeader>
            <CardContent className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="sticky right-0 bg-background">الصلاحية</TableHead>
                    {allRoles.map((role) => (
                      <TableHead key={role} className="text-center min-w-24">
                        <Badge variant={getRoleBadgeVariant(role)} className="text-[10px]">
                          {roleLabels[role]}
                        </Badge>
                      </TableHead>
                    ))}
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {Object.entries(permissionsByCategory || {}).map(([category, perms]) => (
                    <>
                      <TableRow key={`cat-${category}`} className="bg-muted/30">
                        <TableCell colSpan={7} className="font-medium text-sm">
                          {categoryLabels[category] || category}
                        </TableCell>
                      </TableRow>
                      {perms?.map((perm) => (
                        <TableRow key={perm.id}>
                          <TableCell className="sticky right-0 bg-background text-sm">
                            {perm.display_name_ar}
                          </TableCell>
                          {allRoles.map((role) => {
                            const hasIt = getRolePermissionKeys(role).includes(perm.permission_key);
                            return (
                              <TableCell key={role} className="text-center">
                                {hasIt ? (
                                  <Check className="h-4 w-4 text-green-500 mx-auto" />
                                ) : (
                                  <X className="h-4 w-4 text-muted-foreground/30 mx-auto" />
                                )}
                              </TableCell>
                            );
                          })}
                        </TableRow>
                      ))}
                    </>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Demote Confirmation Dialog */}
      <Dialog open={demoteDialog?.open} onOpenChange={(open) => !open && setDemoteDialog(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-destructive" />
              إلغاء صلاحيات المسؤول
            </DialogTitle>
            <DialogDescription>
              هل أنت متأكد من إلغاء صلاحيات المسؤول لـ <strong>{demoteDialog?.email}</strong>؟
              <br />
              سيتم تحويله إلى مستخدم عادي ولن يتمكن من الوصول إلى لوحة التحكم.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setDemoteDialog(null)}>
              إلغاء
            </Button>
            <Button variant="destructive" onClick={handleDemote} disabled={demoteAdmin.isPending}>
              {demoteAdmin.isPending ? "جاري الإلغاء..." : "تأكيد الإلغاء"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
