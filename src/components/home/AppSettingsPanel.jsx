import React, { useEffect, useState } from "react";
import { GraduationCap, LifeBuoy, MessageSquareWarning, Share2 } from "lucide-react";
import { APP_THEMES, getAppTheme, setAppTheme } from "@/lib/appTheme";
import { APP_LANGUAGES, applyAppLanguage, getAppLanguage, setAppLanguage } from "@/lib/appLanguage";
import { useToast } from "@/components/ui/use-toast";
import SupportDialog from "@/components/home/SupportDialog";
import BugReportDialog from "@/components/home/BugReportDialog";
import TutorialDialog from "@/components/home/TutorialDialog";

export default function AppSettingsPanel() {
  const [appTheme, setThemeState] = useState(getAppTheme);
  const [lang, setLangState] = useState(getAppLanguage);
  const [supportOpen, setSupportOpen] = useState(false);
  const [bugOpen, setBugOpen] = useState(false);
  const [tutorialOpen, setTutorialOpen] = useState(false);
  const { toast } = useToast();

  useEffect(() => { applyAppLanguage(getAppLanguage()); }, []);

  // share the app - the App Store / Google Play link lands here once published
  const shareApp = async () => {
    const storeUrl = null;
    const text = storeUrl
      ? `Get Dummy Screen: ${storeUrl}`
      : "Dummy Screen - coming soon to the App Store and Google Play";
    try {
      if (navigator.share) { await navigator.share({ title: "Dummy Screen", text, ...(storeUrl ? { url: storeUrl } : {}) }); return; }
      await navigator.clipboard.writeText(text);
      toast({ description: "Copied - store links coming soon" });
    } catch {}
  };

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
          <div className="text-sm font-body">Tutorial</div>
          <div className="text-[11px] text-muted-foreground font-body">Guided walkthrough of the apps, step by step</div>
        </div>
        <button onClick={() => setTutorialOpen(true)}
          className="flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-xs font-display font-semibold text-muted-foreground hover:text-foreground transition">
          <GraduationCap size={14} /> Start
        </button>
      </div>

      <div className="flex items-center justify-between gap-4 py-3 border-b border-border">
        <div>
          <div className="text-sm font-body">Support</div>
          <div className="text-[11px] text-muted-foreground font-body">Send a message to the dev team</div>
        </div>
        <button onClick={() => setSupportOpen(true)}
          className="flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-xs font-display font-semibold text-muted-foreground hover:text-foreground transition">
          <LifeBuoy size={14} /> Open
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

      <div className="flex items-center justify-between gap-4 pt-3 border-t border-border">
        <div>
          <div className="text-sm font-body">Share App</div>
          <div className="text-[11px] text-muted-foreground font-body">Send Dummy Screen to the rest of the crew</div>
        </div>
        <button onClick={shareApp}
          className="flex items-center gap-1.5 rounded-lg border border-signal/40 bg-signal/10 px-3 py-2 text-xs font-display font-semibold text-signal hover:bg-signal/20 transition">
          <Share2 size={14} /> Share
        </button>
      </div>

      <SupportDialog open={supportOpen} onOpenChange={setSupportOpen} />
      <BugReportDialog open={bugOpen} onOpenChange={setBugOpen} />
      <TutorialDialog open={tutorialOpen} onOpenChange={setTutorialOpen} />
    </div>
  );
}