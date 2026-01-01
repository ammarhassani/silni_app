"use client";

import { useState } from "react";
import { useSubscriptionTiers, useUpdateSubscriptionTier } from "@/hooks/use-subscriptions";
import { useFeatures } from "@/hooks/use-subscriptions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
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
import { Pencil, Crown, Sparkles, Check, X } from "lucide-react";
import type { AdminSubscriptionTier, AdminFeature } from "@/types/database";

export default function SubscriptionTiersPage() {
  const { data: tiers, isLoading } = useSubscriptionTiers();
  const { data: features } = useFeatures();
  const updateTier = useUpdateSubscriptionTier();

  const [editingTier, setEditingTier] = useState<AdminSubscriptionTier | null>(null);
  const [formData, setFormData] = useState({
    display_name_ar: "",
    display_name_en: "",
    description_ar: "",
    description_en: "",
    reminder_limit: -1,
    features: [] as string[],
    icon_name: "",
    color_hex: "#3B82F6",
    is_default: false,
    is_active: true,
  });

  const handleOpenEdit = (tier: AdminSubscriptionTier) => {
    setEditingTier(tier);
    setFormData({
      display_name_ar: tier.display_name_ar,
      display_name_en: tier.display_name_en || "",
      description_ar: tier.description_ar || "",
      description_en: tier.description_en || "",
      reminder_limit: tier.reminder_limit,
      features: tier.features || [],
      icon_name: tier.icon_name,
      color_hex: tier.color_hex,
      is_default: tier.is_default,
      is_active: tier.is_active,
    });
  };

  const handleSave = () => {
    if (!editingTier) return;
    updateTier.mutate(
      {
        id: editingTier.id,
        display_name_ar: formData.display_name_ar,
        display_name_en: formData.display_name_en || null,
        description_ar: formData.description_ar || null,
        description_en: formData.description_en || null,
        reminder_limit: formData.reminder_limit,
        features: formData.features,
        icon_name: formData.icon_name,
        color_hex: formData.color_hex,
        is_default: formData.is_default,
        is_active: formData.is_active,
      },
      { onSuccess: () => setEditingTier(null) }
    );
  };

  const toggleFeature = (featureId: string) => {
    setFormData((f) => ({
      ...f,
      features: f.features.includes(featureId)
        ? f.features.filter((id) => id !== featureId)
        : [...f.features, featureId],
    }));
  };

  const getFeaturesByTier = (tierKey: string) => {
    return features?.filter((f) => f.minimum_tier === tierKey) || [];
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-6 md:grid-cols-2">
          <Skeleton className="h-96" />
          <Skeleton className="h-96" />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">باقات الاشتراك</h1>
        <p className="text-muted-foreground mt-1">
          إدارة باقات الاشتراك (Free & MAX)
        </p>
      </div>

      {/* Tiers Comparison */}
      <div className="grid gap-6 md:grid-cols-2">
        {tiers?.map((tier) => {
          const tierFeatures = getFeaturesByTier(tier.tier_key);
          const isMax = tier.tier_key === "max";

          return (
            <Card
              key={tier.id}
              className={`relative overflow-hidden ${
                isMax
                  ? "border-2 border-yellow-500 shadow-lg shadow-yellow-500/20"
                  : ""
              }`}
            >
              {isMax && (
                <div className="absolute top-0 left-0 right-0 bg-gradient-to-r from-yellow-500 to-orange-500 text-white text-center py-1 text-sm font-medium">
                  <Crown className="inline h-4 w-4 ml-1" />
                  الباقة المميزة
                </div>
              )}

              <CardHeader className={isMax ? "pt-10" : ""}>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-12 h-12 rounded-full flex items-center justify-center"
                      style={{ backgroundColor: `${tier.color_hex}20` }}
                    >
                      {isMax ? (
                        <Sparkles className="h-6 w-6" style={{ color: tier.color_hex }} />
                      ) : (
                        <span
                          className="text-xl font-bold"
                          style={{ color: tier.color_hex }}
                        >
                          F
                        </span>
                      )}
                    </div>
                    <div>
                      <CardTitle className="flex items-center gap-2">
                        {tier.display_name_ar}
                        {tier.is_default && (
                          <Badge variant="secondary">افتراضي</Badge>
                        )}
                      </CardTitle>
                      <CardDescription>{tier.description_ar}</CardDescription>
                    </div>
                  </div>
                  <Button variant="ghost" size="icon" onClick={() => handleOpenEdit(tier)}>
                    <Pencil className="h-4 w-4" />
                  </Button>
                </div>
              </CardHeader>

              <CardContent className="space-y-4">
                <div className="flex items-center justify-between py-3 border-b">
                  <span className="text-muted-foreground">حد التذكيرات</span>
                  <span className="font-bold text-lg">
                    {tier.reminder_limit === -1 ? "∞ غير محدود" : tier.reminder_limit}
                  </span>
                </div>

                <div>
                  <h4 className="font-medium mb-3">الميزات المتاحة ({tier.features?.length || 0})</h4>
                  <div className="space-y-2">
                    {features?.map((feature) => {
                      // Check if tier has this feature in its features array
                      const isInTierFeatures = tier.features?.includes(feature.feature_id);
                      // Fallback to minimum_tier logic if not explicitly included
                      const isIncludedByMinTier =
                        feature.minimum_tier === "free" ||
                        (tier.tier_key === "max" && feature.minimum_tier === "max");
                      // Feature is included if in tier's list OR meets minimum_tier
                      const isIncluded = isInTierFeatures || isIncludedByMinTier;
                      // Check if feature is disabled in admin
                      const isDisabled = !feature.is_active;

                      return (
                        <div
                          key={feature.id}
                          className={`flex items-center gap-2 text-sm ${
                            isDisabled
                              ? "text-red-400 line-through"
                              : !isIncluded
                              ? "text-muted-foreground line-through"
                              : ""
                          }`}
                        >
                          {isDisabled ? (
                            <X className="h-4 w-4 text-red-400" />
                          ) : isIncluded ? (
                            <Check className="h-4 w-4 text-green-500" />
                          ) : (
                            <X className="h-4 w-4 text-red-500" />
                          )}
                          {feature.display_name_ar}
                          {isDisabled && (
                            <span className="text-xs text-red-400">(معطل)</span>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>

                <div className="pt-4 border-t">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">الحالة</span>
                    <Badge variant={tier.is_active ? "default" : "secondary"}>
                      {tier.is_active ? "نشط" : "معطل"}
                    </Badge>
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Edit Dialog */}
      <Dialog open={!!editingTier} onOpenChange={() => setEditingTier(null)}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>تعديل باقة {editingTier?.display_name_ar}</DialogTitle>
            <DialogDescription>
              تعديل إعدادات الباقة والميزات المتاحة
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الاسم (عربي)</Label>
                <Input
                  value={formData.display_name_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_ar: e.target.value }))
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>الاسم (إنجليزي)</Label>
                <Input
                  value={formData.display_name_en}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, display_name_en: e.target.value }))
                  }
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
                  rows={2}
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>حد التذكيرات</Label>
                <Input
                  type="number"
                  value={formData.reminder_limit}
                  onChange={(e) =>
                    setFormData((f) => ({
                      ...f,
                      reminder_limit: parseInt(e.target.value) || 0,
                    }))
                  }
                />
                <p className="text-xs text-muted-foreground">-1 = غير محدود</p>
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
              <div className="space-y-2">
                <Label>اللون</Label>
                <div className="flex gap-2">
                  <Input
                    type="color"
                    value={formData.color_hex}
                    onChange={(e) =>
                      setFormData((f) => ({ ...f, color_hex: e.target.value }))
                    }
                    className="w-14 h-10 p-1"
                  />
                  <Input
                    value={formData.color_hex}
                    onChange={(e) =>
                      setFormData((f) => ({ ...f, color_hex: e.target.value }))
                    }
                    dir="ltr"
                    className="flex-1"
                  />
                </div>
              </div>
            </div>

            <div className="space-y-3">
              <Label>الميزات المضمنة</Label>
              <div className="grid grid-cols-2 gap-2 max-h-48 overflow-y-auto p-2 border rounded-md">
                {features?.map((feature) => (
                  <div
                    key={feature.id}
                    className={`flex items-center gap-2 p-2 rounded cursor-pointer transition-colors ${
                      formData.features.includes(feature.feature_id)
                        ? "bg-primary/10"
                        : "hover:bg-muted"
                    }`}
                    onClick={() => toggleFeature(feature.feature_id)}
                  >
                    <div
                      className={`w-4 h-4 rounded border flex items-center justify-center ${
                        formData.features.includes(feature.feature_id)
                          ? "bg-primary border-primary"
                          : "border-muted-foreground"
                      }`}
                    >
                      {formData.features.includes(feature.feature_id) && (
                        <Check className="h-3 w-3 text-white" />
                      )}
                    </div>
                    <span className="text-sm">{feature.display_name_ar}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="flex items-center gap-8">
              <div className="flex items-center gap-2">
                <Switch
                  checked={formData.is_default}
                  onCheckedChange={(checked) =>
                    setFormData((f) => ({ ...f, is_default: checked }))
                  }
                />
                <Label>الباقة الافتراضية</Label>
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
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setEditingTier(null)}>
              إلغاء
            </Button>
            <Button onClick={handleSave} disabled={updateTier.isPending}>
              {updateTier.isPending ? "جاري الحفظ..." : "حفظ التغييرات"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
