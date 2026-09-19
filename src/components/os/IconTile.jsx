import React from "react";
import { cn } from "@/lib/utils";

const SIZES = {
  sm: { box: "h-9 w-9", icon: 16, radius: "rounded-xl" },
  md: { box: "h-14 w-14", icon: 26, radius: "rounded-2xl" },
  lg: { box: "h-20 w-20", icon: 38, radius: "rounded-[1.4rem]" },
};

function tileStyle(app) {
  const { bg, tile } = app;
  const t = tile || {};
  const fg = t.fg || "#fff";
  switch (t.type) {
    case "flat":
      return { style: { background: bg }, fg };
    case "duo":
      return { style: { background: `linear-gradient(135deg, ${bg}, ${t.bg2})` }, fg };
    case "stripes":
      return { style: { background: `repeating-linear-gradient(45deg, ${bg} 0 9px, ${t.bg2} 9px 18px)` }, fg };
    case "dots":
      return { style: { background: `radial-gradient(${t.bg2} 2.5px, transparent 3px), ${bg}`, backgroundSize: "13px 13px" }, fg };
    case "ring":
      return { style: { background: `repeating-radial-gradient(circle at 30% 25%, ${bg} 0 4px, ${t.bg2} 4px 8px)` }, fg };
    case "gloss":
      return { style: { background: `linear-gradient(180deg, rgba(255,255,255,0.55) 0%, rgba(255,255,255,0.12) 42%, rgba(255,255,255,0) 58%), ${bg}` }, fg };
    case "mono":
      return { style: { background: "#ffffff" }, fg: t.fg || bg };
    case "dark":
      return { style: { background: "linear-gradient(145deg, #1c1c1e, #0a0a0a)", boxShadow: `0 8px 24px ${bg}55, inset 0 1px 2px rgba(255,255,255,0.15)` }, fg: bg };
    case "outline":
      return { style: { background: `${bg}1f`, border: `2px solid ${bg}` }, fg: t.fg || bg };
    default: // glass
      return {
        style: {
          background: `linear-gradient(145deg, rgba(255,255,255,0.45) 0%, rgba(255,255,255,0.1) 42%, rgba(255,255,255,0) 60%), ${bg}`,
          border: "1px solid rgba(255,255,255,0.3)",
        },
        fg: "#fff",
      };
  }
}

export default function IconTile({ app, size = "md" }) {
  if (!app) return null;
  const { Icon } = app;
  const s = SIZES[size] || SIZES.md;
  const { style, fg } = tileStyle(app);
  return (
    <span
      className={cn("flex items-center justify-center backdrop-blur-sm shadow-[0_8px_24px_rgba(0,0,0,0.45)]", s.box, s.radius)}
      style={style}
    >
      <Icon size={s.icon} style={{ color: fg }} className="drop-shadow-[0_1px_2px_rgba(0,0,0,0.4)]" />
    </span>
  );
}