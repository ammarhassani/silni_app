"use client";

import { useState } from "react";
import { usePointsConfig, useUpdatePointsConfig } from "@/hooks/use-gamification";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Save, Phone, Home, MessageCircle, Gift, Calendar, MoreHorizontal } from "lucide-react";
import type { AdminPointsConfig } from "@/types/database";

const iconMap: Record<string, React.ReactNode> = {
  phone: <Phone className="h-5 w-5" />,
  home: <Home className="h-5 w-5" />,
  "message-circle": <MessageCircle className="h-5 w-5" />,
  gift: <Gift className="h-5 w-5" />,
  calendar: <Calendar className="h-5 w-5" />,
  "more-horizontal": <MoreHorizontal className="h-5 w-5" />,
};

export default function PointsConfigPage() {
  const { data: pointsConfig, isLoading } = usePointsConfig();
  const updateConfig = useUpdatePointsConfig();
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editValues, setEditValues] = useState<Partial<AdminPointsConfig>>({});

  const handleEdit = (config: AdminPointsConfig) => {
    setEditingId(config.id);
    setEditValues({
      base_points: config.base_points,
      notes_bonus: config.notes_bonus,
      photo_bonus: config.photo_bonus,
      rating_bonus: config.rating_bonus,
      daily_cap: config.daily_cap,
    });
  };

  const handleSave = () => {
    if (editingId) {
      updateConfig.mutate({ id: editingId, ...editValues });
      setEditingId(null);
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <Card>
          <CardContent className="pt-6">
            <Skeleton className="h-64 w-full" />
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">إعدادات النقاط</h1>
        <p className="text-muted-foreground mt-1">
          ضبط النقاط لكل نوع من التفاعلات
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {pointsConfig?.map((config) => (
          <Card key={config.id} className={!config.is_active ? "opacity-50" : ""}>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div
                  className="w-10 h-10 rounded-lg flex items-center justify-center"
                  style={{ backgroundColor: `${config.color_hex}20`, color: config.color_hex }}
                >
                  {iconMap[config.icon] || <MoreHorizontal className="h-5 w-5" />}
                </div>
                <div>
                  <p className="text-2xl font-bold">{config.base_points}</p>
                  <p className="text-sm text-muted-foreground">{config.display_name_ar}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Config Table */}
      <Card>
        <CardHeader>
          <CardTitle>تفاصيل النقاط</CardTitle>
          <CardDescription>
            النقاط الأساسية والمكافآت الإضافية لكل نوع تفاعل
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>النوع</TableHead>
                <TableHead className="text-center">النقاط الأساسية</TableHead>
                <TableHead className="text-center">مكافأة الملاحظات</TableHead>
                <TableHead className="text-center">مكافأة الصور</TableHead>
                <TableHead className="text-center">مكافأة التقييم</TableHead>
                <TableHead className="text-center">الحد اليومي</TableHead>
                <TableHead className="text-center">الحالة</TableHead>
                <TableHead></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {pointsConfig?.map((config) => (
                <TableRow key={config.id}>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <div
                        className="w-8 h-8 rounded-lg flex items-center justify-center"
                        style={{
                          backgroundColor: `${config.color_hex}20`,
                          color: config.color_hex,
                        }}
                      >
                        {iconMap[config.icon] || <MoreHorizontal className="h-4 w-4" />}
                      </div>
                      <div>
                        <p className="font-medium">{config.display_name_ar}</p>
                        <p className="text-xs text-muted-foreground">
                          {config.interaction_type}
                        </p>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell className="text-center">
                    {editingId === config.id ? (
                      <Input
                        type="number"
                        value={editValues.base_points}
                        onChange={(e) =>
                          setEditValues((prev) => ({
                            ...prev,
                            base_points: parseInt(e.target.value),
                          }))
                        }
                        className="w-20 mx-auto text-center"
                      />
                    ) : (
                      <span className="font-bold text-primary">{config.base_points}</span>
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    {editingId === config.id ? (
                      <Input
                        type="number"
                        value={editValues.notes_bonus}
                        onChange={(e) =>
                          setEditValues((prev) => ({
                            ...prev,
                            notes_bonus: parseInt(e.target.value),
                          }))
                        }
                        className="w-20 mx-auto text-center"
                      />
                    ) : (
                      `+${config.notes_bonus}`
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    {editingId === config.id ? (
                      <Input
                        type="number"
                        value={editValues.photo_bonus}
                        onChange={(e) =>
                          setEditValues((prev) => ({
                            ...prev,
                            photo_bonus: parseInt(e.target.value),
                          }))
                        }
                        className="w-20 mx-auto text-center"
                      />
                    ) : (
                      `+${config.photo_bonus}`
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    {editingId === config.id ? (
                      <Input
                        type="number"
                        value={editValues.rating_bonus}
                        onChange={(e) =>
                          setEditValues((prev) => ({
                            ...prev,
                            rating_bonus: parseInt(e.target.value),
                          }))
                        }
                        className="w-20 mx-auto text-center"
                      />
                    ) : (
                      `+${config.rating_bonus}`
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    {editingId === config.id ? (
                      <Input
                        type="number"
                        value={editValues.daily_cap}
                        onChange={(e) =>
                          setEditValues((prev) => ({
                            ...prev,
                            daily_cap: parseInt(e.target.value),
                          }))
                        }
                        className="w-20 mx-auto text-center"
                      />
                    ) : (
                      config.daily_cap
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    <Switch
                      checked={config.is_active}
                      onCheckedChange={(checked) =>
                        updateConfig.mutate({ id: config.id, is_active: checked })
                      }
                    />
                  </TableCell>
                  <TableCell>
                    {editingId === config.id ? (
                      <div className="flex gap-2">
                        <Button size="sm" onClick={handleSave}>
                          <Save className="h-4 w-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => setEditingId(null)}
                        >
                          إلغاء
                        </Button>
                      </div>
                    ) : (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleEdit(config)}
                      >
                        تعديل
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
