-- مسار طالب العلم — initial schema
-- Source of truth for the content catalog. The app never queries these tables
-- directly in the MVP; the pipeline compiles them into catalog.json.

create table sciences (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name_ar text not null,
  description_ar text,
  icon text,
  sort_order int not null default 0
);

create table series (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  science_id uuid not null references sciences (id),
  title_ar text not null,
  description_ar text,
  thumbnail_url text,
  lesson_count int not null default 0, -- denormalized by the pipeline
  status text not null default 'draft' check (status in ('active', 'draft', 'archived'))
);

-- A series may span multiple YouTube playlists (long series get split),
-- plus optionally a binothaimeen.net series page for enrichment.
create table series_sources (
  id uuid primary key default gen_random_uuid(),
  series_id uuid not null references series (id) on delete cascade,
  source_type text not null check (source_type in ('youtube_playlist', 'site_series')),
  external_id text not null,
  sort_order int not null default 0,
  unique (source_type, external_id)
);

create table lessons (
  id uuid primary key default gen_random_uuid(),
  series_id uuid not null references series (id) on delete cascade,
  position int not null,
  title_ar text not null,
  youtube_video_id text not null unique,
  duration_seconds int,
  published_at timestamptz,
  thumbnail_url text,
  media_type text not null default 'video', -- extension point: 'audio' later
  -- 'unavailable' = removed/private on YouTube; never delete rows, progress may reference them
  status text not null default 'active' check (status in ('active', 'hidden', 'unavailable')),
  unique (series_id, position)
);

-- المسارات التعليمية: the curated layer. Playlists alone are not a curriculum.
create table journeys (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title_ar text not null,
  description_ar text,
  level text not null check (level in ('beginner', 'intermediate', 'advanced')),
  science_id uuid references sciences (id), -- null = cross-science journey
  cover_url text,
  sort_order int not null default 0,
  is_published boolean not null default false
);

create table journey_stages (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references journeys (id) on delete cascade,
  position int not null,
  title_ar text not null,
  description_ar text,
  unique (journey_id, position)
);

create table journey_items (
  id uuid primary key default gen_random_uuid(),
  stage_id uuid not null references journey_stages (id) on delete cascade,
  position int not null,
  item_type text not null default 'series' check (item_type in ('series')), -- later: 'book', 'fatwa_topic'
  series_id uuid references series (id),
  unique (stage_id, position),
  check (item_type <> 'series' or series_id is not null)
);

create table catalog_meta (
  id int primary key default 1 check (id = 1),
  version int not null default 0,
  generated_at timestamptz
);

insert into catalog_meta (id, version) values (1, 0);

create index lessons_series_idx on lessons (series_id, position);
create index series_science_idx on series (science_id);
create index journey_stages_journey_idx on journey_stages (journey_id, position);
create index journey_items_stage_idx on journey_items (stage_id, position);
