import React, { useEffect, useRef, useState } from "react";
import { RotateCcw } from "lucide-react";
import { Switch } from "@/components/ui/switch";
import { APP_THEMES, getAppTheme, setAppTheme } from "@/lib/appTheme";

const NAME_KEY = "takeover-device-name";

export default function AppSettingsPanel({ onNameChange }) {
  const [name, setName] = useState(() => localStorage.getItem(NAME_KEY) || "");
  const [awake, setAwake] = useState(false);
  const [appTheme, setThemeState] = useState(getAppTheme);
  const wakeRef = useRef(null);

  const chooseTheme = (id) => {
    setAppTheme(id);
    setThemeState(id);
  };

  const saveName = (v) => {
    setName(v);
    localStorage.setItem(NAME_KEY, v);
    onNameChange?.(v);
  };

  const toggleAwake = async () => {
    if (awake) {
      try { await wakeRef.current?.release?.(); } catch {}
      wakeRef.current = null;
      setAwake(false);
      return;
    }
    if (!navigator.wakeLock) return;
    try {
      wakeRef.current = await navigator.wakeLock.request("screen");
      wakeRef.current.addEventListener("release", () => setAwake(false));
      setAwake(true);
    } catch {
      setAwake(false);
    }
  };

  useEffect(() => () => { wakeRef.current?.release?.().catch?.(() => {}); }, []);

  const resetOs = () => {
    if (window.confirm("Reset the mock OS to factory defaults? Themes, contacts, dock and lock settings will be restored.")) {
      localStorage.removeItem("takeover-os-config");
      window.location.reload();
    }
  };

  return (
    <div className="flex flex-col">
      <div className="flex items-center justify-between gap-4 py-3 border-b border-border">
        <div>
          <div className="text-sm font-body">Device name</div>
          <div className="text-[11px] text-muted-foreground font-body">Shown on this Home screen</div>
        </div>
        <input value={name} onChange={(e) => saveName(e.target.value)} placeholder="e.g. Hero phone"
          className="w-40 rounded-lg bg-muted/40 border border-border px-3 py-2 text-sm font-body outline-none focus:border-amber/50" />
      </div>

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
          <div className="text-sm font-body">Keep screen awake</div>
          <div className="text-[11px] text-muted-foreground font-body">Stops the prop screen from dimming</div>
        </div>
        <Switch checked={awake} onCheckedChange={toggleAwake} />
      </div>

      <div className="flex items-center justify-between gap-4 py-3">
        <div>
          <div className="text-sm font-body">Reset mock OS</div>
          <div className="text-[11px] text-muted-foreground font-body">Restore the phone OS to factory defaults</div>
        </div>
        <button onClick={resetOs}
          className="rounded-lg border border-alert/40 bg-alert/10 text-alert text-xs font-display font-semibold px-3 py-2 flex items-center gap-1.5">
          <RotateCcw size={14} /> Reset
        </button>
      </div>
    </div>
  );
}