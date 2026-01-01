"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { toast } from "sonner";
import { Loader2, ShieldAlert } from "lucide-react";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();
  const supabase = createClient();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      // Step 1: Sign in with email/password
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (signInError) {
        if (signInError.message.includes("Invalid login")) {
          setError("البريد الإلكتروني أو كلمة المرور غير صحيحة");
        } else {
          setError(signInError.message);
        }
        return;
      }

      // Step 2: Get the logged in user
      const { data: { user } } = await supabase.auth.getUser();

      if (!user) {
        setError("فشل في الحصول على بيانات المستخدم");
        return;
      }

      // Step 3: Check if user is admin
      const { data: profile, error: profileError } = await supabase
        .from("profiles")
        .select("role, display_name")
        .eq("id", user.id)
        .single();

      if (profileError) {
        // Profile doesn't exist - sign out and show error
        await supabase.auth.signOut();
        setError("لم يتم العثور على ملف تعريف المستخدم. تواصل مع المسؤول.");
        return;
      }

      if (profile?.role !== "admin") {
        // Not an admin - sign out and show error
        await supabase.auth.signOut();
        setError("ليس لديك صلاحية الوصول للوحة التحكم. هذه اللوحة للمسؤولين فقط.");
        return;
      }

      // Success - redirect to dashboard
      toast.success(`مرحباً ${profile.display_name || email}`);
      router.push("/dashboard");
      router.refresh();
    } catch {
      setError("حدث خطأ غير متوقع. حاول مرة أخرى.");
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
            {error && (
              <Alert variant="destructive">
                <ShieldAlert className="h-4 w-4" />
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}
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
              {loading ? (
                <>
                  <Loader2 className="ml-2 h-4 w-4 animate-spin" />
                  جاري تسجيل الدخول...
                </>
              ) : (
                "تسجيل الدخول"
              )}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
