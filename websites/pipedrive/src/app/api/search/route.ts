import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import { deals, contacts, companies } from "@/lib/db/schema";
import { auth } from "@/lib/auth";
import { eq } from "drizzle-orm";

export async function GET(req: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const q = (req.nextUrl.searchParams.get("q") || "").toLowerCase();
  if (q.length < 2) return NextResponse.json([]);

  const userId = parseInt(session.user.id);

  const allDeals = db.select().from(deals).where(eq(deals.userId, userId)).all();
  const allContacts = db.select().from(contacts).where(eq(contacts.userId, userId)).all();
  const allCompanies = db.select().from(companies).where(eq(companies.userId, userId)).all();

  const results: { id: number; type: string; title: string; subtitle: string }[] = [];

  allDeals
    .filter((d) => d.title.toLowerCase().includes(q))
    .slice(0, 5)
    .forEach((d) =>
      results.push({
        id: d.id,
        type: "deal",
        title: d.title,
        subtitle: `$${d.value.toLocaleString()} - ${d.status}`,
      })
    );

  allContacts
    .filter(
      (c) =>
        c.firstName.toLowerCase().includes(q) ||
        c.lastName.toLowerCase().includes(q) ||
        (c.email && c.email.toLowerCase().includes(q))
    )
    .slice(0, 5)
    .forEach((c) =>
      results.push({
        id: c.id,
        type: "contact",
        title: `${c.firstName} ${c.lastName}`,
        subtitle: c.email || c.jobTitle || "",
      })
    );

  allCompanies
    .filter(
      (c) =>
        c.name.toLowerCase().includes(q) ||
        (c.domain && c.domain.toLowerCase().includes(q))
    )
    .slice(0, 5)
    .forEach((c) =>
      results.push({
        id: c.id,
        type: "company",
        title: c.name,
        subtitle: c.domain || "",
      })
    );

  return NextResponse.json(results.slice(0, 15));
}
