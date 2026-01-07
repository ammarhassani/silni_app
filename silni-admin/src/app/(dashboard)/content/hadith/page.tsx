"use client";

import { useState } from "react";
import {
  useHadith,
  useDeleteHadith,
  useToggleHadithActive,
  useBulkDeleteHadith,
  useBulkToggleHadithActive,
} from "@/hooks/use-hadith";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
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
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import {
  Plus,
  Search,
  MoreHorizontal,
  Pencil,
  Trash2,
  Eye,
  EyeOff,
  X,
  CheckCheck,
} from "lucide-react";
import { HadithDialog } from "./hadith-dialog";
import type { AdminHadith } from "@/types/database";
import { truncate } from "@/lib/utils";

export default function HadithPage() {
  const [search, setSearch] = useState("");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedHadith, setSelectedHadith] = useState<AdminHadith | null>(null);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  const { data: hadithList, isLoading } = useHadith();
  const deleteHadith = useDeleteHadith();
  const toggleActive = useToggleHadithActive();
  const bulkDelete = useBulkDeleteHadith();
  const bulkToggle = useBulkToggleHadithActive();

  const filteredHadith = hadithList?.filter(
    (h) =>
      h.hadith_text.includes(search) ||
      h.source.includes(search) ||
      h.narrator?.includes(search)
  );

  const handleEdit = (hadith: AdminHadith) => {
    setSelectedHadith(hadith);
    setDialogOpen(true);
  };

  const handleCreate = () => {
    setSelectedHadith(null);
    setDialogOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (confirm("هل أنت متأكد من حذف هذا الحديث؟")) {
      deleteHadith.mutate(id);
    }
  };

  // Selection handlers
  const toggleSelection = (id: string) => {
    const newSet = new Set(selectedIds);
    if (newSet.has(id)) {
      newSet.delete(id);
    } else {
      newSet.add(id);
    }
    setSelectedIds(newSet);
  };

  const toggleAllSelection = () => {
    if (!filteredHadith) return;
    if (selectedIds.size === filteredHadith.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(filteredHadith.map((h) => h.id)));
    }
  };

  const clearSelection = () => {
    setSelectedIds(new Set());
  };

  const handleBulkDelete = () => {
    if (confirm(`هل أنت متأكد من حذف ${selectedIds.size} حديث؟`)) {
      bulkDelete.mutate(Array.from(selectedIds), {
        onSuccess: () => clearSelection(),
      });
    }
  };

  const handleBulkActivate = (is_active: boolean) => {
    bulkToggle.mutate(
      { ids: Array.from(selectedIds), is_active },
      { onSuccess: () => clearSelection() }
    );
  };

  const gradeColors: Record<string, string> = {
    صحيح: "bg-green-500/10 text-green-600",
    حسن: "bg-blue-500/10 text-blue-600",
    ضعيف: "bg-yellow-500/10 text-yellow-600",
    موضوع: "bg-red-500/10 text-red-600",
  };

  const isAllSelected = filteredHadith && filteredHadith.length > 0 && selectedIds.size === filteredHadith.length;
  const isSomeSelected = selectedIds.size > 0;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">الأحاديث النبوية</h1>
          <p className="text-muted-foreground mt-1">
            إدارة مجموعة الأحاديث المعروضة في التطبيق
          </p>
        </div>
        <Button onClick={handleCreate}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة حديث
        </Button>
      </div>

      {/* Bulk Actions Bar */}
      {isSomeSelected && (
        <Card className="border-primary/20 bg-primary/5">
          <CardContent className="py-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <Badge variant="secondary" className="text-sm">
                  <CheckCheck className="h-4 w-4 ml-1" />
                  {selectedIds.size} محدد
                </Badge>
                <div className="flex gap-2">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => handleBulkActivate(true)}
                    disabled={bulkToggle.isPending}
                  >
                    <Eye className="h-4 w-4 ml-1" />
                    تفعيل الكل
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => handleBulkActivate(false)}
                    disabled={bulkToggle.isPending}
                  >
                    <EyeOff className="h-4 w-4 ml-1" />
                    تعطيل الكل
                  </Button>
                  <Button
                    size="sm"
                    variant="destructive"
                    onClick={handleBulkDelete}
                    disabled={bulkDelete.isPending}
                  >
                    <Trash2 className="h-4 w-4 ml-1" />
                    حذف المحدد
                  </Button>
                </div>
              </div>
              <Button size="sm" variant="ghost" onClick={clearSelection}>
                <X className="h-4 w-4 ml-1" />
                إلغاء التحديد
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <div className="flex items-center gap-4">
            <div className="relative flex-1">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="بحث في الأحاديث..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pr-10"
              />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="text-center py-8 text-muted-foreground">
              جاري التحميل...
            </div>
          ) : filteredHadith?.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              لا توجد أحاديث
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-[50px]">
                    <Checkbox
                      checked={isAllSelected}
                      onCheckedChange={toggleAllSelection}
                    />
                  </TableHead>
                  <TableHead className="w-[400px]">نص الحديث</TableHead>
                  <TableHead>المصدر</TableHead>
                  <TableHead>الراوي</TableHead>
                  <TableHead>الدرجة</TableHead>
                  <TableHead>الحالة</TableHead>
                  <TableHead className="w-[100px]">الإجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredHadith?.map((hadith) => (
                  <TableRow
                    key={hadith.id}
                    className={selectedIds.has(hadith.id) ? "bg-primary/5" : ""}
                  >
                    <TableCell>
                      <Checkbox
                        checked={selectedIds.has(hadith.id)}
                        onCheckedChange={() => toggleSelection(hadith.id)}
                      />
                    </TableCell>
                    <TableCell className="font-medium">
                      {truncate(hadith.hadith_text, 100)}
                    </TableCell>
                    <TableCell>{hadith.source}</TableCell>
                    <TableCell>{hadith.narrator || "-"}</TableCell>
                    <TableCell>
                      {hadith.grade && (
                        <Badge className={gradeColors[hadith.grade] || ""}>
                          {hadith.grade}
                        </Badge>
                      )}
                    </TableCell>
                    <TableCell>
                      <Switch
                        checked={hadith.is_active}
                        onCheckedChange={(checked) =>
                          toggleActive.mutate({ id: hadith.id, is_active: checked })
                        }
                      />
                    </TableCell>
                    <TableCell>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="icon">
                            <MoreHorizontal className="h-4 w-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="start">
                          <DropdownMenuItem onClick={() => handleEdit(hadith)}>
                            <Pencil className="h-4 w-4 ml-2" />
                            تعديل
                          </DropdownMenuItem>
                          <DropdownMenuItem
                            onClick={() =>
                              toggleActive.mutate({
                                id: hadith.id,
                                is_active: !hadith.is_active,
                              })
                            }
                          >
                            {hadith.is_active ? (
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
                            onClick={() => handleDelete(hadith.id)}
                            className="text-destructive"
                          >
                            <Trash2 className="h-4 w-4 ml-2" />
                            حذف
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <HadithDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        hadith={selectedHadith}
      />
    </div>
  );
}
