"use client";

import { useState } from "react";
import {
  useUIStrings,
  useCreateUIString,
  useUpdateUIString,
  useDeleteUIString,
  useToggleUIStringActive,
  useSearchUIStrings,
  categoryLabels,
  categoryColors,
  type UIString,
  type UIStringInput,
} from "@/hooks/use-ui-strings";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
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
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import {
  Type,
  Plus,
  Search,
  Edit2,
  Trash2,
  Filter,
  Copy,
  Check,
} from "lucide-react";

const categories = Object.keys(categoryLabels);

export default function UIStringsPage() {
  const [searchQuery, setSearchQuery] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<string>("all");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [editingString, setEditingString] = useState<UIString | null>(null);
  const [stringToDelete, setStringToDelete] = useState<UIString | null>(null);
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  // Queries
  const { data: allStrings, isLoading } = useUIStrings();
  const { data: searchResults } = useSearchUIStrings(searchQuery);

  // Mutations
  const createString = useCreateUIString();
  const updateString = useUpdateUIString();
  const deleteString = useDeleteUIString();
  const toggleActive = useToggleUIStringActive();

  // Form state
  const [formData, setFormData] = useState<UIStringInput>({
    string_key: "",
    category: "general",
    value_ar: "",
    value_en: null,
    description: null,
    screen: null,
    is_active: true,
  });

  // Filter strings
  const displayStrings = searchQuery.length >= 2 ? searchResults : allStrings;
  const filteredStrings = displayStrings?.filter(
    (str) => categoryFilter === "all" || str.category === categoryFilter
  );

  // Group by category for display
  const groupedStrings = filteredStrings?.reduce((acc, str) => {
    if (!acc[str.category]) acc[str.category] = [];
    acc[str.category].push(str);
    return acc;
  }, {} as Record<string, UIString[]>);

  const handleOpenCreate = () => {
    setEditingString(null);
    setFormData({
      string_key: "",
      category: "general",
      value_ar: "",
      value_en: null,
      description: null,
      screen: null,
      is_active: true,
    });
    setDialogOpen(true);
  };

  const handleOpenEdit = (str: UIString) => {
    setEditingString(str);
    setFormData({
      string_key: str.string_key,
      category: str.category,
      value_ar: str.value_ar,
      value_en: str.value_en,
      description: str.description,
      screen: str.screen,
      is_active: str.is_active,
    });
    setDialogOpen(true);
  };

  const handleSubmit = async () => {
    if (editingString) {
      await updateString.mutateAsync({ id: editingString.id, ...formData });
    } else {
      await createString.mutateAsync(formData);
    }
    setDialogOpen(false);
  };

  const handleDelete = async () => {
    if (stringToDelete) {
      await deleteString.mutateAsync(stringToDelete.id);
      setDeleteDialogOpen(false);
      setStringToDelete(null);
    }
  };

  const handleCopyKey = (key: string) => {
    navigator.clipboard.writeText(key);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  // Stats
  const stats = {
    total: allStrings?.length || 0,
    active: allStrings?.filter((s) => s.is_active).length || 0,
    categories: new Set(allStrings?.map((s) => s.category)).size,
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">نصوص الواجهة</h1>
          <p className="text-muted-foreground">
            إدارة نصوص التطبيق وترجماتها عن بُعد
          </p>
        </div>
        <Button onClick={handleOpenCreate}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة نص
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-primary/10 rounded-lg">
                <Type className="h-5 w-5 text-primary" />
              </div>
              <div>
                <p className="text-2xl font-bold">{stats.total}</p>
                <p className="text-sm text-muted-foreground">إجمالي النصوص</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-green-500/10 rounded-lg">
                <Check className="h-5 w-5 text-green-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">{stats.active}</p>
                <p className="text-sm text-muted-foreground">نص نشط</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-500/10 rounded-lg">
                <Filter className="h-5 w-5 text-purple-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">{stats.categories}</p>
                <p className="text-sm text-muted-foreground">فئة</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Search and Filters */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex gap-4">
            <div className="flex-1 relative">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="بحث بالمفتاح أو القيمة..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pr-10"
              />
            </div>
            <Select value={categoryFilter} onValueChange={setCategoryFilter}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="جميع الفئات" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">جميع الفئات</SelectItem>
                {categories.map((cat) => (
                  <SelectItem key={cat} value={cat}>
                    {categoryLabels[cat]}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Strings Table */}
      <Card>
        <CardHeader>
          <CardTitle>قائمة النصوص</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-3">
              {[...Array(5)].map((_, i) => (
                <Skeleton key={i} className="h-16 w-full" />
              ))}
            </div>
          ) : !filteredStrings?.length ? (
            <div className="text-center py-12 text-muted-foreground">
              <Type className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>لا توجد نصوص</p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-12">الحالة</TableHead>
                  <TableHead>المفتاح</TableHead>
                  <TableHead>الفئة</TableHead>
                  <TableHead>القيمة (عربي)</TableHead>
                  <TableHead>القيمة (إنجليزي)</TableHead>
                  <TableHead>الشاشة</TableHead>
                  <TableHead className="w-24">الإجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredStrings.map((str) => (
                  <TableRow key={str.id}>
                    <TableCell>
                      <Switch
                        checked={str.is_active}
                        onCheckedChange={(checked) =>
                          toggleActive.mutate({ id: str.id, is_active: checked })
                        }
                      />
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <code className="text-sm bg-muted px-2 py-1 rounded font-mono">
                          {str.string_key}
                        </code>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-6 w-6"
                          onClick={() => handleCopyKey(str.string_key)}
                        >
                          {copiedKey === str.string_key ? (
                            <Check className="h-3 w-3 text-green-500" />
                          ) : (
                            <Copy className="h-3 w-3" />
                          )}
                        </Button>
                      </div>
                      {str.description && (
                        <p className="text-xs text-muted-foreground mt-1">
                          {str.description}
                        </p>
                      )}
                    </TableCell>
                    <TableCell>
                      <Badge className={`${categoryColors[str.category]} text-white`}>
                        {categoryLabels[str.category]}
                      </Badge>
                    </TableCell>
                    <TableCell className="max-w-[200px] truncate">
                      {str.value_ar}
                    </TableCell>
                    <TableCell className="max-w-[200px] truncate text-muted-foreground">
                      {str.value_en || "-"}
                    </TableCell>
                    <TableCell>
                      {str.screen ? (
                        <Badge variant="outline">{str.screen}</Badge>
                      ) : (
                        <span className="text-muted-foreground">-</span>
                      )}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleOpenEdit(str)}
                        >
                          <Edit2 className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => {
                            setStringToDelete(str);
                            setDeleteDialogOpen(true);
                          }}
                        >
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Create/Edit Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>
              {editingString ? "تعديل النص" : "إضافة نص جديد"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>مفتاح النص *</Label>
                <Input
                  placeholder="home_greeting"
                  value={formData.string_key}
                  onChange={(e) =>
                    setFormData({ ...formData, string_key: e.target.value })
                  }
                  disabled={!!editingString}
                  className="font-mono"
                />
              </div>
              <div className="space-y-2">
                <Label>الفئة *</Label>
                <Select
                  value={formData.category}
                  onValueChange={(value) =>
                    setFormData({ ...formData, category: value })
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {categories.map((cat) => (
                      <SelectItem key={cat} value={cat}>
                        {categoryLabels[cat]}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <Label>القيمة (عربي) *</Label>
              <Textarea
                placeholder="النص بالعربية..."
                value={formData.value_ar}
                onChange={(e) =>
                  setFormData({ ...formData, value_ar: e.target.value })
                }
                rows={2}
              />
            </div>

            <div className="space-y-2">
              <Label>القيمة (إنجليزي)</Label>
              <Textarea
                placeholder="English text..."
                value={formData.value_en || ""}
                onChange={(e) =>
                  setFormData({
                    ...formData,
                    value_en: e.target.value || null,
                  })
                }
                rows={2}
                dir="ltr"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>الشاشة</Label>
                <Input
                  placeholder="home, profile, etc."
                  value={formData.screen || ""}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      screen: e.target.value || null,
                    })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label>الوصف</Label>
                <Input
                  placeholder="وصف للنص..."
                  value={formData.description || ""}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      description: e.target.value || null,
                    })
                  }
                />
              </div>
            </div>

            <div className="flex items-center gap-2">
              <Switch
                checked={formData.is_active}
                onCheckedChange={(checked) =>
                  setFormData({ ...formData, is_active: checked })
                }
              />
              <Label>نشط</Label>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSubmit}
              disabled={
                !formData.string_key ||
                !formData.value_ar ||
                createString.isPending ||
                updateString.isPending
              }
            >
              {editingString ? "حفظ التغييرات" : "إضافة"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>حذف النص</AlertDialogTitle>
            <AlertDialogDescription>
              هل أنت متأكد من حذف النص &quot;{stringToDelete?.string_key}&quot;؟
              <br />
              لا يمكن التراجع عن هذا الإجراء.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>إلغاء</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              حذف
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
