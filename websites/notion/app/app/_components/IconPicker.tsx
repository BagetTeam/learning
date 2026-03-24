"use client";

import { useEffect, useRef, useState } from "react";
import EmojiPicker, { Theme } from "emoji-picker-react";
import { Smile, X } from "lucide-react";

type IconPickerProps = {
  icon: string | null;
  onChange: (icon: string) => void;
  onRemove?: () => void;
};

export default function IconPicker({ icon, onChange, onRemove }: IconPickerProps) {
  const [open, setOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const handleOutsideClick = (event: MouseEvent) => {
      if (!containerRef.current) return;
      if (!containerRef.current.contains(event.target as Node)) {
        setOpen(false);
      }
    };

    window.addEventListener("mousedown", handleOutsideClick);
    return () => window.removeEventListener("mousedown", handleOutsideClick);
  }, []);

  return (
    <div ref={containerRef} className="relative inline-flex items-center gap-1">
      <button
        onClick={() => setOpen((prev) => !prev)}
        className={`inline-flex items-center justify-center rounded-md border border-[var(--line)] bg-[var(--panel)] px-2 hover:bg-[var(--hover)] ${icon ? "h-9 min-w-9 text-lg" : "h-8 gap-1 text-sm text-[var(--muted)]"}`}
        title="Pick icon"
      >
        {icon ? (
          <span>{icon}</span>
        ) : (
          <>
            <Smile className="h-4 w-4" />
            <span>Add icon</span>
          </>
        )}
      </button>

      {icon && onRemove ? (
        <button
          onClick={onRemove}
          className="inline-flex h-7 w-7 items-center justify-center rounded-md border border-[var(--line)] bg-[var(--panel)] hover:bg-[var(--hover)]"
          title="Remove icon"
        >
          <X className="h-3.5 w-3.5 text-[var(--muted)]" />
        </button>
      ) : null}

      {open ? (
        <div className="absolute left-0 top-[110%] z-40 rounded-md border border-[var(--line)] bg-[var(--panel)] shadow-lg">
          <EmojiPicker
            height={360}
            width={320}
            theme={Theme.LIGHT}
            onEmojiClick={(data) => {
              onChange(data.emoji);
              setOpen(false);
            }}
          />
        </div>
      ) : null}
    </div>
  );
}
