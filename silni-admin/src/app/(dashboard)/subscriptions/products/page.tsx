"use client";

import { useState } from "react";
import {
  useSubscriptionProducts,
  useCreateSubscriptionProduct,
  useUpdateSubscriptionProduct,
  useDeleteSubscriptionProduct,
  useSubscriptionTiers,
} from "@/hooks/use-subscriptions";
import {
  useRevenueCatSync,
  isProductInRevenueCat,
} from "@/hooks/use-revenuecat";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
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
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import {
  Plus,
  Pencil,
  Trash2,
  CreditCard,
  Percent,
  Star,
  CheckCircle2,
  XCircle,
  RefreshCw,
  ExternalLink,
} from "lucide-react";
import type { AdminSubscriptionProduct } from "@/types/database";
import { formatDistanceToNow } from "date-fns";
import { ar } from "date-fns/locale";

const BILLING_PERIODS = [
  { value: "monthly", label: "شهري", icon: "📅" },
  { value: "annual", label: "سنوي", icon: "📆" },
  { value: "lifetime", label: "مدى الحياة", icon: "♾️" },
];

type ProductFormData = Omit<AdminSubscriptionProduct, "id" | "created_at" | "updated_at">;

const defaultFormData: ProductFormData = {
  product_id: "",
  tier_key: "max",
  display_name_ar: "",
  display_name_en: "",
  billing_period: "monthly",
  price_usd: null,
  price_sar: null,
  savings_percentage: null,
  is_featured: false,
  is_active: true,
  sort_order: 0,
  price_source: "manual",
  price_verified_at: null,
  revenuecat_package_id: null,
  notes: null,
};

export default function SubscriptionProductsPage() {
  const { data: products, isLoading } = useSubscriptionProducts();
  const { data: tiers } = useSubscriptionTiers();
  const { data: revenueCatSync, isLoading: isRevenueCatLoading, refetch: refetchRevenueCat } = useRevenueCatSync();
  const createProduct = useCreateSubscriptionProduct();
  const updateProduct = useUpdateSubscriptionProduct();
  const deleteProduct = useDeleteSubscriptionProduct();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<AdminSubscriptionProduct | null>(null);
  const [formData, setFormData] = useState<ProductFormData>(defaultFormData);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  const handleOpenCreate = () => {
    setEditingProduct(null);
    setFormData(defaultFormData);
    setIsDialogOpen(true);
  };

  const handleOpenEdit = (product: AdminSubscriptionProduct) => {
    setEditingProduct(product);
    setFormData({
      product_id: product.product_id,
      tier_key: product.tier_key,
      display_name_ar: product.display_name_ar,
      display_name_en: product.display_name_en || "",
      billing_period: product.billing_period,
      price_usd: product.price_usd,
      price_sar: product.price_sar,
      savings_percentage: product.savings_percentage,
      is_featured: product.is_featured,
      is_active: product.is_active,
      sort_order: product.sort_order,
      price_source: product.price_source || "manual",
      price_verified_at: product.price_verified_at,
      revenuecat_package_id: product.revenuecat_package_id,
      notes: product.notes,
    });
    setIsDialogOpen(true);
  };

  const handleSave = () => {
    const data = {
      ...formData,
      display_name_en: formData.display_name_en || null,
    };

    if (editingProduct) {
      updateProduct.mutate(
        { id: editingProduct.id, ...data },
        { onSuccess: () => setIsDialogOpen(false) }
      );
    } else {
      createProduct.mutate(data, { onSuccess: () => setIsDialogOpen(false) });
    }
  };

  const handleDelete = (id: string) => {
    deleteProduct.mutate(id, { onSuccess: () => setDeleteConfirm(null) });
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-4 grid-cols-3">
          {[1, 2, 3].map((i) => (
            <Skeleton key={i} className="h-32" />
          ))}
        </div>
        <Skeleton className="h-96" />
      </div>
    );
  }

  const annualProduct = products?.find((p) => p.billing_period === "annual");
  const activeProducts = products?.filter((p) => p.is_active).length || 0;

  return (
    <TooltipProvider>
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">منتجات الاشتراك</h1>
          <p className="text-muted-foreground mt-1">
            إدارة منتجات RevenueCat (Product IDs)
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => refetchRevenueCat()} disabled={isRevenueCatLoading}>
            <RefreshCw className={`h-4 w-4 ml-2 ${isRevenueCatLoading ? 'animate-spin' : ''}`} />
            مزامنة RevenueCat
          </Button>
          <Button onClick={handleOpenCreate}>
            <Plus className="h-4 w-4 ml-2" />
            إضافة منتج
          </Button>
        </div>
      </div>

      {/* RevenueCat Connection Status */}
      <Card className={revenueCatSync?.connected ? "border-green-200 bg-green-50/50" : "border-yellow-200 bg-yellow-50/50"}>
        <CardContent className="pt-4 pb-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              {revenueCatSync?.connected ? (
                <CheckCircle2 className="h-5 w-5 text-green-600" />
              ) : (
                <XCircle className="h-5 w-5 text-yellow-600" />
              )}
              <div>
                <p className="font-medium">
                  {revenueCatSync?.connected ? "متصل بـ RevenueCat" : "غير متصل بـ RevenueCat"}
                </p>
                <p className="text-sm text-muted-foreground">
                  {revenueCatSync?.connected
                    ? `${revenueCatSync.offerings.length} offerings، ${revenueCatSync.products.length} products`
                    : revenueCatSync?.error || "أضف REVENUECAT_PROJECT_ID و REVENUECAT_API_KEY_V2 في .env.local"}
                </p>
              </div>
            </div>
            {revenueCatSync?.lastSyncAt && (
              <p className="text-xs text-muted-foreground">
                آخر مزامنة: {formatDistanceToNow(new Date(revenueCatSync.lastSyncAt), { locale: ar, addSuffix: true })}
              </p>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Price Info Banner */}
      <Alert variant="default" className="border-blue-200 bg-blue-50/50">
        <ExternalLink className="h-4 w-4 text-blue-600" />
        <AlertTitle className="text-blue-800">الأسعار تُدار من App Store Connect</AlertTitle>
        <AlertDescription className="text-blue-700">
          <p className="mb-2">
            الأسعار تأتي تلقائياً من App Store / Google Play عبر RevenueCat SDK في التطبيق.
            لتغيير الأسعار، عدّلها مباشرة في App Store Connect.
          </p>
          <div className="flex gap-2 flex-wrap">
            <Button variant="outline" size="sm" className="h-7 text-xs" asChild>
              <a href="https://appstoreconnect.apple.com" target="_blank" rel="noopener noreferrer">
                <ExternalLink className="h-3 w-3 ml-1" />
                App Store Connect
              </a>
            </Button>
            <Button variant="outline" size="sm" className="h-7 text-xs" asChild>
              <a href="https://app.revenuecat.com" target="_blank" rel="noopener noreferrer">
                <ExternalLink className="h-3 w-3 ml-1" />
                RevenueCat Dashboard
              </a>
            </Button>
          </div>
        </AlertDescription>
      </Alert>

      {/* Stats Cards */}
      <div className="grid grid-cols-4 gap-4">
        <Card className="bg-gradient-to-br from-blue-500/10 to-cyan-500/10 border-blue-200">
          <CardContent className="pt-6 text-center">
            <CreditCard className="h-8 w-8 mx-auto text-blue-500 mb-2" />
            <p className="text-2xl font-bold">{products?.length || 0}</p>
            <p className="text-sm text-muted-foreground">إجمالي المنتجات</p>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-green-500/10 to-emerald-500/10 border-green-200">
          <CardContent className="pt-6 text-center">
            <CheckCircle2 className="h-8 w-8 mx-auto text-green-500 mb-2" />
            <p className="text-2xl font-bold">{activeProducts}</p>
            <p className="text-sm text-muted-foreground">منتجات نشطة</p>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-purple-500/10 to-pink-500/10 border-purple-200">
          <CardContent className="pt-6 text-center">
            <Percent className="h-8 w-8 mx-auto text-purple-500 mb-2" />
            <p className="text-2xl font-bold">
              {annualProduct?.savings_percentage || 0}%
            </p>
            <p className="text-sm text-muted-foreground">توفير السنوي</p>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-yellow-500/10 to-orange-500/10 border-yellow-200">
          <CardContent className="pt-6 text-center">
            <Star className="h-8 w-8 mx-auto text-yellow-500 mb-2" />
            <p className="text-2xl font-bold">
              {products?.filter((p) => p.is_featured).length || 0}
            </p>
            <p className="text-sm text-muted-foreground">منتجات مميزة</p>
          </CardContent>
        </Card>
      </div>


      {/* Products Table */}
      <Card>
        <CardHeader>
          <CardTitle>قائمة المنتجات</CardTitle>
          <CardDescription>
            معرّفات المنتجات المتصلة بـ RevenueCat
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[30px]">RC</TableHead>
                <TableHead>Product ID</TableHead>
                <TableHead>الاسم</TableHead>
                <TableHead>الباقة</TableHead>
                <TableHead>الفترة</TableHead>
                <TableHead className="text-center">التوفير</TableHead>
                <TableHead className="text-center">الحالة</TableHead>
                <TableHead className="w-[100px]">إجراءات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {products?.map((product) => {
                const isInRevenueCat = isProductInRevenueCat(revenueCatSync, product.product_id);

                return (
                  <TableRow key={product.id}>
                    <TableCell>
                      <Tooltip>
                        <TooltipTrigger>
                          {isInRevenueCat ? (
                            <CheckCircle2 className="h-4 w-4 text-green-500" />
                          ) : (
                            <XCircle className="h-4 w-4 text-red-500" />
                          )}
                        </TooltipTrigger>
                        <TooltipContent>
                          {isInRevenueCat
                            ? "موجود في RevenueCat"
                            : "غير موجود في RevenueCat - تحقق من Product ID"}
                        </TooltipContent>
                      </Tooltip>
                    </TableCell>
                    <TableCell className="font-mono text-sm" dir="ltr">
                      {product.product_id}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        {product.display_name_ar}
                        {product.is_featured && (
                          <Star className="h-4 w-4 text-yellow-500 fill-yellow-500" />
                        )}
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline">
                        {tiers?.find((t) => t.tier_key === product.tier_key)?.display_name_ar}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      {BILLING_PERIODS.find((b) => b.value === product.billing_period)?.icon}{" "}
                      {BILLING_PERIODS.find((b) => b.value === product.billing_period)?.label}
                    </TableCell>
                    <TableCell className="text-center">
                      {product.savings_percentage ? (
                        <Badge variant="secondary">{product.savings_percentage}%</Badge>
                      ) : (
                        <span className="text-muted-foreground">-</span>
                      )}
                    </TableCell>
                    <TableCell className="text-center">
                      <Badge variant={product.is_active ? "default" : "secondary"}>
                        {product.is_active ? "نشط" : "معطل"}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-1">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleOpenEdit(product)}
                        >
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => setDeleteConfirm(product.id)}
                        >
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Create/Edit Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>
              {editingProduct ? "تعديل المنتج" : "إضافة منتج جديد"}
            </DialogTitle>
            <DialogDescription>
              {editingProduct
                ? "تعديل بيانات منتج RevenueCat"
                : "إضافة منتج جديد متصل بـ RevenueCat"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="space-y-2">
              <Label>Product ID (RevenueCat)</Label>
              <Input
                value={formData.product_id}
                onChange={(e) =>
                  setFormData((f) => ({ ...f, product_id: e.target.value }))
                }
                placeholder="silni_max_monthly"
                dir="ltr"
              />
              <p className="text-xs text-muted-foreground">
                يجب أن يتطابق مع معرّف المنتج في RevenueCat
              </p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الاسم (عربي)</Label>
                <Input
                  value={formData.display_name_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_ar: e.target.value }))
                  }
                  placeholder="اشتراك شهري"
                />
              </div>
              <div className="space-y-2">
                <Label>الاسم (إنجليزي)</Label>
                <Input
                  value={formData.display_name_en || ""}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_en: e.target.value }))
                  }
                  placeholder="Monthly Subscription"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الباقة</Label>
                <Select
                  value={formData.tier_key}
                  onValueChange={(v) => setFormData((f) => ({ ...f, tier_key: v }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {tiers?.map((tier) => (
                      <SelectItem key={tier.tier_key} value={tier.tier_key}>
                        {tier.display_name_ar}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>فترة الفوترة</Label>
                <Select
                  value={formData.billing_period}
                  onValueChange={(v) =>
                    setFormData((f) => ({
                      ...f,
                      billing_period: v as AdminSubscriptionProduct["billing_period"],
                    }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {BILLING_PERIODS.map((period) => (
                      <SelectItem key={period.value} value={period.value}>
                        {period.icon} {period.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <Label>نسبة التوفير % (للاشتراك السنوي)</Label>
              <Input
                type="number"
                value={formData.savings_percentage || ""}
                onChange={(e) =>
                  setFormData((f) => ({
                    ...f,
                    savings_percentage: e.target.value
                      ? parseInt(e.target.value)
                      : null,
                  }))
                }
                placeholder="40"
              />
              <p className="text-xs text-muted-foreground">
                يُستخدم لعرض نسبة التوفير مقارنة بالاشتراك الشهري
              </p>
            </div>

            <div className="flex items-center gap-8">
              <div className="flex items-center gap-2">
                <Switch
                  checked={formData.is_featured}
                  onCheckedChange={(checked) =>
                    setFormData((f) => ({ ...f, is_featured: checked }))
                  }
                />
                <Label>منتج مميز (الأكثر توفيراً)</Label>
              </div>
              <div className="flex items-center gap-2">
                <Switch
                  checked={formData.is_active}
                  onCheckedChange={(checked) =>
                    setFormData((f) => ({ ...f, is_active: checked }))
                  }
                />
                <Label>نشط</Label>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSave}
              disabled={createProduct.isPending || updateProduct.isPending}
            >
              {createProduct.isPending || updateProduct.isPending
                ? "جاري الحفظ..."
                : editingProduct
                ? "تحديث"
                : "إضافة"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={!!deleteConfirm} onOpenChange={() => setDeleteConfirm(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>تأكيد الحذف</DialogTitle>
            <DialogDescription>
              هل أنت متأكد من حذف هذا المنتج؟ لا يمكن التراجع عن هذا الإجراء.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteConfirm(null)}>
              إلغاء
            </Button>
            <Button
              variant="destructive"
              onClick={() => deleteConfirm && handleDelete(deleteConfirm)}
              disabled={deleteProduct.isPending}
            >
              {deleteProduct.isPending ? "جاري الحذف..." : "حذف"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
    </TooltipProvider>
  );
}
