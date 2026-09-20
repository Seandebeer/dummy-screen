import { base44 } from "@/api/base44Client";
import { getClip } from "@/lib/cameraRoll";

// turn a camera-roll entry into an uploaded public file URL so it can be
// attached to a message that renders on every device
export const uploadRollItem = async (item) => {
  if (!item) return null;
  let file;
  if (item.type === "video") {
    const rec = await getClip(item.id);
    if (!rec?.blob) return null;
    file = new File([rec.blob], `${item.id}.webm`, { type: rec.blob.type || "video/webm" });
  } else {
    const blob = await (await fetch(item.url)).blob();
    file = new File([blob], `${item.id}.jpg`, { type: blob.type || "image/jpeg" });
  }
  const { file_url } = await base44.integrations.Core.UploadPublicFile({ file });
  return file_url;
};