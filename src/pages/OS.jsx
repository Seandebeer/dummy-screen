import React, { useState, useEffect, useCallback, useRef } from "react";
import { Link } from "react-router-dom";
import { ArrowLeft, Radio } from "lucide-react";
import PhoneFrame from "@/components/os/PhoneFrame";
import Homescreen from "@/components/os/Homescreen";
import PhoneApp from "@/components/os/apps/PhoneApp";
import ContactsApp from "@/components/os/apps/ContactsApp";
import MessagesApp from "@/components/os/apps/MessagesApp";
import EmailApp from "@/components/os/apps/EmailApp";
import ClockApp from "@/components/os/apps/ClockApp";
import CallOverlay from "@/components/os/CallOverlay";
import MockApp from "@/components/os/apps/MockApp";
import { allAppsById } from "@/lib/osApps";
import { base44 } from "@/api/base44Client";

export default function OS() {
  const [app, setApp] = useState(null);
  const [call, setCall] = useState(null);
  const [recents, setRecents] = useState([]);
  const callRef = useRef(null);
  const fmtTime = (d) => new Date(d).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });

  const addRecent = (cur) => setRecents((r) => [{
    label: cur.contact?.name || cur.contact?.number || "Unknown",
    number: cur.contact?.number || "",
    type: cur.phase === "incoming" ? "Incoming" : "Outgoing",
    time: fmtTime(Date.now()),
  }, ...r].slice(0, 30));

  // load + subscribe to commands (control-driven calls)
  useEffect(() => {
    let mounted = true;
    base44.entities.Command.filter({ channel: "stage-1" }, "-created_date", 50)
      .then((data) => {
        if (!mounted) return;
        const past = data.filter((c) => c.status === "completed").map((c) => ({
          label: c.contact_name || c.contact_number || "Unknown",
          number: c.contact_number || "",
          type: c.type === "call_incoming" ? "Incoming" : "Outgoing",
          time: fmtTime(c.created_date),
        }));
        setRecents(past);
      }).catch(() => {});

    const unsub = base44.entities.Command.subscribe((event) => {
      const c = event.data;
      if (!c || c.channel !== "stage-1") return;
      if (event.type === "create") {
        if (c.type === "call_incoming") {
          setCall({ phase: "incoming", contact: { name: c.contact_name, number: c.contact_number }, commandId: c.id });
        } else if (c.type === "call_outgoing") {
          setCall({ phase: "outgoing", contact: { name: c.contact_name, number: c.contact_number }, commandId: c.id, startTime: Date.now() });
          setTimeout(() => setCall((cur) => cur && cur.commandId === c.id ? { ...cur, phase: "active", startTime: Date.now() } : cur), 2200);
        }
      } else if (event.type === "update") {
        // control deck ended the call remotely
        if (c.status === "completed" && callRef.current && c.id === callRef.current.commandId) {
          addRecent(callRef.current);
          setCall(null);
        }
      }
    });
    return () => { mounted = false; unsub(); };
  }, []);

  // keep ref in sync with current call
  useEffect(() => { callRef.current = call; }, [call]);

  const endCall = useCallback(() => {
    setCall((cur) => {
      if (cur) {
        addRecent(cur);
        if (cur.commandId) {
          base44.entities.Command.update(cur.commandId, { status: "completed" }).catch(() => {});
        }
      }
      return null;
    });
  }, []);

  const acceptCall = useCallback(() => {
    setCall((cur) => {
      if (cur?.commandId) base44.entities.Command.update(cur.commandId, { status: "active" }).catch(() => {});
      return { ...cur, phase: "active", startTime: Date.now() };
    });
  }, []);

  const startLocalCall = (contact) => {
    setCall({ phase: "active", contact, startTime: Date.now(), commandId: null });
  };

  const renderApp = () => {
    switch (app) {
      case "phone": return <PhoneApp onCall={startLocalCall} recents={recents} />;
      case "contacts": return <ContactsApp onCall={startLocalCall} />;
      case "messages": return <MessagesApp />;
      case "email": return <EmailApp />;
      case "clock": return <ClockApp />;
      case null: return <Homescreen onOpen={setApp} />;
      default: return <MockApp app={allAppsById[app]} />;
    }
  };

  return (
    <div className="min-h-dvh bg-background grid-backdrop flex flex-col">
      <header className="flex items-center justify-between px-6 py-4 border-b border-border">
        <Link to="/" className="flex items-center gap-2 text-muted-foreground hover:text-foreground text-sm font-body">
          <ArrowLeft size={18} /> Deck
        </Link>
        <div className="font-display font-bold text-lg tracking-wide">OS SIMULATOR</div>
        <div className="flex items-center gap-2 text-xs font-body text-signal">
          <span className="h-2 w-2 rounded-full bg-signal led-pulse" /> SYNC LIVE
        </div>
      </header>
      <div className="flex-1 flex items-center justify-center p-6">
        <PhoneFrame onHome={() => setApp(null)}>
          {renderApp()}
          <CallOverlay call={call} onAccept={acceptCall} onEnd={endCall} />
        </PhoneFrame>
      </div>
      <footer className="px-6 py-3 text-center text-[11px] text-muted-foreground font-body border-t border-border">
        Mock device · channel stage-1 · control deck can drive calls & messages
      </footer>
    </div>
  );
}