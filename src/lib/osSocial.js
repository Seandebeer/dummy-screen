// Default content for the four mock social platforms. Everything is editable
// in-app (profile fields, post text / counts / photos) via each app's edit
// mode, and it all persists with the OS config under `socials`.

const u = (id) => `https://images.unsplash.com/${id}?auto=format&fit=crop&w=800&q=80`;

// stock photo pool - posts cycle through these when swapped in edit mode
export const STOCK_PHOTOS = [
  "photo-1506744038136-46273834b3fb",
  "photo-1501594907352-04cda38ebc29",
  "photo-1519681393784-d120267933ba",
  "photo-1470071459604-3b5ec3a7fe05",
  "photo-1441974231531-c6227db76b6e",
  "photo-1469474968028-5162334e2825",
  "photo-1493246507139-91e8fad4d8d6",
  "photo-1472214103451-9374bd1c798e",
  "photo-1518791841217-8f162f1e0700",
  "photo-1517849845537-26462ac246c9",
  "photo-1504674900247-0877499adc3b",
  "photo-1512621776951-a57141f2eefd",
  "photo-1514525253161-7a46d19cd819",
  "photo-1494790108377-be9c29b29330",
  "photo-1500648767791-00dcc994a43e",
  "photo-1544005313-94ddf0286df2",
].map(u);

export const nextStockPhoto = (current) => {
  const i = current ? STOCK_PHOTOS.indexOf(current) : -1;
  return STOCK_PHOTOS[(i + 1) % STOCK_PHOTOS.length];
};

export const makeDefaultSocials = () => ({
  facepage: {
    name: "Grapevine",
    profile: {
      name: "Alex Carter",
      bio: "Coffee, cameras and long drives. Opinions are my own.",
      friends: 1204,
    },
    posts: [
      { id: "fp-1", author: "Maya Kim", hue: "#E76F51", time: "2h", text: "Golden hour at the coast never misses. Same spot, different light, every single time.", image: STOCK_PHOTOS[1], likes: 214, comments: 18, shares: 4, liked: false },
      { id: "fp-2", author: "Daniel Mokoena", hue: "#2A9D8F", time: "5h", text: "Proud dad moment: Lily scored the winning goal today. Still shaking.", image: "", likes: 89, comments: 12, shares: 1, liked: false },
      { id: "fp-3", author: "Sara Lane", hue: "#6A4C93", time: "9h", text: "Last night was unreal. Best show of the tour so far. Ears still ringing.", image: STOCK_PHOTOS[12], likes: 342, comments: 46, shares: 9, liked: false },
      { id: "fp-4", author: "Tomas Rivera", hue: "#0077B6", time: "1d", text: "Sunday morning breakfast experiment. 10/10 would flip again.", image: STOCK_PHOTOS[10], likes: 57, comments: 6, shares: 0, liked: false },
      { id: "fp-5", author: "Maya Kim", hue: "#E76F51", time: "2d", text: "Fog season is officially open. First light up on the ridge.", image: STOCK_PHOTOS[3], likes: 176, comments: 21, shares: 3, liked: false },
    ],
  },
  photogram: {
    name: "Lume",
    profile: {
      name: "Alex Carter",
      handle: "alex.carter",
      bio: "Filmmaker & coffee enthusiast\nCape Town / wherever the light is",
      followers: 8432,
      following: 312,
    },
    posts: [
      { id: "ig-1", author: "alex.carter", hue: "#833AB4", caption: "chasing light", image: STOCK_PHOTOS[0], likes: 1204, comments: 42, liked: false, saved: false },
      { id: "ig-2", author: "maya.k", hue: "#E76F51", caption: "my new assistant, clearly working hard", image: STOCK_PHOTOS[8], likes: 894, comments: 31, liked: false, saved: false },
      { id: "ig-3", author: "sara.lane", hue: "#6A4C93", caption: "crowd went wild last night", image: STOCK_PHOTOS[12], likes: 2018, comments: 154, liked: false, saved: false },
      { id: "ig-4", author: "tom.r", hue: "#0077B6", caption: "eat the rainbow", image: STOCK_PHOTOS[11], likes: 245, comments: 12, liked: false, saved: false },
      { id: "ig-5", author: "alex.carter", hue: "#833AB4", caption: "fog season is the best season", image: STOCK_PHOTOS[3], likes: 1764, comments: 66, liked: false, saved: false },
      { id: "ig-6", author: "dan.m", hue: "#2A9D8F", caption: "good boy alert", image: STOCK_PHOTOS[9], likes: 3421, comments: 209, liked: false, saved: false },
      { id: "ig-7", author: "maya.k", hue: "#E76F51", caption: "got lost, found this", image: STOCK_PHOTOS[4], likes: 967, comments: 38, liked: false, saved: false },
      { id: "ig-8", author: "alex.carter", hue: "#833AB4", caption: "midnight mission", image: STOCK_PHOTOS[2], likes: 1102, comments: 54, liked: false, saved: false },
    ],
  },
  vidtube: {
    name: "Streamly",
    profile: {
      name: "Alex Carter",
      handle: "@alexcarter",
      subscribers: 12400,
    },
    subs: {},
    chSubs: {},
    videos: [
      { id: "yt-1", title: "I Built a Camera Lens From Scratch", channel: "GearLab", chHue: "#E63946", views: 1200000, age: "2 days ago", duration: "14:32", image: STOCK_PHOTOS[4], cat: "Tech" },
      { id: "yt-2", title: "Sailing the Bay - 4K Drone Film", channel: "SkyFrame", chHue: "#457B9D", views: 486000, age: "1 week ago", duration: "10:05", image: STOCK_PHOTOS[1], cat: "Travel" },
      { id: "yt-3", title: "24 Hours in the World's Quietest Cabin", channel: "Wild Stay", chHue: "#2A9D8F", views: 2100000, age: "3 weeks ago", duration: "22:18", image: STOCK_PHOTOS[6], cat: "Travel" },
      { id: "yt-4", title: "The Ultimate Sunday Brunch Guide", channel: "Fresh Kitchen", chHue: "#E76F51", views: 312000, age: "5 days ago", duration: "8:44", image: STOCK_PHOTOS[10], cat: "Cooking" },
      { id: "yt-5", title: "She Scored the Winning Goal - Full Highlights", channel: "SportsLoop", chHue: "#D62828", views: 987000, age: "1 month ago", duration: "6:12", image: STOCK_PHOTOS[7], cat: "Sports" },
      { id: "yt-6", title: "Mixing a Track in My Bedroom Studio", channel: "BeatRoom", chHue: "#6A4C93", views: 154000, age: "2 weeks ago", duration: "18:26", image: STOCK_PHOTOS[12], cat: "Music" },
      { id: "yt-7", title: "Why Old Cameras Still Beat New Ones", channel: "Pixel Past", chHue: "#0077B6", views: 745000, age: "3 days ago", duration: "12:58", image: STOCK_PHOTOS[3], cat: "Tech" },
      { id: "yt-8", title: "BTS: Filming with Practical Lights", channel: "Alex Carter", chHue: "#1877F2", views: 48200, age: "6 days ago", duration: "9:41", image: STOCK_PHOTOS[14], cat: "Film" },
      { id: "yt-9", title: "My Gear for One-Take Shots", channel: "Alex Carter", chHue: "#1877F2", views: 12900, age: "2 weeks ago", duration: "7:03", image: STOCK_PHOTOS[0], cat: "Film" },
    ],
  },
  quicktok: {
    name: "Flickdeck",
    profile: {
      name: "Alex Carter",
      handle: "alex.carter",
      followers: 2431,
      likes: 89500,
    },
    tabs: { following: "Following", foryou: "For You" },
    following: ["dan.m", "sara.lane"],
    posts: [
      { id: "tt-1", author: "maya.k", caption: "POV: your coffee order is right 10% of the time", image: STOCK_PHOTOS[11], likes: 45200, comments: 1240, shares: 890, liked: false, music: "Original sound - maya.k" },
      { id: "tt-2", author: "dan.m", caption: "teaching my dog to high-five... progress", image: STOCK_PHOTOS[9], likes: 128400, comments: 3200, shares: 2100, liked: false, music: "Happy little tune - lofi.beats" },
      { id: "tt-3", author: "sara.lane", caption: "concert fit check", image: STOCK_PHOTOS[12], likes: 89100, comments: 2100, shares: 1450, liked: false, music: "Original sound - sara.lane" },
      { id: "tt-4", author: "tom.r", caption: "sunset drives, no destination", image: STOCK_PHOTOS[1], likes: 210700, comments: 4600, shares: 3900, liked: false, music: "Golden hour - midnight.driver" },
    ],
  },
});

// get one platform's slice of config data plus a setter, for use inside an app
export const socialSlice = (config, update, key) => {
  const defaults = makeDefaultSocials();
  const current = { ...defaults[key], ...((config.socials || {})[key] || {}) };
  const setData = (patch) => update((c) => {
    const socials = c.socials || makeDefaultSocials();
    const base = socials[key] || defaults[key];
    return { socials: { ...socials, [key]: { ...base, ...(typeof patch === "function" ? patch(base) : patch) } } };
  });
  return { data: current, setData };
};