import type { SocialContentType } from '@/types/database';

export interface CulturalEvent {
  key: string;
  nameAr: string;
  nameEn: string;
  emoji: string;
  /** Approximate start date (month, day) — Hijri dates are approximate for Gregorian */
  startMonth: number;
  startDay: number;
  /** Duration in days */
  durationDays: number;
  /** How many days before the event to start suggesting content */
  leadTimeDays: number;
  /** Family-oriented themes for content generation */
  themes: string[];
  /** Emotional angles for posts */
  emotionalAngles: string[];
  /** Suggested content types that work well for this event */
  suggestedContentTypes: SocialContentType[];
  /** Year-specific Gregorian dates (since Hijri shifts ~11 days/year) */
  gregorianDates: Record<number, { start: string; end: string }>;
}

export const CULTURAL_EVENTS: CulturalEvent[] = [
  {
    key: 'ramadan',
    nameAr: 'شهر رمضان',
    nameEn: 'Ramadan',
    emoji: '🌙',
    startMonth: 2, // Approximate Gregorian month for 2026
    startDay: 18,
    durationDays: 30,
    leadTimeDays: 14,
    themes: [
      'صلة الرحم في رمضان',
      'الإفطار الجماعي مع العائلة',
      'تبادل الأطباق مع الجيران والأقارب',
      'السحور العائلي',
      'العشر الأواخر وصلة الأرحام',
      'زيارة الأقارب المسنين في رمضان',
    ],
    emotionalAngles: [
      'الحنين لأجواء رمضان العائلية',
      'الامتنان للعائلة',
      'تجديد العلاقات العائلية',
      'الروحانية والترابط الأسري',
    ],
    suggestedContentTypes: ['hadith', 'family_tip', 'occasion'],
    gregorianDates: {
      2026: { start: '2026-02-18', end: '2026-03-19' },
      2027: { start: '2027-02-08', end: '2027-03-09' },
    },
  },
  {
    key: 'eid_al_fitr',
    nameAr: 'عيد الفطر',
    nameEn: 'Eid al-Fitr',
    emoji: '🎉',
    startMonth: 3,
    startDay: 20,
    durationDays: 3,
    leadTimeDays: 7,
    themes: [
      'تهاني العيد للعائلة',
      'العيدية وفرحة الأطفال',
      'صلاة العيد مع الأهل',
      'زيارات العيد العائلية',
      'استعادة ذكريات الأعياد',
    ],
    emotionalAngles: [
      'فرحة العيد',
      'الحنين لأعياد الطفولة',
      'الامتنان بعد رمضان',
      'البهجة والاحتفال',
    ],
    suggestedContentTypes: ['occasion', 'family_tip', 'cta'],
    gregorianDates: {
      2026: { start: '2026-03-20', end: '2026-03-22' },
      2027: { start: '2027-03-10', end: '2027-03-12' },
    },
  },
  {
    key: 'hajj_season',
    nameAr: 'موسم الحج',
    nameEn: 'Hajj Season',
    emoji: '🕋',
    startMonth: 5,
    startDay: 20,
    durationDays: 10,
    leadTimeDays: 14,
    themes: [
      'الدعاء للحجاج من العائلة',
      'استقبال الحجاج العائدين',
      'يوم عرفة والصيام',
      'التواصل مع الأقارب الحجاج',
    ],
    emotionalAngles: [
      'الشوق والدعاء',
      'الفخر العائلي',
      'الروحانية',
      'الترابط العائلي',
    ],
    suggestedContentTypes: ['hadith', 'family_tip', 'occasion'],
    gregorianDates: {
      2026: { start: '2026-05-20', end: '2026-05-29' },
      2027: { start: '2027-05-10', end: '2027-05-19' },
    },
  },
  {
    key: 'eid_al_adha',
    nameAr: 'عيد الأضحى',
    nameEn: 'Eid al-Adha',
    emoji: '🐑',
    startMonth: 5,
    startDay: 27,
    durationDays: 4,
    leadTimeDays: 7,
    themes: [
      'الأضحية وتوزيعها على العائلة',
      'تهاني العيد',
      'لمة العيد العائلية',
      'زيارة الأقارب في العيد',
    ],
    emotionalAngles: [
      'التضحية والعطاء',
      'فرحة العيد',
      'الكرم العائلي',
      'صلة الرحم',
    ],
    suggestedContentTypes: ['occasion', 'family_tip', 'cta'],
    gregorianDates: {
      2026: { start: '2026-05-27', end: '2026-05-30' },
      2027: { start: '2027-05-17', end: '2027-05-20' },
    },
  },
  {
    key: 'islamic_new_year',
    nameAr: 'رأس السنة الهجرية',
    nameEn: 'Islamic New Year',
    emoji: '🌟',
    startMonth: 6,
    startDay: 17,
    durationDays: 1,
    leadTimeDays: 5,
    themes: [
      'بداية جديدة مع العائلة',
      'تأمل في صلة الأرحام',
      'أهداف عائلية للسنة الجديدة',
    ],
    emotionalAngles: [
      'التجديد والأمل',
      'الامتنان للماضي',
      'التطلع للمستقبل',
    ],
    suggestedContentTypes: ['family_tip', 'occasion'],
    gregorianDates: {
      2026: { start: '2026-06-17', end: '2026-06-17' },
      2027: { start: '2027-06-07', end: '2027-06-07' },
    },
  },
  {
    key: 'saudi_national_day',
    nameAr: 'اليوم الوطني السعودي',
    nameEn: 'Saudi National Day',
    emoji: '🇸🇦',
    startMonth: 9,
    startDay: 23,
    durationDays: 1,
    leadTimeDays: 7,
    themes: [
      'العائلة والوطن',
      'ذكريات عائلية وطنية',
      'الاحتفال مع العائلة',
      'قيم الترابط الوطني والعائلي',
    ],
    emotionalAngles: [
      'الفخر الوطني',
      'الانتماء',
      'الذكريات العائلية',
      'الاحتفال',
    ],
    suggestedContentTypes: ['family_tip', 'occasion', 'cta'],
    gregorianDates: {
      2026: { start: '2026-09-23', end: '2026-09-23' },
      2027: { start: '2027-09-23', end: '2027-09-23' },
    },
  },
  {
    key: 'school_break_semester1',
    nameAr: 'إجازة الفصل الأول',
    nameEn: 'First Semester Break',
    emoji: '📚',
    startMonth: 12,
    startDay: 20,
    durationDays: 14,
    leadTimeDays: 7,
    themes: [
      'أنشطة عائلية في الإجازة',
      'زيارة الأجداد في الإجازة',
      'رحلات عائلية',
      'وقت نوعي مع الأبناء',
    ],
    emotionalAngles: [
      'الفرح بالإجازة',
      'قضاء الوقت مع العائلة',
      'صنع الذكريات',
    ],
    suggestedContentTypes: ['family_tip', 'cta'],
    gregorianDates: {
      2026: { start: '2026-12-20', end: '2027-01-02' },
      2027: { start: '2027-12-20', end: '2028-01-02' },
    },
  },
];

/**
 * Get events that are within their lead time or currently active.
 * Used by the content generator to auto-suggest topics.
 */
export function getUpcomingEvents(referenceDate?: Date): CulturalEvent[] {
  const now = referenceDate ?? new Date();
  const currentYear = now.getFullYear();

  return CULTURAL_EVENTS.filter((event) => {
    const dates = event.gregorianDates[currentYear];
    if (!dates) return false;

    const start = new Date(dates.start);
    const end = new Date(dates.end);

    // Include if within lead time before start, or during the event
    const leadStart = new Date(start);
    leadStart.setDate(leadStart.getDate() - event.leadTimeDays);

    return now >= leadStart && now <= end;
  });
}

/**
 * Get the next upcoming event (closest to now).
 */
export function getNextEvent(referenceDate?: Date): CulturalEvent | null {
  const now = referenceDate ?? new Date();
  const currentYear = now.getFullYear();

  let closest: CulturalEvent | null = null;
  let closestDiff = Infinity;

  for (const event of CULTURAL_EVENTS) {
    const dates = event.gregorianDates[currentYear];
    if (!dates) continue;

    const start = new Date(dates.start);
    const diff = start.getTime() - now.getTime();

    if (diff > 0 && diff < closestDiff) {
      closestDiff = diff;
      closest = event;
    }
  }

  return closest;
}

/**
 * Build occasion context string for AI content generation.
 * Includes themes and emotional angles for the event.
 */
export function buildOccasionContext(event: CulturalEvent): string {
  const lines = [
    `المناسبة: ${event.nameAr} ${event.emoji}`,
    '',
    'المواضيع المقترحة:',
    ...event.themes.map((t) => `- ${t}`),
    '',
    'الزوايا العاطفية:',
    ...event.emotionalAngles.map((a) => `- ${a}`),
  ];
  return lines.join('\n');
}
