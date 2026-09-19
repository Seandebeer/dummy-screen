const OS_KEY = "takeover-os-config";

// current OS configuration of THIS screen
export const readCurrentOsConfig = () => {
  try {
    return JSON.parse(localStorage.getItem(OS_KEY)) || null;
  } catch {
    return null;
  }
};

// strip heavy generated data - default contacts regenerate on load,
// so a profile only carries the owner's real customisations
export const slimConfig = (config) => ({
  ...config,
  contacts: (config.contacts || []).filter((c) => c.custom),
});

// apply a saved profile to this screen; removing the contacts version markers
// makes the OS regenerate localized defaults and merge the custom ones back in
export const applyOsConfig = (config) => {
  const { contactsVer, contactsLang, ...rest } = config || {};
  try {
    localStorage.setItem(OS_KEY, JSON.stringify(rest));
    return true;
  } catch {
    return false;
  }
};