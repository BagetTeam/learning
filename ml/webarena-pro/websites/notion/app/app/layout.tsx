import { requireAuth } from "@/lib/auth";
import Sidebar from "./_components/Sidebar";
import TabsBar from "./_components/TabsBar";
import GuideDock from "./_components/GuideDock";

export default async function AppLayout({ children }: { children: React.ReactNode }) {
  await requireAuth();

  return (
    <div className="h-screen overflow-hidden bg-[var(--bg)]">
      <div className="flex h-screen overflow-hidden">
        <Sidebar />
        <div className="flex min-w-0 flex-1 flex-col overflow-hidden">
          <TabsBar />
          <main className="flex-1 overflow-y-auto overscroll-contain px-8 py-6">
            {children}
          </main>
        </div>
      </div>
      <GuideDock />
    </div>
  );
}
