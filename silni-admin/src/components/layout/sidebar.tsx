"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import {
  LayoutDashboard,
  BookOpen,
  Trophy,
  Bell,
  Palette,
  Brain,
  CreditCard,
  Shield,
  Settings,
  ChevronDown,
  ChevronLeft,
  Quote,
  MessageSquare,
  Image,
  Star,
  Award,
  TrendingUp,
  Target,
  Flame,
  FileText,
  Clock,
  Paintbrush,
  Sparkles,
  Layers,
  MessageCircle,
  Sliders,
  Crown,
  Package,
  Lock,
  Zap,
  AlertCircle,
  Grid,
  Route,
  Gift,
  Key,
  Send,
} from "lucide-react";
import { useState, useEffect } from "react";
import { Badge } from "@/components/ui/badge";

interface NavItem {
  title: string;
  href: string;
  icon: React.ElementType;
  badge?: string;
  children?: NavItem[];
}

const navigation: NavItem[] = [
  {
    title: "لوحة التحكم",
    href: "/dashboard",
    icon: LayoutDashboard,
  },
  {
    title: "إدارة المحتوى",
    href: "/content",
    icon: BookOpen,
    children: [
      { title: "الأحاديث", href: "/content/hadith", icon: BookOpen },
      { title: "الاقتباسات", href: "/content/quotes", icon: Quote },
      { title: "رسالة اليوم", href: "/content/motd", icon: MessageSquare },
      { title: "البانرات", href: "/content/banners", icon: Image },
    ],
  },
  {
    title: "الذكاء الاصطناعي",
    href: "/ai",
    icon: Brain,
    badge: "واصل",
    children: [
      { title: "الهوية", href: "/ai/identity", icon: Sparkles },
      { title: "الشخصية", href: "/ai/personality", icon: MessageCircle },
      { title: "أوضاع الاستشارة", href: "/ai/modes", icon: MessageSquare },
      { title: "الاقتراحات", href: "/ai/prompts", icon: Quote },
      { title: "المعاملات", href: "/ai/parameters", icon: Sliders },
      { title: "المناسبات والنبرات", href: "/ai/occasions", icon: Star },
      { title: "الذاكرة", href: "/ai/memory", icon: Brain },
      { title: "البث المباشر", href: "/ai/streaming", icon: Zap },
      { title: "رسائل الأخطاء", href: "/ai/errors", icon: AlertCircle },
    ],
  },
  {
    title: "التلعيب",
    href: "/gamification",
    icon: Trophy,
    children: [
      { title: "النقاط", href: "/gamification/points", icon: Star },
      { title: "الأوسمة", href: "/gamification/badges", icon: Award },
      { title: "المستويات", href: "/gamification/levels", icon: TrendingUp },
      { title: "التحديات", href: "/gamification/challenges", icon: Target },
      { title: "السلسلة", href: "/gamification/streaks", icon: Flame },
    ],
  },
  {
    title: "الاشتراكات",
    href: "/subscriptions",
    icon: CreditCard,
    badge: "MAX",
    children: [
      { title: "الباقات", href: "/subscriptions/tiers", icon: Crown },
      { title: "المنتجات", href: "/subscriptions/products", icon: Package },
      { title: "الميزات", href: "/subscriptions/features", icon: Lock },
      { title: "الفترة التجريبية", href: "/subscriptions/trial", icon: Gift },
    ],
  },
  {
    title: "الإشعارات",
    href: "/notifications",
    icon: Bell,
    children: [
      { title: "الإشعارات الفورية", href: "/notifications/announcements", icon: Send },
      { title: "القوالب", href: "/notifications/templates", icon: FileText },
      { title: "الفترات الزمنية", href: "/notifications/time-slots", icon: Clock },
    ],
  },
  {
    title: "نظام التصميم",
    href: "/design",
    icon: Palette,
    children: [
      { title: "الألوان", href: "/design/colors", icon: Paintbrush },
      { title: "الثيمات", href: "/design/themes", icon: Layers },
      { title: "تأثيرات الأنماط", href: "/design/animations", icon: Sparkles },
      { title: "تأثيرات التحريك", href: "/design/patterns", icon: Grid },
    ],
  },
  {
    title: "الإعدادات",
    href: "/settings",
    icon: Settings,
    children: [
      { title: "مسارات التطبيق", href: "/settings/routes", icon: Route },
      { title: "سجل المفاتيح", href: "/settings/keys", icon: Key },
    ],
  },
];

export function Sidebar() {
  const pathname = usePathname();
  const [openGroups, setOpenGroups] = useState<string[]>([]);
  const [collapsed, setCollapsed] = useState(false);

  // Auto-expand active group on mount
  useEffect(() => {
    const activeGroup = navigation.find(
      (item) => item.children && pathname.startsWith(item.href)
    );
    if (activeGroup && !openGroups.includes(activeGroup.href)) {
      setOpenGroups((prev) => [...prev, activeGroup.href]);
    }
  }, [pathname]);

  const toggleGroup = (href: string) => {
    setOpenGroups((prev) =>
      prev.includes(href) ? prev.filter((h) => h !== href) : [...prev, href]
    );
  };

  const isActive = (href: string) =>
    pathname === href || pathname.startsWith(href + "/");

  const isChildActive = (item: NavItem) =>
    item.children?.some((child) => pathname === child.href);

  return (
    <aside
      className={cn(
        "bg-card border-l border-border flex flex-col h-full transition-all duration-300",
        collapsed ? "w-16" : "w-64"
      )}
    >
      {/* Logo */}
      <div className="p-4 border-b border-border">
        <Link href="/dashboard" className="flex items-center gap-3">
          <div className="w-10 h-10 bg-gradient-to-br from-silni-teal to-silni-gold rounded-xl flex items-center justify-center shadow-lg flex-shrink-0">
            <span className="text-white text-lg font-bold">صِ</span>
          </div>
          {!collapsed && (
            <div>
              <h1 className="font-bold text-lg">صِلني</h1>
              <p className="text-xs text-muted-foreground">لوحة التحكم</p>
            </div>
          )}
        </Link>
      </div>

      {/* Navigation */}
      <nav className="flex-1 overflow-y-auto p-2 space-y-1">
        {navigation.map((item) => (
          <div key={item.href}>
            {item.children ? (
              <div>
                <button
                  onClick={() => toggleGroup(item.href)}
                  className={cn(
                    "w-full flex items-center justify-between px-3 py-2.5 rounded-lg text-sm transition-colors",
                    isActive(item.href) || isChildActive(item)
                      ? "bg-primary/10 text-primary font-medium"
                      : "text-muted-foreground hover:bg-accent hover:text-foreground"
                  )}
                >
                  <div className="flex items-center gap-3">
                    <item.icon className="h-4 w-4 flex-shrink-0" />
                    {!collapsed && (
                      <>
                        <span>{item.title}</span>
                        {item.badge && (
                          <Badge
                            variant="secondary"
                            className="text-[10px] px-1.5 py-0"
                          >
                            {item.badge}
                          </Badge>
                        )}
                      </>
                    )}
                  </div>
                  {!collapsed && (
                    <ChevronDown
                      className={cn(
                        "h-4 w-4 transition-transform duration-200",
                        openGroups.includes(item.href) && "rotate-180"
                      )}
                    />
                  )}
                </button>
                {!collapsed && openGroups.includes(item.href) && (
                  <div className="mr-4 mt-1 space-y-0.5 border-r-2 border-border/50 pr-3">
                    {item.children.map((child) => (
                      <Link
                        key={child.href}
                        href={child.href}
                        className={cn(
                          "flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors",
                          pathname === child.href
                            ? "bg-primary text-primary-foreground font-medium"
                            : "text-muted-foreground hover:bg-accent hover:text-foreground"
                        )}
                      >
                        <child.icon className="h-3.5 w-3.5" />
                        <span>{child.title}</span>
                      </Link>
                    ))}
                  </div>
                )}
              </div>
            ) : (
              <Link
                href={item.href}
                className={cn(
                  "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors",
                  pathname === item.href
                    ? "bg-primary text-primary-foreground font-medium"
                    : "text-muted-foreground hover:bg-accent hover:text-foreground"
                )}
              >
                <item.icon className="h-4 w-4 flex-shrink-0" />
                {!collapsed && <span>{item.title}</span>}
              </Link>
            )}
          </div>
        ))}
      </nav>

      {/* Collapse Toggle */}
      <div className="p-2 border-t border-border">
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-lg text-sm text-muted-foreground hover:bg-accent hover:text-foreground transition-colors"
        >
          <ChevronLeft
            className={cn(
              "h-4 w-4 transition-transform",
              collapsed && "rotate-180"
            )}
          />
          {!collapsed && <span>طي القائمة</span>}
        </button>
      </div>

      {/* Footer */}
      {!collapsed && (
        <div className="p-4 border-t border-border">
          <div className="text-xs text-muted-foreground text-center">
            <span className="font-medium">Silni Admin</span>
            <span className="mx-1">•</span>
            <span>v1.0.0</span>
          </div>
        </div>
      )}
    </aside>
  );
}
