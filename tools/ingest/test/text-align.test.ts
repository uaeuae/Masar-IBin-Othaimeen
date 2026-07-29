import { describe, expect, it } from 'vitest';
import {
  anchorMarkers,
  buildLessonText,
  classifyLesson,
  normalizeArabic,
  splitSentences,
  timeSentences,
} from '../src/text-align.js';
import type { StoredLesson } from '../src/store.js';

function lesson(overrides: Partial<StoredLesson>): StoredLesson {
  return {
    youtube_video_id: 'l1',
    position: 1,
    title_ar: 'الدرس الأول',
    duration_seconds: 1000,
    published_at: null,
    thumbnail_url: null,
    status: 'active',
    media: 'audio',
    audio_url: 'https://sounds.example/1.mp3',
    chapters: [],
    ...overrides,
  };
}

describe('normalizeArabic', () => {
  it('folds the variants the site spells inconsistently', () => {
    expect(normalizeArabic('الصَّلَاةُ')).toBe('الصلاه');
    expect(normalizeArabic('أحمد إبراهيم آمن')).toBe('احمد ابراهيم امن'.replace(/ /g, ''));
    expect(normalizeArabic('على ، وسلم .')).toBe('عليوسلم');
  });
});

describe('splitSentences', () => {
  it('splits on Arabic sentence punctuation and newlines', () => {
    expect(splitSentences('الأولى. الثانية؟ الثالثة!\nالرابعة.')).toEqual([
      'الأولى.',
      'الثانية؟',
      'الثالثة!',
      'الرابعة.',
    ]);
  });

  it('re-splits an over-long run at «،» so it never highlights as one blob', () => {
    const long = Array.from({ length: 12 }, (_, i) => `الجزء رقم ${i} من الكلام الطويل،`).join(' ');
    const parts = splitSentences(long, 120);
    expect(parts.length).toBeGreaterThan(1);
    for (const part of parts) expect(part.length).toBeLessThanOrEqual(120);
    // Nothing dropped in the re-split.
    expect(parts.join('').replace(/\s/g, '')).toBe(long.replace(/\s/g, ''));
  });

  it('ignores empty input', () => {
    expect(splitSentences('   ')).toEqual([]);
  });
});

describe('classifyLesson', () => {
  it('separates transcripts from matn indexes by text density', () => {
    const transcript = lesson({
      duration_seconds: 1000,
      chapters: [{ start_seconds: 0, title: 'التفريغ', body: 'ن'.repeat(8000) }],
    });
    const matn = lesson({
      duration_seconds: 1000,
      chapters: [{ start_seconds: 0, title: 'حديث', body: 'ن'.repeat(300) }],
    });
    expect(classifyLesson(transcript)).toBe('transcript');
    expect(classifyLesson(matn)).toBe('matn');
    expect(classifyLesson(lesson({ chapters: [] }))).toBeNull();
  });
});

describe('timeSentences', () => {
  it('spreads the span by character count, monotonically and in bounds', () => {
    const timed = timeSentences(['قصيرة.', 'ط'.repeat(100), 'أخيرة.'], 100, 200);
    const times = timed.map((s) => s.t!);
    expect(times[0]).toBe(100);
    expect(times).toEqual([...times].sort((a, b) => a - b));
    for (const t of times) expect(t).toBeLessThan(200);
  });

  it('leaves sentences untimed when the span is unusable', () => {
    expect(timeSentences(['أ.', 'ب.'], 200, 100).every((s) => s.t === undefined)).toBe(true);
  });
});

describe('anchorMarkers', () => {
  const transcript =
    'مقدمة الدرس وكلام تمهيدي طويل جدا يملأ الوقت الأول من الشريط. ' +
    'قال المؤلف: باب صفة الصلاة وشروطها، ثم شرع في الشرح المطول. ' +
    'ثم قال المؤلف: باب سجود السهو وأحكامه، وتكلم عليه.';

  it('anchors markers it finds, in order', () => {
    const anchors = anchorMarkers(
      transcript,
      [
        { start_seconds: 20, title: 'باب صفة الصلاة وشروطها' },
        { start_seconds: 40, title: 'باب سجود السهو وأحكامه' },
      ],
      0,
    );
    expect(anchors).toHaveLength(2);
    expect(anchors[0]!.seconds).toBe(20);
    expect(anchors[0]!.charOffset).toBeLessThan(anchors[1]!.charOffset);
  });

  it('drops a marker whose implied rate is out of range', () => {
    // 1 second in, but ~60 chars deep: ~60 chars/s, far above real speech.
    expect(
      anchorMarkers(transcript, [{ start_seconds: 1, title: 'باب صفة الصلاة وشروطها' }], 0),
    ).toEqual([]);
  });

  it('never lets a re-quote drag the timeline backwards', () => {
    const repeated = `${transcript} وأعاد: باب صفة الصلاة وشروطها مرة أخرى في آخر الدرس.`;
    const anchors = anchorMarkers(
      repeated,
      [
        { start_seconds: 40, title: 'باب سجود السهو وأحكامه' },
        { start_seconds: 80, title: 'باب صفة الصلاة وشروطها' },
      ],
      0,
    );
    const offsets = anchors.map((a) => a.charOffset);
    expect(offsets).toEqual([...offsets].sort((a, b) => a - b));
  });

  it('ignores titles too short to match on', () => {
    expect(anchorMarkers(transcript, [{ start_seconds: 20, title: 'باب' }], 0)).toEqual([]);
  });
});

describe('buildLessonText', () => {
  it('sections a blob transcript at its matched markers', () => {
    // Density has to look like real speech (~8 chars/s) or the lesson
    // classifies as matn.
    const body =
      'الحمد لله رب العالمين وبعد، فهذه مقدمة الدرس وفيها كلام طويل يشغل أول الشريط كله تقريبا. '.repeat(
        30,
      ) +
      'قال المؤلف: تجب على كل مسلم مكلف إلا حائضا ونفساء، وهذا هو موضع الشاهد. ' +
      'ثم شرع رحمه الله في بيان الأحكام المتعلقة بذلك بكلام مطول. '.repeat(40);

    const text = buildLessonText(
      lesson({
        duration_seconds: 1200,
        chapters: [
          { start_seconds: 0, title: 'التفريغ النصي للشريط رقم (1)', body },
          { start_seconds: 600, title: 'تجب على كل مسلم مكلف إلا حائضا ونفساء ،', body: 'مختصر المتن.' },
        ],
      }),
    );

    expect(text).not.toBeNull();
    expect(text!.kind).toBe('transcript');
    expect(text!.sections).toHaveLength(2);
    // The second section starts exactly on the marker's real timestamp.
    expect(text!.sections[1]!.start).toBe(600);
    const times = text!.sections.flatMap((s) => s.sentences.map((x) => x.t!));
    expect(times).toEqual([...times].sort((a, b) => a - b));
    expect(Math.max(...times)).toBeLessThan(1200);
  });

  it('treats an already-segmented lesson as one section per chapter', () => {
    const text = buildLessonText(
      lesson({
        duration_seconds: 900,
        chapters: [
          { start_seconds: 0, title: 'تفسير الآيات (1-11)', body: 'كلام المفسر هنا. '.repeat(200) },
          { start_seconds: 400, title: 'تفسير الآيات (12-16)', body: 'وتتمة الكلام هنا. '.repeat(200) },
        ],
      }),
    );

    expect(text!.sections.map((s) => s.start)).toEqual([0, 400]);
    expect(text!.sections[1]!.sentences[0]!.t).toBe(400);
  });

  it('leaves matn sentences untimed but keeps the section timestamps', () => {
    const text = buildLessonText(
      lesson({
        duration_seconds: 5000,
        chapters: [
          { start_seconds: 54, title: 'باب إخلاص النية', body: 'قال الله تعالى كذا. وقال أيضا كذا.' },
          { start_seconds: 489, title: 'الحديث الأول', body: 'إنما الأعمال بالنيات.' },
        ],
      }),
    );

    expect(text!.kind).toBe('matn');
    expect(text!.sections.map((s) => s.start)).toEqual([54, 489]);
    expect(text!.sections.every((s) => s.sentences.every((x) => x.t === undefined))).toBe(true);
  });

  it('returns null when the lesson has no text', () => {
    expect(buildLessonText(lesson({ chapters: [] }))).toBeNull();
    expect(buildLessonText(lesson({ chapters: [{ start_seconds: 5, title: 'مدخل', body: '' }] }))).toBeNull();
  });
});
