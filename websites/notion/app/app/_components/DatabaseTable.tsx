"use client";

import { useMemo, useState, type ReactNode } from "react";
import { Database, Eye, Plus, Settings2, SlidersHorizontal, X } from "lucide-react";

type DatabaseProperty = {
  id: string;
  name: string;
  type: "title" | "text" | "select" | "multi_select" | "checkbox" | "date";
  position: number;
  configJson: any;
};

type DatabaseCell = {
  id: string;
  rowId: string;
  propertyId: string;
  valueJson: any;
};

type DatabaseRow = {
  id: string;
  databaseId: string;
  title: string;
  position: number;
  createdAt: string;
  updatedAt: string;
  cells: DatabaseCell[];
};

type DatabasePayload = {
  id: string;
  pageId: string;
  properties: DatabaseProperty[];
  rows: DatabaseRow[];
};

export default function DatabaseTable({ database }: { database: DatabasePayload }) {
  const [rows, setRows] = useState<DatabaseRow[]>(database.rows);
  const [properties, setProperties] = useState<DatabaseProperty[]>(database.properties);
  const [draggingRowId, setDraggingRowId] = useState<string | null>(null);
  const [showSettings, setShowSettings] = useState(false);
  const [viewName, setViewName] = useState("Table");
  const [propertyMenuOpen, setPropertyMenuOpen] = useState(false);
  const [newPropertyName, setNewPropertyName] = useState("");
  const [newPropertyType, setNewPropertyType] = useState<DatabaseProperty["type"]>("text");

  const propertyTypes: { value: DatabaseProperty["type"]; label: string }[] = [
    { value: "text", label: "Text" },
    { value: "select", label: "Select" },
    { value: "multi_select", label: "Multi select" },
    { value: "checkbox", label: "Checkbox" },
    { value: "date", label: "Date" },
  ];

  const sortedRows = useMemo(() => [...rows].sort((a, b) => a.position - b.position), [rows]);
  const sortedProperties = useMemo(() => [...properties].sort((a, b) => a.position - b.position), [properties]);

  function getCellValue(row: DatabaseRow, property: DatabaseProperty) {
    if (property.type === "title") return row.title;
    return row.cells.find((cell) => cell.propertyId === property.id)?.valueJson;
  }

  async function addRow() {
    const response = await fetch(`/api/databases/${database.id}/rows`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title: "New page" }),
    });
    if (!response.ok) return;
    const data = await response.json();
    setRows((prev) => [...prev, data.row]);
  }

  async function updateRowTitle(rowId: string, title: string) {
    setRows((prev) => prev.map((row) => (row.id === rowId ? { ...row, title } : row)));
    await fetch(`/api/databases/${database.id}/rows/${rowId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title }),
    });
  }

  async function updateCell(rowId: string, propertyId: string, value: any) {
    setRows((prev) =>
      prev.map((row) => {
        if (row.id !== rowId) return row;
        const existing = row.cells.find((cell) => cell.propertyId === propertyId);
        if (existing) {
          return {
            ...row,
            cells: row.cells.map((cell) => (cell.propertyId === propertyId ? { ...cell, valueJson: value } : cell)),
          };
        }
        return {
          ...row,
          cells: [...row.cells, { id: `temp_${propertyId}_${rowId}`, rowId, propertyId, valueJson: value } as DatabaseCell],
        };
      })
    );

    await fetch(`/api/databases/${database.id}/cells`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ rowId, propertyId, value }),
    });
  }

  async function moveRow(rowId: string, targetIndex: number) {
    const sourceIndex = sortedRows.findIndex((row) => row.id === rowId);
    if (sourceIndex === -1) return;

    const clamped = Math.max(0, Math.min(sortedRows.length - 1, targetIndex));
    if (sourceIndex === clamped) return;

    const reordered = [...sortedRows];
    const [moved] = reordered.splice(sourceIndex, 1);
    reordered.splice(clamped, 0, moved);
    setRows(reordered.map((row, index) => ({ ...row, position: index })));

    await fetch(`/api/databases/${database.id}/rows/${rowId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ targetIndex: clamped }),
    });
  }

  async function addProperty(type: DatabaseProperty["type"], customName?: string) {
    const name = customName?.trim() || prompt("Property name")?.trim();
    if (!name) return;
    const response = await fetch(`/api/databases/${database.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "add_property", name, type }),
    });
    if (!response.ok) return;
    const data = await response.json();
    setProperties((prev) => [...prev, data.property]);
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <div className="inline-flex items-center gap-2 rounded-full bg-[var(--hover)] px-3 py-1 text-sm font-medium">
          <Database className="h-4 w-4" />
          <span>{viewName}</span>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowSettings((prev) => !prev)}
            className="inline-flex h-10 w-10 items-center justify-center rounded-md border border-[var(--line)] bg-[var(--panel)] hover:bg-[var(--hover)]"
            title="View settings"
          >
            <SlidersHorizontal className="h-4 w-4" />
          </button>
          <button
            onClick={addRow}
            className="inline-flex items-center gap-2 rounded-md bg-[var(--blue)] px-4 py-2 text-sm font-semibold text-white hover:brightness-95"
          >
            <Plus className="h-4 w-4" />
            New
          </button>
        </div>
      </div>

      <div className="overflow-auto rounded-md border border-[var(--line)] bg-[var(--panel)]">
          <table className="min-w-full text-sm">
            <thead>
              <tr className="border-b border-[var(--line)] bg-[var(--surface)]">
                {sortedProperties.map((property) => (
                  <th key={property.id} className="px-3 py-2 text-left text-sm font-semibold tracking-normal text-[var(--muted)]">
                    {property.type === "title" ? "Aa" : ""} {property.name}
                  </th>
                ))}
                <th className="px-3 py-2 text-left">
                  <div className="relative inline-block">
                    <button
                      onClick={() => setPropertyMenuOpen((prev) => !prev)}
                      className="inline-flex items-center gap-1 rounded px-1 py-1 text-sm text-[var(--muted)] hover:bg-[var(--hover)]"
                    >
                      <Plus className="h-4 w-4" />
                      Add property
                    </button>

                    {propertyMenuOpen ? (
                      <div className="absolute left-0 top-[105%] z-20 w-[260px] rounded-md border border-[var(--line)] bg-[var(--panel)] p-2 shadow-lg">
                        <input
                          value={newPropertyName}
                          onChange={(event) => setNewPropertyName(event.target.value)}
                          placeholder="Property name"
                          className="mb-2 w-full rounded border border-[var(--line)] bg-[var(--panel)] px-2 py-1.5"
                        />
                        <select
                          value={newPropertyType}
                          onChange={(event) => setNewPropertyType(event.target.value as DatabaseProperty["type"])}
                          className="mb-2 w-full rounded border border-[var(--line)] bg-[var(--panel)] px-2 py-1.5"
                        >
                          {propertyTypes.map((item) => (
                            <option key={item.value} value={item.value}>
                              {item.label}
                            </option>
                          ))}
                        </select>
                        <div className="flex justify-end gap-2">
                          <button onClick={() => setPropertyMenuOpen(false)} className="rounded border border-[var(--line)] px-2 py-1 text-xs hover:bg-[var(--hover)]">
                            Cancel
                          </button>
                          <button
                            onClick={async () => {
                              await addProperty(newPropertyType, newPropertyName);
                              setPropertyMenuOpen(false);
                              setNewPropertyName("");
                            }}
                            className="rounded border border-[var(--line)] px-2 py-1 text-xs hover:bg-[var(--hover)]"
                          >
                            Create
                          </button>
                        </div>
                      </div>
                    ) : null}
                  </div>
                </th>
              </tr>
            </thead>
            <tbody>
              {sortedRows.map((row) => (
                <tr
                  key={row.id}
                  draggable
                  onDragStart={() => setDraggingRowId(row.id)}
                  onDragEnd={() => setDraggingRowId(null)}
                  onDragOver={(event) => event.preventDefault()}
                  onDrop={(event) => {
                    event.preventDefault();
                    if (!draggingRowId || draggingRowId === row.id) return;
                    const targetIndex = sortedRows.findIndex((candidate) => candidate.id === row.id);
                    if (targetIndex >= 0) {
                      moveRow(draggingRowId, targetIndex);
                    }
                  }}
                  className="border-b border-[var(--line)] hover:bg-[var(--hover)]"
                >
                  {sortedProperties.map((property) => (
                    <td key={property.id} className="px-3 py-2 align-top">
                      <CellEditor row={row} property={property} updateRowTitle={updateRowTitle} updateCell={updateCell} />
                    </td>
                  ))}
                  <td className="px-3 py-2" />
                </tr>
              ))}
              <tr>
                <td colSpan={sortedProperties.length + 1} className="px-3 py-2">
                  <button onClick={addRow} className="inline-flex items-center gap-2 text-[var(--muted)] hover:text-[var(--text)]">
                    <Plus className="h-4 w-4" />
                    New page
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
      </div>

      {showSettings ? (
        <div className="fixed inset-0 z-30 flex justify-end bg-black/20 p-6">
          <aside className="h-fit w-[420px] rounded-md border border-[var(--line)] bg-[var(--panel)] p-4 shadow-xl">
            <div className="mb-3 flex items-center justify-between">
              <p className="text-2xl font-semibold">View settings</p>
              <button onClick={() => setShowSettings(false)} className="rounded p-1 text-[var(--muted)] hover:bg-[var(--hover)]">
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="mb-3 flex items-center gap-2 rounded-md border border-[var(--line)] px-3 py-2">
              <Database className="h-4 w-4 text-[var(--muted)]" />
              <input
                value={viewName}
                onChange={(event) => setViewName(event.target.value)}
                className="w-full border-0 bg-transparent outline-none"
                placeholder="View name"
              />
            </div>

            <div className="space-y-1">
              <SettingsRow icon={<Database className="h-4 w-4" />} label="Layout" value="Table" />
              <SettingsRow icon={<Eye className="h-4 w-4" />} label="Property visibility" value={`${sortedProperties.length}`} />
              <SettingsRow icon={<SlidersHorizontal className="h-4 w-4" />} label="Filter" />
              <SettingsRow icon={<SlidersHorizontal className="h-4 w-4" />} label="Sort" />
              <SettingsRow icon={<SlidersHorizontal className="h-4 w-4" />} label="Group" />
              <SettingsRow icon={<Settings2 className="h-4 w-4" />} label="Conditional color" />
              <SettingsRow icon={<Settings2 className="h-4 w-4" />} label="Create/view automation" />
              <SettingsRow icon={<Settings2 className="h-4 w-4" />} label="Open as full page" />
              <SettingsRow icon={<Settings2 className="h-4 w-4" />} label="Copy link to view" />
            </div>

            <div className="my-4 border-t border-[var(--line)]" />
            <p className="mb-2 text-sm font-semibold text-[var(--muted)]">Edit properties</p>
            <div className="flex flex-wrap gap-2">
              {propertyTypes.map((item) => (
                <button
                  key={item.value}
                  onClick={() => addProperty(item.value)}
                  className="rounded-md border border-[var(--line)] px-2 py-1 text-xs hover:bg-[var(--hover)]"
                >
                  + {item.label}
                </button>
              ))}
            </div>
          </aside>
        </div>
      ) : null}
    </div>
  );
}

function SettingsRow({ icon, label, value }: { icon: ReactNode; label: string; value?: string }) {
  return (
    <button className="flex w-full items-center justify-between rounded-md px-2 py-2 text-left hover:bg-[var(--hover)]">
      <span className="inline-flex items-center gap-2">
        <span className="text-[var(--muted)]">{icon}</span>
        <span>{label}</span>
      </span>
      {value ? <span className="text-[var(--muted)]">{value}</span> : null}
    </button>
  );
}

function CellEditor({
  row,
  property,
  updateRowTitle,
  updateCell,
}: {
  row: DatabaseRow;
  property: DatabaseProperty;
  updateRowTitle: (rowId: string, title: string) => Promise<void>;
  updateCell: (rowId: string, propertyId: string, value: any) => Promise<void>;
}) {
  const value = property.type === "title" ? row.title : row.cells.find((cell) => cell.propertyId === property.id)?.valueJson;
  const options = Array.isArray(property.configJson?.options) ? property.configJson.options : [];

  if (property.type === "title") {
    return <input value={row.title} onChange={(event) => updateRowTitle(row.id, event.target.value)} className="w-full border-0 bg-transparent px-0 py-1 outline-none" />;
  }

  if (property.type === "checkbox") {
    return <input type="checkbox" checked={Boolean(value)} onChange={(event) => updateCell(row.id, property.id, event.target.checked)} className="h-4 w-4" />;
  }

  if (property.type === "select") {
    return (
      <select value={value ?? ""} onChange={(event) => updateCell(row.id, property.id, event.target.value)} className="w-full rounded border border-[var(--line)] bg-[var(--panel)] px-2 py-1">
        <option value="">Select</option>
        {options.map((option: string) => (
          <option key={option} value={option}>
            {option}
          </option>
        ))}
      </select>
    );
  }

  if (property.type === "multi_select") {
    return (
      <input
        value={Array.isArray(value) ? value.join(", ") : value ?? ""}
        onChange={(event) =>
          updateCell(
            row.id,
            property.id,
            event.target.value
              .split(",")
              .map((item) => item.trim())
              .filter(Boolean)
          )
        }
        className="w-full rounded border border-[var(--line)] bg-[var(--panel)] px-2 py-1"
      />
    );
  }

  if (property.type === "date") {
    return <input type="date" value={value ?? ""} onChange={(event) => updateCell(row.id, property.id, event.target.value)} className="w-full rounded border border-[var(--line)] bg-[var(--panel)] px-2 py-1" />;
  }

  return <input value={value ?? ""} onChange={(event) => updateCell(row.id, property.id, event.target.value)} className="w-full rounded border border-[var(--line)] bg-[var(--panel)] px-2 py-1" />;
}
