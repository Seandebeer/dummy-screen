import React, { useState } from "react";
import { Send } from "lucide-react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { useToast } from "@/components/ui/use-toast";

export default function BugReportDialog({ open, onOpenChange }) {
  const [text, setText] = useState("");
  const { toast } = useToast();

  const submit = async () => {
    const report =
      `Dummy Screen bug report - ${new Date().toLocaleString()}\n` +
      `Device: ${navigator.userAgent}\n\n` +
      `What happened:\n${text.trim()}`;
    try { await navigator.clipboard.writeText(report); } catch {}
    onOpenChange(false);
    setText("");
    toast({ description: "Report copied - paste it into a message to the team" });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle className="font-display font-bold">Report a bug</DialogTitle>
          <DialogDescription>Tell us what went wrong and where it happened</DialogDescription>
        </DialogHeader>
        <textarea value={text} onChange={(e) => setText(e.target.value)} rows={4} autoFocus
          placeholder="e.g. The saved layout didn't appear on the device…"
          className="w-full resize-none rounded-lg border border-border bg-muted/30 px-3 py-2 text-sm font-body outline-none focus:border-amber/50" />
        <DialogFooter>
          <button onClick={submit} disabled={!text.trim()}
            className="flex items-center gap-2 rounded-lg bg-amber px-4 py-2 text-xs font-body font-semibold text-black transition disabled:opacity-40">
            <Send size={13} /> Copy report
          </button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}