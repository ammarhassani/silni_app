"use client";

import { useState, useEffect } from "react";
import {
  useSocialTemplates,
  useCreateSocialTemplate,
  useUpdateSocialTemplate,
  useDeleteSocialTemplate,
  useDuplicateSocialTemplate,
} from "@/hooks/use-social-templates";
import {
  useSocialBrandVoice,
  useUpdateSocialBrandVoice,
} from "@/hooks/use-social-brand-voice";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
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
import { Plus, Copy, Trash2, Pencil, Save, MoreHorizontal, Search } from "lucide-react";
import type { SocialTemplate, SocialContentType, SocialTone } from "@/types/database";

// --- Label maps ---

const contentTypeLabels: Record<SocialContentType, string> = {
  hadith: "حديث",
  quran: "قرآن",
  family_tip: "نصيحة عائلية",
  feature: "ميزة",
  update: "تحديث",
  cta: "دعوة للتحميل",
  occasion: "مناسبة",
};

const toneLabels: Record<SocialTone, string> = {
  inspirational: "ملهم",
  educational: "تعليمي",
  conversational: "حواري",
  promotional: "ترويجي",
};

const platformLabels: Record<string, { label: string; color: string }> = {
  twitter: { label: "تويتر", color: "bg-blue-500/10 text-blue-600" },
  instagram: { label: "إنستغرام", color: "bg-pink-500/10 text-pink-600" },
  both: { label: "الكل", color: "bg-purple-500/10 text-purple-600" },
};

const dialectOptions = [
  { value: "msa", label: "فصحى" },
  { value: "colloquial", label: "عامية" },
  { value: "mix", label: "مزيج" },
];

// --- Default form data ---

type TemplateFormData = Omit<SocialTemplate, "id" | "created_at" | "updated_at">;

const defaultFormData: TemplateFormData = {
  name: "",
  content_type: "hadith",
  platform: "both",
  text_template: "",
  default_hashtags: [],
  default_tone: null,
  is_recurring: false,
  recurring_schedule: null,
  tags: [],
  is_active: true,
};

export default function SocialTemplatesPage() {
  // --- Brand voice state ---
  const { data: brandVoice, isLoading: brandVoiceLoading } = useSocialBrandVoice();
  const updateBrandVoice = useUpdateSocialBrandVoice();

  const [toneGuidelines, setToneGuidelines] = useState("");
  const [arabicDialect, setArabicDialect] = useState("msa");
  const [hashtagSetsJson, setHashtagSetsJson] = useState("{}");
  const [bannedWordsText, setBannedWordsText] = useState("");

  useEffect(() => {
    if (brandVoice) {
      setToneGuidelines(brandVoice.tone_guidelines || "");
      setArabicDialect(brandVoice.arabic_dialect || "msa");
      setHashtagSetsJson(JSON.stringify(brandVoice.hashtag_sets || {}, null, 2));
      setBannedWordsText((brandVoice.banned_words || []).join("، "));
    }
  }, [brandVoice]);

  const handleSaveBrandVoice = () => {
    if (!brandVoice) return;

    let parsedHashtagSets: Record<string, string[]> = {};
    try {
      const trimmed = hashtagSetsJson.trim();
      parsedHashtagSets = trimmed ? JSON.parse(trimmed) : {};
    } catch {
      parsedHashtagSets = {};
    }

    const parsedBannedWords = bannedWordsText
      .split(/[,،]/)
      .map((w) => w.trim())
      .filter(Boolean);

    updateBrandVoice.mutate({
      id: brandVoice.id,
      tone_guidelines: toneGuidelines,
      arabic_dialect: arabicDialect as "msa" | "colloquial" | "mix",
      hashtag_sets: parsedHashtagSets,
      banned_words: parsedBannedWords,
    });
  };

  // --- Templates state ---
  const { data: templates, isLoading: templatesLoading } = useSocialTemplates();
  const createTemplate = useCreateSocialTemplate();
  const updateTemplate = useUpdateSocialTemplate();
  const deleteTemplate = useDeleteSocialTemplate();
  const duplicateTemplate = useDuplicateSocialTemplate();

  const [search, setSearch] = useState("");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingTemplate, setEditingTemplate] = useState<SocialTemplate | null>(null);
  const [formData, setFormData] = useState<TemplateFormData>(defaultFormData);
  const [hashtagsInput, setHashtagsInput] = useState("");

  const filteredTemplates = templates?.filter((t) =>
    t.name.includes(search)
  );

  const handleCreate = () => {
    setEditingTemplate(null);
    setFormData(defaultFormData);
    setHashtagsInput("");
    setDialogOpen(true);
  };

  const handleEdit = (template: SocialTemplate) => {
    setEditingTemplate(template);
    setFormData({
      name: template.name,
      content_type: template.content_type,
      platform: template.platform,
      text_template: template.text_template,
      default_hashtags: template.default_hashtags || [],
      default_tone: template.default_tone,
      is_recurring: template.is_recurring,
      recurring_schedule: template.recurring_schedule,
      tags: template.tags || [],
      is_active: template.is_active,
    });
    setHashtagsInput((template.default_hashtags || []).join(", "));
    setDialogOpen(true);
  };

  const handleSaveTemplate = () => {
    const hashtags = hashtagsInput
      .split(/[,،]/)
      .map((h) => h.trim())
      .filter(Boolean);

    const data = {
      ...formData,
      default_hashtags: hashtags,
    };

    if (editingTemplate) {
      updateTemplate.mutate(
        { id: editingTemplate.id, ...data },
        { onSuccess: () => setDialogOpen(false) }
      );
    } else {
      createTemplate.mutate(data, {
        onSuccess: () => setDialogOpen(false),
      });
    }
  };

  const handleDelete = (id: string) => {
    if (confirm("هل أنت متأكد من حذف هذا القالب؟")) {
      deleteTemplate.mutate(id);
    }
  };

  const handleDuplicate = (id: string) => {
    duplicateTemplate.mutate(id);
  };

  const handleToggleActive = (template: SocialTemplate) => {
    updateTemplate.mutate({
      id: template.id,
      is_active: !template.is_active,
    });
  };

  return (
    <div className="space-y-6">
      {/* ======= Section 1: Brand Voice Config ======= */}
      <Card>
        <CardHeader>
          <CardTitle>إعدادات صوت العلامة</CardTitle>
        </CardHeader>
        <CardContent>
          {brandVoiceLoading ? (
            <div className="text-center py-8 text-muted-foreground">
              جاري التحميل...
            </div>
          ) : !brandVoice ? (
            <div className="text-center py-8 text-muted-foreground">
              لا توجد إعدادات صوت العلامة
            </div>
          ) : (
            <div className="grid gap-4">
              <div className="space-y-2">
                <Label>إرشادات النبرة</Label>
                <Textarea
                  value={toneGuidelines}
                  onChange={(e) => setToneGuidelines(e.target.value)}
                  placeholder="اكتب إرشادات النبرة هنا..."
                  rows={3}
                />
              </div>

              <div className="space-y-2">
                <Label>اللهجة العربية</Label>
                <Select
                  value={arabicDialect}
                  onValueChange={setArabicDialect}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {dialectOptions.map((opt) => (
                      <SelectItem key={opt.value} value={opt.value}>
                        {opt.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>مجموعات الهاشتاق</Label>
                <Textarea
                  value={hashtagSetsJson}
                  onChange={(e) => setHashtagSetsJson(e.target.value)}
                  rows={4}
                  dir="ltr"
                  className="font-mono text-sm"
                  placeholder='{"default": ["#صلني", "#عائلة"]}'
                />
              </div>

              <div className="space-y-2">
                <Label>الكلمات المحظورة</Label>
                <Textarea
                  value={bannedWordsText}
                  onChange={(e) => setBannedWordsText(e.target.value)}
                  placeholder="كلمة1، كلمة2، كلمة3"
                  rows={2}
                />
              </div>

              <div className="flex justify-end">
                <Button
                  onClick={handleSaveBrandVoice}
                  disabled={updateBrandVoice.isPending}
                >
                  <Save className="h-4 w-4 ml-2" />
                  {updateBrandVoice.isPending ? "جاري الحفظ..." : "حفظ الإعدادات"}
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* ======= Section 2: Templates Table ======= */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>قوالب المنشورات</CardTitle>
            <Button onClick={handleCreate}>
              <Plus className="h-4 w-4 ml-2" />
              إضافة قالب
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {/* Search */}
          <div className="mb-4">
            <div className="relative">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="بحث بالاسم..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pr-10"
              />
            </div>
          </div>

          {templatesLoading ? (
            <div className="text-center py-8 text-muted-foreground">
              جاري التحميل...
            </div>
          ) : filteredTemplates?.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              لا توجد قوالب
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>الاسم</TableHead>
                  <TableHead>نوع المحتوى</TableHead>
                  <TableHead>المنصة</TableHead>
                  <TableHead>النبرة</TableHead>
                  <TableHead>الحالة</TableHead>
                  <TableHead className="w-[100px]">إجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredTemplates?.map((template) => {
                  const platform = platformLabels[template.platform] || platformLabels.both;
                  return (
                    <TableRow key={template.id}>
                      <TableCell className="font-medium">
                        {template.name}
                      </TableCell>
                      <TableCell>
                        <Badge variant="secondary">
                          {contentTypeLabels[template.content_type] || template.content_type}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <Badge className={platform.color}>
                          {platform.label}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        {template.default_tone
                          ? toneLabels[template.default_tone] || template.default_tone
                          : "-"}
                      </TableCell>
                      <TableCell>
                        <Switch
                          checked={template.is_active}
                          onCheckedChange={() => handleToggleActive(template)}
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
                            <DropdownMenuItem onClick={() => handleEdit(template)}>
                              <Pencil className="h-4 w-4 ml-2" />
                              تعديل
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={() => handleDuplicate(template.id)}>
                              <Copy className="h-4 w-4 ml-2" />
                              نسخ
                            </DropdownMenuItem>
                            <DropdownMenuItem
                              onClick={() => handleDelete(template.id)}
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

      {/* ======= Create / Edit Dialog ======= */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {editingTemplate ? "تعديل القالب" : "إضافة قالب جديد"}
            </DialogTitle>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            {/* Name */}
            <div className="space-y-2">
              <Label>الاسم</Label>
              <Input
                value={formData.name}
                onChange={(e) =>
                  setFormData((f) => ({ ...f, name: e.target.value }))
                }
                placeholder="اسم القالب"
              />
            </div>

            {/* Content type + Platform */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>نوع المحتوى</Label>
                <Select
                  value={formData.content_type}
                  onValueChange={(v) =>
                    setFormData((f) => ({
                      ...f,
                      content_type: v as SocialContentType,
                    }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {Object.entries(contentTypeLabels).map(([value, label]) => (
                      <SelectItem key={value} value={value}>
                        {label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>المنصة</Label>
                <Select
                  value={formData.platform}
                  onValueChange={(v) =>
                    setFormData((f) => ({
                      ...f,
                      platform: v as SocialTemplate["platform"],
                    }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="twitter">تويتر</SelectItem>
                    <SelectItem value="instagram">إنستغرام</SelectItem>
                    <SelectItem value="both">الكل</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            {/* Text template */}
            <div className="space-y-2">
              <Label>نص القالب</Label>
              <Textarea
                value={formData.text_template}
                onChange={(e) =>
                  setFormData((f) => ({ ...f, text_template: e.target.value }))
                }
                placeholder="اكتب نص القالب هنا..."
                rows={4}
              />
              <p className="text-xs text-muted-foreground">
                {"استخدم {{variable}} للمتغيرات"}
              </p>
            </div>

            {/* Hashtags */}
            <div className="space-y-2">
              <Label>الهاشتاقات الافتراضية</Label>
              <Input
                value={hashtagsInput}
                onChange={(e) => setHashtagsInput(e.target.value)}
                placeholder="#صلني، #عائلة، #تواصل"
                dir="ltr"
              />
              <p className="text-xs text-muted-foreground">
                مفصولة بفاصلة
              </p>
            </div>

            {/* Tone + Is Recurring */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>النبرة</Label>
                <Select
                  value={formData.default_tone || ""}
                  onValueChange={(v) =>
                    setFormData((f) => ({
                      ...f,
                      default_tone: (v || null) as SocialTone | null,
                    }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue placeholder="اختر النبرة" />
                  </SelectTrigger>
                  <SelectContent>
                    {Object.entries(toneLabels).map(([value, label]) => (
                      <SelectItem key={value} value={value}>
                        {label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>متكرر</Label>
                <div className="flex items-center gap-2 pt-2">
                  <Switch
                    checked={formData.is_recurring}
                    onCheckedChange={(checked) =>
                      setFormData((f) => ({ ...f, is_recurring: checked }))
                    }
                  />
                  <span className="text-sm text-muted-foreground">
                    {formData.is_recurring ? "نعم" : "لا"}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSaveTemplate}
              disabled={createTemplate.isPending || updateTemplate.isPending}
            >
              {createTemplate.isPending || updateTemplate.isPending
                ? "جاري الحفظ..."
                : editingTemplate
                ? "تحديث"
                : "إضافة"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
