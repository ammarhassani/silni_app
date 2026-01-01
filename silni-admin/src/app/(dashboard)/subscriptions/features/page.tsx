"use client";

import { useState } from "react";
import {
  useFeatures,
  useCreateFeature,
  useUpdateFeature,
  useDeleteFeature,
  useSubscriptionTiers,
} from "@/hooks/use-subscriptions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
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
import { Plus, Pencil, Trash2, Sparkles, BarChart3, Users, Palette, Wrench, Lock } from "lucide-react";
import type { AdminFeature } from "@/types/database";

const CATEGORIES = [
  { value: "ai", label: "الذكاء الاصطناعي", icon: Sparkles, color: "bg-purple-500" },
  { value: "analytics", label: "التحليلات", icon: BarChart3, color: "bg-blue-500" },
  { value: "social", label: "اجتماعي", icon: Users, color: "bg-green-500" },
  { value: "customization", label: "التخصيص", icon: Palette, color: "bg-orange-500" },
  { value: "utility", label: "أدوات", icon: Wrench, color: "bg-gray-500" },
];

type FeatureFormData = Omit<AdminFeature, "id" | "created_at" | "updated_at">;

const defaultFormData: FeatureFormData = {
  feature_id: "",
  display_name_ar: "",
  display_name_en: "",
  description_ar: "",
  description_en: "",
  icon_name: "sparkles",
  category: "utility",
  minimum_tier: "free",
  locked_message_ar: "",
  locked_message_en: "",
  is_active: true,
  sort_order: 0,
};

export default function FeaturesPage() {
  const { data: features, isLoading } = useFeatures();
  const { data: tiers } = useSubscriptionTiers();
  const createFeature = useCreateFeature();
  const updateFeature = useUpdateFeature();
  const deleteFeature = useDeleteFeature();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingFeature, setEditingFeature] = useState<AdminFeature | null>(null);
  const [formData, setFormData] = useState<FeatureFormData>(defaultFormData);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState("all");

  const handleOpenCreate = () => {
    setEditingFeature(null);
    setFormData(defaultFormData);
    setIsDialogOpen(true);
  };

  const handleOpenEdit = (feature: AdminFeature) => {
    setEditingFeature(feature);
    setFormData({
      feature_id: feature.feature_id,
      display_name_ar: feature.display_name_ar,
      display_name_en: feature.display_name_en || "",
      description_ar: feature.description_ar || "",
      description_en: feature.description_en || "",
      icon_name: feature.icon_name,
      category: feature.category,
      minimum_tier: feature.minimum_tier,
      locked_message_ar: feature.locked_message_ar || "",
      locked_message_en: feature.locked_message_en || "",
      is_active: feature.is_active,
      sort_order: feature.sort_order,
    });
    setIsDialogOpen(true);
  };

  const handleSave = () => {
    const data = {
      ...formData,
      display_name_en: formData.display_name_en || null,
      description_ar: formData.description_ar || null,
      description_en: formData.description_en || null,
      locked_message_ar: formData.locked_message_ar || null,
      locked_message_en: formData.locked_message_en || null,
    };

    if (editingFeature) {
      updateFeature.mutate(
        { id: editingFeature.id, ...data },
        { onSuccess: () => setIsDialogOpen(false) }
      );
    } else {
      createFeature.mutate(data, { onSuccess: () => setIsDialogOpen(false) });
    }
  };

  const handleDelete = (id: string) => {
    deleteFeature.mutate(id, { onSuccess: () => setDeleteConfirm(null) });
  };

  const getCategoryIcon = (category: string) => {
    const cat = CATEGORIES.find((c) => c.value === category);
    return cat ? cat.icon : Wrench;
  };

  const getCategoryColor = (category: string) => {
    const cat = CATEGORIES.find((c) => c.value === category);
    return cat?.color || "bg-gray-500";
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-4 grid-cols-5">
          {[1, 2, 3, 4, 5].map((i) => (
            <Skeleton key={i} className="h-24" />
          ))}
        </div>
        <Skeleton className="h-96" />
      </div>
    );
  }

  const groupedFeatures = features?.reduce((acc, f) => {
    if (!acc[f.category]) acc[f.category] = [];
    acc[f.category].push(f);
    return acc;
  }, {} as Record<string, AdminFeature[]>) || {};

  const freeFeatures = features?.filter((f) => f.minimum_tier === "free").length || 0;
  const maxFeatures = features?.filter((f) => f.minimum_tier === "max").length || 0;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">الميزات</h1>
          <p className="text-muted-foreground mt-1">
            إدارة الميزات وبوابات الوصول (Feature Gates)
          </p>
        </div>
        <Button onClick={handleOpenCreate}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة ميزة
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-6 gap-4">
        <Card className="col-span-2 bg-gradient-to-br from-green-500/10 to-emerald-500/10 border-green-200">
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="h-12 w-12 rounded-full bg-green-500/20 flex items-center justify-center">
                <Users className="h-6 w-6 text-green-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">{freeFeatures}</p>
                <p className="text-sm text-muted-foreground">ميزات مجانية</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card className="col-span-2 bg-gradient-to-br from-yellow-500/10 to-orange-500/10 border-yellow-200">
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="h-12 w-12 rounded-full bg-yellow-500/20 flex items-center justify-center">
                <Lock className="h-6 w-6 text-yellow-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">{maxFeatures}</p>
                <p className="text-sm text-muted-foreground">ميزات MAX فقط</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card className="col-span-2">
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="h-12 w-12 rounded-full bg-blue-500/20 flex items-center justify-center">
                <Sparkles className="h-6 w-6 text-blue-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">{features?.length || 0}</p>
                <p className="text-sm text-muted-foreground">إجمالي الميزات</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Category Stats */}
      <div className="grid grid-cols-5 gap-4">
        {CATEGORIES.map((cat) => {
          const Icon = cat.icon;
          return (
            <Card key={cat.value}>
              <CardContent className="pt-6 text-center">
                <div className={`h-10 w-10 mx-auto rounded-full ${cat.color} flex items-center justify-center mb-2`}>
                  <Icon className="h-5 w-5 text-white" />
                </div>
                <p className="text-2xl font-bold">{groupedFeatures[cat.value]?.length || 0}</p>
                <p className="text-sm text-muted-foreground">{cat.label}</p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Features List */}
      <Card>
        <CardHeader>
          <CardTitle>قائمة الميزات</CardTitle>
          <CardDescription>
            إدارة الميزات وتحديد الباقة المطلوبة لكل ميزة
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs value={activeTab} onValueChange={setActiveTab}>
            <TabsList className="mb-4">
              <TabsTrigger value="all">
                الكل ({features?.length || 0})
              </TabsTrigger>
              <TabsTrigger value="free">
                مجانية ({freeFeatures})
              </TabsTrigger>
              <TabsTrigger value="max">
                MAX ({maxFeatures})
              </TabsTrigger>
            </TabsList>

            <TabsContent value="all" className="mt-0">
              <FeatureGrid
                features={features || []}
                tiers={tiers || []}
                getCategoryIcon={getCategoryIcon}
                getCategoryColor={getCategoryColor}
                onEdit={handleOpenEdit}
                onDelete={setDeleteConfirm}
              />
            </TabsContent>

            <TabsContent value="free" className="mt-0">
              <FeatureGrid
                features={features?.filter((f) => f.minimum_tier === "free") || []}
                tiers={tiers || []}
                getCategoryIcon={getCategoryIcon}
                getCategoryColor={getCategoryColor}
                onEdit={handleOpenEdit}
                onDelete={setDeleteConfirm}
              />
            </TabsContent>

            <TabsContent value="max" className="mt-0">
              <FeatureGrid
                features={features?.filter((f) => f.minimum_tier === "max") || []}
                tiers={tiers || []}
                getCategoryIcon={getCategoryIcon}
                getCategoryColor={getCategoryColor}
                onEdit={handleOpenEdit}
                onDelete={setDeleteConfirm}
              />
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>

      {/* Create/Edit Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {editingFeature ? "تعديل الميزة" : "إضافة ميزة جديدة"}
            </DialogTitle>
            <DialogDescription>
              {editingFeature
                ? "تعديل بيانات الميزة وشروط الوصول"
                : "إضافة ميزة جديدة للتحكم في الوصول"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>معرّف الميزة (feature_id)</Label>
                <Input
                  value={formData.feature_id}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, feature_id: e.target.value }))
                  }
                  placeholder="ai_chat"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label>الأيقونة</Label>
                <Input
                  value={formData.icon_name}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, icon_name: e.target.value }))
                  }
                  placeholder="sparkles"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الاسم (عربي)</Label>
                <Input
                  value={formData.display_name_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_ar: e.target.value }))
                  }
                  placeholder="المحادثة الذكية"
                />
              </div>
              <div className="space-y-2">
                <Label>الاسم (إنجليزي)</Label>
                <Input
                  value={formData.display_name_en}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_en: e.target.value }))
                  }
                  placeholder="AI Chat"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الوصف (عربي)</Label>
                <Textarea
                  value={formData.description_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, description_ar: e.target.value }))
                  }
                  placeholder="تحدث مع واصل للحصول على نصائح..."
                  rows={2}
                />
              </div>
              <div className="space-y-2">
                <Label>الوصف (إنجليزي)</Label>
                <Textarea
                  value={formData.description_en}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, description_en: e.target.value }))
                  }
                  placeholder="Chat with Wasel for advice..."
                  rows={2}
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>الفئة</Label>
                <Select
                  value={formData.category}
                  onValueChange={(v) =>
                    setFormData((f) => ({ ...f, category: v as AdminFeature["category"] }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {CATEGORIES.map((cat) => (
                      <SelectItem key={cat.value} value={cat.value}>
                        {cat.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>الباقة المطلوبة</Label>
                <Select
                  value={formData.minimum_tier}
                  onValueChange={(v) =>
                    setFormData((f) => ({ ...f, minimum_tier: v }))
                  }
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
                <Label>الترتيب</Label>
                <Input
                  type="number"
                  value={formData.sort_order}
                  onChange={(e) =>
                    setFormData((f) => ({
                      ...f,
                      sort_order: parseInt(e.target.value) || 0,
                    }))
                  }
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>رسالة القفل (عربي)</Label>
                <Textarea
                  value={formData.locked_message_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, locked_message_ar: e.target.value }))
                  }
                  placeholder="هذه الميزة متاحة في باقة MAX"
                  rows={2}
                />
              </div>
              <div className="space-y-2">
                <Label>رسالة القفل (إنجليزي)</Label>
                <Textarea
                  value={formData.locked_message_en}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, locked_message_en: e.target.value }))
                  }
                  placeholder="This feature is available in MAX"
                  rows={2}
                  dir="ltr"
                />
              </div>
            </div>

            <div className="flex items-center gap-2">
              <Switch
                checked={formData.is_active}
                onCheckedChange={(checked) =>
                  setFormData((f) => ({ ...f, is_active: checked }))
                }
              />
              <Label>مفعل</Label>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSave}
              disabled={createFeature.isPending || updateFeature.isPending}
            >
              {createFeature.isPending || updateFeature.isPending
                ? "جاري الحفظ..."
                : editingFeature
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
              هل أنت متأكد من حذف هذه الميزة؟ لا يمكن التراجع عن هذا الإجراء.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteConfirm(null)}>
              إلغاء
            </Button>
            <Button
              variant="destructive"
              onClick={() => deleteConfirm && handleDelete(deleteConfirm)}
              disabled={deleteFeature.isPending}
            >
              {deleteFeature.isPending ? "جاري الحذف..." : "حذف"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

interface FeatureGridProps {
  features: AdminFeature[];
  tiers: { tier_key: string; display_name_ar: string; color_hex: string }[];
  getCategoryIcon: (category: string) => React.ComponentType<{ className?: string }>;
  getCategoryColor: (category: string) => string;
  onEdit: (feature: AdminFeature) => void;
  onDelete: (id: string) => void;
}

function FeatureGrid({ features, tiers, getCategoryIcon, getCategoryColor, onEdit, onDelete }: FeatureGridProps) {
  if (features.length === 0) {
    return (
      <div className="text-center py-12 text-muted-foreground">
        <Sparkles className="h-12 w-12 mx-auto mb-4 opacity-50" />
        <p>لا توجد ميزات</p>
      </div>
    );
  }

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {features.map((feature) => {
        const Icon = getCategoryIcon(feature.category);
        const tier = tiers.find((t) => t.tier_key === feature.minimum_tier);

        return (
          <Card
            key={feature.id}
            className={`cursor-pointer hover:shadow-md transition-shadow ${
              !feature.is_active ? "opacity-60" : ""
            }`}
          >
            <CardContent className="pt-4">
              <div className="flex items-start gap-3">
                <div
                  className={`w-10 h-10 rounded-lg ${getCategoryColor(feature.category)} flex items-center justify-center`}
                >
                  <Icon className="h-5 w-5 text-white" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h4 className="font-semibold truncate">{feature.display_name_ar}</h4>
                    {!feature.is_active && (
                      <Badge variant="secondary" className="text-xs">معطل</Badge>
                    )}
                  </div>
                  <p className="text-xs text-muted-foreground truncate" dir="ltr">
                    {feature.feature_id}
                  </p>
                  <div className="flex items-center gap-2 mt-2">
                    <Badge
                      variant="outline"
                      style={{
                        borderColor: tier?.color_hex,
                        color: tier?.color_hex,
                      }}
                    >
                      {tier?.display_name_ar || feature.minimum_tier}
                    </Badge>
                    <Badge variant="secondary" className="text-xs">
                      {CATEGORIES.find((c) => c.value === feature.category)?.label}
                    </Badge>
                  </div>
                </div>
                <div className="flex flex-col gap-1">
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-8 w-8"
                    onClick={(e) => {
                      e.stopPropagation();
                      onEdit(feature);
                    }}
                  >
                    <Pencil className="h-4 w-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-8 w-8"
                    onClick={(e) => {
                      e.stopPropagation();
                      onDelete(feature.id);
                    }}
                  >
                    <Trash2 className="h-4 w-4 text-destructive" />
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        );
      })}
    </div>
  );
}
