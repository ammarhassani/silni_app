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
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Pencil, Plus, Trash2, Route, Lock, Crown, ChevronDown, Settings2, Eye, EyeOff, FolderOpen } from "lucide-react";

export default function RoutesPage() {
  // Include inactive routes so toggling visibility doesn't make them disappear
  const { data, isLoading } = useRoutesHierarchy({ includeInactive: true });
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
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  // Simplified route form - essential fields only
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

  // Auto-generate route_key from path
  const handlePathChange = (path: string) => {
    const key = path.replace(/^\//, "").replace(/\//g, "_") || "";
    setRouteForm((f) => ({
      ...f,
      path,
      route_key: f.route_key || key, // Only auto-fill if empty
    }));
  };

  const handleOpenNewRoute = () => {
    setIsNewRoute(true);
    setShowAdvanced(false);
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
    setShowAdvanced(false);
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
    const payload = {
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
    };

    if (isNewRoute) {
      createRoute.mutate(payload, { onSuccess: () => setEditingRoute(null) });
    } else if (editingRoute?.id) {
      updateRoute.mutate(
        { id: editingRoute.id, ...payload },
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
    const payload = {
      category_key: categoryForm.category_key,
      label_ar: categoryForm.label_ar,
      label_en: categoryForm.label_en || null,
      icon: categoryForm.icon || null,
      sort_order: categoryForm.sort_order,
      is_active: categoryForm.is_active,
    };

    if (isNewCategory) {
      createCategory.mutate(payload, { onSuccess: () => setEditingCategory(null) });
    } else if (editingCategory?.id) {
      updateCategory.mutate(
        { id: editingCategory.id, ...payload },
        { onSuccess: () => setEditingCategory(null) }
      );
    }
  };

  const handleDeleteRoute = () => {
    if (deleteConfirm) {
      deleteRoute.mutate(deleteConfirm, {
        onSuccess: () => setDeleteConfirm(null),
      });
    }
  };

  // Quick toggle active status
  const toggleRouteActive = (route: AppRoute) => {
    updateRoute.mutate({
      id: route.id,
      is_active: !route.is_active,
    });
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
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">مسارات التطبيق</h1>
          <p className="text-muted-foreground mt-1">
            {data?.routes.length || 0} مسار في {data?.categories.length || 0} تصنيف
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={handleOpenNewCategory}>
            <FolderOpen className="h-4 w-4 ml-1" />
            تصنيف
          </Button>
          <Button size="sm" onClick={handleOpenNewRoute}>
            <Plus className="h-4 w-4 ml-1" />
            مسار
          </Button>
        </div>
      </div>

      {/* Routes by Category */}
      <div className="space-y-4">
        {Object.entries(data?.hierarchy || {}).map(([categoryKey, { category, routes }]) => (
          <Card key={categoryKey} className={!category.is_active ? "opacity-60" : ""}>
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  {category.icon && <span className="text-lg">{category.icon}</span>}
                  <CardTitle className="text-base">{category.label_ar}</CardTitle>
                  <Badge variant="outline" className="text-xs">
                    {routes.length}
                  </Badge>
                  {!category.is_active && (
                    <Badge variant="secondary" className="text-xs">مخفي</Badge>
                  )}
                </div>
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-8 w-8"
                  onClick={() => handleOpenEditCategory(category)}
                >
                  <Pencil className="h-3 w-3" />
                </Button>
              </div>
            </CardHeader>
            <CardContent className="pt-0">
              <div className="divide-y">
                {routes.map((route) => (
                  <div
                    key={route.id}
                    className={`flex items-center justify-between py-2 group ${!route.is_active ? "opacity-50" : ""}`}
                  >
                    <div
                      className="flex items-center gap-2 flex-1 cursor-pointer"
                      onClick={() => handleOpenEditRoute(route)}
                    >
                      {route.icon && <span className="text-sm">{route.icon}</span>}
                      <div className="min-w-0">
                        <div className="flex items-center gap-1.5">
                          <span className="text-sm font-medium truncate">{route.label_ar}</span>
                          {route.requires_auth && <Lock className="h-3 w-3 text-muted-foreground shrink-0" />}
                          {route.requires_premium && <Crown className="h-3 w-3 text-yellow-500 shrink-0" />}
                        </div>
                        <code className="text-xs text-muted-foreground">{route.path}</code>
                      </div>
                    </div>
                    <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-7 w-7"
                        onClick={() => toggleRouteActive(route)}
                        title={route.is_active ? "إخفاء" : "إظهار"}
                      >
                        {route.is_active ? <Eye className="h-3 w-3" /> : <EyeOff className="h-3 w-3" />}
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-7 w-7"
                        onClick={() => handleOpenEditRoute(route)}
                      >
                        <Pencil className="h-3 w-3" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-7 w-7 text-destructive hover:text-destructive"
                        onClick={() => setDeleteConfirm(route.id)}
                      >
                        <Trash2 className="h-3 w-3" />
                      </Button>
                    </div>
                  </div>
                ))}
                {routes.length === 0 && (
                  <p className="text-center text-muted-foreground text-sm py-3">
                    لا توجد مسارات
                  </p>
                )}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Route Edit Dialog - Simplified */}
      <Dialog open={!!editingRoute} onOpenChange={() => setEditingRoute(null)}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Route className="h-5 w-5" />
              {isNewRoute ? "إضافة مسار" : "تعديل المسار"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4 py-2">
            {/* Essential Fields */}
            <div className="space-y-2">
              <Label>المسار</Label>
              <Input
                value={routeForm.path}
                onChange={(e) => handlePathChange(e.target.value)}
                placeholder="/relatives"
                dir="ltr"
              />
            </div>

            <div className="space-y-2">
              <Label>الاسم</Label>
              <Input
                value={routeForm.label_ar}
                onChange={(e) => setRouteForm((f) => ({ ...f, label_ar: e.target.value }))}
                placeholder="الأقارب"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-2">
                <Label>التصنيف</Label>
                <Select
                  value={routeForm.category_key}
                  onValueChange={(v) => setRouteForm((f) => ({ ...f, category_key: v }))}
                >
                  <SelectTrigger className="h-9">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {data?.categories.map((cat) => (
                      <SelectItem key={cat.category_key} value={cat.category_key}>
                        {cat.icon} {cat.label_ar}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>الأيقونة</Label>
                <Input
                  value={routeForm.icon}
                  onChange={(e) => setRouteForm((f) => ({ ...f, icon: e.target.value }))}
                  placeholder="👥"
                  className="h-9"
                />
              </div>
            </div>

            {/* Quick Toggles */}
            <div className="flex flex-wrap gap-3 pt-2">
              <div
                className={`flex items-center gap-2 px-3 py-1.5 rounded-full border cursor-pointer transition-colors ${
                  routeForm.is_active ? "bg-green-100 border-green-300 dark:bg-green-950 dark:border-green-800" : "bg-muted"
                }`}
                onClick={() => setRouteForm((f) => ({ ...f, is_active: !f.is_active }))}
              >
                {routeForm.is_active ? <Eye className="h-3 w-3" /> : <EyeOff className="h-3 w-3" />}
                <span className="text-xs">{routeForm.is_active ? "مفعّل" : "مخفي"}</span>
              </div>
              <div
                className={`flex items-center gap-2 px-3 py-1.5 rounded-full border cursor-pointer transition-colors ${
                  routeForm.requires_auth ? "bg-blue-100 border-blue-300 dark:bg-blue-950 dark:border-blue-800" : "bg-muted"
                }`}
                onClick={() => setRouteForm((f) => ({ ...f, requires_auth: !f.requires_auth }))}
              >
                <Lock className="h-3 w-3" />
                <span className="text-xs">{routeForm.requires_auth ? "يتطلب دخول" : "عام"}</span>
              </div>
              <div
                className={`flex items-center gap-2 px-3 py-1.5 rounded-full border cursor-pointer transition-colors ${
                  routeForm.requires_premium ? "bg-yellow-100 border-yellow-300 dark:bg-yellow-950 dark:border-yellow-800" : "bg-muted"
                }`}
                onClick={() => setRouteForm((f) => ({ ...f, requires_premium: !f.requires_premium }))}
              >
                <Crown className="h-3 w-3" />
                <span className="text-xs">{routeForm.requires_premium ? "مميز" : "مجاني"}</span>
              </div>
            </div>

            {/* Advanced Options - Collapsible */}
            <Collapsible open={showAdvanced} onOpenChange={setShowAdvanced}>
              <CollapsibleTrigger className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors w-full pt-2">
                <Settings2 className="h-4 w-4" />
                <span>خيارات متقدمة</span>
                <ChevronDown className={`h-4 w-4 mr-auto transition-transform ${showAdvanced ? "rotate-180" : ""}`} />
              </CollapsibleTrigger>
              <CollapsibleContent className="space-y-3 pt-3">
                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-2">
                    <Label className="text-xs">المفتاح</Label>
                    <Input
                      value={routeForm.route_key}
                      onChange={(e) => setRouteForm((f) => ({ ...f, route_key: e.target.value }))}
                      placeholder="relatives"
                      dir="ltr"
                      className="h-8 text-xs"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label className="text-xs">الترتيب</Label>
                    <Input
                      type="number"
                      value={routeForm.sort_order}
                      onChange={(e) => setRouteForm((f) => ({ ...f, sort_order: parseInt(e.target.value) || 0 }))}
                      className="h-8 text-xs"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label className="text-xs">الاسم (إنجليزي)</Label>
                  <Input
                    value={routeForm.label_en}
                    onChange={(e) => setRouteForm((f) => ({ ...f, label_en: e.target.value }))}
                    placeholder="Relatives"
                    dir="ltr"
                    className="h-8 text-xs"
                  />
                </div>
                <div className="space-y-2">
                  <Label className="text-xs">المسار الأب</Label>
                  <Select
                    value={routeForm.parent_route_key || "none"}
                    onValueChange={(v) => setRouteForm((f) => ({ ...f, parent_route_key: v === "none" ? "" : v }))}
                  >
                    <SelectTrigger className="h-8 text-xs">
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
                {features && features.length > 0 && (
                  <div className="space-y-2">
                    <Label className="text-xs">الميزة المرتبطة</Label>
                    <Select
                      value={routeForm.feature_id || "none"}
                      onValueChange={(v) => setRouteForm((f) => ({ ...f, feature_id: v === "none" ? "" : v }))}
                    >
                      <SelectTrigger className="h-8 text-xs">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="none">بدون</SelectItem>
                        {features.map((feature) => (
                          <SelectItem key={feature.feature_id} value={feature.feature_id}>
                            {feature.display_name_ar}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                )}
              </CollapsibleContent>
            </Collapsible>
          </div>

          <DialogFooter>
            <Button variant="outline" size="sm" onClick={() => setEditingRoute(null)}>
              إلغاء
            </Button>
            <Button
              size="sm"
              onClick={handleSaveRoute}
              disabled={createRoute.isPending || updateRoute.isPending || !routeForm.path || !routeForm.label_ar}
            >
              {(createRoute.isPending || updateRoute.isPending) ? "جاري الحفظ..." : "حفظ"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Category Edit Dialog - Simplified */}
      <Dialog open={!!editingCategory} onOpenChange={() => setEditingCategory(null)}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <FolderOpen className="h-5 w-5" />
              {isNewCategory ? "إضافة تصنيف" : "تعديل التصنيف"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4 py-2">
            <div className="grid grid-cols-3 gap-3">
              <div className="space-y-2 col-span-2">
                <Label>الاسم</Label>
                <Input
                  value={categoryForm.label_ar}
                  onChange={(e) => setCategoryForm((f) => ({ ...f, label_ar: e.target.value }))}
                  placeholder="الرئيسية"
                />
              </div>
              <div className="space-y-2">
                <Label>أيقونة</Label>
                <Input
                  value={categoryForm.icon}
                  onChange={(e) => setCategoryForm((f) => ({ ...f, icon: e.target.value }))}
                  placeholder="🏠"
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-2">
                <Label className="text-xs">المفتاح</Label>
                <Input
                  value={categoryForm.category_key}
                  onChange={(e) => setCategoryForm((f) => ({ ...f, category_key: e.target.value }))}
                  placeholder="main"
                  dir="ltr"
                  className="h-8 text-xs"
                />
              </div>
              <div className="space-y-2">
                <Label className="text-xs">الترتيب</Label>
                <Input
                  type="number"
                  value={categoryForm.sort_order}
                  onChange={(e) => setCategoryForm((f) => ({ ...f, sort_order: parseInt(e.target.value) || 0 }))}
                  className="h-8 text-xs"
                />
              </div>
            </div>
            <div className="flex items-center justify-between pt-2">
              <Label>مفعّل</Label>
              <Switch
                checked={categoryForm.is_active}
                onCheckedChange={(c) => setCategoryForm((f) => ({ ...f, is_active: c }))}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" size="sm" onClick={() => setEditingCategory(null)}>
              إلغاء
            </Button>
            <Button
              size="sm"
              onClick={handleSaveCategory}
              disabled={createCategory.isPending || updateCategory.isPending || !categoryForm.label_ar}
            >
              {(createCategory.isPending || updateCategory.isPending) ? "جاري الحفظ..." : "حفظ"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={!!deleteConfirm} onOpenChange={() => setDeleteConfirm(null)}>
        <DialogContent className="max-w-xs">
          <DialogHeader>
            <DialogTitle>حذف المسار؟</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            هذا الإجراء لا يمكن التراجع عنه.
          </p>
          <DialogFooter>
            <Button variant="outline" size="sm" onClick={() => setDeleteConfirm(null)}>
              إلغاء
            </Button>
            <Button
              variant="destructive"
              size="sm"
              onClick={handleDeleteRoute}
              disabled={deleteRoute.isPending}
            >
              {deleteRoute.isPending ? "جاري الحذف..." : "حذف"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
