import type { Metadata } from "next";
import TextReveal from "@/components/animations/TextReveal";
import IslamicPattern from "@/components/animations/IslamicPattern";
import FaqAccordion from "@/components/sections/FaqAccordion";

export const metadata: Metadata = {
  title: "الأسئلة الشائعة — صِلني",
  description: "إجابات على الأسئلة الأكثر شيوعاً عن تطبيق صِلني.",
};

const faqs = [
  {
    question: "هل التطبيق مجاني؟",
    answer: "نعم! تقدر تستخدم صِلني مجاناً مع المميزات الأساسية — تسجيل التواصل، ٣ تذكيرات، شجرة العائلة، والإنجازات. باقة ماكس تعطيك تذكيرات غير محدودة والمساعد الذكي.",
  },
  {
    question: "هل بياناتي آمنة؟",
    answer: "بياناتك مشفّرة ومحمية بالكامل. ما نبيع ولا نشارك معلوماتك مع أي طرف ثالث. خصوصيتك أولويتنا.",
  },
  {
    question: "هل أقدر أستخدم التطبيق بدون إنترنت؟",
    answer: "نعم! صِلني يعمل بدون إنترنت. تقدر تسجّل تواصلك وتشوف بياناتك. لما يرجع الإنترنت، كل شي يتزامن تلقائياً.",
  },
  {
    question: "كيف التذكيرات تشتغل؟",
    answer: "تقدر تحدد لكل قريب جدول تذكير — يومي، أسبوعي، شهري، أو كل جمعة. التطبيق يرسلك إشعار في الوقت المناسب.",
  },
  {
    question: "ما هو المساعد الذكي؟",
    answer: "المساعد الذكي يستخدم الذكاء الاصطناعي ليساعدك تكتب رسائل، يقترح مواضيع للمحادثة، ويعطيك نصائح لتحسين علاقاتك. متاح في باقة ماكس.",
  },
  {
    question: "هل التطبيق متاح على أندرويد؟",
    answer: "حالياً صِلني متاح على iOS فقط (آيفون وآيباد). نسخة أندرويد قادمة قريباً إن شاء الله. سجّل بريدك عشان نبلّغك أول ما تنزل.",
  },
  {
    question: "كيف ألغي الاشتراك؟",
    answer: "تقدر تلغي اشتراكك في أي وقت من إعدادات App Store على جهازك. الإلغاء يسري نهاية الفترة الحالية.",
  },
  {
    question: "هل فيه تجربة مجانية لباقة ماكس؟",
    answer: "نعم! تقدر تجرّب باقة ماكس مجاناً لمدة أسبوع كامل. لو ما عجبتك، ألغِ قبل نهاية الأسبوع وما يتم خصم أي مبلغ.",
  },
];

export default function FaqPage() {
  return (
    <>
      <section className="relative gradient-hero text-white pt-[120px] pb-3xl overflow-hidden">
        <IslamicPattern color="#81C784" opacity={0.05} />
        <div className="max-w-4xl mx-auto px-md lg:px-xl relative z-10 text-center">
          <TextReveal text="الأسئلة الشائعة" as="h1" className="text-hero mb-md" />
        </div>
      </section>

      <section className="py-3xl bg-surface">
        <div className="max-w-7xl mx-auto px-md lg:px-xl">
          <FaqAccordion items={faqs} />
        </div>
      </section>
    </>
  );
}
