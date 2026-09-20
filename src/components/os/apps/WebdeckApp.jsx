import React, { useState, useEffect } from "react";
import { ArrowLeft, X, Globe } from "lucide-react";
import { nextStockPhoto } from "@/lib/osSocial";
import { saveWithPrompt } from "@/lib/savedPages";
import { MAX_SITES } from "@/lib/osSites";
import { Editable, EditToggle, SaveToggle, Photo } from "./social/SocialBits";
import { cn } from "@/lib/utils";

// Webdeck - a fake browser holding up to five fully editable mock websites.
// Pencil toggles edit mode; the save button snapshots the open site to the
// Home saved card under "Websites".

export default function WebdeckApp({ config, update, locked, fullscreen }) {
  const [openId, setOpenId] = useState(null);
  const [editing, setEditing] = useState(false);
  const canEdit = !locked && !fullscreen;
  useEffect(() => { if (!canEdit && editing) setEditing(false); }, [canEdit]);

  const sites = config.webdeck?.sites || [];
  const site = sites.find((s) => s.id === openId) || null;

  const setSites = (fn) => update((c) => ({
    webdeck: { ...(c.webdeck || {}), sites: fn(c.webdeck?.sites || []) },
  }));
  const patchSite = (id, patch) => setSites((list) => list.map((s) => (s.id === id ? { ...s, ...patch } : s)));
  const removeSite = (id) => {
    setSites((list) => list.filter((s) => s.id !== id));
    if (openId === id) setOpenId(null);
  };

  const addSite = () => {
    if (sites.length >= MAX_SITES) return;
    const id = `site-${Date.now()}`;
    setSites((list) => [...list, {
      id,
      name: "New Site",
      url: "mysite.com",
      hue: "#0A84FF",
      tagline: "A brand-new corner of the web",
      nav: ["Home", "About", "Blog", "Contact"],
      hero: { kicker: "Welcome to", heading: "Your headline here", sub: "Say something great about this site.", cta: "Learn more", image: nextStockPhoto() },
      cards: [],
      links: ["About", "Privacy", "Terms"],
      footNote: "© New Site",
    }]);
    setOpenId(id);
  };

  const patchHero = (key, value) => site && patchSite(site.id, { hero: { ...site.hero, [key]: value } });
  const patchCards = (fn) => site && patchSite(site.id, { cards: fn(site.cards || []) });
  const patchStrList = (key, fn) => site && patchSite(site.id, { [key]: fn(site[key] || []) });
  const addCard = () => patchCards((list) => [...list, {
    id: `c-${Date.now()}`, title: "New story", body: "Write something here.", image: nextStockPhoto(),
  }]);

  // editable row of strings (site nav + footer links)
  const StrList = ({ items, keyName, itemClass }) => (
    <span className="flex flex-wrap items-center gap-x-3 gap-y-1">
      {(items || []).map((it, i) => (
        <span key={i} className="flex items-center gap-0.5">
          <Editable editing={editing} value={it}
            onChange={(v) => patchStrList(keyName, (list) => list.map((x, j) => (j === i ? v : x)))}
            className={itemClass} />
          {editing && (
            <button onClick={() => patchStrList(keyName, (list) => list.filter((_, j) => j !== i))} className="p-0.5 text-black/30">
              <X size={11} />
            </button>
          )}
        </span>
      ))}
      {editing && (
        <button onClick={() => patchStrList(keyName, (list) => [...list, "New"])}
          className="text-[11px] font-semibold text-black/40 hover:text-black/70">+ Add</button>
      )}
    </span>
  );

  return (
    <div className="flex h-full flex-col bg-white text-[#111]">
      {/* browser chrome */}
      <div className="flex items-center gap-1.5 border-b border-black/10 bg-[#f2f2f7] px-2 py-2">
        <button onClick={() => setOpenId(null)} disabled={!site} aria-label="Back to start"
          className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-black/70 disabled:opacity-30 transition active:scale-90">
          <ArrowLeft size={16} />
        </button>
        <span className="flex min-w-0 flex-1 items-center gap-1.5 rounded-full border border-black/10 bg-white px-3 py-1.5 shadow-sm">
          <Globe size={12} className="shrink-0 text-black/35" />
          {editing && site ? (
            <Editable editing value={site.url} onChange={(v) => patchSite(site.id, { url: v })}
              className="min-w-0 flex-1 text-[12px] text-black/60" />
          ) : (
            <span className="min-w-0 flex-1 truncate text-[12px] text-black/60">
              {site ? site.url : "webdeck://start"}
            </span>
          )}
        </span>
        {canEdit && (
          <span className="flex shrink-0 items-center gap-1">
            {site && (
              <SaveToggle onSave={() => saveWithPrompt("webdeck", `${site.name} site`, site)} />
            )}
            <EditToggle editing={editing} onToggle={() => setEditing(!editing)} />
          </span>
        )}
      </div>

      {!site ? (
        /* start page - the site deck */
        <div className="flex-1 overflow-y-auto no-scrollbar px-4 pt-5">
          <div className="font-display text-lg font-bold">Webdeck</div>
          <div className="text-[11px] text-black/45">
            {sites.length}/{MAX_SITES} mock sites · fully editable · pencil to edit, save icon to keep
          </div>
          {editing && sites.length < MAX_SITES && (
            <button onClick={addSite}
              className="mt-3 w-full rounded-lg border border-dashed border-black/25 py-1.5 text-[12px] font-semibold text-black/55">
              + Add site
            </button>
          )}
          <div className="mt-4 space-y-2 pb-4">
            {sites.map((s) => (
              <div key={s.id} onClick={!editing ? () => setOpenId(s.id) : undefined}
                className={cn("rounded-xl border border-black/10 bg-white p-3 shadow-sm",
                  !editing && "cursor-pointer transition active:scale-[0.98]")}>
                <div className="flex items-center gap-2.5">
                  <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-[14px] font-bold text-white"
                    style={{ background: s.hue }}>
                    {(s.name || "?")[0]}
                  </span>
                  <span className="min-w-0 flex-1">
                    <Editable editing={editing} value={s.name} onChange={(v) => patchSite(s.id, { name: v })}
                      className="block truncate text-[13px] font-semibold" />
                    <Editable editing={editing} value={s.url} onChange={(v) => patchSite(s.id, { url: v })}
                      className="block truncate text-[11px] text-black/45" />
                  </span>
                  {editing && (
                    <button onClick={() => removeSite(s.id)} aria-label="Delete site"
                      className="p-1 text-black/35 hover:text-alert">
                      <X size={14} />
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : (
        /* the editable website */
        <div className="flex-1 overflow-y-auto no-scrollbar bg-white">
          <div className="flex items-center gap-2.5 border-b border-black/10 px-4 py-3">
            <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-[13px] font-bold text-white"
              style={{ background: site.hue }}>
              {(site.name || "?")[0]}
            </span>
            <span className="min-w-0 flex-1">
              <Editable editing={editing} value={site.name} onChange={(v) => patchSite(site.id, { name: v })}
                className="block truncate text-[15px] font-bold" />
              <Editable editing={editing} value={site.tagline} onChange={(v) => patchSite(site.id, { tagline: v })}
                className="block truncate text-[10px] uppercase tracking-wider text-black/40" />
            </span>
            <StrList items={site.nav} keyName="nav" itemClass="text-[11px] text-black/55" />
          </div>

          <div className="px-5 pt-6">
            <Editable editing={editing} value={site.hero.kicker} onChange={(v) => patchHero("kicker", v)}
              className="block text-[10px] font-semibold uppercase tracking-widest"
              inputClass="text-[10px] uppercase tracking-widest" />
            <Editable editing={editing} value={site.hero.heading} onChange={(v) => patchHero("heading", v)}
              className="block text-[24px] font-display font-bold leading-tight" />
            <Editable editing={editing} value={site.hero.sub} onChange={(v) => patchHero("sub", v)}
              className="mt-1 block text-[13px] leading-snug text-black/60" />
            <span className="mt-3 inline-block rounded-full px-4 py-1.5 text-[12px] font-semibold text-white"
              style={{ background: site.hue }}>
              <Editable editing={editing} value={site.hero.cta} onChange={(v) => patchHero("cta", v)} />
            </span>
            {site.hero.image && (
              <Photo src={site.hero.image} className="mt-4 aspect-[16/9] w-full rounded-xl object-cover"
                editing={editing}
                onSwap={() => patchHero("image", nextStockPhoto(site.hero.image))}
                onUpload={(url) => patchHero("image", url)} />
            )}
            {editing && !site.hero.image && (
              <Photo src="" editing onAdd={() => patchHero("image", nextStockPhoto())}
                className="mt-4 aspect-[16/9] w-full rounded-xl" addLabel="Add hero photo" />
            )}
          </div>

          <div className="mt-5 space-y-6 border-t border-black/10 px-5 pt-4">
            {editing && (
              <button onClick={addCard}
                className="w-full rounded-lg border border-dashed border-black/25 py-1.5 text-[12px] font-semibold text-black/55">
                + Add card
              </button>
            )}
            {(site.cards || []).map((c) => (
              <div key={c.id}>
                <div className="flex items-start gap-2">
                  <Editable editing={editing} value={c.title}
                    onChange={(v) => patchCards((list) => list.map((x) => (x.id === c.id ? { ...x, title: v } : x)))}
                    className="text-[15px] font-bold" />
                  {editing && (
                    <button onClick={() => patchCards((list) => list.filter((x) => x.id !== c.id))}
                      aria-label="Delete card" className="ml-auto p-0.5 text-black/30 hover:text-alert">
                      <X size={13} />
                    </button>
                  )}
                </div>
                <Editable editing={editing} value={c.body}
                  onChange={(v) => patchCards((list) => list.map((x) => (x.id === c.id ? { ...x, body: v } : x)))}
                  className="mt-1 block text-[12.5px] leading-relaxed text-black/70" />
                {c.image ? (
                  <Photo src={c.image} className="mt-2 aspect-video w-full rounded-lg object-cover" editing={editing}
                    onSwap={() => patchCards((list) => list.map((x) => (x.id === c.id ? { ...x, image: nextStockPhoto(x.image) } : x)))}
                    onUpload={(url) => patchCards((list) => list.map((x) => (x.id === c.id ? { ...x, image: url } : x)))}
                    onDelete={() => patchCards((list) => list.map((x) => (x.id === c.id ? { ...x, image: "" } : x)))} />
                ) : editing ? (
                  <Photo src="" editing onAdd={() => patchCards((list) => list.map((x) => (x.id === c.id ? { ...x, image: nextStockPhoto() } : x)))}
                    className="mt-2 aspect-video w-full rounded-lg" addLabel="Add photo" />
                ) : null}
              </div>
            ))}
          </div>

          <div className="mt-6 border-t border-black/10 px-5 py-4">
            <StrList items={site.links} keyName="links" itemClass="text-[11px] text-black/50" />
            <Editable editing={editing} value={site.footNote} onChange={(v) => patchSite(site.id, { footNote: v })}
              className="mt-2 block text-[10px] text-black/35" />
          </div>
        </div>
      )}
    </div>
  );
}