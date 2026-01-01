"use client";

import { useState } from "react";
import {
  useRoutesHierarchy,
  useCreateRoute,
  useUpdateRoute,
  useDeleteRoute,
  useCreateRouteCategory,
  useUpdateRouteCategory,
  type AppRoute,
  type RouteCategory,
} from "@/hooks/use-app-routes";
import { useFeatures } from "@/hooks/use-subscriptions";
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Pencil, Plus, Trash2, FolderTree, Route, Lock, Crown, Eye, EyeOff } from "lucide-react";

export default function RoutesPage() {
  const { data, isLoading } = useRoutesHierarchy();
  const { data: features } = useFeatures();
  const createRoute = useCreateRoute();
  const updateRoute = useUpdateRoute();
  const deleteRoute = useDeleteRoute();
  const createCategory = useCreateRouteCategory();
  const updateCategory = useUpdateRouteCategory();

  const [editingRoute, setEditingRoute] = useState<AppRoute | null>(null);
  const [editingCategory, setEditingCategory] = useState<RouteCategory | null>(null);
  const [isNewRoute, setIsNewRoute] = useState(false);
  const [isNewCategory, setIsNewCategory] = useState(false);
  const [deleteRouteId, setDeleteRouteId] = useState<string | null>(null);

  const [routeForm, setRouteForm] = useState({
    path: "",
    route_key: "",
    label_ar: "",
    label_en: "",
    icon: "",
    description_ar: "",
    category_key: "",
    parent_route_key: "",
    sort_order: 0,
    is_active: true,
    is_public: true,
    requires_auth: true,
    requires_premium: false,
    feature_id: "",
  });

  const [categoryForm, setCategoryForm] = useState({
    category_key: "",
    label_ar: "",
    label_en: "",
    icon: "",
    sort_order: 0,
    is_active: true,
  });

  const handleOpenNewRoute = () => {
    setIsNewRoute(true);
    setRouteForm({
      path: "",
      route_key: "",
      label_ar: "",
      label_en: "",
      icon: "",
      description_ar: "",
      category_key: data?.categories[0]?.category_key || "",
      parent_route_key: "",
      sort_order: 0,
      is_active: true,
      is_public: true,
      requires_auth: true,
      requires_premium: false,
      feature_id: "",
    });
    setEditingRoute({} as AppRoute);
  };

  const handleOpenEditRoute = (route: AppRoute) => {
    setIsNewRoute(false);
    setEditingRoute(route);
    setRouteForm({
      path: route.path,
      route_key: route.route_key,
      label_ar: route.label_ar,
      label_en: route.label_en || "",
      icon: route.icon || "",
      description_ar: route.description_ar || "",
      category_key: route.category_key,
      parent_route_key: route.parent_route_key || "",
      sort_order: route.sort_order,
      is_active: route.is_active,
      is_public: route.is_public,
      requires_auth: route.requires_auth,
      requires_premium: route.requires_premium,
      feature_id: route.feature_id || "",
    });
  };

  const handleSaveRoute = () => {
    if (isNewRoute) {
      createRoute.mutate(
        {
          path: routeForm.path,
          route_key: routeForm.route_key,
          label_ar: routeForm.label_ar,
          label_en: routeForm.label_en || null,
          icon: routeForm.icon || null,
          description_ar: routeForm.description_ar || null,
          category_key: routeForm.category_key,
          parent_route_key: routeForm.parent_route_key || null,
          sort_order: routeForm.sort_order,
          is_active: routeForm.is_active,
          is_public: routeForm.is_public,
          requires_auth: routeForm.requires_auth,
          requires_premium: routeForm.requires_premium,
          feature_id: routeForm.feature_id || null,
        },
        { onSuccess: () => setEditingRoute(null) }
      );
    } else if (editingRoute?.id) {
      updateRoute.mutate(
        {
          id: editingRoute.id,
          path: routeForm.path,
          route_key: routeForm.route_key,
          label_ar: routeForm.label_ar,
          label_en: routeForm.label_en || null,
          icon: routeForm.icon || null,
          description_ar: routeForm.description_ar || null,
          category_key: routeForm.category_key,
          parent_route_key: routeForm.parent_route_key || null,
          sort_order: routeForm.sort_order,
          is_active: routeForm.is_active,
          is_public: routeForm.is_public,
          requires_auth: routeForm.requires_auth,
          requires_premium: routeForm.requires_premium,
          feature_id: routeForm.feature_id || null,
        },
        { onSuccess: () => setEditingRoute(null) }
      );
    }
  };

  const handleOpenNewCategory = () => {
    setIsNewCategory(true);
    setCategoryForm({
      category_key: "",
      label_ar: "",
      label_en: "",
      icon: "",
      sort_order: 0,
      is_active: true,
    });
    setEditingCategory({} as RouteCategory);
  };

  const handleOpenEditCategory = (category: RouteCategory) => {
    setIsNewCategory(false);
    setEditingCategory(category);
    setCategoryForm({
      category_key: category.category_key,
      label_ar: category.label_ar,
      label_en: category.label_en || "",
      icon: category.icon || "",
      sort_order: category.sort_order,
      is_active: category.is_active,
    });
  };

  const handleSaveCategory = () => {
    if (isNewCategory) {
      createCategory.mutate(
        {
          category_key: categoryForm.category_key,
          label_ar: categoryForm.label_ar,
          label_en: categoryForm.label_en || null,
          icon: categoryForm.icon || null,
          sort_order: categoryForm.sort_order,
          is_active: categoryForm.is_active,
        },
        { onSuccess: () => setEditingCategory(null) }
      );
    } else if (editingCategory?.id) {
      updateCategory.mutate(
        {
          id: editingCategory.id,
          category_key: categoryForm.category_key,
          label_ar: categoryForm.label_ar,
          label_en: categoryForm.label_en || null,
          icon: categoryForm.icon || null,
          sort_order: categoryForm.sort_order,
          is_active: categoryForm.is_active,
        },
        { onSuccess: () => setEditingCategory(null) }
      );
    }
  };

  const handleDeleteRoute = () => {
    if (deleteRouteId) {
      deleteRoute.mutate(deleteRouteId, {
        onSuccess: () => setDeleteRouteId(null),
      });
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-4">
          <Skeleton className="h-48" />
          <Skeleton className="h-48" />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">مسارات التطبيق</h1>
          <p className="text-muted-foreground mt-1">
            إدارة مسارات التنقل في التطبيق
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={handleOpenNewCategory}>
            <Plus className="h-4 w-4 ml-2" />
            تصنيف جديد
          </Button>
          <Button onClick={handleOpenNewRoute}>
            <Plus className="h-4 w-4 ml-2" />
            مسار جديد
          </Button>
        </div>
      </div>

      <Tabs defaultValue="routes" className="w-full">
        <TabsList>
          <TabsTrigger value="routes" className="flex items-center gap-2">
            <Route className="h-4 w-4" />
            المسارات ({data?.routes.length || 0})
          </TabsTrigger>
          <TabsTrigger value="categories" className="flex items-center gap-2">
            <FolderTree className="h-4 w-4" />
            التصنيفات ({data?.categories.length || 0})
          </TabsTrigger>
        </TabsList>

        <TabsContent value="routes" className="space-y-4 mt-4">
          {Object.entries(data?.hierarchy || {}).map(([categoryKey, { category, routes }]) => (
            <Card key={categoryKey}>
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    {category.icon && <span className="text-xl">{category.icon}</span>}
                    <CardTitle className="text-lg">{category.label_ar}</CardTitle>
                    <Badge variant="secondary">{routes.length}</Badge>
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => handleOpenEditCategory(category)}
                  >
                    <Pencil className="h-4 w-4" />
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {routes.map((route) => (
                    <div
                      key={route.id}
                      className="flex items-center justify-between p-3 rounded-lg border hover:bg-muted/50 transition-colors"
                    >
                      <div className="flex items-center gap-3">
                        {route.icon && <span className="text-lg">{route.icon}</span>}
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-medium">{route.label_ar}</span>
                            {!route.is_active && (
                              <Badge variant="secondary" className="text-xs">
                                <EyeOff className="h-3 w-3 ml-1" />
                                مخفي
                              </Badge>
                            )}
                            {route.requires_auth && (
                              <Lock className="h-3 w-3 text-muted-foreground" />
                            )}
                            {route.requires_premium && (
                              <Crown className="h-3 w-3 text-yellow-500" />
                            )}
                          </div>
                          <code className="text-xs text-muted-foreground">{route.path}</code>
                        </div>
                      </div>
                      <div className="flex items-center gap-1">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleOpenEditRoute(route)}
                        >
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="text-destructive hover:text-destructive"
                          onClick={() => setDeleteRouteId(route.id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  ))}
                  {routes.length === 0 && (
                    <p className="text-center text-muted-foreground py-4">
                      لا توجد مسارات في هذا التصنيف
                    </p>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </TabsContent>

        <TabsContent value="categories" className="space-y-4 mt-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {data?.categories.map((category) => (
              <Card key={category.id}>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      {category.icon && <span className="text-2xl">{category.icon}</span>}
                      <div>
                        <CardTitle className="text-lg">{category.label_ar}</CardTitle>
                        <CardDescription>{category.category_key}</CardDescription>
                      </div>
                    </div>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleOpenEditCategory(category)}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">عدد المسارات</span>
                    <span className="font-medium">
                      {data?.hierarchy[category.category_key]?.routes.length || 0}
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-sm mt-2">
                    <span className="text-muted-foreground">الترتيب</span>
                    <span className="font-medium">{category.sort_order}</span>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>
      </Tabs>

      {/* Route Edit Dialog */}
      <Dialog open={!!editingRoute} onOpenChange={() => setEditingRoute(null)}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{isNewRoute ? "إضافة مسار جديد" : "تعديل المسار"}</DialogTitle>
            <DialogDescription>
              {isNewRoute ? "أضف مسار جديد للتطبيق" : "تعديل إعدادات المسار"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>المسار (path)</Label>
                <Input
                  value={routeForm.path}
                  onChange={(e) => setRouteForm((f) => ({ ...f, path: e.target.value }))}
                  placeholder="/home"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label>مفتاح المسار</Label>
                <Input
                  value={routeForm.route_key}
                  onChange={(e) => setRouteForm((f) => ({ ...f, route_key: e.target.value }))}
                  placeholder="home"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الاسم (عربي)</Label>
                <Input
                  value={routeForm.label_ar}
                  onChange={(e) => setRouteForm((f) => ({ ...f, label_ar: e.target.value }))}
                />
              </div>
              <div className="space-y-2">
                <Label>الاسم (إنجليزي)</Label>
                <Input
                  value={routeForm.label_en}
                  onChange={(e) => setRouteForm((f) => ({ ...f, label_en: e.target.value }))}
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>الأيقونة</Label>
                <Input
                  value={routeForm.icon}
                  onChange={(e) => setRouteForm((f) => ({ ...f, icon: e.target.value }))}
                  placeholder="home"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label>التصنيف</Label>
                <Select
                  value={routeForm.category_key}
                  onValueChange={(v) => setRouteForm((f) => ({ ...f, category_key: v }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {data?.categories.map((cat) => (
                      <SelectItem key={cat.category_key} value={cat.category_key}>
                        {cat.label_ar}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>الترتيب</Label>
                <Input
                  type="number"
                  value={routeForm.sort_order}
                  onChange={(e) =>
                    setRouteForm((f) => ({ ...f, sort_order: parseInt(e.target.value) || 0 }))
                  }
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>الوصف</Label>
              <Input
                value={routeForm.description_ar}
                onChange={(e) => setRouteForm((f) => ({ ...f, description_ar: e.target.value }))}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>المسار الأب</Label>
                <Select
                  value={routeForm.parent_route_key || "none"}
                  onValueChange={(v) =>
                    setRouteForm((f) => ({ ...f, parent_route_key: v === "none" ? "" : v }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="none">بدون</SelectItem>
                    {data?.routes
                      .filter((r) => r.route_key !== routeForm.route_key)
                      .map((route) => (
                        <SelectItem key={route.route_key} value={route.route_key}>
                          {route.label_ar}
                        </SelectItem>
                      ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>الميزة المرتبطة</Label>
                <Select
                  value={routeForm.feature_id || "none"}
                  onValueChange={(v) =>
                    setRouteForm((f) => ({ ...f, feature_id: v === "none" ? "" : v }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="none">بدون</SelectItem>
                    {features?.map((feature) => (
                      <SelectItem key={feature.feature_id} value={feature.feature_id}>
                        {feature.display_name_ar}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-6 pt-4">
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <Label>مفعل</Label>
                  <Switch
                    checked={routeForm.is_active}
                    onCheckedChange={(c) => setRouteForm((f) => ({ ...f, is_active: c }))}
                  />
                </div>
                <div className="flex items-center justify-between">
                  <Label>عام</Label>
                  <Switch
                    checked={routeForm.is_public}
                    onCheckedChange={(c) => setRouteForm((f) => ({ ...f, is_public: c }))}
                  />
                </div>
              </div>
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <Label>يتطلب تسجيل الدخول</Label>
                  <Switch
                    checked={routeForm.requires_auth}
                    onCheckedChange={(c) => setRouteForm((f) => ({ ...f, requires_auth: c }))}
                  />
                </div>
                <div className="flex items-center justify-between">
                  <Label>يتطلب اشتراك مميز</Label>
                  <Switch
                    checked={routeForm.requires_premium}
                    onCheckedChange={(c) => setRouteForm((f) => ({ ...f, requires_premium: c }))}
                  />
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setEditingRoute(null)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSaveRoute}
              disabled={createRoute.isPending || updateRoute.isPending}
            >
              {(createRoute.isPending || updateRoute.isPending) ? "جاري الحفظ..." : "حفظ"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Category Edit Dialog */}
      <Dialog open={!!editingCategory} onOpenChange={() => setEditingCategory(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {isNewCategory ? "إضافة تصنيف جديد" : "تعديل التصنيف"}
            </DialogTitle>
            <DialogDescription>
              {isNewCategory ? "أضف تصنيف جديد للمسارات" : "تعديل إعدادات التصنيف"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="space-y-2">
              <Label>مفتاح التصنيف</Label>
              <Input
                value={categoryForm.category_key}
                onChange={(e) =>
                  setCategoryForm((f) => ({ ...f, category_key: e.target.value }))
                }
                placeholder="main"
                dir="ltr"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الاسم (عربي)</Label>
                <Input
                  value={categoryForm.label_ar}
                  onChange={(e) =>
                    setCategoryForm((f) => ({ ...f, label_ar: e.target.value }))
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>الاسم (إنجليزي)</Label>
                <Input
                  value={categoryForm.label_en}
                  onChange={(e) =>
                    setCategoryForm((f) => ({ ...f, label_en: e.target.value }))
                  }
                  dir="ltr"
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الأيقونة</Label>
                <Input
                  value={categoryForm.icon}
                  onChange={(e) =>
                    setCategoryForm((f) => ({ ...f, icon: e.target.value }))
                  }
                  placeholder="home"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label>الترتيب</Label>
                <Input
                  type="number"
                  value={categoryForm.sort_order}
                  onChange={(e) =>
                    setCategoryForm((f) => ({
                      ...f,
                      sort_order: parseInt(e.target.value) || 0,
                    }))
                  }
                />
              </div>
            </div>
            <div className="flex items-center justify-between">
              <Label>مفعل</Label>
              <Switch
                checked={categoryForm.is_active}
                onCheckedChange={(c) =>
                  setCategoryForm((f) => ({ ...f, is_active: c }))
                }
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setEditingCategory(null)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSaveCategory}
              disabled={createCategory.isPending || updateCategory.isPending}
            >
              {(createCategory.isPending || updateCategory.isPending)
                ? "جاري الحفظ..."
                : "حفظ"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteRouteId} onOpenChange={() => setDeleteRouteId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>هل أنت متأكد؟</AlertDialogTitle>
            <AlertDialogDescription>
              سيتم حذف هذا المسار نهائياً. هذا الإجراء لا يمكن التراجع عنه.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>إلغاء</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDeleteRoute}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {deleteRoute.isPending ? "جاري الحذف..." : "حذف"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
