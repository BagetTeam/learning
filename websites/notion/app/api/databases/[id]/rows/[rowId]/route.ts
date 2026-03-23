import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireApiAuth } from "@/lib/api-auth";
import { canEditPage, getActiveMembership } from "@/lib/access";

async function getRowContext(rowId: string, userId: string) {
  const row = await prisma.databaseRow.findUnique({
    where: { id: rowId },
    include: {
      database: {
        include: {
          page: {
            include: {
              permissions: {
                where: { userId },
              },
            },
          },
        },
      },
    },
  });
  return row;
}

export async function PATCH(request: Request, { params }: { params: { id: string; rowId: string } }) {
  const auth = requireApiAuth();
  if (!auth.ok) return auth.response;

  const row = await getRowContext(params.rowId, auth.session.userId);
  if (!row || (row.database.id !== params.id && row.database.pageId !== params.id)) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
  if (row.database.page.deletedAt) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  const membership = await getActiveMembership(auth.session.userId, auth.session.workspaceId);
  if (!membership || membership.workspaceId !== row.database.page.workspaceId) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const editable = canEditPage({
    accessLevel: row.database.page.accessLevel,
    workspaceRole: membership.role,
    isPageCreator: row.database.page.createdById === auth.session.userId,
    permissionRole: row.database.page.permissions[0]?.role,
  });
  if (!editable) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  if (row.database.page.isLocked) {
    return NextResponse.json({ error: "Page is locked" }, { status: 423 });
  }

  const body = await request.json().catch(() => null);
  const title = body?.title?.toString().trim();
  const targetIndex = Number.isInteger(body?.targetIndex) ? Number(body.targetIndex) : null;

  if (targetIndex !== null) {
    const rows = await prisma.databaseRow.findMany({
      where: { databaseId: row.databaseId },
      orderBy: { position: "asc" },
      select: { id: true },
    });

    const currentIndex = rows.findIndex((item: { id: string }) => item.id === params.rowId);
    if (currentIndex === -1) {
      return NextResponse.json({ error: "Not found" }, { status: 404 });
    }

    const clamped = Math.max(0, Math.min(rows.length - 1, targetIndex));
    if (clamped !== currentIndex) {
      const reordered = [...rows];
      const [moved] = reordered.splice(currentIndex, 1);
      reordered.splice(clamped, 0, moved);

      await prisma.$transaction(
        reordered.map((item: { id: string }, position) =>
          prisma.databaseRow.update({
            where: { id: item.id },
            data: { position },
          })
        )
      );
    }

    const movedRow = await prisma.databaseRow.findUnique({ where: { id: params.rowId } });
    return NextResponse.json({ row: movedRow });
  }

  const updated = await prisma.databaseRow.update({
    where: { id: params.rowId },
    data: { title: title ?? "" },
  });

  return NextResponse.json({ row: updated });
}

export async function DELETE(_: Request, { params }: { params: { id: string; rowId: string } }) {
  const auth = requireApiAuth();
  if (!auth.ok) return auth.response;

  const row = await getRowContext(params.rowId, auth.session.userId);
  if (!row || (row.database.id !== params.id && row.database.pageId !== params.id)) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
  if (row.database.page.deletedAt) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  const membership = await getActiveMembership(auth.session.userId, auth.session.workspaceId);
  if (!membership || membership.workspaceId !== row.database.page.workspaceId) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const editable = canEditPage({
    accessLevel: row.database.page.accessLevel,
    workspaceRole: membership.role,
    isPageCreator: row.database.page.createdById === auth.session.userId,
    permissionRole: row.database.page.permissions[0]?.role,
  });
  if (!editable) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  if (row.database.page.isLocked) {
    return NextResponse.json({ error: "Page is locked" }, { status: 423 });
  }

  await prisma.databaseRow.delete({ where: { id: params.rowId } });
  return NextResponse.json({ ok: true });
}
