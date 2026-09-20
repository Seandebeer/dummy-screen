import React from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";

const TOPICS = [
  { title: "Projects & Devices", body: "Organise prop hardware per production. Pick a project to see and manage its devices, saved screens and layouts." },
  { title: "Mock OS", body: "Design the prop phone's home screen, contacts, wallpaper and lock behaviour - then save it to a device or your favourites." },
  { title: "VFX Stage", body: "Full-screen chroma screens and tracking markers for shooting. Tap a marker setup to load it on stage." },
  { title: "Control", body: "Trigger calls, alarms and messages on a linked prop screen from the control deck." },
];

export default function HelpDialog({ open, onOpenChange }) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle className="font-display font-bold">Help</DialogTitle>
          <DialogDescription>Quick guide to using PropSync</DialogDescription>
        </DialogHeader>
        <div className="flex flex-col gap-3">
          {TOPICS.map((t) => (
            <div key={t.title} className="rounded-xl border border-border bg-surface p-3">
              <div className="text-sm font-body font-semibold">{t.title}</div>
              <div className="mt-1 text-xs text-muted-foreground font-body leading-relaxed">{t.body}</div>
            </div>
          ))}
        </div>
      </DialogContent>
    </Dialog>
  );
}