import React, { useState, useEffect, useCallback, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { Camera, Download, KeyRound, Loader2, LogOut, Share2, Trash2, UserRound } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { Image } from "@/components/ui/image";
import { useAuth } from "@/lib/AuthContext";
import { useToast } from "@/components/ui/use-toast";
import { applyOsConfig } from "@/lib/osConfigStore";

export default function ProfilePanel() {
  const { user, isAuthenticated, isLoadingAuth, logout, checkUserAuth } = useAuth();
  const navigate = useNavigate();
  const [profiles, setProfiles] = useState(null);
  const [busy, setBusy] = useState(false);
  const [avatar, setAvatar] = useState(null);
  const fileRef = useRef(null);

  const refresh = useCallback(() => {
    base44.entities.OsProfile.list("-updated_date", 50)
      .then((d) => setProfiles(d))
      .catch(() => setProfiles([]));
  }, []);

  useEffect(() => {
    refresh();
    const unsub = base44.entities.OsProfile.subscribe(() => refresh());
    return () => unsub();
  }, [refresh]);

  useEffect(() => { if (user?.image) setAvatar(user.image); }, [user?.image]);

  const initials = (user?.full_name || user?.email || "?")
    .split(/[\s@.]+/).filter(Boolean).slice(0, 2).map((w) => w[0].toUpperCase()).join("") || "?";

  const onAvatarPick = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setBusy(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
      await base44.auth.updateMe({ image: file_url });
      setAvatar(file_url);
      checkUserAuth?.(); // refresh the avatar in the Home top bar too
    } catch {}
    setBusy(false);
  };

  const [designation, setDesignation] = useState("");
  const [savingTitle, setSavingTitle] = useState(false);
  const { toast } = useToast();

  useEffect(() => { setDesignation(user?.designation || ""); }, [user?.designation]);

  const saveDesignation = async () => {
    const val = designation.trim();
    if (val === (user?.designation || "")) return;
    setSavingTitle(true);
    try { await base44.auth.updateMe({ designation: val }); } finally { setSavingTitle(false); }
  };

  // share the app - the App Store / Google Play link lands here once published
  const shareApp = async () => {
    const storeUrl = null;
    const text = storeUrl
      ? `Get PropSync: ${storeUrl}`
      : "PropSync - coming soon to the App Store and Google Play";
    try {
      if (navigator.share) { await navigator.share({ title: "PropSync", text, ...(storeUrl ? { url: storeUrl } : {}) }); return; }
      await navigator.clipboard.writeText(text);
      toast({ description: "Copied - store links coming soon" });
    } catch {}
  };

  const loadProfile = (p) => {
    try {
      applyOsConfig(JSON.parse(p.config));
      navigate("/os");
    } catch {}
  };

  const removeProfile = async (p) => {
    await base44.entities.OsProfile.delete(p.id);
    refresh();
  };

  if (isLoadingAuth) {
    return (
      <div className="rounded-2xl border border-border bg-surface p-5 flex justify-center text-muted-foreground">
        <Loader2 className="animate-spin" size={18} />
      </div>
    );
  }

  if (!isAuthenticated || !user) {
    return (
      <div className="rounded-2xl border border-border bg-surface p-5 flex items-center gap-3">
        <div className="h-11 w-11 rounded-full bg-muted/50 border border-border flex items-center justify-center">
          <UserRound size={20} className="text-muted-foreground" />
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-sm font-body font-semibold">Not signed in</div>
          <div className="text-[11px] text-muted-foreground font-body">Sign in so your phone layouts travel with you between devices</div>
        </div>
        <button onClick={() => navigate("/login")}
          className="rounded-lg bg-amber text-black px-4 py-2 text-xs font-body font-semibold">
          Sign in
        </button>
      </div>
    );
  }

  return (
    <div className="rounded-2xl border border-border bg-surface p-5 flex flex-col gap-4">
      <div className="flex items-center gap-3">
        <button onClick={() => fileRef.current?.click()} title="Change profile picture"
          className="relative h-12 w-12 rounded-full overflow-hidden border border-amber/40 bg-amber/15 flex items-center justify-center shrink-0">
          {avatar
            ? <Image src={avatar} alt="" className="h-full w-full" fittingType="fill" />
            : <span className="font-display font-bold text-sm text-amber">{initials}</span>}
          <span className="absolute bottom-0 right-0 h-5 w-5 rounded-full bg-background border border-border flex items-center justify-center">
            <Camera size={10} className="text-muted-foreground" />
          </span>
          <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={onAvatarPick} />
        </button>
        <div className="flex-1 min-w-0">
          <div className="text-sm font-body font-semibold truncate">{user.full_name || "Company user"}</div>
          <div className="text-[11px] text-muted-foreground font-body truncate">{user.email}</div>
        </div>
        <button onClick={() => logout()} title="Sign out"
          className="h-9 w-9 rounded-lg border border-border flex items-center justify-center text-muted-foreground hover:text-foreground">
          <LogOut size={14} />
        </button>
      </div>

      <div className="flex flex-col gap-2">
        <div>
          <div className="text-[10px] uppercase tracking-wider text-muted-foreground font-body mb-1.5">Designation / Title</div>
          <div className="flex items-center gap-2">
            <input value={designation} onChange={(e) => setDesignation(e.target.value)} onBlur={saveDesignation}
              placeholder="e.g. Prop Master"
              className="flex-1 rounded-lg border border-border bg-muted/30 px-3 py-2 text-xs font-body outline-none focus:border-amber/50" />
            {savingTitle && <Loader2 size={14} className="animate-spin text-muted-foreground shrink-0" />}
          </div>
        </div>
        <div className="grid grid-cols-2 gap-2">
          <button onClick={() => navigate("/forgot-password")}
            className="flex items-center justify-center gap-2 rounded-lg border border-border py-2.5 text-xs font-body font-semibold text-muted-foreground hover:text-foreground transition">
            <KeyRound size={14} /> Reset password
          </button>
          <button onClick={shareApp}
            className="flex items-center justify-center gap-2 rounded-lg border border-signal/40 bg-signal/10 py-2.5 text-xs font-body font-semibold text-signal hover:bg-signal/20 transition">
            <Share2 size={14} /> Share App
          </button>
        </div>
      </div>

      <div>
        {profiles === null ? (
          <div className="py-4 flex justify-center text-muted-foreground"><Loader2 className="animate-spin" size={16} /></div>
        ) : profiles.length === 0 ? null : (
          <ul className="flex flex-col gap-1.5">
            {profiles.map((p) => (
              <li key={p.id} className="group flex items-center gap-3 rounded-lg border border-border bg-muted/30 px-3 py-2">
                <div className="flex-1 min-w-0">
                  <div className="text-sm font-body truncate">{p.name}</div>
                  <div className="text-[10px] text-muted-foreground font-body">
                    {new Date(p.updated_date || p.created_date).toLocaleDateString([], { month: "short", day: "numeric" })}
                  </div>
                </div>
                <button onClick={() => loadProfile(p)} title="Load onto this device"
                  className="flex items-center gap-1 rounded-lg border border-signal/40 bg-signal/10 px-2.5 py-1.5 text-[10px] font-body text-signal hover:bg-signal/20 transition">
                  <Download size={12} /> Load
                </button>
                <button onClick={() => removeProfile(p)} className="text-muted-foreground hover:text-alert transition opacity-60 group-hover:opacity-100">
                  <Trash2 size={14} />
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}