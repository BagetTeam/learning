import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireApiAuth } from "@/lib/api-auth";
import { getActiveMembership } from "@/lib/access";
import { makeId } from "@/lib/ids";

export async function GET(request: Request) {
  const auth = requireApiAuth();
  if (!auth.ok) return auth.response;

  const membership = await getActiveMembership(auth.session.userId, auth.session.workspaceId);
  if (!membership) {
    return NextResponse.json({ error: "No workspace membership" }, { status: 403 });
  }

  const requestUrl = new URL(request.url);
  const requestedScope = requestUrl.searchParams.get("scope") === "trash" ? "trash" : "active";

  const pages = await prisma.page.findMany({
    where: {
      workspaceId: membership.workspaceId,
      deletedAt: requestedScope === "trash" ? { not: null } : null,
      OR: [
        { accessLevel: "workspace" },
        { createdById: auth.session.userId },
        { permissions: { some: { userId: auth.session.userId } } },
      ],
    },
    select: {
      id: true,
      title: true,
      type: true,
      parentPageId: true,
      accessLevel: true,
      icon: true,
      deletedAt: true,
      isSmallText: true,
      isFullWidth: true,
      isLocked: true,
      fontStyle: true,
    },
    orderBy: [{ updatedAt: "desc" }, { title: "asc" }],
  });

  return NextResponse.json({
    workspace: {
      id: membership.workspace.id,
      name: membership.workspace.name,
      slug: membership.workspace.slug,
      role: membership.role,
    },
    pages,
  });
}

export async function POST(request: Request) {
  const auth = requireApiAuth();
  if (!auth.ok) return auth.response;

  const membership = await getActiveMembership(auth.session.userId, auth.session.workspaceId);
  if (!membership || (membership.role !== "owner" && membership.role !== "editor")) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const body = await request.json().catch(() => null);
  const title = body?.title?.toString().trim() || "Untitled";
  const type = body?.type === "database" ? "database" : "document";
  const accessLevel = body?.accessLevel === "private" ? "private" : "workspace";
  const icon = typeof body?.icon === "string" ? body.icon : null;
  const createMode = body?.createMode === "inline" ? "inline" : "full_page";
  const fallbackParentPageId = body?.activePageId ? String(body.activePageId) : null;
  const parentPageId =
    body?.parentPageId !== undefined
      ? body?.parentPageId
        ? String(body.parentPageId)
        : null
      : createMode === "inline"
      ? fallbackParentPageId
      : null;

  if (parentPageId) {
    const parent = await prisma.page.findUnique({ where: { id: parentPageId } });
    if (!parent || parent.workspaceId !== membership.workspaceId || parent.deletedAt) {
      return NextResponse.json({ error: "Invalid parent page" }, { status: 400 });
    }
  }

  const id = makeId("page");
  const page = await prisma.page.create({
    data: {
      id,
      workspaceId: membership.workspaceId,
      createdById: auth.session.userId,
      title,
      type,
      accessLevel,
      parentPageId,
      icon,
      permissions:
        accessLevel === "private"
          ? {
              create: {
                id: makeId("perm"),
                userId: auth.session.userId,
                role: "editor",
              },
            }
          : undefined,
    },
  });

  if (type === "database") {
    const databaseId = makeId("db");
    await prisma.database.create({
      data: {
        id: databaseId,
        pageId: page.id,
        properties: {
          createMany: {
            data: [{ id: makeId("prop"), name: "Name", type: "title", position: 0, configJson: {} }],
          },
        },
      },
    });

    if (body?.createInitialRow !== false) {
      await prisma.databaseRow.create({
        data: {
          id: makeId("row"),
          databaseId,
          title: "Untitled",
          position: 0,
        },
      });
    }
  }

  return NextResponse.json({ page });
}
