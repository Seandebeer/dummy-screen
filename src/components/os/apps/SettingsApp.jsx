import React, { useState, useRef } from "react";
import { Upload, Trash2, Loader2, ChevronDown, Check, RotateCcw, Minus, Plus } from "lucide-react";
import LockSettings from "./LockSettings";
import { bgPresets } from "@/hooks/useOsConfig";
import { DIAL_CODES, makeDefaultContacts } from "@/lib/osData";
import { LANGUAGES, uiFor } from "@/lib/osLanguages";
import { OS_THEMES } from "@/lib/osThemes";
import { OS_SKINS } from "@/lib/osSkins";
import { base44 } from "@/api/base44Client";
import { factoryReset } from "@/lib/factoryReset";
import { cn } from "@/lib/utils";

function Section({ title, children }) {
  return (
    <div className="px-5 pt-2">
      <div className="text-[11px] uppercase tracking-wider text-white/40 font-body mb-2">{title}</div>
      <div className="rounded-xl bg-white/5 border border-white/10 px-4 py-3.5">{children}</div>
    </div>
  );
}

export default function SettingsApp({ config, update, onLock, reset }) {
  const [uploading, setUploading] = useState(false);
  const [resetArmed, setResetArmed] = useState(false);
  const [confirmReset, setConfirmReset] = useState(false);
  const [resetting, setResetting] = useState(false);
  const [uploadError, setUploadError] = useState(false);
  const [editing, setEditing] = useState(null);
  const [draft, setDraft] = useState("");
  const [langOpen, setLangOpen] = useState(false);
  const fileRef = useRef(null);
  const t = uiFor(config.language);
  const activeCodes = config.dialCodes || DIAL_CODES;
  const autoRotate = config.autoRotate !== false;

  const applyCodes = (codes) => update((c) => ({
    dialCodes: codes,
    dialCode: codes[0],
    contactsVer: 2,
    contacts: [...makeDefaultContacts(codes, c.language || "en"), ...(c.contacts || []).filter((x) => x.custom)],
  }));

  // tap a pill to retype its number - a valid new code swaps straight into
  // the dial codes, which regenerates the contacts list immediately
  const commitEdit = (value) => {
    const i = editing;
    setEditing(null);
    if (i == null) return;
    const code = (value || "").trim();
    if (!/^\d{3}$/.test(code) || activeCodes.includes(code) || code === activeCodes[i]) return;
    const codes = [...activeCodes];
    codes[i] = code;
    applyCodes(codes);
  };

  // factory reset: wipe this device's pages, apps, settings and local data.
  // General saved items stay on Home; pages saved to the linked character's
  // device are cleared from that device's record.
  const factoryResetDevice = async () => {
    setResetting(true);
    try {
      await factoryReset();
      reset();
      setResetArmed(false);
      setConfirmReset(false);
      onLock();
    } finally {
      setResetting(false);
    }
  };

  const light = config.theme === "light";
  const bg = config.background || {};
  const hasImage = bg.type === "image" && bg.url;

  const skinButton = (sk) => {
    if (!sk) return null;
    const active = (config.skin || "modern") === sk.id;
    return (
      <button key={sk.id}
        onClick={() => update((c) => ({
          skin: sk.id,
          background: (c.background?.type || "preset") === "image"
            ? c.background
            : { type: "preset", preset: sk.preset, url: "" },
        }))}
        className={cn("flex items-center gap-3 rounded-lg border px-3 py-2.5 text-left transition",
          active ? "border-amber bg-amber/10" : "border-white/10 hover:border-white/30")}>
        <span className="h-10 w-10 shrink-0 rounded-xl border border-white/20" style={{ background: sk.preview }} />
        <span className="min-w-0">
          <span className="block text-sm font-semibold">{sk.name}</span>
          <span className="block text-[11px] text-white/50 font-body">{sk.desc}</span>
        </span>
        {active && <Check size={16} className="ml-auto shrink-0 text-amber" />}
      </button>
    );
  };

  const onFile = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setUploading(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      update({ background: { type: "image", preset: bg.preset || "default", url: file_url } });
      setUploadError(false);
    } catch {
      setUploadError(true);
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="h-full bg-[#0b0b0f] text-white overflow-y-auto no-scrollbar">
      <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={onFile} />

      <div className="px-5 pt-6 pb-2">
        <h2 className="font-display font-bold text-2xl">{t.settings}</h2>
      </div>

      <Section title="Interface">
        <div className="flex flex-col gap-2">
          {skinButton(OS_SKINS.find((s) => s.id === "modern"))}
          {skinButton(OS_SKINS.find((s) => s.id === "android"))}
          <div className="pt-2 text-[10px] uppercase tracking-wider text-white/35 font-body">Legacy</div>
          {OS_SKINS.filter((sk) => sk.era !== "modern").map(skinButton)}
        </div>
        <p className="text-[11px] text-white/40 font-body mt-2">Restyles the status bar, dock, icons and home button of this device.</p>
      </Section>

      <Section title={t.themes}>
        <div className="grid grid-cols-4 gap-2">
          {OS_THEMES.map((th) => {
            const preset = bgPresets.find((p) => p.id === th.preset) || bgPresets[0];
            const active = (bg.preset || "default") === th.preset && light === th.light;
            return (
              <button key={th.id}
                onClick={() => update({ theme: th.light ? "light" : "dark", background: { type: "preset", preset: th.preset, url: "" } })}
                className={cn("rounded-lg border-2 p-1 transition",
                  active ? "border-amber" : "border-white/10 hover:border-white/30")}>
                <span className="block h-10 rounded" style={{ background: th.light ? preset.light : preset.dark }} />
                <span className={cn("block pt-1 text-[10px] font-body", active ? "text-amber" : "text-white/60")}>{th.name}</span>
              </button>
            );
          })}
        </div>
      </Section>

      <Section title={t.background}>
        <div className="grid grid-cols-4 gap-2 mb-3">
          {bgPresets.map((p) => (
            <button key={p.id} onClick={() => update({ background: { type: "preset", preset: p.id, url: "" } })}
              className={cn("rounded-lg border-2 p-1 transition",
                !hasImage && (bg.preset || "default") === p.id ? "border-amber" : "border-white/10 hover:border-white/30")}>
              <span className="block h-8 rounded" style={{ background: p.dark }} />
            </button>
          ))}
        </div>
        <div className="flex gap-2">
          <button onClick={() => fileRef.current?.click()} disabled={uploading}
            className="flex-1 rounded-lg bg-[#0A84FF] text-white text-xs font-semibold py-2 flex items-center justify-center gap-1.5 disabled:opacity-60">
            {uploading ? <Loader2 size={14} className="animate-spin" /> : <Upload size={14} />} Upload Image
          </button>
          {hasImage && (
            <button onClick={() => update({ background: { type: "preset", preset: bg.preset || "default", url: "" } })}
              className="rounded-lg bg-white/10 text-white/80 text-xs px-3 py-2 flex items-center gap-1.5">
              <Trash2 size={14} /> Remove
            </button>
          )}
        </div>
        {uploadError && <p className="text-[11px] text-[#FF453A] font-body mt-2">image upload failed - try again</p>}
      </Section>

      <LockSettings config={config} update={update} onLock={onLock} />

      <Section title={t.dialCodes}>
        <div className="flex gap-2">
          {activeCodes.map((code, i) => editing === i ? (
            <input key={`edit-${i}`} autoFocus inputMode="numeric" value={draft}
              onChange={(e) => {
                const v = e.target.value.replace(/\D/g, "").slice(0, 3);
                setDraft(v);
                if (v.length === 3) commitEdit(v);
              }}
              onBlur={() => commitEdit(draft)}
              onKeyDown={(e) => { if (e.key === "Enter") commitEdit(draft); }}
              className="flex-1 rounded-lg border border-amber bg-amber/10 py-2.5 text-center font-body text-sm text-amber outline-none" />
          ) : (
            <button key={code} onClick={() => { setEditing(i); setDraft(code); }}
              className="flex-1 rounded-lg border border-amber/40 text-amber bg-amber/10 py-2.5 font-body text-sm transition hover:border-amber">
              {code}
            </button>
          ))}
        </div>
        <p className="text-[11px] text-white/40 font-body mt-2">Tap to edit</p>
      </Section>

      <Section title={t.language}>
        <button onClick={() => setLangOpen((o) => !o)} className="flex w-full items-center justify-between text-sm">
          <span>{LANGUAGES.find((l) => l.code === (config.language || "en"))?.native || "English"}</span>
          <ChevronDown size={16} className={cn("text-white/50 transition-transform", langOpen && "rotate-180")} />
        </button>
        {langOpen && (
          <>
            <div className="grid grid-cols-2 gap-2 mt-3">
              {LANGUAGES.map((l) => (
                <button key={l.code}
                  onClick={() => update((c) => ({
                    language: l.code,
                    contactsLang: l.code,
                    contactsVer: 2,
                    contacts: [...makeDefaultContacts(c.dialCodes || DIAL_CODES, l.code), ...(c.contacts || []).filter((x) => x.custom)],
                  }))}
                  className={cn("rounded-lg border px-3 py-2 text-sm text-left font-body transition",
                    (config.language || "en") === l.code ? "border-amber text-amber bg-amber/10" : "border-white/10 text-white/70 hover:border-white/30")}>
                  {l.native}
                </button>
              ))}
            </div>
            <p className="text-[11px] text-white/40 font-body mt-2">Default contacts follow this language; custom contacts are kept.</p>
          </>
        )}
      </Section>

      <Section title={t.answerCalls || "Answer Calls"}>
        <div className="grid grid-cols-2 gap-2">
          {[
            { id: "tap", label: t.answerTap || "Button Tap" },
            { id: "swipe", label: t.answerSwipe || "Swipe" },
          ].map((o) => (
            <button key={o.id} onClick={() => update({ callAnswer: o.id })}
              className={cn("rounded-lg border py-2.5 font-body text-sm transition",
                (config.callAnswer || "tap") === o.id
                  ? "border-amber text-amber bg-amber/10"
                  : "border-white/10 text-white/60 hover:border-white/30")}>
              {o.label}
            </button>
          ))}
        </div>
        <p className="text-[11px] text-white/40 font-body mt-2">How incoming calls are answered on this device.</p>
      </Section>

      <Section title="Ring Duration">
        {(() => {
          const delay = Math.min(60, Math.max(1, Number(config.ringDelay) || 4));
          return (
            <>
              <div className="flex items-center gap-3">
                <button onClick={() => update({ ringDelay: Math.max(1, delay - 1) })}
                  className="h-9 w-9 rounded-lg border border-white/10 text-white/70 flex items-center justify-center hover:border-white/30 transition">
                  <Minus size={14} />
                </button>
                <div className="flex-1 text-center text-sm font-body font-semibold">{delay}s</div>
                <button onClick={() => update({ ringDelay: Math.min(60, delay + 1) })}
                  className="h-9 w-9 rounded-lg border border-white/10 text-white/70 flex items-center justify-center hover:border-white/30 transition">
                  <Plus size={14} />
                </button>
              </div>
              <p className="text-[11px] text-white/40 font-body mt-2">How long the other side rings before picking up (1–60s).</p>
            </>
          );
        })()}
      </Section>

      <Section title="Auto-Rotate">
        <button onClick={() => update({ autoRotate: !autoRotate })}
          className="flex w-full items-center justify-between">
          <span className="text-sm">Turn screen with device</span>
          <span className={cn("relative h-6 w-10 shrink-0 rounded-full transition", autoRotate ? "bg-[#30D158]" : "bg-white/15")}>
            <span className={cn("absolute top-0.5 h-5 w-5 rounded-full bg-white transition-all", autoRotate ? "left-[18px]" : "left-0.5")} />
          </span>
        </button>
        <p className="text-[11px] text-white/40 font-body mt-2">Turn this device on its side and the screen turns with it - even when the device's rotation lock is on.</p>
      </Section>

      <Section title="Reset">
        {resetArmed ? (
          <>
            <p className="text-[12px] text-white/60 font-body leading-relaxed">
              Erase all changes on this device - pages, apps, settings and configurations. Pages saved to this character's device are removed from it; items saved to General stay in Saved.
            </p>
            <div className="mt-3 flex gap-2">
              <button onClick={() => setResetArmed(false)}
                className="flex-1 rounded-lg border border-white/10 py-2.5 text-sm font-body text-white/70 hover:border-white/30 transition">
                Cancel
              </button>
              <button onClick={() => setConfirmReset(true)} disabled={resetting}
                className="flex flex-1 items-center justify-center gap-1.5 rounded-lg bg-[#FF453A] py-2.5 text-sm font-semibold text-white transition disabled:opacity-60">
                {resetting ? <Loader2 size={14} className="animate-spin" /> : <RotateCcw size={14} />} Erase Device
              </button>
            </div>
          </>
        ) : (
          <button onClick={() => setResetArmed(true)}
            className="flex w-full items-center gap-2 text-sm text-[#FF453A]">
            <RotateCcw size={15} /> Factory Reset
          </button>
        )}
      </Section>

      {confirmReset && (
        <div className="absolute inset-0 z-30 flex items-center justify-center bg-black/70 px-8">
          <div className="w-full rounded-2xl bg-[#1c1c1e] p-5 text-center">
            <h3 className="font-display text-[16px] font-semibold">Erase all content?</h3>
            <p className="mt-1.5 text-[12px] leading-relaxed text-white/55 font-body">
              This removes every change on this device - pages, apps, settings and configurations. General saved items are kept. This cannot be undone.
            </p>
            <div className="mt-4 flex flex-col gap-2">
              <button onClick={factoryResetDevice} disabled={resetting}
                className="flex items-center justify-center gap-1.5 rounded-xl bg-[#FF453A] py-2.5 text-sm font-semibold text-white transition disabled:opacity-60">
                {resetting ? <Loader2 size={14} className="animate-spin" /> : <RotateCcw size={14} />} Erase
              </button>
              <button onClick={() => { setConfirmReset(false); setResetArmed(false); }}
                className="rounded-xl bg-white/10 py-2.5 text-sm font-body text-white/80 transition">
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      <p className="text-center text-[10px] text-white/25 font-body uppercase tracking-widest pt-6 pb-8">Takeover OS · prop build 1.0</p>
    </div>
  );
}