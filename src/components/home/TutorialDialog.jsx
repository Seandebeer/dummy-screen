import React from "react";
import { ChevronDown, PlayCircle } from "lucide-react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";

// link a tutorial video here when it's ready - it will play inside this dialog
const TUTORIAL_VIDEO = "";

const STEPS = [
  {
    title: "Create a project",
    body: "Open the Projects panel and create your production. Devices, screens and layouts are all organised per project.",
  },
  {
    title: "Add your devices",
    body: "With a project selected, add the prop hardware you'll be using - phones, tablets and screens, with make, model and colour.",
  },
  {
    title: "Design the mock OS",
    body: "Tap a device to open the OS and build its home screen: apps, wallpaper, clock and lock behaviour. Save it back to the device.",
  },
  {
    title: "Save & reuse setups",
    body: "Save screens and layouts to favourites or straight to a device, then reopen or assign them from the Saved panel.",
  },
  {
    title: "Set up the VFX stage",
    body: "Open the VFX stage for chroma screens and tracking markers. Pick a colour, arrange the markers, then lock - three fingers to unlock.",
  },
  {
    title: "Number UI markers",
    body: "In the mock OS, the UI Markers app lays out a numbered grid - tap buttons in the order the actor should press them.",
  },
  {
    title: "Run it from Control",
    body: "Link the prop screen and trigger calls, alarms and messages live from the control deck during the take.",
  },
];

export default function TutorialDialog({ open, onOpenChange }) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="font-display font-bold">Tutorial</DialogTitle>
          <DialogDescription>A guided walkthrough of PropSync - follow these steps in order</DialogDescription>
        </DialogHeader>

        {TUTORIAL_VIDEO ? (
          <video src={TUTORIAL_VIDEO} controls className="w-full rounded-xl border border-border bg-black" />
        ) : (
          <div className="flex items-center gap-2 rounded-xl border border-dashed border-border bg-surface px-3 py-2 text-xs text-muted-foreground font-body">
            <PlayCircle size={14} /> Video walkthrough coming soon
          </div>
        )}

        <div className="flex flex-col">
          {STEPS.map((s, i) => (
            <React.Fragment key={s.title}>
              <div className="flex gap-3">
                <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full border border-amber/40 bg-amber/15 text-[11px] font-display font-bold text-amber">
                  {i + 1}
                </span>
                <div>
                  <div className="text-sm font-body font-semibold">{s.title}</div>
                  <div className="mt-0.5 text-xs text-muted-foreground font-body leading-relaxed">{s.body}</div>
                </div>
              </div>
              {i < STEPS.length - 1 && (
                <div className="my-0.5 flex justify-start pl-[4px]">
                  <ChevronDown size={16} className="text-muted-foreground/50" />
                </div>
              )}
            </React.Fragment>
          ))}
        </div>
      </DialogContent>
    </Dialog>
  );
}