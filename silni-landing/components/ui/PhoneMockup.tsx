import Image from "next/image";

interface PhoneMockupProps {
  screenshot?: string;
  className?: string;
}

export default function PhoneMockup({
  screenshot = "/images/app_icon.png",
  className = "",
}: PhoneMockupProps) {
  return (
    <div className={`relative animate-fade-up ${className}`} style={{ animationDelay: "0.4s" }}>
      <div className="relative w-[280px] h-[580px] mx-auto">
        <div className="absolute inset-0 bg-gray-900 rounded-[3rem] shadow-2xl border-[6px] border-gray-800">
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[120px] h-[30px] bg-gray-900 rounded-b-2xl z-10" />
          <div className="absolute inset-[3px] rounded-[2.5rem] overflow-hidden bg-primary-deep flex items-center justify-center">
            <Image
              src={screenshot}
              alt="صِلني"
              width={260}
              height={560}
              className="object-cover"
            />
          </div>
        </div>
        <div className="absolute -inset-4 bg-gold/20 blur-3xl rounded-full -z-10" />
      </div>
    </div>
  );
}
