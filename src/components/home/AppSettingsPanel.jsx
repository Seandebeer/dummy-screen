import React, { useEffect, useState } from "react";
import { HelpCircle, MessageSquareWarning } from "lucide-react";
import { APP_THEMES, getAppTheme, setAppTheme } from "@/lib/appTheme";
import { APP_LANGUAGES, applyAppLanguage, getAppLanguage, setAppLanguage } from "@/lib/appLanguage";
import HelpDialog from "@/components/home/HelpDialog";
import BugReportDialog from "@/components/home/BugReportDialog";

export default function AppSettingsPanel() {
  const [appTheme, setThemeState] = useState(getAppTheme);
  const [lang, setLangState] = useState(getAppLanguage);
  const [helpOpen, setHelpOpen] = useState(false);
  const [bugOpen, setBugOpen] = useState(false);

  useEffect(() => { applyAppLanguage(getAppLanguage()); }, []);

  const chooseTheme = (id) => {
    setAppTheme(id);
    setThemeState(id);
  };

  const chooseLang = (code) => {
    setAppLanguage(code);
    setLangState(code);
  };

  return (
    <div className="flex flex-col">
      <div className="flex items-center justify-between gap-4 py-3 border-b border-border">
        <div>
          <div className="text-sm font-body">App theme</div>
          <div className="text-[11px] text-muted-foreground font-body">Colours for the whole control app</div>
        </div>
        <div className="flex gap-1.5">
          {APP_THEMES.map((t) => (
            <button key={t.id} onClick={() => chooseTheme(t.id)}
              className={("rounded-lg border px-3 py-2 text-xs font-display font-semibold transition ") +
                (appTheme === t.id ? "border-amber bg-amber/15 text-amber" : "border-border text-muted-foreground hover:text-foreground")}>
              {t.label}
            </button>
          ))}
        </div>
      </div>

      <div className="flex items-center justify-between gap-4 py-3 border-b border-border">
        <div>
          <div className="text-sm font-body">App language</div>
          <div className="text-[11px] text-muted-foreground font-body">Interface language preference</div>
        </div>
        <select value={lang} onChange={(e) => chooseLang(e.target.value)}
          className="cursor-pointer rounded-lg border border-border bg-muted/40 px-3 py-2 text-xs font-body outline-none transition hover:border-amber/40">
          {APP_LANGUAGES.map((l) => (
            <option key={l.code} value={l.code}>{l.native}</option>
          ))}
        </select>
      </div>

      <div className="flex items-center justify-between gap-4 py-3 border-b border-border">
        <div>
          <div className="text-sm font-body">Help</div>
          <div className="text-[11px] text-muted-foreground font-body">Quick guide to using PropSync</div>
        </div>
        <button onClick={() => setHelpOpen(true)}
          className="flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-xs font-display font-semibold text-muted-foreground hover:text-foreground transition">
          <HelpCircle size={14} /> Open
        </button>
      </div>

      <div className="flex items-center justify-between gap-4 py-3">
        <div>
          <div className="text-sm font-body">Report a bug</div>
          <div className="text-[11px] text-muted-foreground font-body">Something not working? Let the team know</div>
        </div>
        <button onClick={() => setBugOpen(true)}
          className="flex items-center gap-1.5 rounded-lg border border-alert/40 bg-alert/10 px-3 py-2 text-xs font-display font-semibold text-alert transition">
          <MessageSquareWarning size={14} /> Report
        </button>
      </div>

      <HelpDialog open={helpOpen} onOpenChange={setHelpOpen} />
      <BugReportDialog open={bugOpen} onOpenChange={setBugOpen} />
    </div>
  );
}