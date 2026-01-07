"use client";

import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Slider } from "@/components/ui/slider";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Checkbox } from "@/components/ui/checkbox";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Flag,
  Plus,
  Pencil,
  Users,
  Smartphone,
  BarChart3,
  Zap,
  Palette,
  FlaskConical,
  Gauge,
  Search,
} from "lucide-react";
import {
  useFeatureFlags,
  useUpdateFeatureFlag,
  useToggleFeatureFlag,
  useUpdateRollout,
  categoryLabels,
  categoryColors,
  tierLabels,
  platformLabels,
  formatFlagValue,
  FeatureFlag,
} from "@/hooks/use-feature-flags";

const categoryIcons: Record<string, React.ReactNode> = {
  feature: <Zap className="h-4 w-4" />,
  ui: <Palette className="h-4 w-4" />,
  experiment: <FlaskConical className="h-4 w-4" />,
  performance: <Gauge className="h-4 w-4" />,
};

export default function FeatureFlagsPage() {
  const { data: flags, isLoading } = useFeatureFlags();
  const updateFlag = useUpdateFeatureFlag();
  const toggleFlag = useToggleFeatureFlag();
  const updateRollout = useUpdateRollout();

  const [search, setSearch] = useState("");
  const [selectedCategory, setSelectedCategory] = useState<string>("all");
  const [editingFlag, setEditingFlag] = useState<FeatureFlag | null>(null);
  const [localRollouts, setLocalRollouts] = useState<Record<string, number>>({});

  const categories = ["all", "feature", "ui", "experiment", "performance"];

  const filteredFlags = flags?.filter((flag) => {
    const matchesSearch =
      search === "" ||
      flag.name.toLowerCase().includes(search.toLowerCase()) ||
      flag.name_ar.includes(search) ||
      flag.flag_key.toLowerCase().includes(search.toLowerCase());

    const matchesCategory =
      selectedCategory === "all" || flag.category === selectedCategory;

    return matchesSearch && matchesCategory;
  });

  const groupedFlags = filteredFlags?.reduce(
    (acc, flag) => {
      if (!acc[flag.category]) {
        acc[flag.category] = [];
      }
      acc[flag.category].push(flag);
      return acc;
    },
    {} as Record<string, FeatureFlag[]>
  );

  const getRollout = (flag: FeatureFlag) => {
    return localRollouts[flag.id] ?? flag.rollout_percentage;
  };

  const handleRolloutChange = (flagId: string, value: number[]) => {
    setLocalRollouts((prev) => ({ ...prev, [flagId]: value[0] }));
  };

  const saveRollout = async (flag: FeatureFlag) => {
    const newValue = localRollouts[flag.id];
    if (newValue !== undefined && newValue !== flag.rollout_percentage) {
      await updateRollout.mutateAsync({
        id: flag.id,
        rollout_percentage: newValue,
      });
      setLocalRollouts((prev) => {
        const next = { ...prev };
        delete next[flag.id];
        return next;
      });
    }
  };

  const handleTierToggle = async (flag: FeatureFlag, tier: string) => {
    const newTiers = flag.target_tiers.includes(tier)
      ? flag.target_tiers.filter((t) => t !== tier)
      : [...flag.target_tiers, tier];

    await updateFlag.mutateAsync({
      id: flag.id,
      target_tiers: newTiers,
    });
  };

  const handlePlatformToggle = async (flag: FeatureFlag, platform: string) => {
    const newPlatforms = flag.target_platforms.includes(platform)
      ? flag.target_platforms.filter((p) => p !== platform)
      : [...flag.target_platforms, platform];

    await updateFlag.mutateAsync({
      id: flag.id,
      target_platforms: newPlatforms,
    });
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
            <Flag className="h-7 w-7 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">أعلام الميزات</h1>
            <p className="text-muted-foreground mt-1">
              تحكم في إطلاق الميزات وتجارب A/B
            </p>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="بحث عن علم..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pr-10"
          />
        </div>
        <Tabs
          value={selectedCategory}
          onValueChange={setSelectedCategory}
          className="flex-1"
        >
          <TabsList>
            <TabsTrigger value="all">الكل</TabsTrigger>
            <TabsTrigger value="feature" className="gap-1">
              <Zap className="h-3 w-3" />
              ميزات
            </TabsTrigger>
            <TabsTrigger value="ui" className="gap-1">
              <Palette className="h-3 w-3" />
              واجهة
            </TabsTrigger>
            <TabsTrigger value="experiment" className="gap-1">
              <FlaskConical className="h-3 w-3" />
              تجارب
            </TabsTrigger>
            <TabsTrigger value="performance" className="gap-1">
              <Gauge className="h-3 w-3" />
              أداء
            </TabsTrigger>
          </TabsList>
        </Tabs>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        {categories.slice(1).map((cat) => {
          const count = flags?.filter((f) => f.category === cat).length || 0;
          const activeCount =
            flags?.filter((f) => f.category === cat && f.is_active).length || 0;

          return (
            <Card key={cat}>
              <CardContent className="pt-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-muted-foreground">
                      {categoryLabels[cat]}
                    </p>
                    <p className="text-2xl font-bold">
                      {activeCount}
                      <span className="text-sm text-muted-foreground font-normal">
                        /{count}
                      </span>
                    </p>
                  </div>
                  <div
                    className={`w-10 h-10 rounded-lg ${categoryColors[cat]} bg-opacity-20 flex items-center justify-center`}
                  >
                    {categoryIcons[cat]}
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Flags List */}
      <div className="space-y-4">
        {isLoading ? (
          [...Array(5)].map((_, i) => (
            <Card key={i}>
              <CardContent className="pt-6">
                <div className="flex items-center gap-4">
                  <Skeleton className="w-12 h-12 rounded-lg" />
                  <div className="flex-1">
                    <Skeleton className="h-5 w-40 mb-2" />
                    <Skeleton className="h-4 w-64" />
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        ) : filteredFlags?.length === 0 ? (
          <Card>
            <CardContent className="py-12 text-center">
              <Flag className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
              <p className="text-muted-foreground">لا توجد أعلام مطابقة</p>
            </CardContent>
          </Card>
        ) : (
          Object.entries(groupedFlags || {}).map(([category, categoryFlags]) => (
            <div key={category} className="space-y-3">
              <h2 className="flex items-center gap-2 text-lg font-semibold">
                <span
                  className={`w-2 h-2 rounded-full ${categoryColors[category]}`}
                />
                {categoryLabels[category]}
                <Badge variant="secondary">{categoryFlags.length}</Badge>
              </h2>

              {categoryFlags.map((flag) => {
                const hasRolloutChanges =
                  localRollouts[flag.id] !== undefined &&
                  localRollouts[flag.id] !== flag.rollout_percentage;

                return (
                  <Card
                    key={flag.id}
                    className={!flag.is_active ? "opacity-60" : ""}
                  >
                    <CardContent className="pt-6">
                      <div className="flex items-start gap-4">
                        {/* Toggle */}
                        <div className="pt-1">
                          <Switch
                            checked={flag.is_active}
                            onCheckedChange={(checked) =>
                              toggleFlag.mutate({
                                id: flag.id,
                                is_active: checked,
                              })
                            }
                          />
                        </div>

                        {/* Content */}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <h3 className="font-semibold">{flag.name_ar}</h3>
                            <code className="text-xs bg-muted px-1.5 py-0.5 rounded">
                              {flag.flag_key}
                            </code>
                            <Badge
                              variant="outline"
                              className={`${categoryColors[flag.category]} bg-opacity-10`}
                            >
                              {categoryLabels[flag.category]}
                            </Badge>
                          </div>
                          <p className="text-sm text-muted-foreground mb-3">
                            {flag.description_ar || flag.description || "بدون وصف"}
                          </p>

                          {/* Rollout */}
                          <div className="space-y-2 mb-4">
                            <div className="flex items-center justify-between">
                              <Label className="text-sm flex items-center gap-1">
                                <Users className="h-3 w-3" />
                                نسبة الإطلاق
                              </Label>
                              <span className="text-sm font-mono">
                                {getRollout(flag)}%
                              </span>
                            </div>
                            <div className="flex items-center gap-2">
                              <Slider
                                value={[getRollout(flag)]}
                                onValueChange={(v) =>
                                  handleRolloutChange(flag.id, v)
                                }
                                max={100}
                                step={5}
                                className="flex-1"
                                disabled={!flag.is_active}
                              />
                              {hasRolloutChanges && (
                                <Button
                                  size="sm"
                                  onClick={() => saveRollout(flag)}
                                  disabled={updateRollout.isPending}
                                >
                                  حفظ
                                </Button>
                              )}
                            </div>
                          </div>

                          {/* Targeting */}
                          <div className="grid grid-cols-2 gap-4">
                            {/* Tiers */}
                            <div className="space-y-2">
                              <Label className="text-sm flex items-center gap-1">
                                <BarChart3 className="h-3 w-3" />
                                الاشتراكات المستهدفة
                              </Label>
                              <div className="flex flex-wrap gap-2">
                                {Object.entries(tierLabels).map(([tier, label]) => (
                                  <Badge
                                    key={tier}
                                    variant={
                                      flag.target_tiers.includes(tier)
                                        ? "default"
                                        : "outline"
                                    }
                                    className="cursor-pointer"
                                    onClick={() => handleTierToggle(flag, tier)}
                                  >
                                    {label}
                                  </Badge>
                                ))}
                              </div>
                            </div>

                            {/* Platforms */}
                            <div className="space-y-2">
                              <Label className="text-sm flex items-center gap-1">
                                <Smartphone className="h-3 w-3" />
                                المنصات المستهدفة
                              </Label>
                              <div className="flex flex-wrap gap-2">
                                {Object.entries(platformLabels).map(
                                  ([platform, label]) => (
                                    <Badge
                                      key={platform}
                                      variant={
                                        flag.target_platforms.includes(platform)
                                          ? "default"
                                          : "outline"
                                      }
                                      className="cursor-pointer"
                                      onClick={() =>
                                        handlePlatformToggle(flag, platform)
                                      }
                                    >
                                      {label}
                                    </Badge>
                                  )
                                )}
                              </div>
                            </div>
                          </div>

                          {/* Values */}
                          {flag.flag_type !== "boolean" && (
                            <div className="mt-4 p-3 bg-muted/50 rounded-lg">
                              <div className="grid grid-cols-2 gap-4 text-sm">
                                <div>
                                  <span className="text-muted-foreground">
                                    القيمة الافتراضية:
                                  </span>{" "}
                                  <code className="bg-muted px-1.5 py-0.5 rounded">
                                    {formatFlagValue(
                                      flag.default_value,
                                      flag.flag_type
                                    )}
                                  </code>
                                </div>
                                <div>
                                  <span className="text-muted-foreground">
                                    القيمة المفعّلة:
                                  </span>{" "}
                                  <code className="bg-muted px-1.5 py-0.5 rounded">
                                    {formatFlagValue(
                                      flag.enabled_value,
                                      flag.flag_type
                                    )}
                                  </code>
                                </div>
                              </div>
                            </div>
                          )}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          ))
        )}
      </div>

      {/* Info Card */}
      <Card className="border-indigo-500/20 bg-indigo-500/5">
        <CardContent className="pt-6">
          <div className="flex items-start gap-3">
            <Flag className="h-5 w-5 text-indigo-500 mt-0.5" />
            <div>
              <p className="font-medium">كيف تعمل أعلام الميزات؟</p>
              <ul className="text-sm text-muted-foreground mt-2 space-y-1">
                <li>
                  • <strong>نسبة الإطلاق:</strong> تحدد نسبة المستخدمين الذين
                  سيرون الميزة (مبنية على معرّف المستخدم)
                </li>
                <li>
                  • <strong>الاشتراكات:</strong> تحدد أي مستوى اشتراك يمكنه رؤية
                  الميزة
                </li>
                <li>
                  • <strong>المنصات:</strong> تحدد على أي منصة تظهر الميزة
                </li>
                <li>
                  • يحتاج المستخدم لإعادة فتح التطبيق لتطبيق التغييرات
                </li>
              </ul>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
