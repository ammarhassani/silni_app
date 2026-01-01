"use client";

import { useState, useMemo } from "react";
import { ChevronDown, ChevronLeft, Check, ExternalLink, Loader2, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { cn } from "@/lib/utils";
import { useRoutesHierarchy, type AppRoute, type RouteCategory } from "@/hooks/use-app-routes";

interface RouteSelectorProps {
  value: string | null | undefined;
  onChange: (value: string) => void;
  placeholder?: string;
  /** Filter to only show routes for specific use cases */
  filter?: {
    /** Only show routes that are public (no auth required) */
    publicOnly?: boolean;
    /** Only show routes that require premium */
    premiumOnly?: boolean;
    /** Only show routes from specific categories */
    categories?: string[];
  };
}

export function RouteSelector({
  value,
  onChange,
  placeholder = "اختر المسار",
  filter,
}: RouteSelectorProps) {
  const [open, setOpen] = useState(false);
  const [expandedCategory, setExpandedCategory] = useState<string | null>(null);

  const { data: routesData, isLoading, error, refetch } = useRoutesHierarchy();

  // Filter routes based on props
  const filteredHierarchy = useMemo(() => {
    if (!routesData) return null;

    const hierarchy: Record<string, { category: RouteCategory; routes: AppRoute[] }> = {};

    for (const [categoryKey, { category, routes }] of Object.entries(routesData.hierarchy)) {
      // Filter by categories if specified
      if (filter?.categories && !filter.categories.includes(categoryKey)) {
        continue;
      }

      // Filter routes
      let filteredRoutes = routes;

      if (filter?.publicOnly) {
        filteredRoutes = filteredRoutes.filter((r) => r.is_public);
      }

      if (filter?.premiumOnly) {
        filteredRoutes = filteredRoutes.filter((r) => r.requires_premium);
      }

      // Only include category if it has routes
      if (filteredRoutes.length > 0) {
        hierarchy[categoryKey] = { category, routes: filteredRoutes };
      }
    }

    return hierarchy;
  }, [routesData, filter]);

  // Find the current route details
  const selectedRoute = useMemo(() => {
    if (!value || !routesData) return null;

    for (const route of routesData.routes) {
      if (route.path === value) {
        return route;
      }
    }

    // Custom route not in database
    return {
      path: value,
      label_ar: value,
      icon: "📍",
    } as Partial<AppRoute>;
  }, [value, routesData]);

  const handleSelect = (path: string) => {
    onChange(path);
    setOpen(false);
  };

  const handleClear = () => {
    onChange("");
    setOpen(false);
  };

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          role="combobox"
          aria-expanded={open}
          className="w-full justify-between font-normal"
        >
          {selectedRoute ? (
            <span className="flex items-center gap-2">
              <span>{selectedRoute.icon}</span>
              <span>{selectedRoute.label_ar}</span>
              <code className="text-xs bg-muted px-1 rounded" dir="ltr">
                {selectedRoute.path}
              </code>
            </span>
          ) : (
            <span className="text-muted-foreground">{placeholder}</span>
          )}
          <ChevronDown className="h-4 w-4 shrink-0 opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-[400px] p-0" align="start">
        <div className="max-h-[400px] overflow-y-auto">
          {/* Loading state */}
          {isLoading && (
            <div className="flex items-center justify-center py-8 text-muted-foreground">
              <Loader2 className="h-5 w-5 ml-2 animate-spin" />
              <span>جاري تحميل المسارات...</span>
            </div>
          )}

          {/* Error state */}
          {error && (
            <div className="p-4 text-center">
              <p className="text-destructive text-sm mb-2">فشل في تحميل المسارات</p>
              <Button
                variant="outline"
                size="sm"
                onClick={() => refetch()}
                className="gap-2"
              >
                <RefreshCw className="h-4 w-4" />
                إعادة المحاولة
              </Button>
            </div>
          )}

          {/* Routes loaded */}
          {!isLoading && !error && filteredHierarchy && (
            <>
              {/* Clear option */}
              {value && (
                <button
                  onClick={handleClear}
                  className="w-full px-3 py-2 text-right text-sm text-muted-foreground hover:bg-muted flex items-center gap-2 border-b"
                >
                  <span>❌</span>
                  <span>إزالة المسار</span>
                </button>
              )}

              {/* Route categories */}
              {Object.entries(filteredHierarchy).map(([categoryKey, { category, routes }]) => (
                <div key={categoryKey} className="border-b last:border-b-0">
                  {/* Category header */}
                  <button
                    onClick={() =>
                      setExpandedCategory(
                        expandedCategory === categoryKey ? null : categoryKey
                      )
                    }
                    className="w-full px-3 py-2.5 flex items-center justify-between hover:bg-muted/50 transition-colors"
                  >
                    <span className="flex items-center gap-2 font-medium">
                      <span className="text-lg">{category.icon}</span>
                      <span>{category.label_ar}</span>
                      <span className="text-xs text-muted-foreground">
                        ({routes.length})
                      </span>
                    </span>
                    <ChevronLeft
                      className={cn(
                        "h-4 w-4 transition-transform",
                        expandedCategory === categoryKey && "-rotate-90"
                      )}
                    />
                  </button>

                  {/* Routes in category */}
                  {expandedCategory === categoryKey && (
                    <div className="bg-muted/30 py-1">
                      {routes.map((route) => (
                        <button
                          key={route.path}
                          onClick={() => handleSelect(route.path)}
                          className={cn(
                            "w-full px-4 py-2 flex items-center justify-between hover:bg-muted transition-colors",
                            value === route.path && "bg-primary/10"
                          )}
                        >
                          <span className="flex items-center gap-2">
                            <span>{route.icon}</span>
                            <span>{route.label_ar}</span>
                            {route.requires_premium && (
                              <span className="text-xs bg-amber-100 text-amber-800 px-1.5 py-0.5 rounded">
                                Premium
                              </span>
                            )}
                          </span>
                          <span className="flex items-center gap-2">
                            <code
                              className="text-xs bg-background px-1.5 py-0.5 rounded"
                              dir="ltr"
                            >
                              {route.path}
                            </code>
                            {value === route.path && (
                              <Check className="h-4 w-4 text-primary" />
                            )}
                          </span>
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              ))}

              {/* Empty state */}
              {Object.keys(filteredHierarchy).length === 0 && (
                <div className="p-4 text-center text-muted-foreground">
                  <p>لا توجد مسارات متاحة</p>
                </div>
              )}

              {/* Custom route input hint */}
              <div className="px-3 py-2 text-xs text-muted-foreground border-t bg-muted/20">
                <ExternalLink className="h-3 w-3 inline ml-1" />
                يمكنك أيضاً كتابة مسار مخصص في الحقل النصي
              </div>
            </>
          )}
        </div>
      </PopoverContent>
    </Popover>
  );
}
