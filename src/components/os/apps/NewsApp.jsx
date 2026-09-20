import React, { useState, useEffect } from "react";
import { Plus, X } from "lucide-react";
import { nextStockPhoto } from "@/lib/osSocial";
import { saveWithPrompt } from "@/lib/savedPages";
import { Editable, EditToggle, SaveToggle, Photo } from "./social/SocialBits";
import { cn } from "@/lib/utils";

// Bulletin - an editable mock news app. Pencil toggles edit mode; the save
// button snapshots the edition to the Home saved card under "Apps".

export default function NewsApp({ config, update, locked, fullscreen }) {
  const [editing, setEditing] = useState(false);
  const canEdit = !locked && !fullscreen;
  useEffect(() => { if (!canEdit && editing) setEditing(false); }, [canEdit]);

  const data = config.news || {};
  const articles = data.articles || [];

  const patch = (k, v) => update((c) => ({ news: { ...(c.news || {}), [k]: v } }));
  const setArticles = (fn) => update((c) => ({ news: { ...(c.news || {}), articles: fn(c.news?.articles || []) } }));
  const patchArticle = (id, p) => setArticles((list) => list.map((a) => (a.id === id ? { ...a, ...p } : a)));
  const addArticle = () => setArticles((list) => [...list, {
    id: `n-${Date.now()}`, tag: "Local", title: "New story", body: "Write the story here.", image: nextStockPhoto(),
  }]);

  const today = new Date().toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" });

  return (
    <div className="h-full overflow-y-auto no-scrollbar bg-black text-white">
      <div className="sticky top-0 z-10 flex items-center gap-2 bg-black/85 px-4 pb-2 pt-3 backdrop-blur">
        <div className="min-w-0 flex-1">
          <Editable editing={editing} value={data.name || "Bulletin"} onChange={(v) => patch("name", v)}
            className="block font-display text-2xl font-bold leading-tight" />
          <Editable editing={editing} value={data.tagline || ""} onChange={(v) => patch("tagline", v)}
            className="block text-[10px] uppercase tracking-widest text-white/40" />
        </div>
        {canEdit && (
          <span className="flex shrink-0 items-center gap-1">
            <SaveToggle className="bg-white/10 text-white"
              onSave={() => saveWithPrompt("news", `${data.name || "Bulletin"} edition`, data)} />
            <EditToggle editing={editing} onToggle={() => setEditing(!editing)} className="bg-white/10 text-white" />
          </span>
        )}
      </div>
      <div className="px-4 pb-2 text-[10px] uppercase tracking-widest text-white/35">{today}</div>

      {editing && (
        <div className="px-4 pb-2">
          <button onClick={addArticle}
            className="w-full rounded-lg border border-dashed border-white/25 py-1.5 text-[12px] font-semibold text-white/55">
            + Add story
          </button>
        </div>
      )}

      {articles.map((a, i) => (
        <article key={a.id} className={cn("border-b border-white/10", i === 0 ? "px-4 pb-5" : "px-4 py-4")}>
          {i === 0 && (
            <Photo src={a.image} className="aspect-[16/10] w-full rounded-xl object-cover" editing={editing}
              onSwap={() => patchArticle(a.id, { image: nextStockPhoto(a.image) })}
              onUpload={(url) => patchArticle(a.id, { image: url })} />
          )}
          <div className={cn("flex items-center gap-2", i === 0 ? "mt-2.5" : "mb-1")}>
            <span className="rounded-sm bg-[#DC4A38] px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-widest">
              <Editable editing={editing} value={a.tag} onChange={(v) => patchArticle(a.id, { tag: v })} />
            </span>
            {editing && (
              <button onClick={() => setArticles((list) => list.filter((x) => x.id !== a.id))}
                aria-label="Delete story" className="ml-auto p-0.5 text-white/30 hover:text-[#FF453A]">
                <X size={13} />
              </button>
            )}
          </div>
          <div className="flex items-start gap-3">
            <div className="min-w-0 flex-1">
              <Editable editing={editing} value={a.title} onChange={(v) => patchArticle(a.id, { title: v })}
                className={cn("font-display font-bold leading-tight", i === 0 ? "text-[21px]" : "text-[15px]")} />
              <Editable editing={editing} value={a.body} onChange={(v) => patchArticle(a.id, { body: v })}
                className={cn("mt-1 block leading-relaxed text-white/60", i === 0 ? "text-[13px]" : "text-[12.5px] line-clamp-2")} />
            </div>
            {i > 0 && (
              <Photo src={a.image} className="h-20 w-28 shrink-0 rounded-lg object-cover" editing={editing}
                onSwap={() => patchArticle(a.id, { image: nextStockPhoto(a.image) })}
                onUpload={(url) => patchArticle(a.id, { image: url })} />
            )}
          </div>
        </article>
      ))}
      {articles.length === 0 && (
        <div className="py-10 text-center text-sm text-white/30">No stories yet{canEdit ? " - add one in edit mode" : ""}.</div>
      )}
      <div className="px-4 py-5 text-center text-[10px] text-white/25">© {data.name || "Bulletin"} · Mock edition</div>
    </div>
  );
}