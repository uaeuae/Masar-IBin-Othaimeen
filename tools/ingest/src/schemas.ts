import { z } from 'zod';

/** Stable Latin identifiers used as natural keys for idempotent ingestion. */
export const slugSchema = z
  .string()
  .regex(/^[a-z0-9]+(-[a-z0-9]+)*$/, 'slug must be lowercase-kebab-case');

export const scholarSchema = z.object({
  slug: slugSchema,
  /** «الشيخ محمد بن صالح العثيمين» */
  name_ar: z.string().min(1),
  /** Rights holder credited in attribution: «مؤسسة الشيخ ... الخيرية». */
  foundation_ar: z.string().min(1),
  /** Official site, for the about/attribution screens. */
  website: z.string().url().optional(),
  sort_order: z.number().int().default(0),
});

export const scholarsFileSchema = z.object({
  scholars: z.array(scholarSchema).min(1),
});

export const scienceSchema = z.object({
  slug: slugSchema,
  name_ar: z.string().min(1),
  description_ar: z.string().optional(),
  icon: z.string().optional(),
  sort_order: z.number().int(),
});

export const sciencesFileSchema = z.object({
  sciences: z.array(scienceSchema).min(1),
});

export const seriesOverridesSchema = z
  .object({
    exclude_videos: z.array(z.string()).default([]),
    title_cleanup: z
      .string()
      .optional()
      .refine((pattern) => {
        if (pattern === undefined) return true;
        try {
          new RegExp(pattern);
          return true;
        } catch {
          return false;
        }
      }, 'title_cleanup must be a valid regular expression'),
  })
  .default({ exclude_videos: [] });

export const seriesSeedSchema = z.object({
  slug: slugSchema,
  title_ar: z.string().min(1),
  description_ar: z.string().optional(),
  thumbnail_url: z.string().url().optional(),
  science: slugSchema,
  /** Whose شرح this is. Every series belongs to exactly one scholar. */
  scholar: slugSchema.default('ibn-uthaymeen'),
  level: z.enum(['beginner', 'intermediate', 'advanced']).optional(),
  status: z.enum(['active', 'draft', 'archived']).default('draft'),
  /** 'audio' series stream foundation MP3s; 'video' series embed YouTube. */
  media: z.enum(['video', 'audio']).default('video'),
  /**
   * Slug of the video series this audio series is the full audio edition of.
   * Companion series are hidden from library browse; the video series links
   * to them via «النسخة الصوتية». Audio-only field.
   */
  companion_of: slugSchema.optional(),
  /** Ordered: when a long series spans multiple playlists, order here is playback order. */
  youtube_playlists: z.array(z.string().min(1)).default([]),
  /** Audio-library section ids on shekhapi.binothaimeen.net, in playback order. */
  site_audio_sections: z.array(z.string().min(1)).default([]),
  site_series_ids: z.array(z.string().min(1)).default([]),
  overrides: seriesOverridesSchema,
});

export const journeyItemSchema = z.object({
  series: slugSchema,
});

export const journeyStageSchema = z.object({
  title_ar: z.string().min(1),
  description_ar: z.string().optional(),
  items: z.array(journeyItemSchema).min(1),
});

export const journeySeedSchema = z.object({
  slug: slugSchema,
  title_ar: z.string().min(1),
  description_ar: z.string().optional(),
  level: z.enum(['beginner', 'intermediate', 'advanced']),
  science: slugSchema.optional(),
  cover_url: z.string().url().optional(),
  sort_order: z.number().int().default(0),
  is_published: z.boolean().default(false),
  stages: z.array(journeyStageSchema).min(1),
});

export type Scholar = z.infer<typeof scholarSchema>;
export type Science = z.infer<typeof scienceSchema>;
export type SeriesSeed = z.infer<typeof seriesSeedSchema>;
export type JourneySeed = z.infer<typeof journeySeedSchema>;
