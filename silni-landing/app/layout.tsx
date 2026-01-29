import type { Metadata } from "next";
import { cairo, poppins, amiri } from "@/lib/fonts";
import SmoothScrollProvider from "@/components/providers/SmoothScrollProvider";
import Navbar from "@/components/layout/Navbar";
import Footer from "@/components/layout/Footer";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://silni.app"),
  title: {
    default: "صِلني — حافظ على صلة الرحم",
    template: "%s | صِلني",
  },
  description: "صلة الرحم فريضة وصِلني يساعدك تحافظ عليها. تتبّع تواصلك مع أقاربك، تذكيرات ذكية، وإحصائيات تحفّزك.",
  keywords: ["صلة الرحم", "عائلة", "تواصل", "إسلام", "تطبيق", "صلني", "silni"],
  authors: [{ name: "صِلني" }],
  openGraph: {
    title: "صِلني — حافظ على صلة الرحم",
    description: "صلة الرحم فريضة وصِلني يساعدك تحافظ عليها.",
    locale: "ar_SA",
    type: "website",
    siteName: "صِلني",
  },
  twitter: {
    card: "summary_large_image",
    title: "صِلني — حافظ على صلة الرحم",
    description: "صلة الرحم فريضة وصِلني يساعدك تحافظ عليها.",
  },
  robots: { index: true, follow: true },
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
        <SmoothScrollProvider>
          <Navbar />
          <main>{children}</main>
          <Footer />
        </SmoothScrollProvider>
      </body>
    </html>
  );
}
