# Please follow these steps to test the website
```
conda create -n notion-demo nodejs python=3.10 -y
conda activate notion-demo
docker compose up -d
npm install
npx prisma db push ## or npm run prisma:migrate
npm run db:seed
```
After once this is done, please run the following command (+conda activation)
```
npm run dev
```
------
# Following guideline is for developer (Seyeon)
# Notion Sandbox (WebArena-Pro)
A multi-user, multi-workspace Notion-like sandbox for WebArena-style task execution and evaluation.

## What Changed
- Multi-user sessions and workspace switching
- Workspace memberships (`owner`, `editor`, `viewer`)
- Page-level access (`workspace` or `private`) and per-user page permissions
- Workspace tab model (open/close page tabs)
- Public share links for pages
- Page-level comments with basic `@email` mentions
- Attachments (URL and multipart upload)
- Image blocks in document editor
- Deterministic seed/reset across all entities

## Core Stack
- Next.js + TypeScript
- Tailwind CSS
- PostgreSQL
- Prisma ORM

## Local Setup
1. Start PostgreSQL:

```bash
docker-compose up -d
```

2. Create `.env`:

```bash
DATABASE_URL="postgresql://webarena:webarena@localhost:5432/webarena?schema=public"
PASSWORD_SALT="change_me"
```

3. Install dependencies, migrate, and seed:

```bash
npm install
npm run prisma:migrate
npm run db:seed
```

4. Run dev server:

```bash
npm run dev
```

Open `http://localhost:3000`.

If you see `Cannot find module './xxx.js'` from `.next/server/webpack-runtime.js`, stop all running dev servers and rebuild Next cache once:

```bash
npm run clean:next
npm run dev
```

## Seeded Users
All users use password `password123`.
- `demo@webarena.local`
- `alex@webarena.local`
- `mina@webarena.local`

## Reset
- CLI: `npm run db:reset`
- API: `POST /api/reset`

## Main Routes
- `/login`
- `/app`
- `/app/page/:pageId`
- `/app/database/:pageId`
- `/share/:token`

## Manual Checklist (Notion-like MVP)
- [ ] Sidebar can collapse/expand from toggle button and `Cmd/Ctrl + \`.
- [ ] Sidebar state persists after refresh.
- [ ] Page can be dragged onto another page to become a child page.
- [ ] Page can be moved to trash from sidebar row action.
- [ ] Trash section shows deleted pages and supports restore/permanent delete.
- [ ] New database creates with only one `Name` (title) property by default.
- [ ] Database creation works for both full-page and inline modes.
- [ ] Database rows can be reordered by drag-and-drop.
- [ ] Document editor supports slash commands (`/`) for block conversion.
- [ ] Markdown shortcuts convert block type (`#`, `##`, `###`, `-`, `1.`, `[]`, `>`, `````).
- [ ] Block context menu has `Copy link to block`, `Duplicate`, `Delete`, `Turn into`.
- [ ] Opening `/app/page/:id#block-:blockId` scrolls/highlights the target block.
- [ ] Block drag-and-drop reorders blocks and persists.
- [ ] Image upload works via drag/drop, paste, and slash-command upload flow.
- [ ] Page `...` menu toggles page settings (`small text`, `full width`, `lock`, `font`) and persists.
- [ ] Theme mode toggle (`light`, `dark`, `system`) is available in page `...` menu.
- [ ] System mode follows OS dark/light preference changes.
- [ ] Database view settings panel opens from top-right settings icon.
- [ ] Block handle uses left `+` and `...` controls (no separate drag button).

## Evaluation-Friendly APIs
- `GET /api/pages/:id`
- `GET /api/pages/:id/blocks`
- `GET /api/databases/:id`
- `GET /api/databases/:id/rows`
- `GET /api/pages/:id/comments`
- `GET /api/pages/:id/permissions`
- `GET /api/pages/:id/attachments`
- `GET /api/pages/:id/share-links`
- `GET /api/workspaces`
- `GET /api/tabs`
- `POST /api/reset`

## Migration Notes
- A destructive schema migration is included at `prisma/migrations/20260305143000_multi_workspace/migration.sql`.
- This migration rebuilds tables/enums to move from single-user to multi-user/workspace domain.
- Recommended path from old local DB state:
  1. backup if needed
  2. run migration
  3. run seed/reset to restore deterministic baseline
