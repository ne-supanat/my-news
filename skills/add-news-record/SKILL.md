---
name: add-news-record
description: >
  Insert one or more news article records into the Supabase `news` table,
  following the NewsModel schema used in the my_news Flutter app.
  Use this skill whenever asked to add, seed, or import news articles into
  the database.
---

# Add News Record to Supabase

## Overview

The `news` table in the Supabase project (`pduunufxakwfmcynbjxv`) stores news
articles displayed in the Flutter app. Each row maps 1-to-1 to a `NewsModel`
instance.

## NewsModel Schema

| Flutter field | Supabase column | PostgreSQL type          | Nullable | Notes                          |
|---------------|-----------------|--------------------------|----------|--------------------------------|
| `id`          | `id`            | `int8` (bigserial)       | NO       | Auto-generated primary key     |
| `createdAt`   | `created_at`    | `timestamptz`            | NO       | Auto-set by Supabase (`now()`) |
| `title`       | `title`         | `text`                   | NO       | Article headline               |
| `summary`     | `summary`       | `text`                   | NO       | Short description / excerpt    |
| `source`      | `source`        | `text`                   | NO       | Publisher name or URL          |

> [!IMPORTANT]
> `id` and `created_at` are managed by the database. **Never supply them in
> INSERT statements** unless you have a specific reason to override them.

## Steps to Insert a Record

### 1. Confirm the target project

Always verify you are operating on the correct Supabase project before making
any changes.

```
Project name : my-news
Project ID   : pduunufxakwfmcynbjxv
Region       : ap-southeast-2
```

Use the `list_projects` MCP tool to confirm the project is `ACTIVE_HEALTHY`
before proceeding.

### 2. Validate required fields

Before inserting, confirm the caller has provided all three required fields:

- `title`  — non-empty string
- `summary` — non-empty string
- `source`  — non-empty string (publisher name or full URL)

If any field is missing or blank, **stop and ask the user** to supply the
missing value. Do not invent placeholder data.

### 3. Insert via MCP `execute_sql`

Use the Supabase MCP `execute_sql` tool with `project_id = "pduunufxakwfmcynbjxv"`.

#### Single record

```sql
INSERT INTO public.news (title, summary, source)
VALUES (
  'Your article headline here',
  'A short description or excerpt of the article.',
  'https://example.com/article or Publisher Name'
)
RETURNING id, created_at, title, summary, source;
```

#### Multiple records (batch)

```sql
INSERT INTO public.news (title, summary, source)
VALUES
  ('Title 1', 'Summary 1', 'Source 1'),
  ('Title 2', 'Summary 2', 'Source 2'),
  ('Title 3', 'Summary 3', 'Source 3')
RETURNING id, created_at, title, summary, source;
```

Always include `RETURNING *` (or the explicit column list) so you can confirm
the inserted rows and report back to the user.

### 4. Verify the inserted record(s)

After a successful insert, run a quick SELECT to confirm the data looks correct:

```sql
SELECT id, created_at, title, summary, source
FROM public.news
ORDER BY created_at DESC
LIMIT 5;
```

Report the returned rows to the user.

### 5. Handle errors

| Error type                        | Action                                                         |
|-----------------------------------|----------------------------------------------------------------|
| `not-null violation` on a column  | Ask the user for the missing value; do not guess              |
| `unique violation` on `id`        | Remove the explicit `id` from the INSERT and let DB auto-assign|
| `connection timeout`              | Retry once; if it fails again, report the error to the user   |
| Permission denied / RLS violation | Inform the user that Row Level Security may be blocking the insert and ask them to check their Supabase policies |

## Example Interaction

**User:** "Add a news article: title='Flutter 4 Released', summary='Google
announces Flutter 4 with major performance improvements.',
source='https://flutter.dev/blog'"

**Agent actions:**
1. Call `list_projects` → confirm project is healthy.
2. Call `execute_sql` with:
   ```sql
   INSERT INTO public.news (title, summary, source)
   VALUES (
     'Flutter 4 Released',
     'Google announces Flutter 4 with major performance improvements.',
     'https://flutter.dev/blog'
   )
   RETURNING id, created_at, title, summary, source;
   ```
3. Report the returned row (id, created_at, etc.) to the user.
4. Optionally run the verification SELECT.

## Reference: NewsModel (Dart)

```dart
class NewsModel {
  final int id;
  final DateTime createdAt;
  final String title;
  final String summary;
  final String source;

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      title: json['title'],
      summary: json['summary'],
      source: json['source'],
    );
  }
}
```

The column names in the `fromJson` factory (`id`, `created_at`, `title`,
`summary`, `source`) are the **exact Supabase column names** to use in SQL.
