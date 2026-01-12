"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

const supabase = createClient();

// Types for app routes
export interface AppRoute {
  id: string;
  path: string;
  route_key: string;
  label_ar: string;
  label_en: string | null;
  icon: string | null;
  description_ar: string | null;
  category_key: string;
  parent_route_key: string | null;
  sort_order: number;
  is_active: boolean;
  is_public: boolean;
  requires_auth: boolean;
  requires_premium: boolean;
  feature_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface RouteCategory {
  id: string;
  category_key: string;
  label_ar: string;
  label_en: string | null;
  icon: string | null;
  sort_order: number;
  is_active: boolean;
  created_at: string;
}

export interface RoutesHierarchy {
  categories: RouteCategory[];
  routes: AppRoute[];
  // Organized structure for easy consumption
  hierarchy: {
    [categoryKey: string]: {
      category: RouteCategory;
      routes: AppRoute[];
    };
  };
}

// ============ Route Categories ============

export function useRouteCategories() {
  return useQuery({
    queryKey: ["admin", "route-categories"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("admin_route_categories")
        .select("*")
        .eq("is_active", true)
        .order("sort_order", { ascending: true });

      if (error) throw error;
      return data as RouteCategory[];
    },
    staleTime: 60000, // 1 minute - routes don't change often
  });
}

// ============ App Routes ============

export function useAppRoutes(filters?: { categoryKey?: string; activeOnly?: boolean }) {
  return useQuery({
    queryKey: ["admin", "app-routes", filters],
    queryFn: async () => {
      let query = supabase
        .from("admin_app_routes")
        .select("*")
        .order("sort_order", { ascending: true });

      if (filters?.categoryKey) {
        query = query.eq("category_key", filters.categoryKey);
      }
      if (filters?.activeOnly !== false) {
        query = query.eq("is_active", true);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data as AppRoute[];
    },
    staleTime: 60000,
  });
}

// ============ Combined Hierarchy (for RouteSelector) ============

export function useRoutesHierarchy(options?: { includeInactive?: boolean }) {
  const includeInactive = options?.includeInactive ?? false;

  return useQuery({
    queryKey: ["admin", "routes-hierarchy", { includeInactive }],
    queryFn: async () => {
      // Fetch categories and routes in parallel
      let categoriesQuery = supabase
        .from("admin_route_categories")
        .select("*")
        .order("sort_order", { ascending: true });

      let routesQuery = supabase
        .from("admin_app_routes")
        .select("*")
        .order("sort_order", { ascending: true });

      // Only filter by is_active if not including inactive
      if (!includeInactive) {
        categoriesQuery = categoriesQuery.eq("is_active", true);
        routesQuery = routesQuery.eq("is_active", true);
      }

      const [categoriesRes, routesRes] = await Promise.all([
        categoriesQuery,
        routesQuery,
      ]);

      if (categoriesRes.error) throw categoriesRes.error;
      if (routesRes.error) throw routesRes.error;

      const categories = categoriesRes.data as RouteCategory[];
      const routes = routesRes.data as AppRoute[];

      // Build hierarchy
      const hierarchy: RoutesHierarchy["hierarchy"] = {};

      for (const category of categories) {
        hierarchy[category.category_key] = {
          category,
          routes: routes.filter((r) => r.category_key === category.category_key),
        };
      }

      return {
        categories,
        routes,
        hierarchy,
      } as RoutesHierarchy;
    },
    staleTime: 60000,
  });
}

// ============ Mutations ============

export function useCreateRoute() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (route: Omit<AppRoute, "id" | "created_at" | "updated_at">) => {
      const { data, error } = await supabase
        .from("admin_app_routes")
        .insert(route)
        .select()
        .single();

      if (error) throw error;
      return data as AppRoute;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "app-routes"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "routes-hierarchy"] });
      toast.success("تم إضافة المسار بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إضافة المسار: ${error.message}`);
    },
  });
}

export function useUpdateRoute() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...route }: Partial<AppRoute> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_app_routes")
        .update({ ...route, updated_at: new Date().toISOString() })
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as AppRoute;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "app-routes"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "routes-hierarchy"] });
      toast.success("تم تحديث المسار بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث المسار: ${error.message}`);
    },
  });
}

export function useDeleteRoute() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("admin_app_routes").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "app-routes"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "routes-hierarchy"] });
      toast.success("تم حذف المسار بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف المسار: ${error.message}`);
    },
  });
}

// ============ Category Mutations ============

export function useCreateRouteCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (category: Omit<RouteCategory, "id" | "created_at">) => {
      const { data, error } = await supabase
        .from("admin_route_categories")
        .insert(category)
        .select()
        .single();

      if (error) throw error;
      return data as RouteCategory;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "route-categories"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "routes-hierarchy"] });
      toast.success("تم إضافة التصنيف بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في إضافة التصنيف: ${error.message}`);
    },
  });
}

export function useUpdateRouteCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...category }: Partial<RouteCategory> & { id: string }) => {
      const { data, error } = await supabase
        .from("admin_route_categories")
        .update(category)
        .eq("id", id)
        .select()
        .single();

      if (error) throw error;
      return data as RouteCategory;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "route-categories"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "routes-hierarchy"] });
      toast.success("تم تحديث التصنيف بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في تحديث التصنيف: ${error.message}`);
    },
  });
}

export function useDeleteRouteCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("admin_route_categories").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "route-categories"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "routes-hierarchy"] });
      toast.success("تم حذف التصنيف بنجاح");
    },
    onError: (error) => {
      toast.error(`فشل في حذف التصنيف: ${error.message}`);
    },
  });
}
