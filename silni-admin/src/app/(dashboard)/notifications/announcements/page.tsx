"use client";

import { useState } from "react";
import {
  useAnnouncements,
  useCreateAnnouncement,
  useUpdateAnnouncement,
  useDeleteAnnouncement,
  useSendAnnouncement,
  useAnnouncementStats,
  STATUS_LABELS,
  TARGET_LABELS,
  STATUS_COLORS,
  type Announcement,
  type AnnouncementStatus,
  type AnnouncementTarget,
  type CreateAnnouncementInput,
} from "@/hooks/use-announcements";
import { useAppRoutes } from "@/hooks/use-app-routes";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
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
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Bell,
  Plus,
  Send,
  Pencil,
  Trash2,
  Users,
  CheckCircle,
  Clock,
  AlertCircle,
  Link as LinkIcon,
  FileText,
  Loader2,
} from "lucide-react";

export default function AnnouncementsPage() {
  const { data: announcements, isLoading } = useAnnouncements();
  const { data: stats } = useAnnouncementStats();
  const { data: routes } = useAppRoutes();
  const createMutation = useCreateAnnouncement();
  const updateMutation = useUpdateAnnouncement();
  const deleteMutation = useDeleteAnnouncement();
  const sendMutation = useSendAnnouncement();

  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [isSendDialogOpen, setIsSendDialogOpen] = useState(false);
  const [selectedAnnouncement, setSelectedAnnouncement] = useState<Announcement | null>(null);
  const [formData, setFormData] = useState<CreateAnnouncementInput>({
    title_ar: "",
    title_en: "",
    body_ar: "",
    body_en: "",
    deep_link: "",
    target_users: "all",
    priority: "high",
  });

  const handleOpenCreate = () => {
    setSelectedAnnouncement(null);
    setFormData({
      title_ar: "",
      title_en: "",
      body_ar: "",
      body_en: "",
      deep_link: "",
      target_users: "all",
      priority: "high",
    });
    setIsDialogOpen(true);
  };

  const handleOpenEdit = (announcement: Announcement) => {
    setSelectedAnnouncement(announcement);
    setFormData({
      title_ar: announcement.title_ar,
      title_en: announcement.title_en || "",
      body_ar: announcement.body_ar,
      body_en: announcement.body_en || "",
      deep_link: announcement.deep_link || "",
      target_users: announcement.target_users,
      priority: announcement.priority,
    });
    setIsDialogOpen(true);
  };

  const handleOpenDelete = (announcement: Announcement) => {
    setSelectedAnnouncement(announcement);
    setIsDeleteDialogOpen(true);
  };

  const handleOpenSend = (announcement: Announcement) => {
    setSelectedAnnouncement(announcement);
    setIsSendDialogOpen(true);
  };

  const handleSubmit = async () => {
    if (selectedAnnouncement) {
      await updateMutation.mutateAsync({
        id: selectedAnnouncement.id,
        ...formData,
      });
    } else {
      await createMutation.mutateAsync(formData);
    }
    setIsDialogOpen(false);
  };

  const handleDelete = async () => {
    if (selectedAnnouncement) {
      await deleteMutation.mutateAsync(selectedAnnouncement.id);
      setIsDeleteDialogOpen(false);
    }
  };

  const handleSend = async () => {
    if (selectedAnnouncement) {
      await sendMutation.mutateAsync(selectedAnnouncement.id);
      setIsSendDialogOpen(false);
    }
  };

  const formatDate = (date: string | null) => {
    if (!date) return "-";
    return new Date(date).toLocaleDateString("ar-SA", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <Skeleton className="h-10 w-64" />
          <Skeleton className="h-10 w-32" />
        </div>
        <div className="grid gap-4 md:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-24" />
          ))}
        </div>
        <Skeleton className="h-96" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2.5 rounded-xl bg-gradient-to-br from-orange-500 to-amber-500 shadow-lg">
            <Bell className="h-6 w-6 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold">الإشعارات الفورية</h1>
            <p className="text-muted-foreground">أرسل إشعارات مخصصة لمستخدمي التطبيق</p>
          </div>
        </div>
        <Button onClick={handleOpenCreate} className="gap-2">
          <Plus className="h-4 w-4" />
          إشعار جديد
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">إجمالي الإشعارات</CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats?.total || 0}</div>
            <p className="text-xs text-muted-foreground">
              {stats?.draft || 0} مسودة
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">تم الإرسال</CardTitle>
            <CheckCircle className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">{stats?.sent || 0}</div>
            <p className="text-xs text-muted-foreground">
              {stats?.totalSuccessful || 0} مستلم
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">مجدول</CardTitle>
            <Clock className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-blue-600">{stats?.scheduled || 0}</div>
            <p className="text-xs text-muted-foreground">في الانتظار</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">فشل</CardTitle>
            <AlertCircle className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">{stats?.failed || 0}</div>
            <p className="text-xs text-muted-foreground">تحتاج مراجعة</p>
          </CardContent>
        </Card>
      </div>

      {/* Announcements Table */}
      <Card>
        <CardHeader>
          <CardTitle>سجل الإشعارات</CardTitle>
          <CardDescription>جميع الإشعارات المرسلة والمجدولة</CardDescription>
        </CardHeader>
        <CardContent>
          {announcements && announcements.length > 0 ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>العنوان</TableHead>
                  <TableHead>الحالة</TableHead>
                  <TableHead>الجمهور</TableHead>
                  <TableHead>الرابط</TableHead>
                  <TableHead>التاريخ</TableHead>
                  <TableHead className="text-left">الإجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {announcements.map((announcement) => (
                  <TableRow key={announcement.id}>
                    <TableCell>
                      <div>
                        <div className="font-medium">{announcement.title_ar}</div>
                        <div className="text-sm text-muted-foreground line-clamp-1">
                          {announcement.body_ar}
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge className={STATUS_COLORS[announcement.status]}>
                        {STATUS_LABELS[announcement.status]}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1 text-sm">
                        <Users className="h-3 w-3" />
                        {TARGET_LABELS[announcement.target_users]}
                      </div>
                    </TableCell>
                    <TableCell>
                      {announcement.deep_link ? (
                        <div className="flex items-center gap-1 text-sm text-blue-600">
                          <LinkIcon className="h-3 w-3" />
                          {announcement.deep_link}
                        </div>
                      ) : (
                        <span className="text-muted-foreground">-</span>
                      )}
                    </TableCell>
                    <TableCell className="text-sm">
                      {announcement.sent_at
                        ? formatDate(announcement.sent_at)
                        : formatDate(announcement.created_at)}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        {(announcement.status === "draft" || announcement.status === "scheduled") && (
                          <>
                            <Button
                              variant="default"
                              size="sm"
                              onClick={() => handleOpenSend(announcement)}
                              disabled={sendMutation.isPending}
                              className="gap-1"
                            >
                              <Send className="h-3 w-3" />
                              إرسال
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleOpenEdit(announcement)}
                            >
                              <Pencil className="h-3 w-3" />
                            </Button>
                          </>
                        )}
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleOpenDelete(announcement)}
                          className="text-red-600 hover:text-red-700"
                        >
                          <Trash2 className="h-3 w-3" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          ) : (
            <div className="text-center py-12">
              <Bell className="h-12 w-12 mx-auto text-muted-foreground/50" />
              <h3 className="mt-4 text-lg font-medium">لا توجد إشعارات</h3>
              <p className="text-muted-foreground">ابدأ بإنشاء إشعار جديد</p>
              <Button onClick={handleOpenCreate} className="mt-4 gap-2">
                <Plus className="h-4 w-4" />
                إشعار جديد
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Create/Edit Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>
              {selectedAnnouncement ? "تعديل الإشعار" : "إشعار جديد"}
            </DialogTitle>
            <DialogDescription>
              أنشئ إشعاراً مخصصاً لإرساله للمستخدمين
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="title_ar">العنوان (عربي) *</Label>
                <Input
                  id="title_ar"
                  value={formData.title_ar}
                  onChange={(e) => setFormData({ ...formData, title_ar: e.target.value })}
                  placeholder="عنوان الإشعار"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="title_en">العنوان (إنجليزي)</Label>
                <Input
                  id="title_en"
                  value={formData.title_en}
                  onChange={(e) => setFormData({ ...formData, title_en: e.target.value })}
                  placeholder="Notification title"
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="body_ar">المحتوى (عربي) *</Label>
                <Textarea
                  id="body_ar"
                  value={formData.body_ar}
                  onChange={(e) => setFormData({ ...formData, body_ar: e.target.value })}
                  placeholder="محتوى الإشعار..."
                  rows={3}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="body_en">المحتوى (إنجليزي)</Label>
                <Textarea
                  id="body_en"
                  value={formData.body_en}
                  onChange={(e) => setFormData({ ...formData, body_en: e.target.value })}
                  placeholder="Notification body..."
                  rows={3}
                  dir="ltr"
                />
              </div>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="deep_link">رابط الهبوط (Deep Link)</Label>
                <Select
                  value={formData.deep_link || "none"}
                  onValueChange={(value) =>
                    setFormData({ ...formData, deep_link: value === "none" ? "" : value })
                  }
                >
                  <SelectTrigger>
                    <SelectValue placeholder="اختر صفحة الهبوط" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="none">بدون رابط</SelectItem>
                    <SelectItem value="/home">الرئيسية</SelectItem>
                    <SelectItem value="/ai-chat">المساعد الذكي</SelectItem>
                    <SelectItem value="/reminders">التذكيرات</SelectItem>
                    <SelectItem value="/relatives">الأقارب</SelectItem>
                    <SelectItem value="/profile">الملف الشخصي</SelectItem>
                    <SelectItem value="/settings">الإعدادات</SelectItem>
                    <SelectItem value="/gaming-center">مركز الألعاب</SelectItem>
                    <SelectItem value="/badges">الشارات</SelectItem>
                    {routes?.map((route) => (
                      <SelectItem key={route.id} value={route.path}>
                        {route.label_ar || route.path}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="target_users">الجمهور المستهدف</Label>
                <Select
                  value={formData.target_users}
                  onValueChange={(value: AnnouncementTarget) =>
                    setFormData({ ...formData, target_users: value })
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">جميع المستخدمين</SelectItem>
                    <SelectItem value="active">المستخدمين النشطين (7+ أيام)</SelectItem>
                    <SelectItem value="premium">المشتركين المميزين</SelectItem>
                    <SelectItem value="inactive">المستخدمين غير النشطين</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="priority">أولوية الإشعار</Label>
              <Select
                value={formData.priority}
                onValueChange={(value) => setFormData({ ...formData, priority: value })}
              >
                <SelectTrigger className="w-48">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="high">عالية (مستحسن)</SelectItem>
                  <SelectItem value="default">عادية</SelectItem>
                  <SelectItem value="low">منخفضة</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSubmit}
              disabled={
                !formData.title_ar ||
                !formData.body_ar ||
                createMutation.isPending ||
                updateMutation.isPending
              }
            >
              {(createMutation.isPending || updateMutation.isPending) && (
                <Loader2 className="ml-2 h-4 w-4 animate-spin" />
              )}
              {selectedAnnouncement ? "حفظ التغييرات" : "إنشاء الإشعار"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>حذف الإشعار</AlertDialogTitle>
            <AlertDialogDescription>
              هل أنت متأكد من حذف &quot;{selectedAnnouncement?.title_ar}&quot;؟
              <br />
              لا يمكن التراجع عن هذا الإجراء.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>إلغاء</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-red-600 hover:bg-red-700"
            >
              {deleteMutation.isPending && <Loader2 className="ml-2 h-4 w-4 animate-spin" />}
              حذف
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Send Confirmation Dialog */}
      <AlertDialog open={isSendDialogOpen} onOpenChange={setIsSendDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>إرسال الإشعار</AlertDialogTitle>
            <AlertDialogDescription>
              هل أنت متأكد من إرسال &quot;{selectedAnnouncement?.title_ar}&quot; إلى{" "}
              <strong>{TARGET_LABELS[selectedAnnouncement?.target_users || "all"]}</strong>؟
              <br />
              <br />
              سيتم إرسال الإشعار فوراً لجميع المستخدمين المستهدفين.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>إلغاء</AlertDialogCancel>
            <AlertDialogAction onClick={handleSend}>
              {sendMutation.isPending && <Loader2 className="ml-2 h-4 w-4 animate-spin" />}
              إرسال الآن
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
