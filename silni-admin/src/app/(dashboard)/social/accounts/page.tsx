"use client";

import { useSocialAccounts, useDisconnectSocialAccount } from "@/hooks/use-social-accounts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Globe,
  ExternalLink,
  Unplug,
  RefreshCw,
  AlertCircle,
} from "lucide-react";
import type { SocialAccount, SocialAccountStatus } from "@/types/database";

const STATUS_CONFIG: Record<SocialAccountStatus, { label: string; className: string }> = {
  connected: { label: "متصل", className: "bg-green-100 text-green-700" },
  expired: { label: "منتهي الصلاحية", className: "bg-amber-100 text-amber-700" },
  disconnected: { label: "غير متصل", className: "bg-gray-100 text-gray-700" },
};

function StatusBadge({ status }: { status: SocialAccountStatus }) {
  const config = STATUS_CONFIG[status];
  return (
    <Badge className={config.className}>
      {config.label}
    </Badge>
  );
}

function AccountCard({
  platform,
  label,
  icon: Icon,
  accentClass,
  connectUrl,
  account,
  onDisconnect,
  isDisconnecting,
}: {
  platform: string;
  label: string;
  icon: React.ElementType;
  accentClass: string;
  connectUrl: string;
  account: SocialAccount | undefined;
  onDisconnect: (id: string) => void;
  isDisconnecting: boolean;
}) {
  const isConnected = account && account.status !== "disconnected";

  return (
    <Card className="overflow-hidden">
      <div className="flex">
        <div className={`w-1.5 ${accentClass}`} />
        <div className="flex-1">
          <CardHeader>
            <CardTitle className="flex items-center gap-3 text-lg">
              <div className={`w-10 h-10 rounded-xl ${accentClass} flex items-center justify-center shadow-sm`}>
                <Icon className="h-5 w-5 text-white" />
              </div>
              {label}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {account && isConnected ? (
              <>
                <div className="flex items-center justify-between">
                  <span className="text-lg font-medium">@{account.account_handle}</span>
                  <StatusBadge status={account.status} />
                </div>

                {account.last_post_at && (
                  <p className="text-sm text-muted-foreground">
                    آخر نشر: {new Date(account.last_post_at).toLocaleDateString("ar")}
                  </p>
                )}

                {account.status === "expired" && (
                  <div className="flex items-center gap-2 text-amber-600 text-sm">
                    <AlertCircle className="h-4 w-4" />
                    <span>يجب إعادة ربط الحساب لتجديد الصلاحية</span>
                  </div>
                )}

                <div className="flex items-center gap-2 pt-2">
                  <Button
                    variant="destructive"
                    size="sm"
                    disabled={isDisconnecting}
                    onClick={() => onDisconnect(account.id)}
                  >
                    {isDisconnecting ? (
                      <RefreshCw className="h-4 w-4 ml-2 animate-spin" />
                    ) : (
                      <Unplug className="h-4 w-4 ml-2" />
                    )}
                    فصل الحساب
                  </Button>
                  {account.status === "expired" && (
                    <Button variant="outline" size="sm" asChild>
                      <a href={connectUrl}>
                        <RefreshCw className="h-4 w-4 ml-2" />
                        إعادة الربط
                      </a>
                    </Button>
                  )}
                </div>
              </>
            ) : (
              <div className="text-center py-6 space-y-4">
                <div className="w-16 h-16 mx-auto bg-muted rounded-2xl flex items-center justify-center">
                  <Icon className="h-8 w-8 text-muted-foreground" />
                </div>
                <p className="text-muted-foreground">غير متصل</p>
                <Button asChild>
                  <a href={connectUrl}>
                    <ExternalLink className="h-4 w-4 ml-2" />
                    ربط الحساب
                  </a>
                </Button>
              </div>
            )}
          </CardContent>
        </div>
      </div>
    </Card>
  );
}

function LoadingSkeleton() {
  return (
    <div className="space-y-6 p-6">
      <div className="space-y-2">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-4 w-96" />
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Skeleton className="h-64 rounded-xl" />
        <Skeleton className="h-64 rounded-xl" />
      </div>
    </div>
  );
}

export default function SocialAccountsPage() {
  const { data: accounts, isLoading } = useSocialAccounts();
  const disconnect = useDisconnectSocialAccount();

  const twitterAccount = accounts?.find((a) => a.platform === "twitter");
  const instagramAccount = accounts?.find((a) => a.platform === "instagram");

  if (isLoading) {
    return <LoadingSkeleton />;
  }

  return (
    <div className="space-y-8 p-6" dir="rtl">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold">الحسابات المتصلة</h1>
        <p className="text-muted-foreground mt-1">
          إدارة حسابات التواصل الاجتماعي المرتبطة
        </p>
      </div>

      {/* Account Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <AccountCard
          platform="twitter"
          label="تويتر / X"
          icon={Globe}
          accentClass="bg-blue-500"
          connectUrl="/api/social/auth/twitter"
          account={twitterAccount}
          onDisconnect={(id) => disconnect.mutate(id)}
          isDisconnecting={disconnect.isPending}
        />

        <AccountCard
          platform="instagram"
          label="إنستغرام"
          icon={Globe}
          accentClass="bg-gradient-to-b from-pink-500 to-purple-500"
          connectUrl="/api/social/auth/instagram"
          account={instagramAccount}
          onDisconnect={(id) => disconnect.mutate(id)}
          isDisconnecting={disconnect.isPending}
        />
      </div>
    </div>
  );
}
