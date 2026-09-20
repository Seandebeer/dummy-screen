import { STOCK_PHOTOS } from "./osSocial";

// Frames - a 16:9-only video sharing app. Two feeds (Shorts, Discover) with
// the same shape, plus watch parties and a channel page. Everything lives
// under `frames` in the OS config and is editable in-app.
const vid = (id, title, channel, chHue, views, likes, comments, shares, age, duration, poster) =>
  ({ id, title, channel, chHue, views, likes, comments, shares, age, duration, poster, video: "", liked: false });

export const makeDefaultFrames = () => ({
  name: "Frames",
  profile: { name: "Alex Carter", handle: "@alexcarter", subscribers: 8340 },
  shorts: [
    vid("fr-s1", "POV: the drone battery dies at golden hour", "Maya Kim", "#E76F51", 184200, 12400, 312, 890, "2h", "0:21", STOCK_PHOTOS[1]),
    vid("fr-s2", "3-second breakfast hack", "Priya Nair", "#F4A261", 96300, 6100, 148, 402, "4h", "0:15", STOCK_PHOTOS[10]),
    vid("fr-s3", "sound check gone right", "Sara Lane", "#6A4C93", 42800, 2900, 76, 190, "5h", "0:32", STOCK_PHOTOS[12]),
    vid("fr-s4", "the goal celebration, slow-mo", "Daniel Mokoena", "#2A9D8F", 67100, 4300, 121, 350, "6h", "0:18", STOCK_PHOTOS[7]),
    vid("fr-s5", "van tour but it's raining", "Owen Frost", "#264653", 53900, 3600, 89, 240, "8h", "0:44", STOCK_PHOTOS[4]),
    vid("fr-s6", "market haul under R200", "Tomas Rivera", "#0077B6", 78600, 5200, 164, 410, "9h", "0:26", STOCK_PHOTOS[11]),
    vid("fr-s7", "lens test: vintage vs modern", "Alex Carter", "#E56E42", 21400, 1580, 43, 96, "11h", "0:38", STOCK_PHOTOS[14]),
    vid("fr-s8", "my dog's first swim", "Daniel Mokoena", "#2A9D8F", 302400, 21400, 587, 1620, "13h", "0:29", STOCK_PHOTOS[9]),
    vid("fr-s9", "fog rolling over the ridge", "Maya Kim", "#E76F51", 88100, 5900, 132, 380, "16h", "0:23", STOCK_PHOTOS[3]),
    vid("fr-s10", "one-take guitar loop", "Sara Lane", "#6A4C93", 37600, 2450, 64, 170, "18h", "0:41", STOCK_PHOTOS[2]),
    vid("fr-s11", "sunset run, no music", "Priya Nair", "#F4A261", 45200, 3100, 87, 220, "21h", "0:19", STOCK_PHOTOS[7]),
    vid("fr-s12", "street food first bite", "Tomas Rivera", "#0077B6", 128900, 8700, 233, 640, "1d", "0:16", STOCK_PHOTOS[5]),
    vid("fr-s13", "camp stove coffee ritual", "Owen Frost", "#264653", 61800, 4200, 98, 260, "1d", "0:34", STOCK_PHOTOS[6]),
    vid("fr-s14", "thrift flip: R40 jacket", "Maya Kim", "#E76F51", 93700, 6400, 176, 490, "1d", "0:47", STOCK_PHOTOS[13]),
    vid("fr-s15", "clipping in for the first time", "Priya Nair", "#F4A261", 26900, 1700, 52, 84, "2d", "0:22", STOCK_PHOTOS[6]),
    vid("fr-s16", "BTS: practical lights only", "Alex Carter", "#E56E42", 18300, 1210, 38, 71, "2d", "0:52", STOCK_PHOTOS[0]),
    vid("fr-s17", "kickflip, take 84", "Daniel Mokoena", "#2A9D8F", 74200, 5000, 143, 395, "3d", "0:13", STOCK_PHOTOS[8]),
    vid("fr-s18", "bookstore hideaway", "Sara Lane", "#6A4C93", 33400, 2200, 61, 130, "3d", "0:27", STOCK_PHOTOS[15]),
    vid("fr-s19", "the wave that ended the shoot", "Owen Frost", "#264653", 109600, 7300, 201, 580, "4d", "0:36", STOCK_PHOTOS[1]),
    vid("fr-s20", "my desk setup, spring refresh", "Alex Carter", "#E56E42", 15700, 980, 29, 58, "5d", "0:31", STOCK_PHOTOS[10]),
  ],
  discover: [
    vid("fr-d1", "How I Shot a Short Film in 48 Hours", "Alex Carter", "#E56E42", 22800, 1540, 42, 88, "3 days ago", "12:34", STOCK_PHOTOS[14]),
    vid("fr-d2", "The Complete Beginner's Guide to Film Lighting", "GearLab", "#E63946", 1200000, 48200, 1240, 3600, "2 days ago", "18:22", STOCK_PHOTOS[4]),
    vid("fr-d3", "Cooking Pasta From Scratch, Start to Finish", "Fresh Kitchen", "#E76F51", 1100000, 39800, 980, 2400, "1 month ago", "19:47", STOCK_PHOTOS[5]),
    vid("fr-d4", "We Hiked 40km in One Day (Big Mistake)", "Wild Stay", "#2A9D8F", 634000, 22100, 640, 1900, "1 week ago", "16:49", STOCK_PHOTOS[3]),
    vid("fr-d5", "Every Lens I Own, Ranked", "Pixel Past", "#0077B6", 412000, 15600, 480, 1100, "2 weeks ago", "25:03", STOCK_PHOTOS[9]),
    vid("fr-d6", "Live Looping With Just One Guitar", "BeatRoom", "#6A4C93", 891000, 31400, 870, 2300, "3 days ago", "13:40", STOCK_PHOTOS[2]),
    vid("fr-d7", "The Science of Perfect Coffee", "Lab Notes", "#457B9D", 1780000, 62300, 2100, 5400, "2 months ago", "15:56", STOCK_PHOTOS[8]),
    vid("fr-d8", "Restoring a 40-Year-Old Motorbike", "WrenchWorks", "#F4A261", 736000, 28900, 760, 2100, "1 month ago", "28:12", STOCK_PHOTOS[13]),
    vid("fr-d9", "Sailing the Bay - 4K Drone Film", "SkyFrame", "#457B9D", 486000, 19400, 520, 1500, "1 week ago", "10:05", STOCK_PHOTOS[1]),
    vid("fr-d10", "Beginner Bouldering: First Month Progress", "ClimbOn", "#2A9D8F", 94500, 3800, 120, 340, "5 days ago", "9:18", STOCK_PHOTOS[6]),
    vid("fr-d11", "Why Old Cameras Still Beat New Ones", "Pixel Past", "#0077B6", 745000, 26700, 830, 1900, "3 days ago", "12:58", STOCK_PHOTOS[3]),
    vid("fr-d12", "Marathon Training, Week 6 Update", "RunPace", "#D62828", 143000, 5900, 170, 480, "1 week ago", "8:52", STOCK_PHOTOS[7]),
    vid("fr-d13", "Editing a Doc in One Sitting", "Alex Carter", "#E56E42", 17600, 1120, 34, 62, "4 days ago", "14:07", STOCK_PHOTOS[0]),
    vid("fr-d14", "The Ultimate Sunday Brunch Guide", "Fresh Kitchen", "#E76F51", 312000, 12700, 390, 1100, "5 days ago", "8:44", STOCK_PHOTOS[10]),
    vid("fr-d15", "24 Hours in the World's Quietest Cabin", "Wild Stay", "#2A9D8F", 2100000, 78900, 2600, 7200, "3 weeks ago", "22:18", STOCK_PHOTOS[6]),
    vid("fr-d16", "Mixing a Track in My Bedroom Studio", "BeatRoom", "#6A4C93", 154000, 6800, 190, 520, "2 weeks ago", "18:26", STOCK_PHOTOS[12]),
    vid("fr-d17", "Street Photography at Night, No Tripod", "SkyFrame", "#457B9D", 367000, 13900, 410, 1200, "2 weeks ago", "10:21", STOCK_PHOTOS[11]),
    vid("fr-d18", "She Scored the Winning Goal - Full Highlights", "SportsLoop", "#D62828", 987000, 34200, 940, 2700, "1 month ago", "6:12", STOCK_PHOTOS[7]),
    vid("fr-d19", "Colour Grading: Before and After", "GearLab", "#E63946", 254000, 9700, 280, 760, "6 days ago", "11:38", STOCK_PHOTOS[15]),
    vid("fr-d20", "Sound Design With Everyday Objects", "Alex Carter", "#E56E42", 48200, 3100, 96, 140, "6 days ago", "9:41", STOCK_PHOTOS[2]),
  ],
  parties: [
    { id: "fr-p1", title: "Friday night double feature", host: "Alex Carter", hostHue: "#E56E42", viewers: 6, poster: STOCK_PHOTOS[12], video: "", seats: ["Maya Kim", "Owen Frost", "Priya Nair", "Tomas Rivera"] },
    { id: "fr-p2", title: "Doc marathon: episode 4", host: "Maya Kim", hostHue: "#E76F51", viewers: 4, poster: STOCK_PHOTOS[2], video: "", seats: ["Sara Lane", "Daniel Mokoena", "Owen Frost"] },
    { id: "fr-p3", title: "Champions final rewatch", host: "Daniel Mokoena", hostHue: "#2A9D8F", viewers: 9, poster: STOCK_PHOTOS[7], video: "", seats: ["Tomas Rivera", "Priya Nair", "Maya Kim", "Owen Frost"] },
    { id: "fr-p4", title: "Studio night: animation classics", host: "Priya Nair", hostHue: "#F4A261", viewers: 12, poster: STOCK_PHOTOS[6], video: "", seats: ["Sara Lane", "Maya Kim", "Daniel Mokoena", "Owen Frost", "Tomas Rivera"] },
    { id: "fr-p5", title: "Bad movie roast night", host: "Sara Lane", hostHue: "#6A4C93", viewers: 7, poster: STOCK_PHOTOS[13], video: "", seats: ["Maya Kim", "Owen Frost", "Daniel Mokoena"] },
  ],
});

// saved feeds keep their edits, but always show at least 20 videos -
// missing defaults are appended below whatever has been customised
const topUp = (feed, def) => {
  if (!Array.isArray(feed) || feed.length >= 20) return feed;
  const ids = new Set(feed.map((p) => p.id));
  return [...feed, ...def.filter((p) => !ids.has(p.id))].slice(0, 20);
};

// one slice of the OS config for the Frames app, plus a setter
export const framesSlice = (config, update) => {
  const defaults = makeDefaultFrames();
  const mergeBase = (base) => {
    const merged = { ...defaults, ...(base || {}) };
    merged.shorts = topUp(merged.shorts, defaults.shorts);
    merged.discover = topUp(merged.discover, defaults.discover);
    merged.parties = Array.isArray(merged.parties) ? merged.parties : defaults.parties;
    return merged;
  };
  const current = mergeBase(config.frames);
  const setData = (patch) => update((c) => {
    const base = mergeBase(c.frames);
    return { frames: { ...base, ...(typeof patch === "function" ? patch(base) : patch) } };
  });
  return { data: current, setData };
};