"use client";

import { useState } from "react";
import {
  useCounselingModes,
  useSuggestedPrompts,
  useCreateSuggestedPrompt,
  useUpdateSuggestedPrompt,
  useDeleteSuggestedPrompt,
} from "@/hooks/use-ai";
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
  DialogHeader,
  DialogTitle,
  DialogTrigger
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
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
import { Save, Plus, MessageCircle, Trash2, Edit2 } from "lucide-react";

export default function SuggestedPromptsPage() {
  const { data: modes, isLoading: loadingModes } = useCounselingModes();
  const { data: allPrompts, isLoading: loadingPrompts } = useSuggestedPrompts();
  const createPrompt = useCreateSuggestedPrompt();
  const updatePrompt = useUpdateSuggestedPrompt();
  const deletePrompt = useDeleteSuggestedPrompt();

  const [selectedMode, setSelectedMode] = useState<string>("general");
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [editingPrompt, setEditingPrompt] = useState<string | null>(null);
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);

  const [newPrompt, setNewPrompt] = useState({
    mode_key: "general",
    prompt_ar: "",
    prompt_en: "",
    is_active: true,
    sort_order: 0,
  });

  const [editValues, setEditValues] = useState({
    prompt_ar: "",
    prompt_en: "",
    is_active: true,
    sort_order: 0,
  });

  const isLoading = loadingModes || loadingPrompts;

  const promptsForMode = allPrompts?.filter((p) => p.mode_key === selectedMode) || [];
  const sortedPrompts = [...promptsForMode].sort((a, b) => a.sort_order - b.sort_order);

  const handleCreatePrompt = () => {
    createPrompt.mutate(newPrompt, {
      onSuccess: () => {
        setIsCreateDialogOpen(false);
        setNewPrompt({
          mode_key: selectedMode,
          prompt_ar: "",
          prompt_en: "",
          is_active: true,
          sort_order: promptsForMode.length,
        });
      },
    });
  };

  const handleUpdatePrompt = () => {
    if (!editingPrompt) return;
    updatePrompt.mutate(
      { id: editingPrompt, ...editValues },
      {
        onSuccess: () => {
          setEditingPrompt(null);
        },
      }
    );
  };

  const handleDeletePrompt = () => {
    if (!deleteConfirmId) return;
    deletePrompt.mutate(deleteConfirmId, {
      onSuccess: () => {
        setDeleteConfirmId(null);
      },
    });
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="space-y-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-20" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">الاقتراحات المقترحة</h1>
          <p className="text-muted-foreground mt-1">
            إدارة الأسئلة المقترحة لكل وضع استشارة
          </p>
        </div>
        <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
          <DialogTrigger asChild>
            <Button>
              <Plus className="h-4 w-4 ml-2" />
              إضافة اقتراح
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>إضافة اقتراح جديد</DialogTitle>
              <DialogDescription>
                أضف سؤالاً أو عبارة مقترحة للمستخدم
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label>الوضع</Label>
                <Select
                  value={newPrompt.mode_key}
                  onValueChange={(value) =>
                    setNewPrompt((prev) => ({ ...prev, mode_key: value }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {modes?.map((mode) => (
                      <SelectItem key={mode.mode_key} value={mode.mode_key}>
                        {mode.display_name_ar}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>الاقتراح (عربي) *</Label>
                <Textarea
                  value={newPrompt.prompt_ar}
                  onChange={(e) =>
                    setNewPrompt((prev) => ({ ...prev, prompt_ar: e.target.value }))
                  }
                  placeholder="كيف أحافظ على صلة الرحم؟"
                  rows={2}
                />
              </div>
              <div className="space-y-2">
                <Label>الاقتراح (إنجليزي)</Label>
                <Textarea
                  value={newPrompt.prompt_en}
                  onChange={(e) =>
                    setNewPrompt((prev) => ({ ...prev, prompt_en: e.target.value }))
                  }
                  placeholder="How do I maintain family ties?"
                  rows={2}
                  dir="ltr"
                />
              </div>
              <div className="space-y-2">
                <Label>الترتيب</Label>
                <Input
                  type="number"
                  value={newPrompt.sort_order}
                  onChange={(e) =>
                    setNewPrompt((prev) => ({
                      ...prev,
                      sort_order: parseInt(e.target.value) || 0,
                    }))
                  }
                />
              </div>
            </div>
            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={() => setIsCreateDialogOpen(false)}>
                إلغاء
              </Button>
              <Button
                onClick={handleCreatePrompt}
                disabled={!newPrompt.prompt_ar || createPrompt.isPending}
              >
                <Plus className="h-4 w-4 ml-2" />
                إضافة
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      {/* Info Card */}
      <Card className="border-purple-500/20 bg-gradient-to-br from-purple-500/5 to-pink-500/5">
        <CardContent className="pt-6">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center">
              <MessageCircle className="h-6 w-6 text-white" />
            </div>
            <div className="flex-1">
              <h3 className="font-semibold">الاقتراحات الذكية</h3>
              <p className="text-muted-foreground text-sm mt-1">
                هذه الاقتراحات تظهر للمستخدم عند بدء محادثة جديدة لتسهيل التفاعل مع واصل.
              </p>
              <div className="flex gap-2 mt-3">
                <Badge variant="outline">{allPrompts?.length || 0} اقتراح</Badge>
                <Badge variant="outline" className="bg-green-500/10 text-green-600">
                  {allPrompts?.filter((p) => p.is_active).length || 0} نشط
                </Badge>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Mode Tabs */}
      <Tabs value={selectedMode} onValueChange={setSelectedMode}>
        <TabsList className="flex-wrap h-auto gap-2">
          {modes?.map((mode) => {
            const count = allPrompts?.filter((p) => p.mode_key === mode.mode_key).length || 0;
            return (
              <TabsTrigger key={mode.mode_key} value={mode.mode_key} className="gap-2">
                {mode.display_name_ar}
                <Badge variant="secondary" className="text-xs">
                  {count}
                </Badge>
              </TabsTrigger>
            );
          })}
        </TabsList>

        {modes?.map((mode) => (
          <TabsContent key={mode.mode_key} value={mode.mode_key} className="mt-6">
            <div className="space-y-3">
              {sortedPrompts.map((prompt, index) => (
                <Card
                  key={prompt.id}
                  className={`transition-all ${!prompt.is_active ? "opacity-50" : ""}`}
                >
                  <CardContent className="py-4">
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex items-start gap-3 flex-1">
                        <Badge variant="outline" className="shrink-0 mt-1">
                          {index + 1}
                        </Badge>
                        <div className="flex-1">
                          {editingPrompt === prompt.id ? (
                            <div className="space-y-3">
                              <Textarea
                                value={editValues.prompt_ar}
                                onChange={(e) =>
                                  setEditValues((prev) => ({
                                    ...prev,
                                    prompt_ar: e.target.value,
                                  }))
                                }
                                rows={2}
                              />
                              <Textarea
                                value={editValues.prompt_en}
                                onChange={(e) =>
                                  setEditValues((prev) => ({
                                    ...prev,
                                    prompt_en: e.target.value,
                                  }))
                                }
                                rows={2}
                                dir="ltr"
                                placeholder="English version..."
                              />
                              <div className="flex items-center gap-2">
                                <Label className="text-xs">الترتيب:</Label>
                                <Input
                                  type="number"
                                  value={editValues.sort_order}
                                  onChange={(e) =>
                                    setEditValues((prev) => ({
                                      ...prev,
                                      sort_order: parseInt(e.target.value) || 0,
                                    }))
                                  }
                                  className="w-20 h-8"
                                />
                              </div>
                              <div className="flex gap-2">
                                <Button
                                  size="sm"
                                  variant="outline"
                                  onClick={() => setEditingPrompt(null)}
                                >
                                  إلغاء
                                </Button>
                                <Button
                                  size="sm"
                                  onClick={handleUpdatePrompt}
                                  disabled={updatePrompt.isPending}
                                >
                                  <Save className="h-3 w-3 ml-1" />
                                  حفظ
                                </Button>
                              </div>
                            </div>
                          ) : (
                            <>
                              <p className="font-medium">{prompt.prompt_ar}</p>
                              {prompt.prompt_en && (
                                <p className="text-sm text-muted-foreground mt-1" dir="ltr">
                                  {prompt.prompt_en}
                                </p>
                              )}
                            </>
                          )}
                        </div>
                      </div>
                      {editingPrompt !== prompt.id && (
                        <div className="flex items-center gap-2">
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => {
                              setEditingPrompt(prompt.id);
                              setEditValues({
                                prompt_ar: prompt.prompt_ar,
                                prompt_en: prompt.prompt_en || "",
                                is_active: prompt.is_active,
                                sort_order: prompt.sort_order,
                              });
                            }}
                          >
                            <Edit2 className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="text-destructive hover:text-destructive"
                            onClick={() => setDeleteConfirmId(prompt.id)}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                          <Switch
                            checked={prompt.is_active}
                            onCheckedChange={(checked) => {
                              updatePrompt.mutate({ id: prompt.id, is_active: checked });
                            }}
                          />
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))}

              {sortedPrompts.length === 0 && (
                <Card>
                  <CardContent className="py-8 text-center text-muted-foreground">
                    <MessageCircle className="h-12 w-12 mx-auto mb-4 opacity-50" />
                    <p>لا توجد اقتراحات لهذا الوضع</p>
                    <Button
                      variant="outline"
                      className="mt-4"
                      onClick={() => {
                        setNewPrompt((prev) => ({ ...prev, mode_key: selectedMode }));
                        setIsCreateDialogOpen(true);
                      }}
                    >
                      <Plus className="h-4 w-4 ml-2" />
                      إضافة اقتراح
                    </Button>
                  </CardContent>
                </Card>
              )}
            </div>
          </TabsContent>
        ))}
      </Tabs>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={!!deleteConfirmId} onOpenChange={() => setDeleteConfirmId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>حذف الاقتراح</AlertDialogTitle>
            <AlertDialogDescription>
              هل أنت متأكد من حذف هذا الاقتراح؟ لا يمكن التراجع عن هذا الإجراء.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>إلغاء</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDeletePrompt}
              className="bg-destructive hover:bg-destructive/90"
            >
              حذف
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
