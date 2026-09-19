import React from "react";
import AppLibrary from "@/components/os/AppLibrary";

// the App Library lives as a real home-screen app now - the eye toggle
// adds / removes apps from the home screen just like before
export default function AppStoreApp({ config, update }) {
  const toggleApp = (id) => {
    update((c) => {
      if (c.order.includes(id)) {
        return { order: c.order.filter((x) => x !== id), dock: (c.dock || []).filter((x) => x !== id) };
      }
      return { order: [...c.order, id] };
    });
  };

  return <AppLibrary order={config.order} onToggle={toggleApp} />;
}