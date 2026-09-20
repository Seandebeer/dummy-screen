import React, { useState, useEffect } from "react";
import { ArrowLeft, Bath, BedDouble, Heart, Plus, Ruler, X } from "lucide-react";
import { nextStockPhoto } from "@/lib/osSocial";
import { Editable, EditToggle, SaveToggle, Photo } from "./social/SocialBits";
import { cn } from "@/lib/utils";

// Realty - an editable mock property app. Browse listings, open one for the
// full detail; pencil toggles edit mode, the save button snapshots to Home.

export default function PropertyApp({ config, update, locked, fullscreen }) {
  const [openId, setOpenId] = useState(null);
  const [editing, setEditing] = useState(false);
  const [booked, setBooked] = useState([]);
  const canEdit = !locked && !fullscreen;
  useEffect(() => { if (!canEdit && editing) setEditing(false); }, [canEdit]);

  const data = config.property || {};
  const listings = data.listings || [];
  const listing = listings.find((l) => l.id === openId) || null;

  const patch = (k, v) => update((c) => ({ property: { ...(c.property || {}), [k]: v } }));
  const setListings = (fn) => update((c) => ({ property: { ...(c.property || {}), listings: fn(c.property?.listings || []) } }));
  const patchListing = (id, p) => setListings((list) => list.map((l) => (l.id === id ? { ...l, ...p } : l)));
  const addListing = () => {
    const id = `p-${Date.now()}`;
    setListings((list) => [...list, {
      id, price: "R 0", address: "New address", beds: "3", baths: "2", size: "120 m²",
      blurb: "Describe this home.", image: nextStockPhoto(),
    }]);
    setOpenId(id);
  };

  const toggleBook = (id) => setBooked((b) => (b.includes(id) ? b.filter((x) => x !== id) : [...b, id]));

  if (listing) {
    const isBooked = booked.includes(listing.id);
    return (
      <div className="flex h-full flex-col bg-black text-white">
        <div className="flex items-center gap-2 border-b border-white/10 px-2 py-2">
          <button onClick={() => setOpenId(null)} aria-label="Back to listings"
            className="flex h-8 w-8 items-center justify-center rounded-full text-white/70 active:bg-white/10">
            <ArrowLeft size={18} />
          </button>
          <span className="min-w-0 flex-1 truncate text-sm font-semibold">{listing.address}</span>
          {canEdit && (
            <span className="flex shrink-0 items-center gap-1">
              <SaveToggle className="bg-white/10 text-white" app="property"
                defaultName={`${listing.address} · Realty`} data={data} />
              <EditToggle editing={editing} onToggle={() => setEditing(!editing)} className="bg-white/10 text-white" />
            </span>
          )}
        </div>
        <div className="flex-1 overflow-y-auto no-scrollbar pb-6">
          <Photo src={listing.image} className="aspect-[4/3] w-full object-cover" editing={editing}
            onSwap={() => patchListing(listing.id, { image: nextStockPhoto(listing.image) })}
            onUpload={(url) => patchListing(listing.id, { image: url })} />
          <div className="px-4 pt-3">
            <Editable editing={editing} value={listing.price} onChange={(v) => patchListing(listing.id, { price: v })}
              className="text-[22px] font-bold text-[#32D74B]" />
            <Editable editing={editing} value={listing.address} onChange={(v) => patchListing(listing.id, { address: v })}
              className="mt-0.5 block text-[13px] text-white/60" />
            <div className="mt-3 flex items-center gap-4 rounded-xl bg-white/[0.07] px-3 py-2.5 text-[12px] text-white/70">
              <span className="flex items-center gap-1.5"><BedDouble size={15} className="text-white/45" />
                <Editable editing={editing} value={listing.beds} onChange={(v) => patchListing(listing.id, { beds: v })} /></span>
              <span className="flex items-center gap-1.5"><Bath size={15} className="text-white/45" />
                <Editable editing={editing} value={listing.baths} onChange={(v) => patchListing(listing.id, { baths: v })} /></span>
              <span className="flex items-center gap-1.5"><Ruler size={15} className="text-white/45" />
                <Editable editing={editing} value={listing.size} onChange={(v) => patchListing(listing.id, { size: v })} /></span>
            </div>
            <Editable editing={editing} value={listing.blurb} onChange={(v) => patchListing(listing.id, { blurb: v })}
              className="mt-3 block text-[13px] leading-relaxed text-white/75" />
            <button onClick={() => toggleBook(listing.id)}
              className={cn("mt-4 w-full rounded-xl py-3 text-[14px] font-semibold transition",
                isBooked ? "bg-white/10 text-white/60" : "bg-[#32D74B] text-black")}>
              {isBooked ? "Viewing booked ✓" : "Book a viewing"}
            </button>
            {editing && (
              <button onClick={() => { setListings((list) => list.filter((x) => x.id !== listing.id)); setOpenId(null); }}
                className="mt-3 w-full rounded-xl bg-[#FF453A]/15 py-3 text-[13px] font-semibold text-[#FF453A]">
                Delete listing
              </button>
            )}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-full flex-col bg-black text-white">
      <div className="flex items-center gap-2 border-b border-white/10 px-4 pb-2 pt-3">
        <div className="min-w-0 flex-1">
          <Editable editing={editing} value={data.name || "Realty"} onChange={(v) => patch("name", v)}
            className="block font-display text-2xl font-bold leading-tight" />
          <Editable editing={editing} value={data.tagline || ""} onChange={(v) => patch("tagline", v)}
            className="block text-[10px] uppercase tracking-widest text-white/40" />
        </div>
        {canEdit && (
          <span className="flex shrink-0 items-center gap-1">
            <SaveToggle className="bg-white/10 text-white" app="property"
              defaultName={`${data.name || "Realty"} listings`} data={data} />
            <EditToggle editing={editing} onToggle={() => setEditing(!editing)} className="bg-white/10 text-white" />
          </span>
        )}
      </div>
      <div className="flex-1 overflow-y-auto no-scrollbar px-3 pb-4 pt-3">
        {editing && (
          <button onClick={addListing}
            className="mb-3 w-full rounded-xl border border-dashed border-white/25 py-2 text-[12px] font-semibold text-white/55">
            + Add listing
          </button>
        )}
        <div className="space-y-3">
          {listings.map((l) => (
            <div key={l.id} onClick={!editing ? () => setOpenId(l.id) : undefined}
              className={cn("overflow-hidden rounded-2xl bg-white/[0.06]", !editing && "cursor-pointer active:scale-[0.98]")}>
              <div className="relative">
                <Photo src={l.image} className="aspect-[16/10] w-full object-cover" editing={editing}
                  onSwap={() => patchListing(l.id, { image: nextStockPhoto(l.image) })}
                  onUpload={(url) => patchListing(l.id, { image: url })} />
                {editing && (
                  <button onClick={() => setListings((list) => list.filter((x) => x.id !== l.id))}
                    aria-label="Delete listing"
                    className="absolute right-2 top-2 rounded-full bg-black/60 p-1.5 text-white/80">
                    <X size={13} />
                  </button>
                )}
                {!editing && (
                  <button onClick={(e) => { e.stopPropagation(); setBooked((b) => b.includes(l.id) ? b : [...b, l.id]); }}
                    aria-label="Save listing"
                    className="absolute right-2 top-2 rounded-full bg-black/55 p-2 text-white/85 backdrop-blur">
                    <Heart size={14} />
                  </button>
                )}
              </div>
              <div className="px-3.5 py-3">
                <Editable editing={editing} value={l.price} onChange={(v) => patchListing(l.id, { price: v })}
                  className="text-[16px] font-bold text-[#32D74B]" />
                <Editable editing={editing} value={l.address} onChange={(v) => patchListing(l.id, { address: v })}
                  className="block truncate text-[12px] text-white/55" />
                <div className="mt-1 flex items-center gap-3 text-[11px] text-white/45">
                  <span className="flex items-center gap-1"><BedDouble size={12} />{l.beds}</span>
                  <span className="flex items-center gap-1"><Bath size={12} />{l.baths}</span>
                  <span className="flex items-center gap-1"><Ruler size={12} />{l.size}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
        {listings.length === 0 && (
          <div className="py-10 text-center text-sm text-white/30">No listings yet{canEdit ? " - add one in edit mode" : ""}.</div>
        )}
      </div>
    </div>
  );
}