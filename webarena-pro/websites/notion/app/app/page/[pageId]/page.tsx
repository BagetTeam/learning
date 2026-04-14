import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { canReadPage, getActiveMembership } from "@/lib/access";
import { getSessionUserId, getSessionWorkspaceId } from "@/lib/auth";
import PageEditor from "@/app/app/_components/PageEditor";
import PageHeader from "@/app/app/_components/PageHeader";
import OpenTabSync from "@/app/app/_components/OpenTabSync";

export default async function DocumentPage({ params }: { params: { pageId: string } }) {
  const userId = getSessionUserId();
  if (!userId) {
    redirect("/login");
  }

  const preferredWorkspaceId = getSessionWorkspaceId();
  const membership = await getActiveMembership(userId, preferredWorkspaceId);
  if (!membership) {
    return <div className="p-8 text-sm text-[var(--muted)]">No workspace membership found.</div>;
  }

  const page = await prisma.page.findUnique({
    where: { id: params.pageId },
    include: {
      permissions: {
        where: { userId },
      },
    },
  });

  if (!page || page.workspaceId !== membership.workspaceId) {
    return <div className="p-8 text-sm text-[var(--muted)]">Page not found.</div>;
  }
  if (page.deletedAt) {
    return <div className="p-8 text-sm text-[var(--muted)]">This page is in trash.</div>;
  }

  const readable = canReadPage({
    accessLevel: page.accessLevel,
    workspaceRole: membership.role,
    isPageCreator: page.createdById === userId,
    permissionRole: page.permissions[0]?.role,
  });

  if (!readable) {
    return <div className="p-8 text-sm text-[var(--muted)]">You do not have access to this page.</div>;
  }

  if (page.type === "database") {
    redirect(`/app/database/${page.id}`);
  }

  const blocks = await prisma.block.findMany({
    where: { pageId: page.id },
    orderBy: { position: "asc" },
    select: {
      id: true,
      type: true,
      contentText: true,
      checked: true,
      imageUrl: true,
      position: true,
      parentBlockId: true,
      propsJson: true,
      richTextJson: true,
    },
  });

  const allPages = await prisma.page.findMany({
    where: {
      workspaceId: membership.workspaceId,
      OR: [
        { accessLevel: "workspace" },
        { createdById: userId },
        { permissions: { some: { userId } } },
      ],
    },
    select: {
      id: true,
      title: true,
      parentPageId: true,
      type: true,
      accessLevel: true,
      icon: true,
      deletedAt: true,
      isSmallText: true,
      isFullWidth: true,
      isLocked: true,
      fontStyle: true,
    },
    orderBy: { title: "asc" },
  });

  return (
    <div
      className={`mx-auto w-full ${
        page.isFullWidth ? "" : "max-w-[1100px]"
      } ${
        page.fontStyle === "serif" ? "font-serif" : page.fontStyle === "mono" ? "font-mono" : ""
      } ${page.isSmallText ? "text-[14px]" : ""} pb-36`}
    >
      <OpenTabSync pageId={page.id} />
      <PageHeader page={page} allPages={allPages} />
      <PageEditor pageId={page.id} initialBlocks={blocks} />
    </div>
  );
}
