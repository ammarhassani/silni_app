import type { Metadata } from "next";
import { cairo, poppins, amiri } from "@/lib/fonts";
import SmoothScrollProvider from "@/components/providers/SmoothScrollProvider";
import "./globals.css";

export const metadata: Metadata = {
  title: "صِلني — حافظ على صلة الرحم",
  description:
    "صلة الرحم فريضة وصِلني يساعدك تحافظ عليها. تتبّع تواصلك مع أقاربك، تذكيرات ذكية، وإحصائيات تحفّزك.",
  keywords: ["صلة الرحم", "عائلة", "تواصل", "إسلام", "تطبيق", "صلني"],
  openGraph: {
    title: "صِلني — حافظ على صلة الرحم",
    description: "صلة الرحم فريضة وصِلني يساعدك تحافظ عليها.",
    locale: "ar_SA",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="ar"
      dir="rtl"
      className={`${cairo.variable} ${poppins.variable} ${amiri.variable}`}
    >
      <body className="font-cairo antialiased">
        <SmoothScrollProvider>{children}</SmoothScrollProvider>
      </body>
    </html>
  );
}
