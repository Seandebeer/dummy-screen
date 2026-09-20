import React, { useState } from "react";
import { Loader2, Send } from "lucide-react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { useToast } from "@/components/ui/use-toast";
import { base44 } from "@/api/base44Client";

// Support - send a message straight to the dev team
export default function SupportDialog({ open, onOpenChange }) {
  const [subject, setSubject] = useState("");
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);
  const { toast } = useToast();

  const submit = async () => {
    if (busy) return;
    setBusy(true);
    try {
      const res = await base44.functions.invoke("sendSupportMessage", {
        subject: subject.trim(),
        message: message.trim(),
      });
      if (res?.data?.ok) {
        onOpenChange(false);
        setSubject("");
        setMessage("");
        toast({ description: "Message sent to the dev team" });
      } else {
        toast({ description: res?.data?.error || "Could not send - please try again" });
      }
    } catch {
      toast({ description: "Could not send - please try again" });
    }
    setBusy(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle className="font-display font-bold">Support</DialogTitle>
          <DialogDescription>Send a message to the dev team</DialogDescription>
        </DialogHeader>
        <div className="flex flex-col gap-2.5">
          <input value={subject} onChange={(e) => setSubject(e.target.value)} placeholder="Subject (optional)"
            className="w-full rounded-lg border border-border bg-muted/30 px-3 py-2 text-sm font-body outline-none focus:border-amber/50" />
          <textarea value={message} onChange={(e) => setMessage(e.target.value)} rows={5} autoFocus
            placeholder="What do you need help with?"
            className="w-full resize-none rounded-lg border border-border bg-muted/30 px-3 py-2 text-sm font-body outline-none focus:border-amber/50" />
        </div>
        <DialogFooter>
          <button onClick={submit} disabled={!message.trim() || busy}
            className="flex items-center gap-2 rounded-lg bg-amber px-4 py-2 text-xs font-body font-semibold text-black transition disabled:opacity-40">
            {busy ? <Loader2 size={13} className="animate-spin" /> : <Send size={13} />} Send
          </button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}