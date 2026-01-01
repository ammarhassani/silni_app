"use client";

import { useState, useMemo } from "react";
import { useMOTDList, useDeleteMOTD, useUpdateMOTD } from "@/hooks/use-content";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Plus, MoreHorizontal, Pencil, Trash2, Eye, EyeOff, MessageSquare, Calendar } from "lucide-react";
import { MOTDDialog } from "./motd-dialog";
import type { AdminMOTD } from "@/types/database";
import { truncate } from "@/lib/utils";
import { format } from "date-fns";
import { ar } from "date-fns/locale";

export default function MOTDPage() {
  const [typeFilter, setTypeFilter] = useState<string>("all");
  const [activeFilter, setActiveFilter] = useState<string>("all");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedMOTD, setSelectedMOTD] = useState<AdminMOTD | null>(null);

  const filters = useMemo(() => ({
    type: typeFilter !== "all" ? typeFilter : undefined,
    active: activeFilter === "all" ? undefined : activeFilter === "active",
  }), [typeFilter, activeFilter]);

  const { data: motdList, isLoading } = useMOTDList(filters);
  const deleteMOTD = useDeleteMOTD();
  const updateMOTD = useUpdateMOTD();

  const handleEdit = (motd: AdminMOTD) => {
    setSelectedMOTD(motd);
    setDialogOpen(true);
  };

  const handleCreate = () => {
    setSelectedMOTD(null);
    setDialogOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (confirm("هل أنت متأكد من حذف هذه الرسالة؟")) {
      deleteMOTD.mutate(id);
    }
  };

  const handleToggleActive = (motd: AdminMOTD) => {
    updateMOTD.mutate({
      id: motd.id,
      is_active: !motd.is_active,
    });
  };

  const typeLabels: Record<string, { label: string; color: string }> = {
    tip: { label: "نصيحة", color: "bg-blue-500/10 text-blue-600" },
    motivation: { label: "تحفيز", color: "bg-green-500/10 text-green-600" },
    reminder: { label: "تذكير", color: "bg-yellow-500/10 text-yellow-600" },
    announcement: { label: "إعلان", color: "bg-purple-500/10 text-purple-600" },
    celebration: { label: "احتفال", color: "bg-pink-500/10 text-pink-600" },
  };

  const isWithinDateRange = (motd: AdminMOTD) => {
    const now = new Date();
    if (motd.start_date && new Date(motd.start_date) > now) return false;
    if (motd.end_date && new Date(motd.end_date) < now) return false;
    return true;
  };

  const activeCount = motdList?.filter((m) => m.is_active && isWithinDateRange(m)).length ?? 0;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">رسالة اليوم</h1>
          <p className="text-muted-foreground mt-1">
            إدارة الرسائل التحفيزية والإعلانات اليومية
            {activeCount > 0 && (
              <Badge variant="secondary" className="mr-2">
                {activeCount} نشط الآن
              </Badge>
            )}
          </p>
        </div>
        <Button onClick={handleCreate}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة رسالة
        </Button>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-4">
            <Select value={typeFilter} onValueChange={setTypeFilter}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="جميع الأنواع" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">جميع الأنواع</SelectItem>
                {Object.entries(typeLabels).map(([value, { label }]) => (
                  <SelectItem key={value} value={value}>
                    {label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={activeFilter} onValueChange={setActiveFilter}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="جميع الحالات" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">جميع الحالات</SelectItem>
                <SelectItem value="active">نشط فقط</SelectItem>
                <SelectItem value="inactive">غير نشط</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-4">
              {[...Array(5)].map((_, i) => (
                <Skeleton key={i} className="h-20 w-full" />
              ))}
            </div>
          ) : !motdList || motdList.length === 0 ? (
            <div className="text-center py-12">
              <MessageSquare className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">لا توجد رسائل</p>
              <Button variant="outline" className="mt-4" onClick={handleCreate}>
                <Plus className="h-4 w-4 ml-2" />
                إضافة أول رسالة
              </Button>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>الأيقونة</TableHead>
                  <TableHead className="w-[300px]">العنوان والرسالة</TableHead>
                  <TableHead>النوع</TableHead>
                  <TableHead>الفترة</TableHead>
                  <TableHead>الأولوية</TableHead>
                  <TableHead>الحالة</TableHead>
                  <TableHead className="w-[100px]">الإجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {motdList.map((motd) => {
                  const isInRange = isWithinDateRange(motd);
                  return (
                    <TableRow key={motd.id} className={!isInRange ? "opacity-50" : ""}>
                      <TableCell>
                        <div
                          className="w-10 h-10 rounded-lg flex items-center justify-center text-lg"
                          style={{
                            background: motd.background_gradient
                              ? `linear-gradient(135deg, ${motd.background_gradient.start}, ${motd.background_gradient.end})`
                              : "var(--muted)",
                          }}
                        >
                          {motd.icon}
                        </div>
                      </TableCell>
                      <TableCell>
                        <div>
                          <p className="font-medium">{motd.title}</p>
                          <p className="text-sm text-muted-foreground">
                            {truncate(motd.message, 60)}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge className={typeLabels[motd.type]?.color || ""}>
                          {typeLabels[motd.type]?.label || motd.type}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        {motd.start_date || motd.end_date ? (
                          <div className="flex items-center gap-1 text-sm">
                            <Calendar className="h-3 w-3" />
                            <span>
                              {motd.start_date
                                ? format(new Date(motd.start_date), "d MMM", { locale: ar })
                                : "∞"}{" "}
                              -{" "}
                              {motd.end_date
                                ? format(new Date(motd.end_date), "d MMM", { locale: ar })
                                : "∞"}
                            </span>
                          </div>
                        ) : (
                          <span className="text-muted-foreground">دائم</span>
                        )}
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">{motd.display_priority}</Badge>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Switch
                            checked={motd.is_active}
                            onCheckedChange={() => handleToggleActive(motd)}
                            disabled={updateMOTD.isPending}
                          />
                          {!isInRange && motd.is_active && (
                            <Badge variant="secondary" className="text-xs">
                              خارج الفترة
                            </Badge>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="icon">
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="start">
                            <DropdownMenuItem onClick={() => handleEdit(motd)}>
                              <Pencil className="h-4 w-4 ml-2" />
                              تعديل
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={() => handleToggleActive(motd)}>
                              {motd.is_active ? (
                                <>
                                  <EyeOff className="h-4 w-4 ml-2" />
                                  إخفاء
                                </>
                              ) : (
                                <>
                                  <Eye className="h-4 w-4 ml-2" />
                                  إظهار
                                </>
                              )}
                            </DropdownMenuItem>
                            <DropdownMenuItem
                              onClick={() => handleDelete(motd.id)}
                              className="text-destructive"
                            >
                              <Trash2 className="h-4 w-4 ml-2" />
                              حذف
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <MOTDDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        motd={selectedMOTD}
      />
    </div>
  );
}
