"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { toast } from "sonner";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        toast.error(error.message);
        return;
      }

      // Get the logged in user
      const { data: { user } } = await supabase.auth.getUser();

      // Check if user is admin
      const { data: profile, error: profileError } = await supabase
        .from("profiles")
        .select("role")
        .eq("id", user?.id)
        .single();

      console.log("Profile check:", { profile, profileError, userId: user?.id });

      // TODO: Re-enable admin check after setup
      // if (profileError || profile?.role !== "admin") {
      //   await supabase.auth.signOut();
      //   toast.error("ليس لديك صلاحية الوصول للوحة التحكم");
      //   return;
      // }

      toast.success("تم تسجيل الدخول بنجاح");
      router.push("/dashboard");
      router.refresh();
    } catch {
      toast.error("حدث خطأ أثناء تسجيل الدخول");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-silni-teal/10 via-background to-silni-gold/10">
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-1/4 -right-20 w-96 h-96 bg-silni-teal/5 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 -left-20 w-96 h-96 bg-silni-gold/5 rounded-full blur-3xl" />
      </div>

      <Card className="w-full max-w-md mx-4 relative">
        <CardHeader className="text-center space-y-4">
          <div className="mx-auto w-16 h-16 bg-gradient-to-br from-silni-teal to-silni-gold rounded-2xl flex items-center justify-center shadow-lg">
            <span className="text-white text-2xl font-bold">صِ</span>
          </div>
          <div>
            <CardTitle className="text-2xl">لوحة تحكم صِلني</CardTitle>
            <CardDescription className="mt-2">
              سجّل دخولك للوصول إلى لوحة الإدارة
            </CardDescription>
          </div>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleLogin} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">البريد الإلكتروني</Label>
              <Input
                id="email"
                type="email"
                placeholder="admin@silni.app"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                dir="ltr"
                className="text-left"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">كلمة المرور</Label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                dir="ltr"
                className="text-left"
              />
            </div>
            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? "جاري تسجيل الدخول..." : "تسجيل الدخول"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
