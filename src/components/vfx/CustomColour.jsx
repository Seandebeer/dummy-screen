import { useState } from "react";
import { cn } from "@/lib/utils";

function hslToHex(h, s, l) {
  const a = s * Math.min(l, 1 - l);
  const f = (n) => {
    const k = (n + h / 30) % 12;
    const channel = l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1);
    return Math.round(255 * channel).toString(16).padStart(2, "0");
  };
  return `#${f(0)}${f(8)}${f(4)}`.toUpperCase();
}

const SWATCHES = (() => {
  const list = [];
  for (const light of [0.9, 0.7, 0.5, 0.32]) {
    for (let step = 0; step < 12; step++) list.push(hslToHex(step * 30, 0.78, light));
  }
  for (let step = 0; step < 12; step++) {
    const value = Math.round((255 * (11 - step)) / 11).toString(16).padStart(2, "0");
    list.push(`#${value}${value}${value}`.toUpperCase());
  }
  return [...new Set(list)];
})();

export default function CustomColour({ value, onChange, label = "Custom colour" }) {
  const [open, setOpen] = useState(false);
  const [hexOn, setHexOn] = useState(false);
  const [draft, setDraft] = useState(value || "");
  const selected = (value || "").toUpperCase();

  const applyHex = () => {
    const raw = draft.trim();
    const hex = raw.startsWith("#") ? raw : `#${raw}`;
    if (!/^#[0-9a-fA-F]{6}$/.test(hex)) return;
    onChange(hex.toUpperCase());
  };

  return (
    <div>
      <button
        type="button"
        onClick={() => setOpen((current) => !current)}
        className="flex w-full items-center gap-2.5 rounded-lg px-2 py-1.5 text-left text-[11px] font-body transition hover:bg-white/10"
      >
        <span
          className="h-4 w-4 shrink-0 rounded-full border border-white/25"
          style={{
            background: value || "conic-gradient(red, yellow, lime, cyan, blue, magenta, red)",
          }}
        />
        {label}
      </button>
      {open && (
        <div className="px-2 pb-1">
          <div className="grid max-h-36 grid-cols-6 gap-1 overflow-y-auto py-1">
            {SWATCHES.map((hex) => (
              <button
                key={hex}
                type="button"
                title={hex}
                onClick={() => onChange(hex)}
                className={cn(
                  "h-4 w-4 rounded-full border border-white/25",
                  selected === hex && "ring-2 ring-amber ring-offset-1 ring-offset-black",
                )}
                style={{ background: hex }}
              />
            ))}
          </div>
          <button
            type="button"
            onClick={() => setHexOn((current) => !current)}
            className="mt-1 text-[10px] font-body uppercase tracking-wider text-white/50"
          >
            {hexOn ? "Hide hex code" : "Hex code"}
          </button>
          {hexOn && (
            <form
              onSubmit={(event) => {
                event.preventDefault();
                applyHex();
              }}
              className="mt-1 flex gap-1"
            >
              <input
                value={draft}
                onChange={(event) => setDraft(event.target.value)}
                placeholder="#00B140"
                className="w-full rounded border border-white/15 bg-black/40 px-2 py-1 text-[11px] text-white outline-none"
              />
            </form>
          )}
        </div>
      )}
    </div>
  );
}
