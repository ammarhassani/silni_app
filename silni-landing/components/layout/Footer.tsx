import Link from "next/link";
import Image from "next/image";
import AppStoreBadge from "@/components/ui/AppStoreBadge";

const footerLinks = [
  {
    title: "صِلني",
    links: [
      { href: "/about", label: "عن صِلني" },
      { href: "/features", label: "المميزات" },
      { href: "/pricing", label: "الأسعار" },
    ],
  },
  {
    title: "الدعم",
    links: [
      { href: "/faq", label: "الأسئلة الشائعة" },
      { href: "mailto:support@silni.app", label: "تواصل معنا" },
    ],
  },
  {
    title: "قانوني",
    links: [
      { href: "/privacy", label: "سياسة الخصوصية" },
      { href: "/terms", label: "شروط الاستخدام" },
    ],
  },
];

export default function Footer() {
  return (
    <footer className="gradient-deep text-white">
      <div className="max-w-7xl mx-auto px-md lg:px-xl py-3xl">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-2xl">
          <div className="lg:col-span-1">
            <div className="flex items-center gap-2 mb-lg">
              <Image
                src="/images/app_icon.png"
                alt="صِلني"
                width={48}
                height={48}
                className="rounded-xl"
              />
              <span className="text-headline-md font-bold">صِلني</span>
            </div>
            <p className="text-white/70 text-body-lg mb-lg leading-relaxed">
              حافظ على صلة الرحم مع تطبيق صِلني
            </p>
            <AppStoreBadge />
          </div>

          {footerLinks.map((group) => (
            <div key={group.title}>
              <h3 className="font-bold text-lg mb-md">{group.title}</h3>
              <ul className="space-y-sm">
                {group.links.map((link) => (
                  <li key={link.href}>
                    <Link
                      href={link.href}
                      className="text-white/60 hover:text-white transition-colors text-body-lg"
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="border-t border-white/10 mt-2xl pt-lg text-center text-white/40 text-body-md">
          <p>© {new Date().getFullYear()} صِلني. جميع الحقوق محفوظة.</p>
        </div>
      </div>
    </footer>
  );
}
