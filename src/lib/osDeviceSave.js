import { base44 } from "@/api/base44Client";
import { enqueueDeviceCreate, enqueueDeviceUpdate } from "@/lib/cloudSync";
import { markOsPushed } from "@/lib/osLiveSync";

// ways a saved OS layout can land on a device - shared by the OS save sheet
// and the Saved panel's "to device" flow. Offline saves are queued locally
// and sync to the cloud when the screen has signal again.

const offline = () => typeof navigator !== "undefined" && !navigator.onLine;

// apply a config straight onto an existing device record
export async function applyConfigToDevice(deviceId, config) {
  const configJson = JSON.stringify(config);
  markOsPushed(configJson);
  // offline, or the server can't be reached: keep the save local - the
  // queued update syncs once the screen has signal again
  if (offline()) {
    enqueueDeviceUpdate(deviceId, configJson);
    return { queued: true };
  }
  try {
    await base44.entities.Device.update(deviceId, { config: configJson });
    return { queued: false };
  } catch {
    enqueueDeviceUpdate(deviceId, configJson);
    return { queued: true };
  }
}

// create a new device carrying this config inside an existing project
// (projectName carries a brand-new project's name when saving offline)
export async function createDeviceInProject(projectId, name, config, projectName) {
  const configJson = JSON.stringify(config);
  markOsPushed(configJson);
  if (offline()) {
    enqueueDeviceCreate(projectId || null, projectId ? "" : (projectName || ""), name.trim(), configJson);
    return null;
  }
  try {
    return await base44.entities.Device.create({
      name: name.trim(), kind: "phone", status: "offline",
      project_id: projectId, config: configJson,
    });
  } catch {
    enqueueDeviceCreate(projectId || null, projectId ? "" : (projectName || ""), name.trim(), configJson);
    return null;
  }
}

// create a brand-new project with a device inside it carrying this config
export async function createProjectWithDevice(projectName, deviceName, config) {
  if (!offline()) {
    try {
      const proj = await base44.entities.Project.create({ name: projectName.trim() });
      const device = await createDeviceInProject(proj.id, deviceName, config);
      return { project: proj, device };
    } catch {} // unreachable - queue the whole create below instead
  }
  enqueueDeviceCreate(null, projectName.trim(), deviceName.trim(), JSON.stringify(config));
  return null;
}