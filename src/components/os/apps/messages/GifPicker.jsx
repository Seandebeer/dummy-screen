import React, { useEffect, useState } from "react";
import { Loader2, Search, X } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { cn } from "@/lib/utils";

// GIF search backed by the searchGifs backend function (Tenor API)
export default function GifPicker({ dark, onPick, onClose }) {
  const [query, setQuery] = useState("");
  const [gifs, setGifs] = useState(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  const load = async (q) => {
    setBusy(true);
    setError("");
    try {
      const res = await base44.functions.invoke("searchGifs", {
        query: q, mode: q ? "search" : "trending",
      });
      setGifs(res.data.gifs || []);
    } catch (e) {
      setGifs([]);
      setError(e?.response?.data?.error || "GIFs are unavailable right now");
    }
    setBusy(false);
  };

  useEffect(() => { load(""); }, []);

  return (
    <div className={cn("absolute inset-0 z-50 flex flex-col",
      dark ? "bg-[#0b0b0f] text-white" : "bg-white text-black")}>
      <div className={cn("flex items-center justify-between border-b px-3 py-2.5",
        dark ? "border-white/10" : "border-black/10")}>
        <button onClick={onClose} className="flex items-center gap-0.5 text-[#007AFF]">
          <X size={16} /> <span className="text-sm">Cancel</span>
        </button>
        <span className="text-[15px] font-semibold">GIFs</span>
        <span className="w-14" />
      </div>
      <div className={cn("mx-3 my-2 flex items-center gap-2 rounded-full border px-3 py-1.5",
        dark ? "border-white/15" : "border-black/15")}>
        <Search size={13} className="shrink-0 opacity-50" />
        <input value={query} onChange={(e) => setQuery(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && load(query.trim())}
          placeholder="Search GIFs"
          className="min-w-0 flex-1 bg-transparent text-sm outline-none placeholder:opacity-40" />
        <button onClick={() => load(query.trim())} disabled={busy}
          className="shrink-0 text-[11px] font-semibold text-[#007AFF] disabled:opacity-40">Go</button>
      </div>
      <div className="flex-1 overflow-y-auto no-scrollbar p-1">
        {busy && (
          <div className="flex justify-center py-6">
            <Loader2 size={18} className="animate-spin opacity-60" />
          </div>
        )}
        {error && !busy && <div className="px-4 py-6 text-center text-xs opacity-60">{error}</div>}
        {!busy && !error && gifs?.length === 0 && (
          <div className="px-4 py-6 text-center text-xs opacity-60">No GIFs found</div>
        )}
        {gifs && gifs.length > 0 && (
          <div className="grid grid-cols-3 gap-1">
            {gifs.map((g, i) => (
              <button key={i} onClick={() => onPick(g.url)}
                className="overflow-hidden rounded-lg bg-black/10 active:opacity-70">
                <img src={g.preview || g.url} alt="" loading="lazy"
                  className="h-24 w-full object-cover" />
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}