"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Database, FileText, Plus, X } from "lucide-react";

type TabItem = {
  id: string;
  pageId: string;
  position: number;
  page: {
    id: string;
    title: string;
    type: "document" | "database";
  };
};

export default function TabsBar() {
  const pathname = usePathname();
  const router = useRouter();
  const [tabs, setTabs] = useState<TabItem[]>([]);

  async function refreshTabs() {
    const response = await fetch("/api/tabs");
    if (!response.ok) return;
    const data = await response.json();
    setTabs(data.tabs ?? []);
  }

  useEffect(() => {
    refreshTabs();
    const handler = () => refreshTabs();
    window.addEventListener("tabs:refresh", handler);
    return () => window.removeEventListener("tabs:refresh", handler);
  }, []);

  async function closeTab(tabId: string) {
    await fetch(`/api/tabs?tabId=${encodeURIComponent(tabId)}`, { method: "DELETE" });
    refreshTabs();
  }

  async function createNewPageTab() {
    const response = await fetch("/api/pages", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        title: "New page",
        type: "document",
        accessLevel: "workspace",
      }),
    });
    if (!response.ok) return;
    const data = await response.json();
    if (!data?.page?.id) return;
    window.dispatchEvent(new Event("pages:refresh"));
    window.dispatchEvent(new Event("tabs:refresh"));
    router.push(`/app/page/${data.page.id}`);
  }

  return (
    <div className="sticky top-0 z-20 border-b border-[var(--line)] bg-[var(--panel)] px-3 py-1.5">
      <div className="mx-auto flex max-w-[1200px] items-center gap-1 overflow-x-auto scrollbar-thin">
        {tabs.map((tab) => {
          const active = pathname?.includes(tab.pageId);
          return (
            <div
              key={tab.id}
              className={`group flex items-center rounded-md px-2 py-1 text-sm ${
                active ? "bg-[var(--selected)]" : "hover:bg-[var(--hover)]"
              }`}
            >
              <Link
                href={tab.page.type === "database" ? `/app/database/${tab.page.id}` : `/app/page/${tab.page.id}`}
                className="inline-flex max-w-[220px] items-center gap-1 truncate"
              >
                {tab.page.type === "database" ? <Database className="h-3.5 w-3.5 shrink-0 text-[var(--muted)]" /> : <FileText className="h-3.5 w-3.5 shrink-0 text-[var(--muted)]" />}
                {tab.page.title}
              </Link>
              <button
                className="ml-2 text-xs text-[var(--muted)] hover:text-[var(--text)]"
                onClick={() => closeTab(tab.id)}
                aria-label="Close tab"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </div>
          );
        })}
        <button
          onClick={() => void createNewPageTab()}
          className="inline-flex h-7 w-7 items-center justify-center rounded-md border border-[var(--line)] text-[var(--muted)] hover:bg-[var(--hover)] hover:text-[var(--text)]"
          title="New page tab"
        >
          <Plus className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
}
