import React from "react";

// composite VFX tracking-marker glyphs (circle / triangle / quadrant designs
// from the reference sheet) drawn as SVG in a 100 x 100 viewbox, centred on
// the marker point. Main shapes use the mark colour; cut-outs and detail
// shapes auto-invert so they stay visible on top of it.

const isLightHex = (hex) => {
  const m = /^#?([0-9a-f]{6})$/i.exec(hex || "");
  if (!m) return true;
  const n = parseInt(m[1], 16);
  return ((n >> 16) & 255) * 0.299 + ((n >> 8) & 255) * 0.587 + (n & 255) * 0.114 > 150;
};

// triangle pointing up (dir 1) / down (dir -1), centred on (cx, cy)
const tri = (cx, cy, hw, h, dir) =>
  `M ${cx} ${cy - (dir * 2 * h) / 3} L ${cx + hw} ${cy + (dir * h) / 3} L ${cx - hw} ${cy + (dir * h) / 3} Z`;

const Plus = ({ x, y, l, w, color }) => (<>
  <rect x={x - l / 2} y={y - w / 2} width={l} height={w} fill={color} />
  <rect x={x - w / 2} y={y - l / 2} width={w} height={l} fill={color} />
</>);

const CORNERS = [[8, 8], [92, 8], [8, 92], [92, 92]];
const TIPS = [[50, 6], [50, 94], [6, 50], [94, 50]];

export default function CompositeGlyph({ kind, fill, size = 1, thickness = 1 }) {
  const inv = isLightHex(fill) ? "#000000" : "#FFFFFF";
  const st = Math.max(2, 5 * thickness);
  let g = null;

  if (kind === "circtriplus") {
    // circle + triangle outline + centre plus, plus signs at the corners
    g = (<>
      <circle cx={50} cy={50} r={38} fill="none" stroke={fill} strokeWidth={st} />
      <path d={tri(50, 53, 19, 25, 1)} fill="none" stroke={fill} strokeWidth={st} strokeLinejoin="round" />
      <Plus x={50} y={53} l={11} w={3.5} color={fill} />
      {CORNERS.map(([x, y], i) => <Plus key={i} x={x} y={y} l={11} w={3.5} color={fill} />)}
    </>);
  } else if (kind === "solidtri") {
    // solid triangle with a punched-out centre dot, corner circle / triangle shapes
    g = (<>
      <circle cx={50} cy={50} r={38} fill="none" stroke={fill} strokeWidth={st} />
      <path d={tri(50, 54, 21, 30, 1)} fill={fill} />
      <circle cx={50} cy={52} r={5} fill={inv} />
      <circle cx={7} cy={7} r={5} fill={fill} />
      <path d={tri(93, 7, 4.5, 8, 1)} fill={fill} />
      <path d={tri(7, 93, 4.5, 8, -1)} fill={fill} />
      <circle cx={93} cy={93} r={5} fill={fill} />
    </>);
  } else if (kind === "squaretri") {
    // square + inverted circle + solid triangle with inverted triangle inside
    g = (<>
      <rect x={7} y={7} width={86} height={86} fill="none" stroke={fill} strokeWidth={st} />
      <circle cx={50} cy={50} r={33} fill={inv} />
      <path d={tri(50, 52, 22, 30, 1)} fill={fill} />
      <path d={tri(50, 56, 11, 15, -1)} fill={inv} />
      {[[12, 12], [88, 12], [12, 88], [88, 88]].map(([x, y], i) => (
        <rect key={i} x={x - 4.5} y={y - 4.5} width={9} height={9} fill={inv} />
      ))}
      {[[27, 27], [73, 27], [27, 73], [73, 73]].map(([x, y], i) => (
        <Plus key={`p${i}`} x={x} y={y} l={9} w={3} color={inv} />
      ))}
    </>);
  } else if (kind === "invtri") {
    // downward solid triangle with smaller inverted triangle inside
    g = (<>
      <circle cx={50} cy={50} r={38} fill="none" stroke={fill} strokeWidth={st} />
      <path d={tri(50, 50, 24, 34, -1)} fill={fill} />
      <path d={tri(50, 52, 12, 17, 1)} fill={inv} />
      {CORNERS.map(([x, y], i) => <Plus key={i} x={x} y={y} l={11} w={3.5} color={fill} />)}
    </>);
  } else if (kind === "plusgrid") {
    // big solid plus with small plus signs at each tip
    g = (<>
      <Plus x={50} y={50} l={66} w={20} color={fill} />
      {TIPS.map(([x, y], i) => <Plus key={i} x={x} y={y} l={11} w={3.5} color={fill} />)}
    </>);
  } else if (kind === "dotcircle") {
    // circle with a solid dot at the dead centre
    g = (<>
      <circle cx={50} cy={50} r={38} fill="none" stroke={fill} strokeWidth={st} />
      <circle cx={50} cy={50} r={10} fill={fill} />
    </>);
  } else if (kind === "quads") {
    // circle divided into alternating quadrants
    g = (<>
      <circle cx={50} cy={50} r={38} fill="none" stroke={fill} strokeWidth={st} />
      <path d="M 50 50 L 50 12 A 38 38 0 0 1 88 50 Z" fill={fill} />
      <path d="M 50 50 L 50 88 A 38 38 0 0 1 12 50 Z" fill={fill} />
    </>);
  } else if (kind === "squads") {
    // square framing a quadrant circle, inverted squares in the corners
    g = (<>
      <rect x={8} y={8} width={84} height={84} fill="none" stroke={fill} strokeWidth={st} />
      <circle cx={50} cy={50} r={27} fill="none" stroke={fill} strokeWidth={st} />
      <path d="M 50 50 L 50 23 A 27 27 0 0 1 77 50 Z" fill={fill} />
      <path d="M 50 50 L 50 77 A 27 27 0 0 1 23 50 Z" fill={fill} />
      {[[13, 13], [87, 13], [13, 87], [87, 87]].map(([x, y], i) => (
        <rect key={i} x={x - 4.5} y={y - 4.5} width={9} height={9} fill={inv} />
      ))}
    </>);
  } else if (kind === "crosshair") {
    // circle with a thick crosshair reaching its edges
    g = (<>
      <circle cx={50} cy={50} r={38} fill="none" stroke={fill} strokeWidth={st} />
      <rect x={12} y={44} width={76} height={12} fill={fill} />
      <rect x={44} y={12} width={12} height={76} fill={fill} />
    </>);
  }

  if (!g) return null;
  const s = 56 * size;
  return (
    <svg className="absolute" width={s} height={s} viewBox="0 0 100 100"
      style={{ transform: "translate(-50%, -50%)" }}>
      {g}
    </svg>
  );
}