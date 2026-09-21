import { useEffect } from "react";
import { enterTakeover } from "@/lib/screenTakeover";

// the app owns the entire screen from the moment it opens. Browsers only
// allow fullscreen once the user has interacted, so we take it immediately
// where permitted and at the very first tap anywhere otherwise.
export default function InstantTakeover() {
  useEffect(() => {
    const grab = () => {
      enterTakeover();
      window.removeEventListener("pointerdown", grab);
      window.removeEventListener("keydown", grab);
    };
    enterTakeover();
    window.addEventListener("pointerdown", grab);
    window.addEventListener("keydown", grab);
    return () => {
      window.removeEventListener("pointerdown", grab);
      window.removeEventListener("keydown", grab);
    };
  }, []);

  return null;
}