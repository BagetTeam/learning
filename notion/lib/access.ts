import { PageAccessLevel, PagePermissionRole, WorkspaceRole } from "@prisma/client";
import { NextResponse } from "next/server";
import { prisma } from "./prisma";

export type MembershipWithWorkspace = Awaited<ReturnType<typeof getActiveMembership>>;

export async function getActiveMembership(userId: string, preferredWorkspaceId: string | null) {
  if (preferredWorkspaceId) {
    const preferred = await prisma.workspaceMembership.findUnique({
      where: {
        workspaceId_userId: {
          workspaceId: preferredWorkspaceId,
          userId,
        },
      },
      include: { workspace: true },
    });
    if (preferred) {
      return preferred;
    }
  }

  return prisma.workspaceMembership.findFirst({
    where: { userId },
    include: { workspace: true },
    orderBy: { createdAt: "asc" },
  });
}

export async function getPageAccessContext(params: {
  pageId: string;
  userId: string;
  preferredWorkspaceId: string | null;
  includeTrashed?: boolean;
}) {
  const page = await prisma.page.findUnique({
    where: { id: params.pageId },
    include: {
      permissions: {
        where: { userId: params.userId },
      },
    },
  });

  if (!page) {
    return {
      ok: false as const,
      response: NextResponse.json({ error: "Not found" }, { status: 404 }),
    };
  }

  if (page.deletedAt && !params.includeTrashed) {
    return {
      ok: false as const,
      response: NextResponse.json({ error: "Not found" }, { status: 404 }),
    };
  }

  const membership = await getActiveMembership(params.userId, params.preferredWorkspaceId);
  if (!membership || membership.workspaceId !== page.workspaceId) {
    return {
      ok: false as const,
      response: NextResponse.json({ error: "Forbidden" }, { status: 403 }),
    };
  }

  const permissionRole = page.permissions[0]?.role;

  return {
    ok: true as const,
    page,
    membership,
    permissionRole,
  };
}

function isWorkspaceEditor(role: WorkspaceRole) {
  return role === "owner" || role === "editor";
}

function isPermissionEditor(role: PagePermissionRole | undefined) {
  return role === "editor";
}

function isPermissionCommenter(role: PagePermissionRole | undefined) {
  return role === "commenter" || role === "editor";
}

export function canReadPage(params: {
  accessLevel: PageAccessLevel;
  workspaceRole: WorkspaceRole;
  isPageCreator: boolean;
  permissionRole: PagePermissionRole | undefined;
}) {
  if (params.accessLevel === "workspace") {
    return true;
  }

  if (params.workspaceRole === "owner" || params.isPageCreator) {
    return true;
  }

  return Boolean(params.permissionRole);
}

export function canEditPage(params: {
  accessLevel: PageAccessLevel;
  workspaceRole: WorkspaceRole;
  isPageCreator: boolean;
  permissionRole: PagePermissionRole | undefined;
}) {
  if (!isWorkspaceEditor(params.workspaceRole) && !params.isPageCreator) {
    return false;
  }

  if (params.accessLevel === "workspace") {
    return true;
  }

  if (params.workspaceRole === "owner" || params.isPageCreator) {
    return true;
  }

  return isPermissionEditor(params.permissionRole);
}

export function canCommentPage(params: {
  accessLevel: PageAccessLevel;
  workspaceRole: WorkspaceRole;
  isPageCreator: boolean;
  permissionRole: PagePermissionRole | undefined;
}) {
  if (params.accessLevel === "workspace") {
    return true;
  }

  if (params.workspaceRole === "owner" || params.isPageCreator) {
    return true;
  }

  return isPermissionCommenter(params.permissionRole);
}
