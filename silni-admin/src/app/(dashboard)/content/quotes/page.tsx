"use client";

import { useState, useMemo } from "react";
import { useQuotesList, useDeleteQuote, useUpdateQuote, useQuoteCategories } from "@/hooks/use-content";
import { useDebounce } from "@/hooks/use-debounce";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
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
import { Plus, Search, MoreHorizontal, Pencil, Trash2, Eye, EyeOff, Loader2, Quote } from "lucide-react";
import { QuoteDialog } from "./quote-dialog";
import type { AdminQuote } from "@/types/database";
import { truncate } from "@/lib/utils";

export default function QuotesPage() {
  const [search, setSearch] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<string>("all");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedQuote, setSelectedQuote] = useState<AdminQuote | null>(null);

  const debouncedSearch = useDebounce(search, 300);

  const filters = useMemo(() => ({
    category: categoryFilter !== "all" ? categoryFilter : undefined,
    search: debouncedSearch || undefined,
  }), [categoryFilter, debouncedSearch]);

  const {
    data,
    isLoading,
    isFetchingNextPage,
    hasNextPage,
    fetchNextPage,
  } = useQuotesList(filters);

  const { data: categories } = useQuoteCategories() as { data: string[] | undefined };
  const deleteQuote = useDeleteQuote();
  const updateQuote = useUpdateQuote();

  const quotes = useMemo(() => {
    return data?.pages.flatMap((page) => page.items) ?? [];
  }, [data]);

  const totalCount = data?.pages[0]?.totalCount ?? 0;

  const handleEdit = (quote: AdminQuote) => {
    setSelectedQuote(quote);
    setDialogOpen(true);
  };

  const handleCreate = () => {
    setSelectedQuote(null);
    setDialogOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (confirm("هل أنت متأكد من حذف هذا الاقتباس؟")) {
      deleteQuote.mutate(id);
    }
  };

  const handleToggleActive = (quote: AdminQuote) => {
    updateQuote.mutate({
      id: quote.id,
      is_active: !quote.is_active,
    });
  };

  const categoryLabels: Record<string, string> = {
    wisdom: "حكمة",
    motivation: "تحفيز",
    family: "عائلة",
    islamic: "إسلامي",
    general: "عام",
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">الاقتباسات</h1>
          <p className="text-muted-foreground mt-1">
            إدارة مجموعة الاقتباسات والحكم المعروضة في التطبيق
            {totalCount > 0 && (
              <span className="mr-2">({totalCount} اقتباس)</span>
            )}
          </p>
        </div>
        <Button onClick={handleCreate}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة اقتباس
        </Button>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-4">
            <div className="relative flex-1">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="بحث في الاقتباسات..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pr-10"
              />
            </div>
            <Select value={categoryFilter} onValueChange={setCategoryFilter}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="جميع التصنيفات" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">جميع التصنيفات</SelectItem>
                {categories?.map((cat) => (
                  <SelectItem key={cat} value={cat}>
                    {categoryLabels[cat] || cat}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-4">
              {[...Array(5)].map((_, i) => (
                <Skeleton key={i} className="h-16 w-full" />
              ))}
            </div>
          ) : quotes.length === 0 ? (
            <div className="text-center py-12">
              <Quote className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">لا توجد اقتباسات</p>
              <Button variant="outline" className="mt-4" onClick={handleCreate}>
                <Plus className="h-4 w-4 ml-2" />
                إضافة أول اقتباس
              </Button>
            </div>
          ) : (
            <>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-[400px]">نص الاقتباس</TableHead>
                    <TableHead>المؤلف</TableHead>
                    <TableHead>التصنيف</TableHead>
                    <TableHead>الأولوية</TableHead>
                    <TableHead>الحالة</TableHead>
                    <TableHead className="w-[100px]">الإجراءات</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {quotes.map((quote) => (
                    <TableRow key={quote.id}>
                      <TableCell className="font-medium">
                        {truncate(quote.quote_text, 100)}
                      </TableCell>
                      <TableCell>{quote.author || "-"}</TableCell>
                      <TableCell>
                        <Badge variant="secondary">
                          {categoryLabels[quote.category] || quote.category}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">{quote.display_priority}</Badge>
                      </TableCell>
                      <TableCell>
                        <Switch
                          checked={quote.is_active}
                          onCheckedChange={() => handleToggleActive(quote)}
                          disabled={updateQuote.isPending}
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
                            <DropdownMenuItem onClick={() => handleEdit(quote)}>
                              <Pencil className="h-4 w-4 ml-2" />
                              تعديل
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={() => handleToggleActive(quote)}>
                              {quote.is_active ? (
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
                              onClick={() => handleDelete(quote.id)}
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

              {hasNextPage && (
                <div className="flex justify-center mt-6">
                  <Button
                    variant="outline"
                    onClick={() => fetchNextPage()}
                    disabled={isFetchingNextPage}
                  >
                    {isFetchingNextPage ? (
                      <>
                        <Loader2 className="h-4 w-4 ml-2 animate-spin" />
                        جاري التحميل...
                      </>
                    ) : (
                      "تحميل المزيد"
                    )}
                  </Button>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      <QuoteDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        quote={selectedQuote}
      />
    </div>
  );
}
