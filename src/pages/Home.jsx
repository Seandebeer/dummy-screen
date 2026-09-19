import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Monitor, Grid2x2, Radio, ArrowUpRight } from "lucide-react";
import PhoneMirror from "@/components/os/PhoneMirror";
import VFXPicker from "@/components/vfx/VFXPicker";
import ControlPanel from "@/components/control/ControlPanel";
import { useIsMobile } from "@/hooks/use-mobile";
import { cn } from "@/lib/utils";

const osApps = [
  { label: "Phone", color: "#34C759" },
  { label: "Messages", color: "#34C759" },
  { label: "Mail", color: "#0A84FF" },
  { label: "Clock", color: "#FF9F0A" },
  { label: "Contacts", color: "#5A5D6B" },
];

function CardHeader({ icon: Icon, title, accent }) {
  return (
    <div className="flex items-center gap-2.5 mb-4">
      <span className={cn("h-9 w-9 rounded-lg flex items-center justify-center", accent)}>
        <Icon size={18} />
      </span>
      <div>
        <h3 className="font-display font-bold text-base leading-none">{title}</h3>
      </div>
    </div>
  );
}

function MobileHome() {
  const navigate = useNavigate();
  const [color, setColor] = useState("green");
  const [marks, setMarks] = useState("crosshair");

  return (
    <div className="min-h-dvh bg-background">
      <div className="sticky top-0 z-30 border-b border-border bg-surface/95 backdrop-blur px-4 py-3 flex items-center justify-between">
        <div className="font-display font-bold text-lg tracking-wide">TAKEOVER</div>
        <span className="flex items-center gap-1.5 text-[11px] font-body text-signal">
          <span className="h-2 w-2 rounded-full bg-signal led-pulse" /> SYNC LIVE
        </span>
      </div>

      <div className="p-4 flex flex-col gap-4">
        {/* mirror preview */}
        <div className="rounded-2xl border border-border bg-surface p-4 flex flex-col items-center gap-4">
          <PhoneMirror />
          <div className="grid grid-cols-5 gap-2 w-full">
            {osApps.map((a) => (
              <button key={a.label} onClick={() => navigate("/os")}
                className="flex flex-col items-center gap-1.5 active:scale-95 transition">
                <span className="h-11 w-11 rounded-xl flex items-center justify-center" style={{ background: a.color }}>
                  <span className="text-white text-xs font-display font-bold">{a.label[0]}</span>
                </span>
                <span className="text-[10px] text-muted-foreground font-body">{a.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* VFX quick stage */}
        <div className="rounded-2xl border border-border bg-surface p-4">
          <CardHeader icon={Grid2x2} title="VFX Chroma Stage" accent="bg-amber/15 text-amber" />
          <VFXPicker color={color} setColor={setColor} marks={marks} setMarks={setMarks}
            onTakeover={() => navigate(`/vfx?color=${color}&marks=${marks}`)} />
        </div>

        {/* control deck */}
        <div className="rounded-2xl border border-border bg-surface p-4">
          <CardHeader icon={Radio} title="Remote Control Deck" accent="bg-signal/15 text-signal" />
          <ControlPanel />
        </div>
      </div>
    </div>
  );
}

export default function Home() {
  const isMobile = useIsMobile();
  const navigate = useNavigate();
  const [color, setColor] = useState("green");
  const [marks, setMarks] = useState("crosshair");

  if (isMobile) return <MobileHome />;

  return (
    <div className="min-h-dvh bg-background grid-backdrop">
      <header className="border-b border-border px-8 py-5 flex items-center justify-between">
        <div>
          <h1 className="font-display font-bold text-2xl tracking-wide">TAKEOVER</h1>
          <p className="text-[11px] text-muted-foreground font-body uppercase tracking-wider">Prop Phone Control Deck</p>
        </div>
        <div className="flex items-center gap-4 text-[11px] font-body">
          <span className="flex items-center gap-1.5 text-signal"><span className="h-2 w-2 rounded-full bg-signal led-pulse" /> SYNC LIVE</span>
          <span className="text-muted-foreground">CHANNEL stage-1</span>
        </div>
      </header>

      <div className="grid grid-cols-3 gap-6 p-6 max-w-[1400px] mx-auto">
        {/* left column — mirror preview */}
        <div className="rounded-2xl border border-border bg-surface p-5 flex flex-col">
          <PhoneMirror />
        </div>

        {/* right column — feature deck */}
        <div className="col-span-2 flex flex-col gap-6">
          {/* OS card */}
          <div className="rounded-2xl border border-border bg-surface p-5">
            <div className="flex items-center justify-between mb-4">
              <CardHeader icon={Monitor} title="OS Simulator" accent="bg-[#34C759]/15 text-[#34C759]" />
              <button onClick={() => navigate("/os")} className="flex items-center gap-1 text-xs font-body text-amber hover:underline">
                Launch fullscreen <ArrowUpRight size={14} />
              </button>
            </div>
            <div className="grid grid-cols-5 gap-3">
              {osApps.map((a) => (
                <button key={a.label} onClick={() => navigate("/os")}
                  className="flex flex-col items-center gap-2 rounded-xl border border-border bg-muted/30 p-3 hover:border-amber/40 transition">
                  <span className="h-11 w-11 rounded-xl flex items-center justify-center" style={{ background: a.color }}>
                    <span className="text-white font-display font-bold">{a.label[0]}</span>
                  </span>
                  <span className="text-[11px] font-body text-muted-foreground">{a.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* VFX + Control row */}
          <div className="grid grid-cols-2 gap-6">
            <div className="rounded-2xl border border-border bg-surface p-5">
              <CardHeader icon={Grid2x2} title="VFX Chroma Stage" accent="bg-amber/15 text-amber" />
              <VFXPicker color={color} setColor={setColor} marks={marks} setMarks={setMarks}
                onTakeover={() => navigate(`/vfx?color=${color}&marks=${marks}`)} />
            </div>
            <div className="rounded-2xl border border-border bg-surface p-5">
              <CardHeader icon={Radio} title="Remote Control Deck" accent="bg-signal/15 text-signal" />
              <div className="h-[420px]"><ControlPanel /></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}