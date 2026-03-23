"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  Check,
  ChevronDown,
  ChevronsLeft,
  ChevronsRight,
  CircleUserRound,
  Database,
  FilePlus2,
  FileText,
  Lock,
  NotebookPen,
  RotateCcw,
  Search,
  Settings,
  Star,
  Trash2,
  UserPlus,
  Users,
} from "lucide-react";
import { getFavoritePageIds } from "@/lib/favorites";

const SIDEBAR_COLLAPSED_KEY = "sidebar:collapsed";

export type PageItem = {
  id: string;
  title: string;
  type: "document" | "database";
  parentPageId: string | null;
  accessLevel: "workspace" | "private";
  icon: string | null;
  deletedAt: string | Date | null;
  isSmallText: boolean;
  isFullWidth: boolean;
  isLocked: boolean;
  fontStyle: "default" | "serif" | "mono";
};

type WorkspaceItem = {
  id: string;
  name: string;
  slug: string;
  role: "owner" | "editor" | "viewer";
  active: boolean;
};

type SearchResult = {
  id: string;
  title: string;
  type: "document" | "database";
};

type CurrentUser = {
  id: string;
  email: string;
  displayName: string;
  initials: string;
};

type TemplateBlock = {
  type: "paragraph" | "heading_1" | "heading_2" | "bulleted_list_item" | "todo";
  contentText: string;
};

type PageTemplate = {
  id: string;
  label: string;
  title: string;
  blocks: TemplateBlock[];
};

const PAGE_TEMPLATES: PageTemplate[] = [
  {
    id: "meeting_notes",
    label: "AI Meeting Notes",
    title: "AI Meeting Notes",
    blocks: [
      { type: "heading_1", contentText: "Meeting" },
      { type: "paragraph", contentText: "Date: " },
      { type: "paragraph", contentText: "Attendees: " },
      { type: "heading_2", contentText: "Agenda" },
      { type: "bulleted_list_item", contentText: "Topic 1" },
      { type: "bulleted_list_item", contentText: "Topic 2" },
      { type: "heading_2", contentText: "Action items" },
      { type: "todo", contentText: "Owner + due date" },
    ],
  },
  {
    id: "project_brief",
    label: "Project Brief",
    title: "Project Brief",
    blocks: [
      { type: "heading_1", contentText: "Project Brief" },
      { type: "heading_2", contentText: "Goal" },
      { type: "paragraph", contentText: "What are we trying to achieve?" },
      { type: "heading_2", contentText: "Scope" },
      { type: "bulleted_list_item", contentText: "In scope" },
      { type: "bulleted_list_item", contentText: "Out of scope" },
      { type: "heading_2", contentText: "Timeline" },
      { type: "todo", contentText: "Milestone 1" },
    ],
  },
  {
    id: "weekly_review",
    label: "Weekly Review",
    title: "Weekly Review",
    blocks: [
      { type: "heading_1", contentText: "Weekly Review" },
      { type: "heading_2", contentText: "Wins" },
      { type: "bulleted_list_item", contentText: "What went well?" },
      { type: "heading_2", contentText: "Learnings" },
      { type: "bulleted_list_item", contentText: "What can be improved?" },
      { type: "heading_2", contentText: "Next week" },
      { type: "todo", contentText: "Top priority 1" },
      { type: "todo", contentText: "Top priority 2" },
    ],
  },
];

function getActivePageId(pathname: string | null): string | null {
  if (!pathname) return null;
  const pageMatch = pathname.match(/\/app\/page\/([^/]+)/);
  if (pageMatch?.[1]) return pageMatch[1];
  const dbMatch = pathname.match(/\/app\/database\/([^/]+)/);
  if (dbMatch?.[1]) return dbMatch[1];
  return null;
}

export default function Sidebar() {
  const router = useRouter();
  const pathname = usePathname();

  const [pages, setPages] = useState<PageItem[]>([]);
  const [trashPages, setTrashPages] = useState<PageItem[]>([]);
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<SearchResult[]>([]);
  const [workspaces, setWorkspaces] = useState<WorkspaceItem[]>([]);
  const [activeWorkspaceId, setActiveWorkspaceId] = useState<string>("");
  const [collapsed, setCollapsed] = useState(false);
  const [draggingPageId, setDraggingPageId] = useState<string | null>(null);
  const [currentUser, setCurrentUser] = useState<CurrentUser | null>(null);
  const [accountPanelOpen, setAccountPanelOpen] = useState(false);
  const [createMenuOpen, setCreateMenuOpen] = useState(false);
  const [favoriteIds, setFavoriteIds] = useState<Set<string>>(new Set());
  const searchInputRef = useRef<HTMLInputElement | null>(null);
  const accountPanelRef = useRef<HTMLDivElement | null>(null);
  const createMenuRef = useRef<HTMLDivElement | null>(null);

  const activePageId = getActivePageId(pathname);

  async function refreshPages() {
    const response = await fetch("/api/pages");
    if (!response.ok) return;
    const data = await response.json();
    setPages(data.pages ?? []);
    if (data.workspace?.id) {
      setActiveWorkspaceId(data.workspace.id);
    }
  }

  async function refreshTrash() {
    const response = await fetch("/api/pages?scope=trash");
    if (!response.ok) return;
    const data = await response.json();
    setTrashPages(data.pages ?? []);
  }

  async function refreshWorkspaces() {
    const response = await fetch("/api/workspaces");
    if (!response.ok) return;
    const data = await response.json();
    const list = data.workspaces ?? [];
    setWorkspaces(list);
    const active = list.find((workspace: WorkspaceItem) => workspace.active);
    if (active) {
      setActiveWorkspaceId(active.id);
    }
  }

  async function refreshCurrentUser() {
    const response = await fetch("/api/me");
    if (!response.ok) return;
    const data = await response.json();
    if (data?.user) {
      setCurrentUser(data.user);
    }
  }

  useEffect(() => {
    refreshPages();
    refreshTrash();
    refreshWorkspaces();
    refreshCurrentUser();
    setFavoriteIds(getFavoritePageIds());
    const handler = () => {
      refreshPages();
      refreshTrash();
      refreshWorkspaces();
    };
    window.addEventListener("pages:refresh", handler);
    const onFavorite = () => setFavoriteIds(getFavoritePageIds());
    window.addEventListener("favorites:changed", onFavorite);
    return () => {
      window.removeEventListener("pages:refresh", handler);
      window.removeEventListener("favorites:changed", onFavorite);
    };
  }, []);

  useEffect(() => {
    const onOutsideClick = (event: MouseEvent) => {
      const target = event.target as Node;
      if (accountPanelRef.current && !accountPanelRef.current.contains(target)) {
        setAccountPanelOpen(false);
      }
      if (createMenuRef.current && !createMenuRef.current.contains(target)) {
        setCreateMenuOpen(false);
      }
    };
    window.addEventListener("mousedown", onOutsideClick);
    return () => window.removeEventListener("mousedown", onOutsideClick);
  }, []);

  useEffect(() => {
    setAccountPanelOpen(false);
    setCreateMenuOpen(false);
  }, [pathname]);

  useEffect(() => {
    const saved = window.localStorage.getItem(SIDEBAR_COLLAPSED_KEY);
    if (saved === "1") {
      setCollapsed(true);
    }

    const onKeyDown = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key === "\\") {
        event.preventDefault();
        setCollapsed((prev) => {
          const next = !prev;
          window.localStorage.setItem(SIDEBAR_COLLAPSED_KEY, next ? "1" : "0");
          return next;
        });
      }
    };

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);

  useEffect(() => {
    if (!query.trim()) {
      setResults([]);
      return;
    }

    const controller = new AbortController();
    const timer = setTimeout(async () => {
      const response = await fetch(`/api/search?q=${encodeURIComponent(query)}`, {
        signal: controller.signal,
      });
      if (!response.ok) return;
      const data = await response.json();
      setResults(data.results ?? []);
    }, 200);

    return () => {
      controller.abort();
      clearTimeout(timer);
    };
  }, [query]);

  const tree = useMemo(() => {
    const map = new Map<string, PageItem[]>();
    for (const page of pages) {
      const key = page.parentPageId ?? "root";
      const list = map.get(key) ?? [];
      list.push(page);
      map.set(key, list);
    }

    for (const list of map.values()) {
      list.sort((a, b) => a.title.localeCompare(b.title));
    }

    return map;
  }, [pages]);

  const favoritePages = useMemo(
    () =>
      pages
        .filter((page) => favoriteIds.has(page.id))
        .sort((a, b) => a.title.localeCompare(b.title)),
    [favoriteIds, pages]
  );

  async function createPage(options: {
    parentPageId: string | null;
    type: "document" | "database";
    accessLevel: "workspace" | "private";
    createMode?: "full_page" | "inline";
    title?: string;
    icon?: string | null;
    navigate?: boolean;
    createInitialRow?: boolean;
  }) {
    const response = await fetch("/api/pages", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        title: options.title ?? (options.type === "database" ? "Untitled database" : "Untitled"),
        parentPageId: options.parentPageId,
        activePageId,
        type: options.type,
        accessLevel: options.accessLevel,
        createMode: options.createMode ?? "full_page",
        icon: options.icon ?? null,
        createInitialRow: options.createInitialRow ?? true,
      }),
    });
    const data = await response.json();
    if (!response.ok) return null;
    window.dispatchEvent(new Event("pages:refresh"));
    const shouldNavigate = options.navigate ?? (options.createMode ?? "full_page") === "full_page";
    if (shouldNavigate) {
      router.push(options.type === "database" ? `/app/database/${data.page.id}` : `/app/page/${data.page.id}`);
    }
    return data.page as PageItem;
  }

  async function switchWorkspace(workspaceId: string) {
    await fetch("/api/workspaces/select", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ workspaceId }),
    });
    await refreshPages();
    await refreshTrash();
    await refreshWorkspaces();
    router.push("/app");
    router.refresh();
  }

  async function movePage(draggedId: string, parentPageId: string | null) {
    await fetch(`/api/pages/${draggedId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ parentPageId }),
    });
    window.dispatchEvent(new Event("pages:refresh"));
  }

  async function moveToTrash(pageId: string) {
    await fetch(`/api/pages/${pageId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ trashAction: "move" }),
    });
    window.dispatchEvent(new Event("pages:refresh"));
    if (activePageId === pageId) {
      router.push("/app");
    }
  }

  async function restorePage(pageId: string) {
    await fetch(`/api/pages/${pageId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ trashAction: "restore" }),
    });
    window.dispatchEvent(new Event("pages:refresh"));
  }

  async function permanentDelete(pageId: string) {
    await fetch(`/api/pages/${pageId}?permanent=1`, { method: "DELETE" });
    window.dispatchEvent(new Event("pages:refresh"));
  }

  async function logout() {
    await fetch("/api/logout", { method: "POST" });
    router.push("/login");
    router.refresh();
  }

  async function createFromTemplate(template: PageTemplate) {
    const page = await createPage({
      parentPageId: null,
      type: "document",
      accessLevel: "workspace",
      title: template.title,
      navigate: true,
    });
    if (!page?.id) return;

    let afterBlockId: string | undefined;
    for (const block of template.blocks) {
      const response = await fetch(`/api/pages/${page.id}/blocks`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          type: block.type,
          contentText: block.contentText,
          afterBlockId,
        }),
      });
      if (!response.ok) continue;
      const data = await response.json();
      afterBlockId = data?.block?.id;
    }
  }

  function renderPageIcon(page: PageItem) {
    const icon = page.icon?.trim() ?? "";
    const normalized = icon.toLowerCase();

    if (normalized) {
      if (normalized.includes("table") || normalized.includes("database")) {
        return <Database className="h-3.5 w-3.5" />;
      }
      if (normalized.includes("team") || normalized.includes("group")) {
        return <Users className="h-3.5 w-3.5" />;
      }
      if (normalized.includes("note") || normalized.includes("doc")) {
        return <FileText className="h-3.5 w-3.5" />;
      }
      if (/\p{Extended_Pictographic}/u.test(icon)) {
        return <span className="leading-none">{icon}</span>;
      }
    }

    return page.type === "database" ? <Database className="h-3.5 w-3.5" /> : <FileText className="h-3.5 w-3.5" />;
  }

  function renderTree(parentId: string | null, depth: number) {
    const list = tree.get(parentId ?? "root") ?? [];
    return list.map((page) => {
      const isActive = pathname?.includes(page.id);
      const href = page.type === "database" ? `/app/database/${page.id}` : `/app/page/${page.id}`;
      return (
        <div key={page.id} className="space-y-1">
          <div
            className={`group flex items-center justify-between overflow-hidden rounded-md px-2 py-1 text-[13px] ${
              isActive ? "bg-[var(--selected)]" : "hover:bg-[var(--hover)]"
            }`}
            style={{ marginLeft: depth * 12 }}
            draggable
            onDragStart={() => setDraggingPageId(page.id)}
            onDragEnd={() => setDraggingPageId(null)}
            onDragOver={(event) => event.preventDefault()}
            onDrop={(event) => {
              event.preventDefault();
              if (!draggingPageId || draggingPageId === page.id) return;
              movePage(draggingPageId, page.id);
            }}
          >
            <Link href={href} className="flex min-w-0 flex-1 items-center gap-1.5 overflow-hidden" title={page.title}>
              <span className="mr-1 inline-flex h-4 w-4 items-center justify-center text-[12px] text-[var(--muted)]">
                {renderPageIcon(page)}
              </span>
              <span className="truncate">{page.title}</span>
              {page.accessLevel === "private" ? (
                <span className="ml-1 inline-flex shrink-0 items-center gap-1 text-[11px] text-[var(--muted)]">
                  <Lock className="h-3 w-3" />
                  private
                </span>
              ) : null}
            </Link>
            <div className="hidden items-center gap-1 group-hover:flex">
              <button
                onClick={() => createPage({ parentPageId: page.id, type: "document", accessLevel: "workspace", createMode: "inline" })}
                className="text-[11px] text-[var(--muted)] hover:text-[var(--text)]"
                title="Add child page"
              >
                +
              </button>
              <button
                onClick={() => moveToTrash(page.id)}
                className="text-[11px] text-[var(--muted)] hover:text-[#b42318]"
                title="Move to trash"
              >
                <Trash2 className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
          {renderTree(page.id, depth + 1)}
        </div>
      );
    });
  }

  return (
    <aside className={`${collapsed ? "w-[52px]" : "w-[280px]"} flex h-screen shrink-0 flex-col overflow-visible border-r border-[var(--line)] bg-[var(--sidebar)] px-2 py-3 transition-[width]`}>
      <div className="flex min-h-0 flex-1 flex-col gap-2">
        <div className="flex items-center justify-between px-1">
          {!collapsed ? <p className="text-xs font-semibold uppercase tracking-[0.08em] text-[var(--muted)]">Workspace</p> : null}
          <button
            onClick={() => {
              setCollapsed((prev) => {
                const next = !prev;
                window.localStorage.setItem(SIDEBAR_COLLAPSED_KEY, next ? "1" : "0");
                return next;
              });
            }}
            className="rounded px-2 py-1 text-xs text-[var(--muted)] hover:bg-[var(--hover)]"
            title="Toggle sidebar (Cmd/Ctrl + \\)"
          >
            {collapsed ? <ChevronsRight className="h-4 w-4" /> : <ChevronsLeft className="h-4 w-4" />}
          </button>
        </div>

        <div ref={accountPanelRef} className="relative">
          <button
            onClick={() => setAccountPanelOpen((prev) => !prev)}
            className={`flex w-full items-center gap-2 rounded-md px-2 py-1.5 hover:bg-[var(--hover)] ${collapsed ? "justify-center" : ""}`}
            title={currentUser?.email ?? "Account"}
          >
            <span className="inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-md bg-[var(--selected)] text-xs font-semibold text-[var(--text)]">
              {currentUser?.initials ?? "U"}
            </span>
            {!collapsed ? (
              <>
                <span className="min-w-0 flex-1 text-left">
                  <span className="block truncate text-[13px] font-medium">{currentUser?.displayName ?? "User"}</span>
                  <span className="block truncate text-[11px] text-[var(--muted)]">{currentUser?.email ?? "No email"}</span>
                </span>
                <ChevronDown className="h-4 w-4 text-[var(--muted)]" />
              </>
            ) : null}
          </button>

          {accountPanelOpen ? (
            <div className={`absolute z-40 w-[340px] rounded-xl border border-[var(--line)] bg-[var(--panel)] shadow-xl ${collapsed ? "left-0 top-[105%]" : "left-0 top-[105%]"}`}>
              <div className="border-b border-[var(--line)] p-3">
                <p className="truncate text-[13px] font-semibold">{currentUser?.displayName ?? "User"}</p>
                <p className="truncate text-xs text-[var(--muted)]">{currentUser?.email ?? "No email"}</p>
                <div className="mt-3 flex gap-2">
                  <button
                    onClick={() => {
                      setAccountPanelOpen(false);
                      router.push("/app/settings");
                    }}
                    className="inline-flex items-center gap-1 rounded-md border border-[var(--line)] px-2 py-1 text-sm hover:bg-[var(--hover)]"
                  >
                    <Settings className="h-4 w-4" />
                    Settings
                  </button>
                  <button
                    onClick={() => {
                      setAccountPanelOpen(false);
                      router.push("/app/settings?section=people");
                    }}
                    className="inline-flex items-center gap-1 rounded-md border border-[var(--line)] px-2 py-1 text-sm hover:bg-[var(--hover)]"
                  >
                    <UserPlus className="h-4 w-4" />
                    Invite members
                  </button>
                </div>
              </div>

              <div className="max-h-[240px] overflow-y-auto overscroll-contain p-2">
                {workspaces.map((workspace) => (
                  <button
                    key={workspace.id}
                    onClick={() => {
                      void switchWorkspace(workspace.id);
                      setAccountPanelOpen(false);
                    }}
                    className="flex w-full items-center justify-between rounded px-2 py-1.5 text-left text-sm hover:bg-[var(--hover)]"
                  >
                    <span className="min-w-0 truncate">{workspace.name}</span>
                    {workspace.id === activeWorkspaceId ? <Check className="h-4 w-4 text-[var(--muted)]" /> : null}
                  </button>
                ))}
              </div>

              <div className="border-t border-[var(--line)] p-2 text-sm">
                <button
                  onClick={() => {
                    setAccountPanelOpen(false);
                    router.push("/login");
                  }}
                  className="w-full rounded px-2 py-1.5 text-left text-[var(--muted)] hover:bg-[var(--hover)]"
                >
                  Add another account
                </button>
                <button onClick={logout} className="w-full rounded px-2 py-1.5 text-left text-[#b42318] hover:bg-[var(--hover)]">Log out all accounts</button>
              </div>
            </div>
          ) : null}
        </div>

        {collapsed ? (
          <div className="space-y-1 px-1">
            <button
              onClick={() => createPage({ parentPageId: null, type: "document", accessLevel: "workspace" })}
              className="flex h-8 w-8 items-center justify-center rounded hover:bg-[var(--hover)]"
              title="New page"
            >
              <FilePlus2 className="h-4 w-4" />
            </button>
            <button
              onClick={() => createPage({ parentPageId: activePageId, type: "database", accessLevel: "workspace", createMode: "inline", navigate: false })}
              className="flex h-8 w-8 items-center justify-center rounded hover:bg-[var(--hover)]"
              title="New inline DB"
            >
              <Database className="h-4 w-4" />
            </button>
            <button
              onClick={() => searchInputRef.current?.focus()}
              className="flex h-8 w-8 items-center justify-center rounded hover:bg-[var(--hover)]"
              title="Search"
            >
              <Search className="h-4 w-4" />
            </button>
            <button
              onClick={() => router.push("/app/settings")}
              className="flex h-8 w-8 items-center justify-center rounded hover:bg-[var(--hover)]"
              title="Settings"
            >
              <Settings className="h-4 w-4" />
            </button>
          </div>
        ) : (
          <>
            <div className="space-y-2">
              <div className="space-y-1">
                <button onClick={() => searchInputRef.current?.focus()} className="flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-[13px] hover:bg-[var(--hover)]">
                  <Search className="h-4 w-4 text-[var(--muted)]" />
                  <span>Search</span>
                </button>
                <button
                  onClick={() => router.push("/app/settings")}
                  className="flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-[13px] hover:bg-[var(--hover)]"
                >
                  <Settings className="h-4 w-4 text-[var(--muted)]" />
                  <span>Settings</span>
                </button>

                <div ref={createMenuRef} className="relative">
                  <button
                    onClick={() => setCreateMenuOpen((prev) => !prev)}
                    className="flex w-full items-center justify-between rounded-md px-2 py-1.5 text-[13px] hover:bg-[var(--hover)]"
                  >
                    <span className="inline-flex items-center gap-2">
                      <NotebookPen className="h-4 w-4 text-[var(--muted)]" />
                      New
                    </span>
                    <ChevronDown className="h-4 w-4 text-[var(--muted)]" />
                  </button>
                  {createMenuOpen ? (
                    <div className="absolute left-0 top-[105%] z-40 w-[220px] rounded-xl border border-[var(--line)] bg-[var(--panel)] p-1 shadow-xl">
                      <button
                        onClick={() => {
                          setCreateMenuOpen(false);
                          void createPage({ parentPageId: null, type: "document", accessLevel: "workspace", createMode: "full_page", navigate: true });
                        }}
                        className="flex w-full items-center gap-2 rounded px-2 py-1.5 text-left text-sm hover:bg-[var(--hover)]"
                      >
                        <FilePlus2 className="h-4 w-4 text-[var(--muted)]" />
                        Page
                      </button>
                      <button
                        onClick={() => {
                          setCreateMenuOpen(false);
                          void createPage({ parentPageId: null, type: "database", accessLevel: "workspace", createMode: "full_page", navigate: true });
                        }}
                        className="flex w-full items-center gap-2 rounded px-2 py-1.5 text-left text-sm hover:bg-[var(--hover)]"
                      >
                        <Database className="h-4 w-4 text-[var(--muted)]" />
                        Database
                      </button>
                      <button
                        onClick={() => {
                          setCreateMenuOpen(false);
                          void createPage({
                            parentPageId: activePageId,
                            type: "database",
                            accessLevel: "workspace",
                            createMode: "inline",
                            navigate: false,
                          });
                        }}
                        className="flex w-full items-center gap-2 rounded px-2 py-1.5 text-left text-sm hover:bg-[var(--hover)]"
                      >
                        <Database className="h-4 w-4 text-[var(--muted)]" />
                        Inline database
                      </button>
                      <div className="my-1 border-t border-[var(--line)]" />
                      <p className="px-2 pb-1 pt-0.5 text-xs font-medium text-[var(--muted)]">Templates</p>
                      {PAGE_TEMPLATES.map((template) => (
                        <button
                          key={template.id}
                          onClick={() => {
                            setCreateMenuOpen(false);
                            void createFromTemplate(template);
                          }}
                          className="flex w-full items-center gap-2 rounded px-2 py-1.5 text-left text-sm hover:bg-[var(--hover)]"
                        >
                          <CircleUserRound className="h-4 w-4 text-[var(--muted)]" />
                          {template.label}
                        </button>
                      ))}
                    </div>
                  ) : null}
                </div>
              </div>
              <input
                ref={searchInputRef}
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                placeholder="Search"
                className="w-full rounded-md border border-[var(--line)] bg-[var(--panel)] px-2 py-1.5 text-[13px]"
              />

              {query && results.length > 0 ? (
                <div className="rounded-md border border-[var(--line)] bg-[var(--panel)] p-2">
                  {results.map((result) => (
                    <Link
                      key={result.id}
                      href={result.type === "database" ? `/app/database/${result.id}` : `/app/page/${result.id}`}
                      className="block rounded px-2 py-1 text-[13px] hover:bg-[var(--hover)]"
                      onClick={() => setQuery("")}
                    >
                      {result.title}
                    </Link>
                  ))}
                </div>
              ) : null}
            </div>

            <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain">
              <div className="rounded-md border border-transparent p-1">
                <p className="px-1 text-[11px] uppercase tracking-[0.08em] text-[var(--muted)]">Favorites</p>
                <div className="space-y-1 pt-2">
                  {favoritePages.length === 0 ? (
                    <p className="px-2 py-1 text-xs text-[var(--muted)]">No favorite pages</p>
                  ) : (
                    favoritePages.map((page) => (
                      <Link
                        key={page.id}
                        href={page.type === "database" ? `/app/database/${page.id}` : `/app/page/${page.id}`}
                        className="flex items-center gap-2 rounded px-2 py-1 text-[13px] hover:bg-[var(--hover)]"
                      >
                        <Star className="h-3.5 w-3.5 text-[#f79009]" />
                        <span className="truncate">{page.title}</span>
                      </Link>
                    ))
                  )}
                </div>
              </div>

              <div
                className="rounded-md border border-transparent p-1"
                onDragOver={(event) => event.preventDefault()}
                onDrop={(event) => {
                  event.preventDefault();
                  if (!draggingPageId) return;
                  movePage(draggingPageId, null);
                }}
              >
                <p className="px-1 text-[11px] uppercase tracking-[0.08em] text-[var(--muted)]">Pages</p>
                <div className="space-y-1 pt-2">{renderTree(null, 0)}</div>
              </div>

              <div className="mt-3 space-y-1 border-t border-[var(--line)] pt-2">
                <p className="px-1 text-[11px] uppercase tracking-[0.08em] text-[var(--muted)]">Trash</p>
                <div className="space-y-1">
                  {trashPages.length === 0 ? <p className="px-2 py-1 text-xs text-[var(--muted)]">No pages in trash</p> : null}
                  {trashPages.map((page) => (
                    <div key={page.id} className="flex items-center justify-between rounded px-2 py-1 text-[13px] hover:bg-[var(--hover)]">
                      <span className="truncate" title={page.title}>{page.title}</span>
                      <div className="flex items-center gap-1">
                        <button onClick={() => restorePage(page.id)} className="text-[11px] text-[var(--muted)] hover:text-[var(--text)]" title="Restore">
                          <RotateCcw className="h-3.5 w-3.5" />
                        </button>
                        <button onClick={() => permanentDelete(page.id)} className="text-[11px] text-[var(--muted)] hover:text-[#b42318]" title="Delete permanently">
                          <Trash2 className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </aside>
  );
}
