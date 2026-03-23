import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireApiAuth } from "@/lib/api-auth";
import { canEditPage, canReadPage, getActiveMembership } from "@/lib/access";
import { makeId } from "@/lib/ids";

async function resolveDatabaseWithPage(id: string, userId: string) {
  return (
    (await prisma.database.findUnique({
      where: { id },
      include: {
        page: {
          include: {
            permissions: { where: { userId } },
          },
        },
      },
    })) ||
    (await prisma.database.findUnique({
      where: { pageId: id },
      include: {
        page: {
          include: {
            permissions: { where: { userId } },
          },
        },
      },
    }))
  );
}

export async function GET(_: Request, { params }: { params: { id: string } }) {
  const auth = requireApiAuth();
  if (!auth.ok) return auth.response;

  const database = await resolveDatabaseWithPage(params.id, auth.session.userId);
  if (!database) return NextResponse.json({ error: "Not found" }, { status: 404 });
  if (database.page.deletedAt) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const membership = await getActiveMembership(auth.session.userId, auth.session.workspaceId);
  if (!membership || membership.workspaceId !== database.page.workspaceId) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const readable = canReadPage({
    accessLevel: database.page.accessLevel,
    workspaceRole: membership.role,
    isPageCreator: database.page.createdById === auth.session.userId,
    permissionRole: database.page.permissions[0]?.role,
  });
  if (!readable) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const rows = await prisma.databaseRow.findMany({
    where: { databaseId: database.id },
    orderBy: { position: "asc" },
    include: { cells: true },
  });

  return NextResponse.json({ rows });
}

export async function POST(request: Request, { params }: { params: { id: string } }) {
  const auth = requireApiAuth();
  if (!auth.ok) return auth.response;

  const database = await resolveDatabaseWithPage(params.id, auth.session.userId);
  if (!database) return NextResponse.json({ error: "Not found" }, { status: 404 });
  if (database.page.deletedAt) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const membership = await getActiveMembership(auth.session.userId, auth.session.workspaceId);
  if (!membership || membership.workspaceId !== database.page.workspaceId) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const editable = canEditPage({
    accessLevel: database.page.accessLevel,
    workspaceRole: membership.role,
    isPageCreator: database.page.createdById === auth.session.userId,
    permissionRole: database.page.permissions[0]?.role,
  });
  if (!editable) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  if (database.page.isLocked) {
    return NextResponse.json({ error: "Page is locked" }, { status: 423 });
  }

  const body = await request.json().catch(() => null);
  const title = body?.title?.toString().trim() || "New Row";

  const lastRow = await prisma.databaseRow.findFirst({
    where: { databaseId: database.id },
    orderBy: { position: "desc" },
  });

  const row = await prisma.databaseRow.create({
    data: {
      id: makeId("row"),
      databaseId: database.id,
      title,
      position: (lastRow?.position ?? -1) + 1,
    },
    include: { cells: true },
  });

  return NextResponse.json({ row });
}
