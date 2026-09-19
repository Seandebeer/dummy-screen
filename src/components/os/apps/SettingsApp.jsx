import React, { useState, useRef } from "react";
import { Upload, Trash2, Loader2, ChevronDown, Check } from "lucide-react";
import LockSettings from "./LockSettings";
import { bgPresets } from "@/hooks/useOsConfig";
import { DIAL_CODES, makeDefaultContacts } from "@/lib/osData";
import { LANGUAGES, uiFor } from "@/lib/osLanguages";
import { OS_THEMES } from "@/lib/osThemes";
import { OS_SKINS } from "@/lib/osSkins";
import { base44 } from "@/api/base44Client";
import { cn } from "@/lib/utils";

function Section({ title, children }) {
  return (
    <div className="px-5 pt-2">
      <div className="text-[11px] uppercase tracking-wider text-white/40 font-body mb-2">{title}</div>
      <div className="rounded-xl bg-white/5 border border-white/10 px-4 py-3.5">{children}</div>
    </div>
  );
}

export default function SettingsApp({ config, update, onLock }) {
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState(false);
  const [codeDraft, setCodeDraft] = useState("");
  const [langOpen, setLangOpen] = useState(false);
  const fileRef = useRef(null);
  const t = uiFor(config.language);
  const activeCodes = config.dialCodes || DIAL_CODES;

  const applyCodes = (codes) => update((c) => ({
    dialCodes: codes,
    dialCode: codes[0],
    contactsVer: 2,
    contacts: [...makeDefaultContacts(codes, c.language || "en"), ...(c.contacts || []).filter((x) => x.custom)],
  }));

  const toggleCode = (code) => {
    if (activeCodes.includes(code)) {
      if (activeCodes.length > 1) applyCodes(activeCodes.filter((c) => c !== code));
    } else if (activeCodes.length >= 3) {
      applyCodes([...activeCodes.slice(1), code]);
    } else {
      applyCodes([...activeCodes, code]);
    }
  };

  const applyCustomCode = () => {
    if (codeDraft.length !== 3 || activeCodes.includes(codeDraft)) return;
    toggleCode(codeDraft);
    setCodeDraft("");
  };

  const light = config.theme === "light";
  const bg = config.background || {};
  const hasImage = bg.type === "image" && bg.url;

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
          {OS_SKINS.map((sk) => {
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
          })}
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
          {DIAL_CODES.map((code) => (
            <button key={code} onClick={() => toggleCode(code)}
              className={cn("flex-1 rounded-lg border py-2.5 font-body text-sm transition",
                activeCodes.includes(code)
                  ? "border-amber text-amber bg-amber/10"
                  : "border-white/10 text-white/60 hover:border-white/30")}>
              {code}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-2 mt-3">
          <input value={codeDraft} onChange={(e) => setCodeDraft(e.target.value.replace(/\D/g, "").slice(0, 3))}
            inputMode="numeric" placeholder="Custom code"
            className="flex-1 rounded-lg bg-white/5 border border-white/10 px-3 py-2 font-body text-sm outline-none focus:border-amber placeholder:text-white/25" />
          <button disabled={codeDraft.length !== 3} onClick={applyCustomCode}
            className="rounded-lg bg-amber/15 border border-amber/40 text-amber text-xs font-semibold px-3 py-2 disabled:opacity-35 disabled:border-white/10 disabled:text-white/30">
            Apply
          </button>
        </div>
        <p className="text-[11px] text-white/40 font-body mt-2">Up to 3 codes stay active - mock numbers start with an active code, the rest is random.</p>
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

      <p className="text-center text-[10px] text-white/25 font-body uppercase tracking-widest pt-6 pb-8">Takeover OS · prop build 1.0</p>
    </div>
  );
}