"use client";

import { useState } from "react";
import { useChallenges, useCreateChallenge, useUpdateChallenge } from "@/hooks/use-gamification";
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
import { Plus, Pencil, Calendar, Trophy, Zap, Star, Repeat } from "lucide-react";
import type { AdminChallenge } from "@/types/database";

const CHALLENGE_TYPES = [
  { value: "daily", label: "يومي", icon: Calendar, color: "bg-blue-500" },
  { value: "weekly", label: "أسبوعي", icon: Calendar, color: "bg-green-500" },
  { value: "monthly", label: "شهري", icon: Calendar, color: "bg-purple-500" },
  { value: "special", label: "خاص", icon: Star, color: "bg-yellow-500" },
  { value: "seasonal", label: "موسمي", icon: Trophy, color: "bg-orange-500" },
];

const REQUIREMENT_TYPES = [
  { value: "interaction_count", label: "عدد التفاعلات" },
  { value: "unique_relatives", label: "أقارب مختلفين" },
  { value: "specific_type", label: "نوع محدد" },
  { value: "streak", label: "سلسلة" },
  { value: "custom", label: "مخصص" },
];

type ChallengeFormData = Omit<AdminChallenge, "id" | "created_at" | "updated_at">;

const defaultFormData: ChallengeFormData = {
  challenge_key: "",
  title_ar: "",
  title_en: "",
  description_ar: "",
  description_en: "",
  type: "daily",
  requirement_type: "interaction_count",
  requirement_value: 3,
  requirement_metadata: {},
  xp_reward: 50,
  points_reward: 20,
  badge_reward: null,
  icon: "🎯",
  color_hex: "#3B82F6",
  start_date: null,
  end_date: null,
  is_active: true,
  is_recurring: true,
  sort_order: 0,
};

export default function ChallengesPage() {
  const { data: challenges, isLoading } = useChallenges();
  const createChallenge = useCreateChallenge();
  const updateChallenge = useUpdateChallenge();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingChallenge, setEditingChallenge] = useState<AdminChallenge | null>(null);
  const [formData, setFormData] = useState<ChallengeFormData>(defaultFormData);
  const [activeTab, setActiveTab] = useState("daily");

  const handleOpenCreate = () => {
    setEditingChallenge(null);
    setFormData(defaultFormData);
    setIsDialogOpen(true);
  };

  const handleOpenEdit = (challenge: AdminChallenge) => {
    setEditingChallenge(challenge);
    setFormData({
      challenge_key: challenge.challenge_key,
      title_ar: challenge.title_ar,
      title_en: challenge.title_en || "",
      description_ar: challenge.description_ar,
      description_en: challenge.description_en || "",
      type: challenge.type,
      requirement_type: challenge.requirement_type,
      requirement_value: challenge.requirement_value,
      requirement_metadata: challenge.requirement_metadata,
      xp_reward: challenge.xp_reward,
      points_reward: challenge.points_reward,
      badge_reward: challenge.badge_reward,
      icon: challenge.icon,
      color_hex: challenge.color_hex,
      start_date: challenge.start_date,
      end_date: challenge.end_date,
      is_active: challenge.is_active,
      is_recurring: challenge.is_recurring,
      sort_order: challenge.sort_order,
    });
    setIsDialogOpen(true);
  };

  const handleSave = () => {
    if (editingChallenge) {
      updateChallenge.mutate(
        { id: editingChallenge.id, ...formData },
        { onSuccess: () => setIsDialogOpen(false) }
      );
    } else {
      createChallenge.mutate(formData, { onSuccess: () => setIsDialogOpen(false) });
    }
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

  const groupedChallenges = challenges?.reduce((acc, ch) => {
    if (!acc[ch.type]) acc[ch.type] = [];
    acc[ch.type].push(ch);
    return acc;
  }, {} as Record<string, AdminChallenge[]>) || {};

  const activeChallenges = challenges?.filter((c) => c.is_active).length || 0;
  const recurringChallenges = challenges?.filter((c) => c.is_recurring).length || 0;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">التحديات</h1>
          <p className="text-muted-foreground mt-1">
            إدارة التحديات اليومية والأسبوعية والشهرية
          </p>
        </div>
        <Button onClick={handleOpenCreate}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة تحدي
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-5 gap-4">
        {CHALLENGE_TYPES.map((type) => (
          <Card key={type.value}>
            <CardContent className="pt-6 text-center">
              <div className={`h-10 w-10 mx-auto rounded-full ${type.color} flex items-center justify-center mb-2`}>
                <type.icon className="h-5 w-5 text-white" />
              </div>
              <p className="text-2xl font-bold">{groupedChallenges[type.value]?.length || 0}</p>
              <p className="text-sm text-muted-foreground">{type.label}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Summary Stats */}
      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="pt-6 flex items-center gap-4">
            <div className="h-12 w-12 rounded-full bg-green-500/10 flex items-center justify-center">
              <Zap className="h-6 w-6 text-green-500" />
            </div>
            <div>
              <p className="text-2xl font-bold">{activeChallenges}</p>
              <p className="text-sm text-muted-foreground">تحديات نشطة</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6 flex items-center gap-4">
            <div className="h-12 w-12 rounded-full bg-blue-500/10 flex items-center justify-center">
              <Repeat className="h-6 w-6 text-blue-500" />
            </div>
            <div>
              <p className="text-2xl font-bold">{recurringChallenges}</p>
              <p className="text-sm text-muted-foreground">تحديات متكررة</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6 flex items-center gap-4">
            <div className="h-12 w-12 rounded-full bg-purple-500/10 flex items-center justify-center">
              <Trophy className="h-6 w-6 text-purple-500" />
            </div>
            <div>
              <p className="text-2xl font-bold">{challenges?.length || 0}</p>
              <p className="text-sm text-muted-foreground">إجمالي التحديات</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Challenges by Type */}
      <Card>
        <CardHeader>
          <CardTitle>قائمة التحديات</CardTitle>
          <CardDescription>
            استعرض وعدّل التحديات حسب النوع
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs value={activeTab} onValueChange={setActiveTab}>
            <TabsList className="grid grid-cols-5 w-full">
              {CHALLENGE_TYPES.map((type) => (
                <TabsTrigger key={type.value} value={type.value}>
                  {type.label} ({groupedChallenges[type.value]?.length || 0})
                </TabsTrigger>
              ))}
            </TabsList>

            {CHALLENGE_TYPES.map((type) => (
              <TabsContent key={type.value} value={type.value} className="mt-4">
                {!groupedChallenges[type.value]?.length ? (
                  <div className="text-center py-12 text-muted-foreground">
                    <Trophy className="h-12 w-12 mx-auto mb-4 opacity-50" />
                    <p>لا توجد تحديات من نوع {type.label}</p>
                    <Button variant="outline" className="mt-4" onClick={handleOpenCreate}>
                      إضافة تحدي
                    </Button>
                  </div>
                ) : (
                  <div className="grid gap-4 md:grid-cols-2">
                    {groupedChallenges[type.value]?.map((challenge) => (
                      <Card
                        key={challenge.id}
                        className={`cursor-pointer hover:shadow-md transition-shadow ${
                          !challenge.is_active ? "opacity-60" : ""
                        }`}
                        onClick={() => handleOpenEdit(challenge)}
                      >
                        <CardContent className="pt-4">
                          <div className="flex items-start gap-3">
                            <div
                              className="w-12 h-12 rounded-lg flex items-center justify-center text-2xl"
                              style={{ backgroundColor: `${challenge.color_hex}20` }}
                            >
                              {challenge.icon}
                            </div>
                            <div className="flex-1">
                              <div className="flex items-center gap-2">
                                <h4 className="font-semibold">{challenge.title_ar}</h4>
                                {!challenge.is_active && (
                                  <Badge variant="secondary">معطل</Badge>
                                )}
                                {challenge.is_recurring && (
                                  <Repeat className="h-3 w-3 text-muted-foreground" />
                                )}
                              </div>
                              <p className="text-sm text-muted-foreground line-clamp-1">
                                {challenge.description_ar}
                              </p>
                              <div className="flex items-center gap-4 mt-2 text-sm">
                                <span className="flex items-center gap-1">
                                  <Zap className="h-3 w-3 text-yellow-500" />
                                  {challenge.xp_reward} XP
                                </span>
                                <span className="flex items-center gap-1">
                                  <Star className="h-3 w-3 text-blue-500" />
                                  {challenge.points_reward} نقطة
                                </span>
                                <span className="text-muted-foreground">
                                  الشرط: {challenge.requirement_value}
                                </span>
                              </div>
                            </div>
                            <Button variant="ghost" size="icon">
                              <Pencil className="h-4 w-4" />
                            </Button>
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>
                )}
              </TabsContent>
            ))}
          </Tabs>
        </CardContent>
      </Card>

      {/* Create/Edit Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {editingChallenge ? "تعديل التحدي" : "إضافة تحدي جديد"}
            </DialogTitle>
            <DialogDescription>
              {editingChallenge ? "تعديل بيانات التحدي" : "إضافة تحدي جديد للنظام"}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>المفتاح (challenge_key)</Label>
                <Input
                  value={formData.challenge_key}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, challenge_key: e.target.value }))
                  }
                  placeholder="daily_connect_3"
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label>النوع</Label>
                <Select
                  value={formData.type}
                  onValueChange={(v) =>
                    setFormData((f) => ({ ...f, type: v as AdminChallenge["type"] }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {CHALLENGE_TYPES.map((type) => (
                      <SelectItem key={type.value} value={type.value}>
                        {type.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>العنوان (عربي)</Label>
                <Input
                  value={formData.title_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, title_ar: e.target.value }))
                  }
                  placeholder="تواصل مع 3 أقارب"
                />
              </div>
              <div className="space-y-2">
                <Label>العنوان (إنجليزي)</Label>
                <Input
                  value={formData.title_en || ""}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, title_en: e.target.value }))
                  }
                  placeholder="Connect with 3 relatives"
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
                  placeholder="سجل 3 تفاعلات مع أقاربك اليوم"
                />
              </div>
              <div className="space-y-2">
                <Label>الوصف (إنجليزي)</Label>
                <Textarea
                  value={formData.description_en || ""}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, description_en: e.target.value }))
                  }
                  placeholder="Log 3 interactions with your relatives today"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>نوع الشرط</Label>
                <Select
                  value={formData.requirement_type}
                  onValueChange={(v) =>
                    setFormData((f) => ({
                      ...f,
                      requirement_type: v as AdminChallenge["requirement_type"],
                    }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {REQUIREMENT_TYPES.map((type) => (
                      <SelectItem key={type.value} value={type.value}>
                        {type.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>قيمة الشرط</Label>
                <Input
                  type="number"
                  value={formData.requirement_value}
                  onChange={(e) =>
                    setFormData((f) => ({
                      ...f,
                      requirement_value: parseInt(e.target.value) || 0,
                    }))
                  }
                />
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

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>مكافأة XP</Label>
                <Input
                  type="number"
                  value={formData.xp_reward}
                  onChange={(e) =>
                    setFormData((f) => ({
                      ...f,
                      xp_reward: parseInt(e.target.value) || 0,
                    }))
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>مكافأة النقاط</Label>
                <Input
                  type="number"
                  value={formData.points_reward}
                  onChange={(e) =>
                    setFormData((f) => ({
                      ...f,
                      points_reward: parseInt(e.target.value) || 0,
                    }))
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>وسام المكافأة (اختياري)</Label>
                <Input
                  value={formData.badge_reward || ""}
                  onChange={(e) =>
                    setFormData((f) => ({
                      ...f,
                      badge_reward: e.target.value || null,
                    }))
                  }
                  placeholder="badge_key"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الأيقونة</Label>
                <Input
                  value={formData.icon}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, icon: e.target.value }))
                  }
                  className="text-2xl text-center"
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

            {(formData.type === "special" || formData.type === "seasonal") && (
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>تاريخ البداية</Label>
                  <Input
                    type="date"
                    value={formData.start_date || ""}
                    onChange={(e) =>
                      setFormData((f) => ({
                        ...f,
                        start_date: e.target.value || null,
                      }))
                    }
                  />
                </div>
                <div className="space-y-2">
                  <Label>تاريخ النهاية</Label>
                  <Input
                    type="date"
                    value={formData.end_date || ""}
                    onChange={(e) =>
                      setFormData((f) => ({
                        ...f,
                        end_date: e.target.value || null,
                      }))
                    }
                  />
                </div>
              </div>
            )}

            <div className="flex items-center gap-8">
              <div className="flex items-center gap-2">
                <Switch
                  checked={formData.is_recurring}
                  onCheckedChange={(checked) =>
                    setFormData((f) => ({ ...f, is_recurring: checked }))
                  }
                />
                <Label>تحدي متكرر</Label>
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
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSave}
              disabled={createChallenge.isPending || updateChallenge.isPending}
            >
              {createChallenge.isPending || updateChallenge.isPending
                ? "جاري الحفظ..."
                : editingChallenge
                ? "تحديث"
                : "إضافة"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
