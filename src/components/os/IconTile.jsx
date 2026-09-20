import React from "react";
import { Image } from "@/components/ui/image";
import { cn } from "@/lib/utils";

const SIZES = {
  sm: { box: "h-9 w-9", icon: 16 },
  md: { box: "h-14 w-14", icon: 26 },
  lg: { box: "h-20 w-20", icon: 38 },
};
// continuous-corner squircle, like a native app icon
const RADIUS = "rounded-[23%]";

function tileStyle(app) {
  const { bg, tile } = app;
  const t = tile || {};
  const fg = t.fg || "#fff";
  switch (t.type) {
    case "flat":
      return { style: { background: bg }, fg };
    case "duo":
      return { style: { background: `linear-gradient(180deg, ${bg}, ${t.bg2})` }, fg };
    case "stripes":
      return { style: { background: `repeating-linear-gradient(135deg, ${bg} 0 12px, ${t.bg2}AA 12px 24px)` }, fg };
    case "dots":
      return { style: { background: `radial-gradient(${t.bg2}99 2px, transparent 2.6px), ${bg}`, backgroundSize: "15px 15px" }, fg };
    case "ring":
      return { style: { background: `repeating-radial-gradient(circle at 30% 25%, ${bg} 0 5px, ${t.bg2}80 5px 9px)` }, fg };
    case "gloss":
      return { style: { background: `linear-gradient(180deg, rgba(255,255,255,0.5) 0%, rgba(255,255,255,0.1) 45%, rgba(255,255,255,0) 60%), ${bg}` }, fg };
    case "mono":
      return { style: { background: "#ffffff" }, fg: t.fg || bg };
    case "dark":
      return { style: { background: "linear-gradient(145deg, #1c1c1e, #0a0a0a)" }, fg: bg };
    case "outline":
      return { style: { background: `${bg}14`, border: `1.5px solid ${bg}` }, fg: t.fg || bg };
    case "glass":
      return { style: { background: `linear-gradient(145deg, rgba(255,255,255,0.4) 0%, rgba(255,255,255,0.08) 45%, rgba(255,255,255,0) 60%), ${bg}` }, fg: "#fff" };
    // downloaded-app styles: each family reads like a different company's brand
    case "split":
      return { style: { background: `linear-gradient(135deg, ${bg} 0 50%, ${t.bg2} 50%)` }, fg: "#fff" };
    case "badge":
      return { style: { background: `radial-gradient(circle closest-side at 50% 44%, ${bg} 0 86%, transparent 87%), #ffffff` }, fg: "#fff" };
    case "pastel":
      return { style: { background: `linear-gradient(180deg, ${bg}2E, ${bg}14)` }, fg: t.fg || bg };
    default: // core apps - clean flat native icon
      return { style: { background: bg }, fg: "#fff" };
  }
}

export default function IconTile({ app, size = "md" }) {
  if (!app) return null;
  const { Icon } = app;
  const s = SIZES[size] || SIZES.md;
  const { style, fg } = tileStyle(app);
  return (
    <span
      className={cn("app-icon-tile relative flex items-center justify-center overflow-hidden", s.box, RADIUS)}
      style={style}
    >
      {/* polished glass finish: soft top sheen + fine inner highlight */}
      <span className="tile-glint pointer-events-none absolute inset-0 rounded-[inherit] shadow-[inset_0_1px_1px_rgba(255,255,255,0.3),inset_0_0_0_0.5px_rgba(255,255,255,0.12)]" />
      <span className="tile-sheen pointer-events-none absolute inset-x-0 top-0 h-1/2 bg-gradient-to-b from-white/25 to-transparent" />
      {/* apps with uploaded artwork render the image itself as the icon */}
      {app.img ? (
        <Image src={app.img} alt={app.label} className="h-full w-full" fittingType="fill" focalPointX={0.5} focalPointY={0.33} />
      ) : (
        <Icon size={s.icon} style={{ color: fg }} className="relative drop-shadow-[0_1px_1.5px_rgba(0,0,0,0.3)]" />
      )}
    </span>
  );
}