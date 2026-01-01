"use client";

import { useState, useMemo } from "react";
import { useLevels, useUpdateLevel } from "@/hooks/use-gamification";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { Alert, AlertDescription } from "@/components/ui/alert";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Pencil, TrendingUp, Star, Zap, Target, Calculator, Info } from "lucide-react";
import type { AdminLevel } from "@/types/database";

export default function LevelsPage() {
  const { data: levels, isLoading } = useLevels();
  const updateLevel = useUpdateLevel();

  const [editingLevel, setEditingLevel] = useState<AdminLevel | null>(null);
  const [formData, setFormData] = useState({
    title_ar: "",
    title_en: "",
    xp_required: 0,
    icon: "",
    color_hex: "#3B82F6",
  });

  // Sort levels by level number for calculations
  const sortedLevels = useMemo(() => {
    return [...(levels || [])].sort((a, b) => a.level - b.level);
  }, [levels]);

  // Calculate xp_to_next for a given level based on next level's xp_required
  const calculateXpToNext = (levelNum: number, currentXpRequired: number) => {
    const nextLevel = sortedLevels.find(l => l.level === levelNum + 1);
    if (!nextLevel) return null; // Last level has no xp_to_next
    return nextLevel.xp_required - currentXpRequired;
  };

  // Get the calculated xp_to_next when editing (accounts for form changes)
  const getEditingXpToNext = () => {
    if (!editingLevel) return null;
    const nextLevel = sortedLevels.find(l => l.level === editingLevel.level + 1);
    if (!nextLevel) return null;
    return nextLevel.xp_required - formData.xp_required;
  };

  // Get previous level's xp_required for validation
  const getPreviousLevelXp = () => {
    if (!editingLevel) return 0;
    const prevLevel = sortedLevels.find(l => l.level === editingLevel.level - 1);
    return prevLevel?.xp_required || 0;
  };

  // Get next level's xp_required for info
  const getNextLevelXp = () => {
    if (!editingLevel) return null;
    const nextLevel = sortedLevels.find(l => l.level === editingLevel.level + 1);
    return nextLevel?.xp_required || null;
  };

  const handleOpenEdit = (level: AdminLevel) => {
    setEditingLevel(level);
    setFormData({
      title_ar: level.title_ar,
      title_en: level.title_en || "",
      xp_required: level.xp_required,
      icon: level.icon || "",
      color_hex: level.color_hex || "#3B82F6",
    });
  };

  const handleSave = () => {
    if (!editingLevel) return;

    // Calculate xp_to_next based on next level
    const xpToNext = getEditingXpToNext();

    updateLevel.mutate(
      {
        id: editingLevel.id,
        title_ar: formData.title_ar,
        title_en: formData.title_en || null,
        xp_required: formData.xp_required,
        xp_to_next: xpToNext,
        icon: formData.icon || null,
        color_hex: formData.color_hex || null,
      },
      {
        onSuccess: () => {
          // Also update the previous level's xp_to_next if there is one
          const prevLevel = sortedLevels.find(l => l.level === editingLevel.level - 1);
          if (prevLevel) {
            const prevXpToNext = formData.xp_required - prevLevel.xp_required;
            updateLevel.mutate({
              id: prevLevel.id,
              xp_to_next: prevXpToNext,
            });
          }
          setEditingLevel(null);
        }
      }
    );
  };

  // Validation: xp_required must be greater than previous level (or >= 0 for level 1)
  const isXpValid = editingLevel?.level === 1
    ? formData.xp_required >= 0
    : formData.xp_required > getPreviousLevelXp();
  const editingXpToNext = getEditingXpToNext();
  const isXpToNextValid = editingXpToNext === null || editingXpToNext > 0;

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid gap-4 grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-32" />
          ))}
        </div>
        <Skeleton className="h-96" />
      </div>
    );
  }

  const totalXP = levels?.reduce((sum, l) => sum + l.xp_required, 0) || 0;
  const maxLevel = levels?.length || 0;
  const avgXPPerLevel = maxLevel > 0 ? Math.round(totalXP / maxLevel) : 0;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">المستويات</h1>
        <p className="text-muted-foreground mt-1">
          إعداد نظام المستويات والترقيات
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-4 gap-4">
        <Card className="bg-gradient-to-br from-blue-500/10 to-cyan-500/10 border-blue-200">
          <CardContent className="pt-6 text-center">
            <TrendingUp className="h-8 w-8 mx-auto text-blue-500 mb-2" />
            <p className="text-2xl font-bold">{maxLevel}</p>
            <p className="text-sm text-muted-foreground">إجمالي المستويات</p>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-purple-500/10 to-pink-500/10 border-purple-200">
          <CardContent className="pt-6 text-center">
            <Star className="h-8 w-8 mx-auto text-purple-500 mb-2" />
            <p className="text-2xl font-bold">{totalXP.toLocaleString()}</p>
            <p className="text-sm text-muted-foreground">إجمالي XP للحد الأقصى</p>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-green-500/10 to-emerald-500/10 border-green-200">
          <CardContent className="pt-6 text-center">
            <Zap className="h-8 w-8 mx-auto text-green-500 mb-2" />
            <p className="text-2xl font-bold">{avgXPPerLevel.toLocaleString()}</p>
            <p className="text-sm text-muted-foreground">متوسط XP/مستوى</p>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-orange-500/10 to-yellow-500/10 border-orange-200">
          <CardContent className="pt-6 text-center">
            <Target className="h-8 w-8 mx-auto text-orange-500 mb-2" />
            <p className="text-2xl font-bold">
              {levels?.[levels.length - 1]?.xp_required.toLocaleString() || 0}
            </p>
            <p className="text-sm text-muted-foreground">XP للمستوى الأخير</p>
          </CardContent>
        </Card>
      </div>

      {/* XP Progression Chart */}
      <Card>
        <CardHeader>
          <CardTitle>تدرج XP المطلوب</CardTitle>
          <CardDescription>
            الفرق في XP بين كل مستوى والذي يليه
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-end gap-2 h-32">
            {levels?.map((level) => {
              const maxXP = levels[levels.length - 1]?.xp_required || 1;
              const height = Math.max(10, (level.xp_required / maxXP) * 100);
              return (
                <div
                  key={level.id}
                  className="flex-1 flex flex-col items-center gap-1"
                >
                  <div
                    className="w-full rounded-t transition-all hover:opacity-80"
                    style={{
                      height: `${height}%`,
                      backgroundColor: level.color_hex || "#3B82F6",
                    }}
                    title={`${level.xp_required.toLocaleString()} XP`}
                  />
                  <span className="text-xs font-medium">{level.level}</span>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Levels Table */}
      <Card>
        <CardHeader>
          <CardTitle>قائمة المستويات</CardTitle>
          <CardDescription>
            انقر على زر التعديل لتغيير إعدادات المستوى
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[80px] text-center">المستوى</TableHead>
                <TableHead>اللقب</TableHead>
                <TableHead className="text-center">XP المطلوب</TableHead>
                <TableHead className="text-center">XP للمستوى التالي</TableHead>
                <TableHead className="text-center">اللون</TableHead>
                <TableHead className="w-[80px]">تعديل</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {levels?.map((level) => (
                <TableRow key={level.id}>
                  <TableCell className="text-center">
                    <div
                      className="w-10 h-10 mx-auto rounded-full flex items-center justify-center text-white font-bold"
                      style={{ backgroundColor: level.color_hex || "#3B82F6" }}
                    >
                      {level.level}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div>
                      <p className="font-medium">{level.title_ar}</p>
                      {level.title_en && (
                        <p className="text-xs text-muted-foreground" dir="ltr">
                          {level.title_en}
                        </p>
                      )}
                    </div>
                  </TableCell>
                  <TableCell className="text-center font-mono">
                    {level.xp_required.toLocaleString()}
                  </TableCell>
                  <TableCell className="text-center font-mono">
                    {level.xp_to_next ? `+${level.xp_to_next.toLocaleString()}` : "-"}
                  </TableCell>
                  <TableCell className="text-center">
                    <div
                      className="w-6 h-6 mx-auto rounded border"
                      style={{ backgroundColor: level.color_hex || "#3B82F6" }}
                    />
                  </TableCell>
                  <TableCell>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleOpenEdit(level)}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Edit Dialog */}
      <Dialog open={!!editingLevel} onOpenChange={() => setEditingLevel(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              تعديل المستوى {editingLevel?.level}
            </DialogTitle>
            <DialogDescription>
              تعديل بيانات المستوى ومتطلبات XP
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>اللقب (عربي)</Label>
                <Input
                  value={formData.title_ar}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, title_ar: e.target.value }))
                  }
                  placeholder="مبتدئ"
                />
              </div>
              <div className="space-y-2">
                <Label>اللقب (إنجليزي)</Label>
                <Input
                  value={formData.title_en}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, title_en: e.target.value }))
                  }
                  placeholder="Beginner"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="space-y-4">
              <div className="space-y-2">
                <Label>XP المطلوب للوصول</Label>
                <Input
                  type="number"
                  value={formData.xp_required}
                  onChange={(e) =>
                    setFormData((f) => ({
                      ...f,
                      xp_required: parseInt(e.target.value) || 0,
                    }))
                  }
                  className={!isXpValid ? "border-red-500" : ""}
                />
                <p className="text-xs text-muted-foreground">
                  إجمالي XP المطلوب للوصول لهذا المستوى
                </p>
                {!isXpValid && editingLevel?.level !== 1 && (
                  <p className="text-xs text-red-500">
                    يجب أن يكون أكبر من المستوى السابق ({getPreviousLevelXp().toLocaleString()} XP)
                  </p>
                )}
                {!isXpValid && editingLevel?.level === 1 && (
                  <p className="text-xs text-red-500">
                    يجب أن يكون 0 أو أكثر
                  </p>
                )}
              </div>

              {/* Auto-calculated XP info */}
              <Alert className="bg-muted/50">
                <Calculator className="h-4 w-4" />
                <AlertDescription className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm">XP للمستوى التالي (محسوب تلقائياً)</span>
                    <Badge variant={editingXpToNext !== null && editingXpToNext > 0 ? "default" : "secondary"}>
                      {editingXpToNext !== null ? `+${editingXpToNext.toLocaleString()}` : "آخر مستوى"}
                    </Badge>
                  </div>
                  {editingXpToNext !== null && !isXpToNextValid && (
                    <p className="text-xs text-red-500">
                      تحذير: القيمة سالبة! المستوى التالي يتطلب {getNextLevelXp()?.toLocaleString()} XP
                    </p>
                  )}
                  <p className="text-xs text-muted-foreground">
                    <Info className="inline h-3 w-3 ml-1" />
                    يُحسب تلقائياً من الفرق بين هذا المستوى والمستوى التالي
                  </p>
                </AlertDescription>
              </Alert>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الأيقونة</Label>
                <Input
                  value={formData.icon}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, icon: e.target.value }))
                  }
                  placeholder="star"
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
                    placeholder="#3B82F6"
                    dir="ltr"
                    className="flex-1"
                  />
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setEditingLevel(null)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSave}
              disabled={updateLevel.isPending || !isXpValid || !isXpToNextValid}
            >
              {updateLevel.isPending ? "جاري الحفظ..." : "حفظ التغييرات"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
