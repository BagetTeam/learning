import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { deals, activities, pipelineStages } from "@/lib/db/schema";
import { auth } from "@/lib/auth";
import { eq, desc } from "drizzle-orm";

export async function GET() {
  const session = await auth();
  if (!session?.user?.id) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const userId = parseInt(session.user.id);

  const allDeals = db.select().from(deals).where(eq(deals.userId, userId)).all();
  const allStages = db.select().from(pipelineStages).all();
  const allActivities = db
    .select()
    .from(activities)
    .where(eq(activities.userId, userId))
    .orderBy(desc(activities.createdAt))
    .all();

  const openDeals = allDeals.filter((d) => d.status === "open");
  const wonDeals = allDeals.filter((d) => d.status === "won");
  const lostDeals = allDeals.filter((d) => d.status === "lost");

  // Summary cards
  const totalOpenValue = openDeals.reduce((sum, d) => sum + d.value, 0);
  const totalWonValue = wonDeals.reduce((sum, d) => sum + d.value, 0);
  const winRate =
    wonDeals.length + lostDeals.length > 0
      ? Math.round((wonDeals.length / (wonDeals.length + lostDeals.length)) * 100)
      : 0;

  // Activities this week
  const weekAgo = new Date();
  weekAgo.setDate(weekAgo.getDate() - 7);
  const weekStr = weekAgo.toISOString().split("T")[0];
  const activitiesThisWeek = allActivities.filter(
    (a) => a.dueDate && a.dueDate >= weekStr
  ).length;

  // Deals by stage
  const stageMap = new Map(allStages.map((s) => [s.id, s]));
  const dealsByStage = allStages
    .sort((a, b) => a.position - b.position)
    .map((stage) => {
      const stageDeals = openDeals.filter((d) => d.stageId === stage.id);
      return {
        stage: stage.name,
        count: stageDeals.length,
        value: stageDeals.reduce((sum, d) => sum + d.value, 0),
      };
    });

  // Revenue forecast (next 6 months, weighted by stage probability)
  const forecast: { month: string; weighted: number; total: number }[] = [];
  for (let i = 0; i < 6; i++) {
    const date = new Date();
    date.setMonth(date.getMonth() + i);
    const monthStr = date.toISOString().slice(0, 7);
    const monthLabel = date.toLocaleDateString("en-US", { month: "short", year: "numeric" });

    const monthDeals = openDeals.filter(
      (d) => d.expectedCloseDate && d.expectedCloseDate.slice(0, 7) === monthStr
    );

    const total = monthDeals.reduce((sum, d) => sum + d.value, 0);
    const weighted = monthDeals.reduce((sum, d) => {
      const stage = stageMap.get(d.stageId);
      const prob = stage ? stage.probability / 100 : 0;
      return sum + d.value * prob;
    }, 0);

    forecast.push({ month: monthLabel, weighted: Math.round(weighted), total: Math.round(total) });
  }

  // Won/Lost breakdown
  const wonLost = [
    { name: "Won", value: wonDeals.length },
    { name: "Lost", value: lostDeals.length },
  ];

  // Recent activities
  const recentActivities = allActivities.slice(0, 10).map((a) => ({
    id: a.id,
    type: a.type,
    subject: a.subject,
    dueDate: a.dueDate,
    isDone: a.isDone,
    createdAt: a.createdAt,
  }));

  return NextResponse.json({
    summary: {
      openDeals: openDeals.length,
      totalOpenValue,
      totalWonValue,
      winRate,
      activitiesThisWeek,
    },
    dealsByStage,
    forecast,
    wonLost,
    recentActivities,
  });
}
