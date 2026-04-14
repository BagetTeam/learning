import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireApiAuth } from "@/lib/api-auth";
import { canEditPage, canReadPage, getActiveMembership } from "@/lib/access";
import { makeId } from "@/lib/ids";

const PROPERTY_TYPES = new Set(["title", "text", "select", "multi_select", "checkbox", "date"]);

async function resolveDatabaseWithPage(id: string, userId: string) {
  return (
    (await prisma.database.findUnique({
      where: { id },
      include: {
        properties: { orderBy: { position: "asc" } },
        page: {
          include: {
            permissions: {
              where: { userId },
            },
          },
        },
      },
    })) ||
    (await prisma.database.findUnique({
      where: { pageId: id },
      include: {
        properties: { orderBy: { position: "asc" } },
        page: {
          include: {
            permissions: {
              where: { userId },
            },
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

  if (!database) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  if (database.page.deletedAt) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

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

  return NextResponse.json({ database });
}

export async function PATCH(request: Request, { params }: { params: { id: string } }) {
  const auth = requireApiAuth();
  if (!auth.ok) return auth.response;

  const database = await resolveDatabaseWithPage(params.id, auth.session.userId);
  if (!database) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
  if (database.page.deletedAt) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

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
  const action = body?.action?.toString();

  if (action === "add_property") {
    const type = PROPERTY_TYPES.has(body?.type) ? body.type : "text";
    const name = typeof body?.name === "string" && body.name.trim() ? body.name.trim() : "Property";
    const last = await prisma.databaseProperty.findFirst({
      where: { databaseId: database.id },
      orderBy: { position: "desc" },
      select: { position: true },
    });

    const property = await prisma.databaseProperty.create({
      data: {
        id: makeId("prop"),
        databaseId: database.id,
        name,
        type,
        position: (last?.position ?? -1) + 1,
        configJson: type === "select" || type === "multi_select" ? { options: [] } : {},
      },
    });
    return NextResponse.json({ property });
  }

  return NextResponse.json({ error: "Unsupported action" }, { status: 400 });
}
