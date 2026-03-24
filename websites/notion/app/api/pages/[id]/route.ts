import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireApiAuth } from "@/lib/api-auth";
import { canEditPage, canReadPage, getPageAccessContext } from "@/lib/access";

async function collectDescendants(rootId: string, workspaceId: string) {
  const pages = await prisma.page.findMany({
    where: { workspaceId },
    select: { id: true, parentPageId: true },
  });

  const childrenMap = new Map<string | null, string[]>();
  for (const page of pages) {
    const key = page.parentPageId ?? null;
    const list = childrenMap.get(key) ?? [];
    list.push(page.id);
    childrenMap.set(key, list);
  }

  const ids: string[] = [];
  const stack = [rootId];
  while (stack.length) {
    const current = stack.pop()!;
    ids.push(current);
    const children = childrenMap.get(current) ?? [];
    stack.push(...children);
  }

  return ids;
}

export async function GET(request: Request, { params }: { params: { id: string } }) {
  const auth = requireApiAuth();
  if (!auth.ok) return auth.response;

  const requestUrl = new URL(request.url);
  const includeTrashed = requestUrl.searchParams.get("includeTrashed") === "1";

  const context = await getPageAccessContext({
    pageId: params.id,
    userId: auth.session.userId,
    preferredWorkspaceId: auth.session.workspaceId,
    includeTrashed,
  });
  if (!context.ok) return context.response;

  const readable = canReadPage({
    accessLevel: context.page.accessLevel,
    workspaceRole: context.membership.role,
    isPageCreator: context.page.createdById === auth.session.userId,
    permissionRole: context.permissionRole,
  });
  if (!readable) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const page = await prisma.page.findUnique({
    where: { id: params.id },
    include: {
      permissions: {
        include: { user: { select: { id: true, email: true } } },
      },
    },
  });

  return NextResponse.json({ page });
}

export async function PATCH(request: Request, { params }: { params: { id: string } }) {
  const auth = requireApiAuth();
  if (!auth.ok) return auth.response;

  const context = await getPageAccessContext({
    pageId: params.id,
    userId: auth.session.userId,
    preferredWorkspaceId: auth.session.workspaceId,
    includeTrashed: true,
  });
  if (!context.ok) return context.response;

  const editable = canEditPage({
    accessLevel: context.page.accessLevel,
    workspaceRole: context.membership.role,
    isPageCreator: context.page.createdById === auth.session.userId,
    permissionRole: context.permissionRole,
  });
  if (!editable) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const body = await request.json().catch(() => null);
  const data: {
    title?: string;
    parentPageId?: string | null;
    accessLevel?: "workspace" | "private";
    icon?: string | null;
    deletedAt?: Date | null;
    isSmallText?: boolean;
    isFullWidth?: boolean;
    isLocked?: boolean;
    fontStyle?: "default" | "serif" | "mono";
  } = {};

  if (typeof body?.title === "string") {
    data.title = body.title.trim() || "Untitled";
  }

  if (body?.parentPageId !== undefined) {
    const parentPageId = body.parentPageId ? String(body.parentPageId) : null;
    if (parentPageId === params.id) {
      return NextResponse.json({ error: "Invalid parent" }, { status: 400 });
    }
    if (parentPageId) {
      const parent = await prisma.page.findUnique({ where: { id: parentPageId } });
      if (!parent || parent.workspaceId !== context.page.workspaceId || parent.deletedAt) {
        return NextResponse.json({ error: "Invalid parent" }, { status: 400 });
      }
    }
    data.parentPageId = parentPageId;
  }

  if (body?.accessLevel === "workspace" || body?.accessLevel === "private") {
    data.accessLevel = body.accessLevel;
  }

  if (body?.icon !== undefined) {
    data.icon = body.icon ? String(body.icon) : null;
  }

  if (body?.trashAction === "move") {
    const ids = await collectDescendants(params.id, context.page.workspaceId);
    const deletedAt = new Date();
    await prisma.page.updateMany({
      where: { id: { in: ids }, workspaceId: context.page.workspaceId },
      data: { deletedAt },
    });
    const page = await prisma.page.findUnique({ where: { id: params.id } });
    return NextResponse.json({ page });
  }

  if (body?.trashAction === "restore") {
    const ids = await collectDescendants(params.id, context.page.workspaceId);
    await prisma.page.updateMany({
      where: { id: { in: ids }, workspaceId: context.page.workspaceId },
      data: { deletedAt: null },
    });
    const page = await prisma.page.findUnique({ where: { id: params.id } });
    return NextResponse.json({ page });
  }

  if (body?.isSmallText !== undefined) {
    data.isSmallText = Boolean(body.isSmallText);
  }

  if (body?.isFullWidth !== undefined) {
    data.isFullWidth = Boolean(body.isFullWidth);
  }

  if (body?.isLocked !== undefined) {
    data.isLocked = Boolean(body.isLocked);
  }

  if (body?.fontStyle === "default" || body?.fontStyle === "serif" || body?.fontStyle === "mono") {
    data.fontStyle = body.fontStyle;
  }

  const page = await prisma.page.update({
    where: { id: params.id },
    data,
  });

  return NextResponse.json({ page });
}

export async function DELETE(request: Request, { params }: { params: { id: string } }) {
  const auth = requireApiAuth();
  if (!auth.ok) return auth.response;

  const requestUrl = new URL(request.url);
  const permanent = requestUrl.searchParams.get("permanent") === "1";

  const context = await getPageAccessContext({
    pageId: params.id,
    userId: auth.session.userId,
    preferredWorkspaceId: auth.session.workspaceId,
    includeTrashed: true,
  });
  if (!context.ok) return context.response;

  const editable = canEditPage({
    accessLevel: context.page.accessLevel,
    workspaceRole: context.membership.role,
    isPageCreator: context.page.createdById === auth.session.userId,
    permissionRole: context.permissionRole,
  });
  if (!editable) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const ids = await collectDescendants(params.id, context.page.workspaceId);
  if (permanent) {
    await prisma.page.deleteMany({
      where: { id: { in: ids }, workspaceId: context.page.workspaceId, deletedAt: { not: null } },
    });
  } else {
    await prisma.page.updateMany({
      where: { id: { in: ids }, workspaceId: context.page.workspaceId },
      data: { deletedAt: new Date() },
    });
  }

  return NextResponse.json({ ok: true });
}
