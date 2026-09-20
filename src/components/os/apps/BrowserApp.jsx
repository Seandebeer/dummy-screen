import React, { useState } from "react";
import { ArrowLeft, ArrowRight, RotateCw, Home as HomeIcon, Globe } from "lucide-react";
import { cn } from "@/lib/utils";

// Browser - a real, working web browser on the mock phone. Pages render in a
// sandboxed frame; anything typed without a dot searches Wikipedia.

const QUICK = [
  { name: "Wikipedia", url: "https://en.wikipedia.org/wiki/Main_Page", hue: "#64748b" },
  { name: "Wiktionary", url: "https://en.wiktionary.org/wiki/Wiktionary:Main_Page", hue: "#475569" },
  { name: "OpenStreetMap", url: "https://www.openstreetmap.org/export/embed.html?bbox=18.35,-33.95,18.55,-33.85&layer=mapnik", hue: "#3f8f5f" },
  { name: "Example.com", url: "https://example.com", hue: "#8a8a8e" },
];

const normalize = (input) => {
  const s = input.trim();
  if (!s) return null;
  if (/^https?:\/\//i.test(s)) return s;
  if (/^[\w-]+(\.[\w-]+)+/i.test(s)) return `https://${s}`;
  return `https://en.wikipedia.org/wiki/Special:Search?search=${encodeURIComponent(s)}`;
};

const hostOf = (url) => url.replace(/^https?:\/\//, "").split("/")[0];

const chromeBtn = "flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-black/70 disabled:opacity-30 transition active:scale-90";

export default function BrowserApp() {
  const [url, setUrl] = useState("");
  const [current, setCurrent] = useState(null);
  const [history, setHistory] = useState([]);
  const [idx, setIdx] = useState(-1);
  const [loading, setLoading] = useState(false);
  const [reloadKey, setReloadKey] = useState(0);

  const go = (raw) => {
    const target = normalize(raw);
    if (!target) return;
    const h = [...history.slice(0, idx + 1), target];
    setHistory(h);
    setIdx(h.length - 1);
    setCurrent(target);
    setUrl(target);
    setLoading(true);
  };

  const jump = (i) => {
    if (i < 0 || i >= history.length) return;
    setIdx(i);
    setCurrent(history[i]);
    setUrl(history[i]);
    setLoading(true);
  };

  const reload = () => {
    setReloadKey((k) => k + 1);
    setLoading(true);
  };

  const home = () => {
    setCurrent(null);
    setUrl("");
    setLoading(false);
  };

  return (
    <div className="flex h-full flex-col bg-white text-[#111]">
      {/* light browser chrome */}
      <div className="flex items-center gap-1.5 border-b border-black/10 bg-[#f2f2f7] px-2 py-2">
        <button onClick={home} aria-label="Start page" className={chromeBtn}>
          <HomeIcon size={16} />
        </button>
        <button onClick={() => jump(idx - 1)} disabled={idx <= 0} aria-label="Back" className={chromeBtn}>
          <ArrowLeft size={16} />
        </button>
        <button onClick={() => jump(idx + 1)} disabled={idx >= history.length - 1} aria-label="Forward" className={chromeBtn}>
          <ArrowRight size={16} />
        </button>
        <button onClick={reload} disabled={!current} aria-label="Reload" className={chromeBtn}>
          <RotateCw size={15} className={cn(loading && "animate-spin")} />
        </button>
        <form
          onSubmit={(e) => { e.preventDefault(); go(url); }}
          className="flex min-w-0 flex-1 items-center gap-1.5 rounded-full border border-black/10 bg-white px-3 py-1.5 shadow-sm"
        >
          <Globe size={12} className="shrink-0 text-black/35" />
          <input
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder="Search or enter address"
            className="min-w-0 flex-1 bg-transparent text-[12px] outline-none placeholder:text-black/30"
          />
        </form>
      </div>

      <div className="relative min-h-0 flex-1">
        {/* slim load progress line */}
        <div className="absolute inset-x-0 top-0 z-10 h-[2px]">
          <div className={cn("h-full bg-[#0A84FF] transition-all", loading ? "w-1/2 animate-pulse" : "w-0")} />
        </div>

        {current ? (
          <iframe
            key={`${current}-${reloadKey}`}
            src={current}
            onLoad={() => setLoading(false)}
            title="Web page"
            className="h-full w-full border-0 bg-white"
            sandbox="allow-scripts allow-same-origin allow-forms allow-popups"
            referrerPolicy="no-referrer"
          />
        ) : (
          <div className="h-full overflow-y-auto no-scrollbar px-5 pt-8">
            <div className="text-center">
              <span className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-[#0A84FF] text-white shadow-md">
                <Globe size={26} />
              </span>
              <div className="mt-3 font-display text-lg font-bold">Browser</div>
              <p className="text-[11px] text-black/45">Live web, right on the mock phone</p>
            </div>
            <div className="mt-6 grid grid-cols-2 gap-3 pb-3">
              {QUICK.map((q) => (
                <button key={q.name} onClick={() => go(q.url)}
                  className="flex items-center gap-2.5 rounded-xl border border-black/10 bg-white p-3 text-left shadow-sm transition active:scale-95">
                  <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-[13px] font-bold text-white"
                    style={{ background: q.hue }}>
                    {q.name[0]}
                  </span>
                  <span className="min-w-0">
                    <span className="block truncate text-[12px] font-semibold">{q.name}</span>
                    <span className="block truncate text-[10px] text-black/40">{hostOf(q.url)}</span>
                  </span>
                </button>
              ))}
            </div>
            <p className="pb-6 text-center text-[10px] leading-relaxed text-black/35">
              Type an address or a search. Some sites refuse to load inside other apps and will stay blank.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}