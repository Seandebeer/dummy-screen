import React, { useState } from "react";
import { cn } from "@/lib/utils";

const fmt = (n) => {
  if (!isFinite(n)) return "Error";
  const r = Math.round(n * 1e10) / 1e10;
  return String(r).length > 12 ? r.toExponential(6) : String(r);
};

export default function CalculatorApp() {
  const [display, setDisplay] = useState("0");
  const [acc, setAcc] = useState(null);
  const [op, setOp] = useState(null);
  const [fresh, setFresh] = useState(true);

  const compute = (a, b, o) =>
    o === "+" ? a + b : o === "−" ? a - b : o === "×" ? a * b : b === 0 ? NaN : a / b;

  const press = (k) => {
    if (/^[0-9]$/.test(k)) {
      setDisplay((d) => (fresh || d === "0" ? k : d.length >= 12 ? d : d + k));
      setFresh(false);
      return;
    }
    if (k === ".") {
      if (fresh) { setDisplay("0."); setFresh(false); return; }
      setDisplay((d) => (d.includes(".") ? d : d + "."));
      return;
    }
    if (k === "C") { setDisplay("0"); setAcc(null); setOp(null); setFresh(true); return; }
    if (k === "±") { setDisplay((d) => (d.startsWith("-") ? d.slice(1) : d === "0" ? d : "-" + d)); return; }
    if (k === "%") { setDisplay((d) => fmt(parseFloat(d) / 100)); setFresh(true); return; }
    if (k === "=") {
      if (op != null && acc != null) {
        setDisplay(fmt(compute(acc, parseFloat(display), op)));
        setAcc(null); setOp(null); setFresh(true);
      }
      return;
    }
    const cur = parseFloat(display);
    if (op != null && acc != null && !fresh) {
      const r = compute(acc, cur, op);
      setAcc(r); setDisplay(fmt(r));
    } else {
      setAcc(cur);
    }
    setOp(k); setFresh(true);
  };

  const KEYS = [
    ["C", "±", "%", "÷"],
    ["7", "8", "9", "×"],
    ["4", "5", "6", "−"],
    ["1", "2", "3", "+"],
    ["0", ".", "="],
  ];

  const keyStyle = (k) =>
    ["÷", "×", "−", "+", "="].includes(k)
      ? "bg-amber text-black font-semibold"
      : ["C", "±", "%"].includes(k)
        ? "bg-white/10 text-foreground"
        : "bg-white/[0.07] text-foreground";

  return (
    <div className="h-full flex flex-col bg-[#0b0b0d] p-3 gap-3 select-none">
      <div className="flex-1 flex items-end justify-end px-2 pt-6">
        <div className="font-display text-right break-all leading-tight"
          style={{ fontSize: display.length > 9 ? "1.6rem" : "2.6rem" }}>
          {display}
        </div>
      </div>
      <div className="grid grid-cols-4 gap-2">
        {KEYS.flat().map((k) => (
          <button key={k} onClick={() => press(k)}
            className={cn("h-11 rounded-full font-display text-lg active:brightness-125", keyStyle(k), k === "0" && "col-span-2")}>
            {k}
          </button>
        ))}
      </div>
    </div>
  );
}