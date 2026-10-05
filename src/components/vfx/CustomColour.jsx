import { useState } from "react";
import { Pipette } from "lucide-react";

function hsvToHex(h, s, v) {
  const c = v * s;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = v - c;
  let r = 0;
  let g = 0;
  let b = 0;
  if (h < 60) [r, g, b] = [c, x, 0];
  else if (h < 120) [r, g, b] = [x, c, 0];
  else if (h < 180) [r, g, b] = [0, c, x];
  else if (h < 240) [r, g, b] = [0, x, c];
  else if (h < 300) [r, g, b] = [x, 0, c];
  else [r, g, b] = [c, 0, x];
  const channel = (n) => Math.round((n + m) * 255).toString(16).padStart(2, "0");
  return `#${channel(r)}${channel(g)}${channel(b)}`.toUpperCase();
}

function hexToHsv(hex) {
  const match = /^#?([0-9a-fA-F]{6})$/.exec(hex || "");
  if (!match) return { h: 0, s: 1, v: 1 };
  const value = parseInt(match[1], 16);
  const r = ((value >> 16) & 255) / 255;
  const g = ((value >> 8) & 255) / 255;
  const b = (value & 255) / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const d = max - min;
  let h = 0;
  if (d !== 0) {
    if (max === r) h = ((g - b) / d) % 6;
    else if (max === g) h = (b - r) / d + 2;
    else h = (r - g) / d + 4;
    h *= 60;
    if (h < 0) h += 360;
  }
  return { h, s: max === 0 ? 0 : d / max, v: max };
}

export default function CustomColour({ value, onChange, label = "Custom colour" }) {
  const initial = hexToHsv(value);
  const [open, setOpen] = useState(false);
  const [hexOn, setHexOn] = useState(false);
  const [draft, setDraft] = useState(value || "");
  const [hue, setHue] = useState(initial.h);
  const [saturation, setSaturation] = useState(initial.s);
  const [bright, setBright] = useState(initial.v);

  const emit = (nextHue, nextSat, nextVal) => {
    const hex = hsvToHex(nextHue, nextSat, nextVal);
    setDraft(hex);
    onChange(hex);
  };

  const pickField = (event) => {
    const box = event.currentTarget.getBoundingClientRect();
    const sat = Math.min(1, Math.max(0, (event.clientX - box.left) / box.width));
    const val = Math.min(1, Math.max(0, 1 - (event.clientY - box.top) / box.height));
    setSaturation(sat);
    setBright(val);
    emit(hue, sat, val);
  };

  const pickHue = (event) => {
    const box = event.currentTarget.getBoundingClientRect();
    const next = Math.min(360, Math.max(0, ((event.clientX - box.left) / box.width) * 360));
    setHue(next);
    emit(next, saturation, bright);
  };

  const applyHex = () => {
    const raw = draft.trim();
    const hex = raw.startsWith("#") ? raw : `#${raw}`;
    if (!/^#[0-9a-fA-F]{6}$/.test(hex)) return;
    const next = hexToHsv(hex);
    setHue(next.h);
    setSaturation(next.s);
    setBright(next.v);
    onChange(hex.toUpperCase());
  };

  return (
    <div>
      <button
        type="button"
        onClick={() => setOpen((current) => !current)}
        className="flex w-full items-center gap-2.5 rounded-lg px-2 py-1.5 text-left text-[11px] font-body transition hover:bg-white/10"
      >
        <Pipette size={14} color={value || "currentColor"} />
        {label}
      </button>
      {open && (
        <div className="px-2 pb-1">
          <div
            onPointerDown={pickField}
            onPointerMove={(event) => {
              if (event.buttons) pickField(event);
            }}
            className="relative h-28 w-full touch-none overflow-hidden rounded-md"
            style={{ backgroundColor: `hsl(${hue} 100% 50%)` }}
          >
            <div className="absolute inset-0" style={{ background: "linear-gradient(to right, #fff, transparent)" }} />
            <div className="absolute inset-0" style={{ background: "linear-gradient(to top, #000, transparent)" }} />
            <Pipette
              size={16}
              className="pointer-events-none absolute text-white drop-shadow"
              style={{
                left: `calc(${saturation * 100}% - 8px)`,
                top: `calc(${(1 - bright) * 100}% - 8px)`,
              }}
            />
          </div>
          <div
            onPointerDown={pickHue}
            onPointerMove={(event) => {
              if (event.buttons) pickHue(event);
            }}
            className="mt-2 h-3 w-full touch-none rounded-full"
            style={{
              background: "linear-gradient(to right, #f00, #ff0, #0f0, #0ff, #00f, #f0f, #f00)",
            }}
          />
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
