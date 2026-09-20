import { base44 } from "@/api/base44Client";

// ways a saved OS layout can land on a device - shared by the OS save sheet
// and the Saved panel's "to device" flow

// apply a config straight onto an existing device record
export async function applyConfigToDevice(deviceId, config) {
  await base44.entities.Device.update(deviceId, { config: JSON.stringify(config) });
}

// create a new device carrying this config inside an existing project
export async function createDeviceInProject(projectId, name, config) {
  const rec = await base44.entities.Device.create({
    name: name.trim(), kind: "phone", status: "offline",
    project_id: projectId, config: JSON.stringify(config),
  });
  return rec;
}

// create a brand-new project with a device inside it carrying this config
export async function createProjectWithDevice(projectName, deviceName, config) {
  const proj = await base44.entities.Project.create({ name: projectName.trim() });
  const device = await createDeviceInProject(proj.id, deviceName, config);
  return { project: proj, device };
}