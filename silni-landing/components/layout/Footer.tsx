import Link from "next/link";
import Image from "next/image";
import AppStoreBadge from "@/components/ui/AppStoreBadge";

const socialLinks = [
  {
    href: "https://x.com/silniapp",
    label: "X",
    icon: (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
        <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
      </svg>
    ),
  },
  {
    href: "https://instagram.com/silniapp",
    label: "Instagram",
    icon: (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z" />
      </svg>
    ),
  },
];

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
      { href: "mailto:silniapp@outlook.com", label: "تواصل معنا" },
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
            <div className="flex items-center gap-md mt-lg">
              {socialLinks.map((social) => (
                <a
                  key={social.href}
                  href={social.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label={social.label}
                  className="text-white/60 hover:text-white transition-colors"
                >
                  {social.icon}
                </a>
              ))}
            </div>
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
