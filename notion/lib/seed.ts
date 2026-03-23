import { PrismaClient } from "@prisma/client";
import { hashPassword } from "./password";

const SEED_DATE = new Date("2024-01-01T00:00:00.000Z");

export async function resetDatabase(prisma: PrismaClient) {
  await prisma.commentMention.deleteMany();
  await prisma.comment.deleteMany();
  await prisma.attachment.deleteMany();
  await prisma.shareLink.deleteMany();
  await prisma.pagePermission.deleteMany();
  await prisma.workspaceTab.deleteMany();
  await prisma.databaseCellValue.deleteMany();
  await prisma.databaseRow.deleteMany();
  await prisma.databaseProperty.deleteMany();
  await prisma.database.deleteMany();
  await prisma.block.deleteMany();
  await prisma.page.deleteMany();
  await prisma.workspaceMembership.deleteMany();
  await prisma.workspace.deleteMany();
  await prisma.user.deleteMany();

  await prisma.user.createMany({
    data: [
      {
        id: "user_demo",
        email: "demo@webarena.local",
        passwordHash: hashPassword("password123"),
        createdAt: SEED_DATE,
      },
      {
        id: "user_alex",
        email: "alex@webarena.local",
        passwordHash: hashPassword("password123"),
        createdAt: SEED_DATE,
      },
      {
        id: "user_mina",
        email: "mina@webarena.local",
        passwordHash: hashPassword("password123"),
        createdAt: SEED_DATE,
      },
    ],
  });

  await prisma.workspace.createMany({
    data: [
      {
        id: "ws_webarena",
        slug: "webarena-hq",
        name: "WebArena HQ",
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "ws_research",
        slug: "research-lab",
        name: "Research Lab",
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
    ],
  });

  await prisma.workspaceMembership.createMany({
    data: [
      {
        id: "membership_demo_hq",
        workspaceId: "ws_webarena",
        userId: "user_demo",
        role: "owner",
        lastActiveAt: SEED_DATE,
        createdAt: SEED_DATE,
      },
      {
        id: "membership_alex_hq",
        workspaceId: "ws_webarena",
        userId: "user_alex",
        role: "editor",
        lastActiveAt: SEED_DATE,
        createdAt: SEED_DATE,
      },
      {
        id: "membership_mina_hq",
        workspaceId: "ws_webarena",
        userId: "user_mina",
        role: "viewer",
        lastActiveAt: SEED_DATE,
        createdAt: SEED_DATE,
      },
      {
        id: "membership_demo_lab",
        workspaceId: "ws_research",
        userId: "user_demo",
        role: "owner",
        lastActiveAt: SEED_DATE,
        createdAt: SEED_DATE,
      },
      {
        id: "membership_alex_lab",
        workspaceId: "ws_research",
        userId: "user_alex",
        role: "editor",
        lastActiveAt: SEED_DATE,
        createdAt: SEED_DATE,
      },
    ],
  });

  const pages = [
    {
      id: "page_team_notes",
      workspaceId: "ws_webarena",
      createdById: "user_demo",
      title: "Team Notes",
      type: "document" as const,
      accessLevel: "workspace" as const,
      parentPageId: null,
      icon: "note",
    },
    {
      id: "page_project_alpha",
      workspaceId: "ws_webarena",
      createdById: "user_demo",
      title: "Project Alpha",
      type: "document" as const,
      accessLevel: "workspace" as const,
      parentPageId: null,
      icon: "rocket",
    },
    {
      id: "page_hiring_plan",
      workspaceId: "ws_webarena",
      createdById: "user_alex",
      title: "Hiring Plan",
      type: "document" as const,
      accessLevel: "workspace" as const,
      parentPageId: null,
      icon: "team",
    },
    {
      id: "page_hiring_private",
      workspaceId: "ws_webarena",
      createdById: "user_alex",
      title: "Hiring Compensation Matrix",
      type: "document" as const,
      accessLevel: "private" as const,
      parentPageId: "page_hiring_plan",
      icon: "lock",
    },
    {
      id: "page_hiring_plan_interview",
      workspaceId: "ws_webarena",
      createdById: "user_alex",
      title: "Interview Loop",
      type: "document" as const,
      accessLevel: "workspace" as const,
      parentPageId: "page_hiring_plan",
      icon: null,
    },
    {
      id: "page_hiring_plan_offer",
      workspaceId: "ws_webarena",
      createdById: "user_alex",
      title: "Offer Checklist",
      type: "document" as const,
      accessLevel: "workspace" as const,
      parentPageId: "page_hiring_plan",
      icon: null,
    },
    {
      id: "page_task_tracker",
      workspaceId: "ws_webarena",
      createdById: "user_demo",
      title: "Task Tracker",
      type: "database" as const,
      accessLevel: "workspace" as const,
      parentPageId: null,
      icon: "table",
    },
    {
      id: "page_lab_notes",
      workspaceId: "ws_research",
      createdById: "user_demo",
      title: "Experiment Notes",
      type: "document" as const,
      accessLevel: "workspace" as const,
      parentPageId: null,
      icon: "lab",
    },
  ];

  for (const page of pages.filter((item) => !item.parentPageId)) {
    await prisma.page.create({
      data: {
        ...page,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
    });
  }

  for (const page of pages.filter((item) => item.parentPageId)) {
    await prisma.page.create({
      data: {
        ...page,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
    });
  }

  await prisma.pagePermission.createMany({
    data: [
      {
        id: "perm_hiring_private_demo",
        pageId: "page_hiring_private",
        userId: "user_demo",
        role: "editor",
        createdAt: SEED_DATE,
      },
      {
        id: "perm_hiring_private_alex",
        pageId: "page_hiring_private",
        userId: "user_alex",
        role: "editor",
        createdAt: SEED_DATE,
      },
      {
        id: "perm_hiring_private_mina",
        pageId: "page_hiring_private",
        userId: "user_mina",
        role: "viewer",
        createdAt: SEED_DATE,
      },
    ],
  });

  await prisma.workspaceTab.createMany({
    data: [
      {
        id: "tab_demo_1",
        membershipId: "membership_demo_hq",
        pageId: "page_team_notes",
        position: 0,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "tab_demo_2",
        membershipId: "membership_demo_hq",
        pageId: "page_task_tracker",
        position: 1,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "tab_demo_3",
        membershipId: "membership_demo_hq",
        pageId: "page_hiring_plan",
        position: 2,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "tab_alex_1",
        membershipId: "membership_alex_hq",
        pageId: "page_project_alpha",
        position: 0,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "tab_alex_2",
        membershipId: "membership_alex_hq",
        pageId: "page_hiring_private",
        position: 1,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
    ],
  });

  await prisma.block.createMany({
    data: [
      {
        id: "block_team_1",
        pageId: "page_team_notes",
        type: "paragraph",
        contentText: "Welcome to the WebArena team space.",
        position: 0,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_team_2",
        pageId: "page_team_notes",
        type: "paragraph",
        contentText: "Weekly focus: ship the multi-workspace MVP.",
        position: 1,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_team_3",
        pageId: "page_team_notes",
        type: "image",
        contentText: "Roadmap draft",
        imageUrl: "/uploads/roadmap-seed.png",
        position: 2,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_team_4",
        pageId: "page_team_notes",
        type: "todo",
        contentText: "Finalize seed dataset",
        checked: true,
        position: 3,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_team_5",
        pageId: "page_team_notes",
        type: "todo",
        contentText: "Review evaluator APIs",
        checked: false,
        position: 4,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_team_6",
        pageId: "page_team_notes",
        type: "todo",
        contentText: "Collect feedback from Alex",
        checked: false,
        position: 5,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_alpha_1",
        pageId: "page_project_alpha",
        type: "heading_1",
        contentText: "Project Alpha",
        position: 0,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_alpha_2",
        pageId: "page_project_alpha",
        type: "paragraph",
        contentText: "Multi-user Notion-like sandbox for evaluation.",
        position: 1,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_alpha_3",
        pageId: "page_project_alpha",
        type: "bulleted_list_item",
        contentText: "Workspace membership and permissions",
        position: 2,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_alpha_4",
        pageId: "page_project_alpha",
        type: "bulleted_list_item",
        contentText: "Comments, mentions, and share links",
        position: 3,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_hiring_1",
        pageId: "page_hiring_plan",
        type: "heading_1",
        contentText: "Hiring Plan",
        position: 0,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_hiring_2",
        pageId: "page_hiring_plan",
        type: "paragraph",
        contentText: "Focus on product-minded engineers.",
        position: 1,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_hiring_private_1",
        pageId: "page_hiring_private",
        type: "heading_2",
        contentText: "Compensation Matrix",
        position: 0,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_hiring_private_2",
        pageId: "page_hiring_private",
        type: "paragraph",
        contentText: "Level 4 range: confidential.",
        position: 1,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_lab_1",
        pageId: "page_lab_notes",
        type: "heading_1",
        contentText: "Experiment Notes",
        position: 0,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "block_lab_2",
        pageId: "page_lab_notes",
        type: "paragraph",
        contentText: "Workspace-isolated notes for research team.",
        position: 1,
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
    ],
  });

  await prisma.database.create({
    data: {
      id: "db_task_tracker",
      pageId: "page_task_tracker",
      createdAt: SEED_DATE,
      updatedAt: SEED_DATE,
    },
  });

  await prisma.databaseProperty.createMany({
    data: [
      {
        id: "prop_name",
        databaseId: "db_task_tracker",
        name: "Name",
        type: "title",
        position: 0,
        configJson: {},
      },
      {
        id: "prop_status",
        databaseId: "db_task_tracker",
        name: "Status",
        type: "select",
        position: 1,
        configJson: { options: ["Not Started", "In Progress", "Blocked", "Done"] },
      },
      {
        id: "prop_priority",
        databaseId: "db_task_tracker",
        name: "Priority",
        type: "select",
        position: 2,
        configJson: { options: ["Low", "Medium", "High"] },
      },
      {
        id: "prop_done",
        databaseId: "db_task_tracker",
        name: "Done",
        type: "checkbox",
        position: 3,
        configJson: {},
      },
      {
        id: "prop_due",
        databaseId: "db_task_tracker",
        name: "Due Date",
        type: "date",
        position: 4,
        configJson: {},
      },
    ],
  });

  await prisma.databaseRow.createMany({
    data: [
      { id: "row_1", databaseId: "db_task_tracker", title: "Design permissions API", position: 0, createdAt: SEED_DATE, updatedAt: SEED_DATE },
      { id: "row_2", databaseId: "db_task_tracker", title: "Implement share link page", position: 1, createdAt: SEED_DATE, updatedAt: SEED_DATE },
      { id: "row_3", databaseId: "db_task_tracker", title: "Ship comment mentions", position: 2, createdAt: SEED_DATE, updatedAt: SEED_DATE },
      { id: "row_4", databaseId: "db_task_tracker", title: "Attachment flow", position: 3, createdAt: SEED_DATE, updatedAt: SEED_DATE },
      { id: "row_5", databaseId: "db_task_tracker", title: "Finalize reset semantics", position: 4, createdAt: SEED_DATE, updatedAt: SEED_DATE },
    ],
  });

  await prisma.databaseCellValue.createMany({
    data: [
      { id: "cell_1_status", rowId: "row_1", propertyId: "prop_status", valueJson: "In Progress" },
      { id: "cell_1_priority", rowId: "row_1", propertyId: "prop_priority", valueJson: "High" },
      { id: "cell_1_done", rowId: "row_1", propertyId: "prop_done", valueJson: false },
      { id: "cell_1_due", rowId: "row_1", propertyId: "prop_due", valueJson: "2024-02-10" },
      { id: "cell_2_status", rowId: "row_2", propertyId: "prop_status", valueJson: "Not Started" },
      { id: "cell_2_priority", rowId: "row_2", propertyId: "prop_priority", valueJson: "Medium" },
      { id: "cell_2_done", rowId: "row_2", propertyId: "prop_done", valueJson: false },
      { id: "cell_2_due", rowId: "row_2", propertyId: "prop_due", valueJson: "2024-02-11" },
      { id: "cell_3_status", rowId: "row_3", propertyId: "prop_status", valueJson: "Done" },
      { id: "cell_3_priority", rowId: "row_3", propertyId: "prop_priority", valueJson: "Low" },
      { id: "cell_3_done", rowId: "row_3", propertyId: "prop_done", valueJson: true },
      { id: "cell_3_due", rowId: "row_3", propertyId: "prop_due", valueJson: "2024-01-20" },
      { id: "cell_4_status", rowId: "row_4", propertyId: "prop_status", valueJson: "In Progress" },
      { id: "cell_4_priority", rowId: "row_4", propertyId: "prop_priority", valueJson: "High" },
      { id: "cell_4_done", rowId: "row_4", propertyId: "prop_done", valueJson: false },
      { id: "cell_4_due", rowId: "row_4", propertyId: "prop_due", valueJson: "2024-02-15" },
      { id: "cell_5_status", rowId: "row_5", propertyId: "prop_status", valueJson: "In Progress" },
      { id: "cell_5_priority", rowId: "row_5", propertyId: "prop_priority", valueJson: "High" },
      { id: "cell_5_done", rowId: "row_5", propertyId: "prop_done", valueJson: false },
      { id: "cell_5_due", rowId: "row_5", propertyId: "prop_due", valueJson: "2024-02-08" },
    ],
  });

  await prisma.comment.createMany({
    data: [
      {
        id: "comment_1",
        pageId: "page_team_notes",
        authorId: "user_alex",
        content: "@demo@webarena.local, can we expose permissions in evaluator API too?",
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "comment_2",
        pageId: "page_team_notes",
        authorId: "user_demo",
        parentCommentId: "comment_1",
        content: "Yes. I will add it with workspace scoping.",
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
      {
        id: "comment_3",
        pageId: "page_hiring_private",
        authorId: "user_alex",
        content: "@mina@webarena.local has view-only access here.",
        createdAt: SEED_DATE,
        updatedAt: SEED_DATE,
      },
    ],
  });

  await prisma.commentMention.createMany({
    data: [
      {
        id: "mention_1",
        commentId: "comment_1",
        userId: "user_demo",
        createdAt: SEED_DATE,
      },
      {
        id: "mention_2",
        commentId: "comment_3",
        userId: "user_mina",
        createdAt: SEED_DATE,
      },
    ],
  });

  await prisma.attachment.createMany({
    data: [
      {
        id: "attachment_1",
        pageId: "page_team_notes",
        uploadedById: "user_demo",
        fileName: "architecture-v2.pdf",
        fileUrl: "/uploads/architecture-v2.pdf",
        mimeType: "application/pdf",
        sizeBytes: 124500,
        createdAt: SEED_DATE,
      },
      {
        id: "attachment_2",
        pageId: "page_project_alpha",
        uploadedById: "user_alex",
        fileName: "roadmap.png",
        fileUrl: "/uploads/roadmap.png",
        mimeType: "image/png",
        sizeBytes: 85321,
        createdAt: SEED_DATE,
      },
    ],
  });

  await prisma.shareLink.createMany({
    data: [
      {
        id: "share_1",
        token: "share_team_notes_public",
        pageId: "page_team_notes",
        createdById: "user_demo",
        isActive: true,
        createdAt: SEED_DATE,
      },
      {
        id: "share_2",
        token: "share_project_alpha_review",
        pageId: "page_project_alpha",
        createdById: "user_alex",
        isActive: true,
        createdAt: SEED_DATE,
      },
    ],
  });
}
