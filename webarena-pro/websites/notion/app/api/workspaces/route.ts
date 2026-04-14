import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireApiAuth } from "@/lib/api-auth";
import { makeId } from "@/lib/ids";

function slugify(value: string) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)+/g, "")
    .slice(0, 48);
}

export async function GET() {
  const auth = requireApiAuth();
  if (!auth.ok) return auth.response;

  const memberships = await prisma.workspaceMembership.findMany({
    where: { userId: auth.session.userId },
    include: {
      workspace: true,
    },
    orderBy: { createdAt: "asc" },
  });

  return NextResponse.json({
    workspaces: memberships.map((membership: { workspace: { id: string; name: string; slug: string }; role: string; workspaceId: string }) => ({
      id: membership.workspace.id,
      name: membership.workspace.name,
      slug: membership.workspace.slug,
      role: membership.role,
      active: membership.workspaceId === auth.session.workspaceId,
    })),
  });
}

export async function POST(request: Request) {
  const auth = requireApiAuth();
  if (!auth.ok) return auth.response;

  const body = await request.json().catch(() => null);
  const name = body?.name?.toString().trim();
  if (!name) {
    return NextResponse.json({ error: "Workspace name is required" }, { status: 400 });
  }

  const slugBase = slugify(name) || "workspace";
  let slug = slugBase;
  let suffix = 1;
  while (await prisma.workspace.findUnique({ where: { slug } })) {
    slug = `${slugBase}-${suffix}`;
    suffix += 1;
  }

  const workspace = await prisma.workspace.create({
    data: {
      id: makeId("ws"),
      name,
      slug,
      memberships: {
        create: {
          id: makeId("membership"),
          userId: auth.session.userId,
          role: "owner",
        },
      },
    },
  });

  return NextResponse.json({ workspace });
}
