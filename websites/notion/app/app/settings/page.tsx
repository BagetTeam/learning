"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Bell, Download, Globe, Link2, Settings2, Shield, Users, X } from "lucide-react";
import { applyThemeMode, getSavedThemeMode, type ThemeMode } from "@/lib/theme-mode";

type SettingsSection =
  | "preferences"
  | "notifications"
  | "connections"
  | "general"
  | "people"
  | "import"
  | "public_pages"
  | "emoji"
  | "offline"
  | "teamspaces"
  | "security"
  | "identity";

type MePayload = {
  user?: {
    email: string;
    displayName: string;
  };
};

const MENU: { group: string; items: { id: SettingsSection; label: string; icon: typeof Settings2 }[] }[] = [
  {
    group: "Account",
    items: [
      { id: "preferences", label: "Preferences", icon: Settings2 },
      { id: "notifications", label: "Notifications", icon: Bell },
      { id: "connections", label: "Connections", icon: Link2 },
    ],
  },
  {
    group: "Workspace",
    items: [
      { id: "general", label: "General", icon: Settings2 },
      { id: "people", label: "People", icon: Users },
      { id: "import", label: "Import", icon: Download },
    ],
  },
  {
    group: "Features",
    items: [
      { id: "public_pages", label: "Public pages", icon: Globe },
      { id: "emoji", label: "Emoji", icon: Globe },
      { id: "offline", label: "Offline", icon: Globe },
    ],
  },
  {
    group: "Admin",
    items: [
      { id: "teamspaces", label: "Teamspaces", icon: Users },
      { id: "security", label: "Security", icon: Shield },
      { id: "identity", label: "Identity", icon: Shield },
    ],
  },
];

function titleForSection(section: SettingsSection) {
  if (section === "preferences") return "Preferences";
  if (section === "notifications") return "Notifications";
  if (section === "connections") return "Connections";
  if (section === "general") return "General";
  if (section === "people") return "People";
  if (section === "import") return "Import";
  if (section === "public_pages") return "Public pages";
  if (section === "emoji") return "Emoji";
  if (section === "offline") return "Offline";
  if (section === "teamspaces") return "Teamspaces";
  if (section === "security") return "Security";
  return "Identity";
}

export default function SettingsPage() {
  const searchParams = useSearchParams();
  const initialSection = (searchParams.get("section") as SettingsSection | null) ?? "preferences";
  const [active, setActive] = useState<SettingsSection>(initialSection);
  const [themeMode, setThemeMode] = useState<ThemeMode>("system");
  const [language, setLanguage] = useState("English (US)");
  const [showDirectionControl, setShowDirectionControl] = useState(false);
  const [userName, setUserName] = useState("User");
  const [userEmail, setUserEmail] = useState("No email");

  useEffect(() => {
    const next = (searchParams.get("section") as SettingsSection | null) ?? "preferences";
    setActive(next);
  }, [searchParams]);

  useEffect(() => {
    setThemeMode(getSavedThemeMode());
  }, []);

  useEffect(() => {
    const fetchMe = async () => {
      const response = await fetch("/api/me");
      if (!response.ok) return;
      const data = (await response.json()) as MePayload;
      if (data.user?.displayName) setUserName(data.user.displayName);
      if (data.user?.email) setUserEmail(data.user.email);
    };
    void fetchMe();
  }, []);

  const heading = useMemo(() => titleForSection(active), [active]);

  return (
    <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/30 p-4">
      <div className="h-[min(88vh,920px)] w-[min(1180px,96vw)] overflow-hidden rounded-2xl border border-[var(--line)] bg-[var(--panel)] shadow-2xl">
        <div className="grid h-full grid-cols-[320px_minmax(0,1fr)]">
          <aside className="h-full overflow-y-auto overscroll-contain border-r border-[var(--line)] bg-[var(--sidebar)] p-4">
            <p className="mb-3 text-sm font-semibold text-[var(--muted)]">Account</p>
            <button className="mb-4 flex w-full items-center gap-2 rounded-xl border border-[var(--line)] bg-[var(--panel)] px-3 py-2 text-left">
              <span className="inline-flex h-10 w-10 items-center justify-center rounded-full bg-[var(--selected)] text-sm font-semibold">
                {userName.slice(0, 2).toUpperCase()}
              </span>
              <span className="min-w-0">
                <span className="block truncate text-sm font-medium">{userName}</span>
                <span className="block truncate text-xs text-[var(--muted)]">{userEmail}</span>
              </span>
            </button>

            {MENU.map((group) => (
              <div key={group.group} className="mb-5">
                <p className="mb-1 text-sm font-semibold text-[var(--muted)]">{group.group}</p>
                <div className="space-y-1">
                  {group.items.map((item) => {
                    const Icon = item.icon;
                    return (
                      <button
                        key={item.id}
                        onClick={() => setActive(item.id)}
                        className={`flex w-full items-center gap-2 rounded-md px-3 py-2 text-left text-[15px] ${
                          active === item.id ? "bg-[var(--selected)] font-medium" : "hover:bg-[var(--hover)]"
                        }`}
                      >
                        <Icon className="h-4 w-4 text-[var(--muted)]" />
                        {item.label}
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}
          </aside>

          <section className="h-full overflow-y-auto overscroll-contain p-8">
            <div className="mb-4 flex items-start justify-between">
              <div>
                <p className="text-sm text-[var(--muted)]">Account</p>
                <h1 className="text-6xl font-semibold tracking-[-0.02em]">{heading}</h1>
              </div>
              <Link href="/app" className="rounded-md p-2 text-[var(--muted)] hover:bg-[var(--hover)]">
                <X className="h-6 w-6" />
              </Link>
            </div>

            {active === "preferences" ? (
              <div className="space-y-10 pt-4">
                <div>
                  <h2 className="mb-4 text-5xl font-semibold tracking-[-0.02em]">Appearance</h2>
                  <div className="border-t border-[var(--line)] pt-5">
                    <div className="flex items-start justify-between gap-4">
                      <div>
                        <p className="text-3xl font-semibold">Theme</p>
                        <p className="mt-1 text-2xl text-[var(--muted)]">Choose a theme for Notion on this device</p>
                      </div>
                      <select
                        value={themeMode}
                        onChange={(event) => {
                          const mode = event.target.value as ThemeMode;
                          setThemeMode(mode);
                          applyThemeMode(mode);
                        }}
                        className="rounded-xl border border-[var(--line)] bg-[var(--panel)] px-4 py-3 text-2xl"
                      >
                        <option value="light">Light</option>
                        <option value="dark">Dark</option>
                        <option value="system">System</option>
                      </select>
                    </div>
                  </div>
                </div>

                <div>
                  <h2 className="mb-4 text-5xl font-semibold tracking-[-0.02em]">Language & Time</h2>
                  <div className="border-t border-[var(--line)] pt-5">
                    <div className="mb-7 flex items-start justify-between gap-4">
                      <div>
                        <p className="text-3xl font-semibold">Language</p>
                        <p className="mt-1 text-2xl text-[var(--muted)]">Choose the language you want to use</p>
                      </div>
                      <select
                        value={language}
                        onChange={(event) => setLanguage(event.target.value)}
                        className="rounded-xl border border-[var(--line)] bg-[var(--panel)] px-4 py-3 text-2xl"
                      >
                        <option>English (US)</option>
                        <option>Korean</option>
                        <option>Japanese</option>
                      </select>
                    </div>

                    <div className="flex items-start justify-between gap-4">
                      <div>
                        <p className="text-3xl font-semibold">Always show text direction controls</p>
                        <p className="mt-1 text-2xl text-[var(--muted)]">
                          Show the option to change text direction in the editor.
                        </p>
                      </div>
                      <button
                        onClick={() => setShowDirectionControl((prev) => !prev)}
                        className={`inline-flex h-10 w-20 items-center rounded-full p-1 transition ${
                          showDirectionControl ? "bg-[var(--blue)]" : "bg-[var(--line)]"
                        }`}
                      >
                        <span
                          className={`h-8 w-8 rounded-full bg-white transition ${
                            showDirectionControl ? "translate-x-10" : "translate-x-0"
                          }`}
                        />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            ) : (
              <div className="pt-8">
                <p className="text-lg text-[var(--muted)]">
                  {heading} section is prepared. Detailed controls will be added in this screen.
                </p>
              </div>
            )}
          </section>
        </div>
      </div>
    </div>
  );
}
