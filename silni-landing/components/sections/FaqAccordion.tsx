interface FaqItem {
  question: string;
  answer: string;
}

interface FaqAccordionProps {
  items: FaqItem[];
}

export default function FaqAccordion({ items }: FaqAccordionProps) {
  return (
    <div className="space-y-md max-w-3xl mx-auto">
      {items.map((item, i) => (
        <details
          key={i}
          className="group bg-white rounded-card shadow-sm border border-primary-pale/40"
        >
          <summary className="cursor-pointer list-none text-right p-xl flex items-center justify-between gap-md hover:bg-primary-pale/10 transition-colors [&::-webkit-details-marker]:hidden">
            <span className="text-headline-sm text-primary-deep">
              {item.question}
            </span>
            <span className="text-primary text-2xl flex-shrink-0 transition-transform duration-300 group-open:rotate-180">
              ▼
            </span>
          </summary>
          <div className="px-xl pb-xl text-body-lg text-text-secondary leading-relaxed">
            {item.answer}
          </div>
        </details>
      ))}
    </div>
  );
}
