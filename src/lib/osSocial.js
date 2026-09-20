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
      { id: "fp-1", author: "Maya Kim", hue: "#E76F51", time: "30m", text: "Golden hour at the coast never misses. Same spot, different light, every single time.", image: STOCK_PHOTOS[1], likes: 214, comments: 18, shares: 4, liked: false },
      { id: "fp-2", author: "Daniel Mokoena", hue: "#2A9D8F", time: "1h", text: "Proud dad moment: Lily scored the winning goal today. Still shaking.", image: "", likes: 89, comments: 12, shares: 1, liked: false },
      { id: "fp-3", author: "Sara Lane", hue: "#6A4C93", time: "2h", text: "Last night was unreal. Best show of the tour so far. Ears still ringing.", image: STOCK_PHOTOS[12], likes: 342, comments: 46, shares: 9, liked: false },
      { id: "fp-4", author: "Tomas Rivera", hue: "#0077B6", time: "3h", text: "Sunday morning breakfast experiment. 10/10 would flip again.", image: STOCK_PHOTOS[10], likes: 57, comments: 6, shares: 0, liked: false },
      { id: "fp-5", author: "Priya Nair", hue: "#F4A261", time: "5h", text: "New recipe drop: chilli-garlic noodles that fixed my whole week.", image: STOCK_PHOTOS[13], likes: 143, comments: 17, shares: 2, liked: false },
      { id: "fp-6", author: "Owen Frost", hue: "#264653", time: "7h", text: "Hiked the ridge before sunrise. Zero people, all clouds.", image: STOCK_PHOTOS[3], likes: 98, comments: 9, shares: 1, liked: false },
      { id: "fp-7", author: "Maya Kim", hue: "#E76F51", time: "9h", text: "Fog season is officially open. First light up on the ridge.", image: STOCK_PHOTOS[6], likes: 176, comments: 21, shares: 3, liked: false },
      { id: "fp-8", author: "Daniel Mokoena", hue: "#2A9D8F", time: "12h", text: "The dog learned to open the back door. We are not okay.", image: STOCK_PHOTOS[9], likes: 421, comments: 58, shares: 12, liked: false },
      { id: "fp-9", author: "Sara Lane", hue: "#6A4C93", time: "1d", text: "Studio day. New track is finally sounding like the demo in my head.", image: "", likes: 132, comments: 15, shares: 2, liked: false },
      { id: "fp-10", author: "Tomas Rivera", hue: "#0077B6", time: "1d", text: "Street food crawl part 3. The queue was 40 minutes and worth every one.", image: STOCK_PHOTOS[11], likes: 187, comments: 23, shares: 5, liked: false },
      { id: "fp-11", author: "Priya Nair", hue: "#F4A261", time: "2d", text: "Book club verdict: everyone hated the ending except me. Chaos.", image: "", likes: 64, comments: 31, shares: 0, liked: false },
      { id: "fp-12", author: "Owen Frost", hue: "#264653", time: "2d", text: "Broke out the film camera for the first time in a year. No regrets.", image: STOCK_PHOTOS[14], likes: 205, comments: 19, shares: 4, liked: false },
      { id: "fp-13", author: "Maya Kim", hue: "#E76F51", time: "3d", text: "Coffee and a view that costs nothing. Best deal in town.", image: STOCK_PHOTOS[8], likes: 158, comments: 12, shares: 1, liked: false },
      { id: "fp-14", author: "Daniel Mokoena", hue: "#2A9D8F", time: "4d", text: "Coaching the under-10s on Saturdays was the best decision of my year.", image: STOCK_PHOTOS[7], likes: 233, comments: 27, shares: 6, liked: false },
      { id: "fp-15", author: "Sara Lane", hue: "#6A4C93", time: "5d", text: "Tour diary, day 12: missed my own bed, loved every second anyway.", image: STOCK_PHOTOS[2], likes: 311, comments: 34, shares: 7, liked: false },
      { id: "fp-16", author: "Tomas Rivera", hue: "#0077B6", time: "6d", text: "Tried baking bread. The loaf fought back. The loaf won.", image: STOCK_PHOTOS[10], likes: 76, comments: 8, shares: 0, liked: false },
      { id: "fp-17", author: "Priya Nair", hue: "#F4A261", time: "1w", text: "Weekend market haul. The tomatoes alone were worth the trip.", image: STOCK_PHOTOS[5], likes: 121, comments: 11, shares: 2, liked: false },
      { id: "fp-18", author: "Owen Frost", hue: "#264653", time: "1w", text: "Camp stove coffee is a personality trait at this point.", image: STOCK_PHOTOS[4], likes: 143, comments: 14, shares: 3, liked: false },
      { id: "fp-19", author: "Maya Kim", hue: "#E76F51", time: "2w", text: "Throwback to the trip that started all of this. Same van, new miles.", image: STOCK_PHOTOS[13], likes: 267, comments: 29, shares: 8, liked: false },
      { id: "fp-20", author: "Sara Lane", hue: "#6A4C93", time: "2w", text: "Sound check shenanigans before doors. Never a quiet moment.", image: STOCK_PHOTOS[0], likes: 189, comments: 22, shares: 4, liked: false },
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
      { id: "ig-9", author: "priya.n", hue: "#F4A261", caption: "market mornings", image: STOCK_PHOTOS[5], likes: 738, comments: 26, liked: false, saved: false },
      { id: "ig-10", author: "owen.f", hue: "#264653", caption: "cold start, warm coffee", image: STOCK_PHOTOS[6], likes: 1520, comments: 61, liked: false, saved: false },
      { id: "ig-11", author: "sara.lane", hue: "#6A4C93", caption: "backstage calm before the storm", image: STOCK_PHOTOS[13], likes: 2890, comments: 118, liked: false, saved: false },
      { id: "ig-12", author: "dan.m", hue: "#2A9D8F", caption: "saturday league vibes", image: STOCK_PHOTOS[7], likes: 645, comments: 22, liked: false, saved: false },
      { id: "ig-13", author: "tom.r", hue: "#0077B6", caption: "street food friday", image: STOCK_PHOTOS[10], likes: 812, comments: 33, liked: false, saved: false },
      { id: "ig-14", author: "alex.carter", hue: "#833AB4", caption: "lens test, take forty-seven", image: STOCK_PHOTOS[14], likes: 456, comments: 19, liked: false, saved: false },
      { id: "ig-15", author: "maya.k", hue: "#E76F51", caption: "window seat, always", image: STOCK_PHOTOS[1], likes: 1934, comments: 74, liked: false, saved: false },
      { id: "ig-16", author: "priya.n", hue: "#F4A261", caption: "homemade is a love language", image: STOCK_PHOTOS[11], likes: 587, comments: 24, liked: false, saved: false },
      { id: "ig-17", author: "owen.f", hue: "#264653", caption: "trails before traffic", image: STOCK_PHOTOS[3], likes: 2140, comments: 87, liked: false, saved: false },
      { id: "ig-18", author: "sara.lane", hue: "#6A4C93", caption: "encore energy", image: STOCK_PHOTOS[2], likes: 3267, comments: 142, liked: false, saved: false },
      { id: "ig-19", author: "dan.m", hue: "#2A9D8F", caption: "he insists on supervising", image: STOCK_PHOTOS[9], likes: 4103, comments: 231, liked: false, saved: false },
      { id: "ig-20", author: "alex.carter", hue: "#833AB4", caption: "last light on the coast", image: STOCK_PHOTOS[4], likes: 1378, comments: 52, liked: false, saved: false },
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
      { id: "yt-10", title: "Cooking Dinner With What's Actually In My Fridge", channel: "Fresh Kitchen", chHue: "#E76F51", views: 205000, age: "4 days ago", duration: "11:27", image: STOCK_PHOTOS[11], cat: "Cooking" },
      { id: "yt-11", title: "We Hiked 40km in One Day (Big Mistake)", channel: "Wild Stay", chHue: "#2A9D8F", views: 634000, age: "1 week ago", duration: "16:49", image: STOCK_PHOTOS[5], cat: "Travel" },
      { id: "yt-12", title: "Every Gaming Console I Own, Ranked", channel: "Pixel Past", chHue: "#0077B6", views: 412000, age: "2 weeks ago", duration: "25:03", image: STOCK_PHOTOS[9], cat: "Gaming" },
      { id: "yt-13", title: "Live Looping With Just One Guitar", channel: "BeatRoom", chHue: "#6A4C93", views: 891000, age: "3 days ago", duration: "13:40", image: STOCK_PHOTOS[2], cat: "Music" },
      { id: "yt-14", title: "The Science of Perfect Coffee", channel: "Lab Notes", chHue: "#457B9D", views: 1780000, age: "2 months ago", duration: "15:56", image: STOCK_PHOTOS[8], cat: "Science" },
      { id: "yt-15", title: "Restoring a 40-Year-Old Motorbike", channel: "WrenchWorks", chHue: "#F4A261", views: 736000, age: "1 month ago", duration: "28:12", image: STOCK_PHOTOS[13], cat: "Cars" },
      { id: "yt-16", title: "Beginner Bouldering - First Month Progress", channel: "ClimbOn", chHue: "#2A9D8F", views: 94500, age: "5 days ago", duration: "9:18", image: STOCK_PHOTOS[6], cat: "Fitness" },
      { id: "yt-17", title: "I Scored a Film With Free Software Only", channel: "Alex Carter", chHue: "#1877F2", views: 22800, age: "3 days ago", duration: "12:34", image: STOCK_PHOTOS[14], cat: "Film" },
      { id: "yt-18", title: "Marathon Training, Week 6 Update", channel: "RunPace", chHue: "#D62828", views: 143000, age: "1 week ago", duration: "8:52", image: STOCK_PHOTOS[7], cat: "Fitness" },
      { id: "yt-19", title: "Street Photography at Night - No Tripod", channel: "SkyFrame", chHue: "#457B9D", views: 367000, age: "2 weeks ago", duration: "10:21", image: STOCK_PHOTOS[1], cat: "Tech" },
      { id: "yt-20", title: "Making Pasta From Scratch, Start to Finish", channel: "Fresh Kitchen", chHue: "#E76F51", views: 1100000, age: "1 month ago", duration: "19:47", image: STOCK_PHOTOS[5], cat: "Cooking" },
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
      { id: "tt-5", author: "priya.n", caption: "cooking hacks my grandmother taught me", image: STOCK_PHOTOS[10], likes: 156800, comments: 2900, shares: 1800, liked: false, music: "Kitchen groove - the.vibes" },
      { id: "tt-6", author: "owen.f", caption: "5am hike, no filter needed", image: STOCK_PHOTOS[3], likes: 98400, comments: 1500, shares: 940, liked: false, music: "Morning air - trail.mix" },
      { id: "tt-7", author: "maya.k", caption: "room tour but it's just plants", image: STOCK_PHOTOS[8], likes: 67300, comments: 890, shares: 410, liked: false, music: "Grow - green.thumb" },
      { id: "tt-8", author: "dan.m", caption: "the goal celebration we practiced all season", image: STOCK_PHOTOS[7], likes: 189200, comments: 5100, shares: 4200, liked: false, music: "Stadium anthem - sport.beats" },
      { id: "tt-9", author: "sara.lane", caption: "sound check turns dance party", image: STOCK_PHOTOS[13], likes: 143900, comments: 2600, shares: 1700, liked: false, music: "Original sound - sara.lane" },
      { id: "tt-10", author: "tom.r", caption: "street food challenge: $10 budget", image: STOCK_PHOTOS[11], likes: 234500, comments: 6800, shares: 5100, liked: false, music: "Night market - city.sounds" },
      { id: "tt-11", author: "priya.n", caption: "when the bread finally works out", image: STOCK_PHOTOS[5], likes: 76200, comments: 1100, shares: 620, liked: false, music: "Rise and bake - flour.power" },
      { id: "tt-12", author: "owen.f", caption: "van life reality check", image: STOCK_PHOTOS[4], likes: 112600, comments: 2400, shares: 1500, liked: false, music: "Open road - wander.wav" },
      { id: "tt-13", author: "maya.k", caption: "thrift flip: $4 jacket transformation", image: STOCK_PHOTOS[2], likes: 198700, comments: 4300, shares: 3200, liked: false, music: "Runway - thrift.finds" },
      { id: "tt-14", author: "dan.m", caption: "my dog's first beach day (pure chaos)", image: STOCK_PHOTOS[14], likes: 301400, comments: 8200, shares: 6400, liked: false, music: "Original sound - dan.m" },
      { id: "tt-15", author: "sara.lane", caption: "tour bus karaoke, hour nine", image: STOCK_PHOTOS[6], likes: 88500, comments: 1700, shares: 1100, liked: false, music: "Bus songs - sara.lane" },
      { id: "tt-16", author: "tom.r", caption: "making the perfect omelette at 2am", image: STOCK_PHOTOS[0], likes: 54700, comments: 760, shares: 380, liked: false, music: "Late night - kitchen.dj" },
      { id: "tt-17", author: "priya.n", caption: "market haul but everything is under $20", image: STOCK_PHOTOS[10], likes: 121900, comments: 2800, shares: 1900, liked: false, music: "Market run - budget.king" },
      { id: "tt-18", author: "owen.f", caption: "when the fog rolls in mid-shoot", image: STOCK_PHOTOS[1], likes: 156300, comments: 3300, shares: 2400, liked: false, music: "Fog - moody.scenes" },
      { id: "tt-19", author: "maya.k", caption: "couch to 5k, day one, wish me luck", image: STOCK_PHOTOS[7], likes: 43200, comments: 640, shares: 290, liked: false, music: "Pump it - run.club" },
      { id: "tt-20", author: "dan.m", caption: "teaching my kid the family recipe", image: STOCK_PHOTOS[5], likes: 267800, comments: 7400, shares: 5800, liked: false, music: "Original sound - dan.m" },
    ],
  },
});

// which key holds each platform's scrollable feed
const FEED_KEYS = { facepage: "posts", photogram: "posts", vidtube: "videos", quicktok: "posts" };

// saved feeds keep their edits, but always show at least 20 posts - missing
// defaults are appended below whatever has already been customised
const topUpFeed = (feed, defaultsFeed) => {
  if (!Array.isArray(feed) || feed.length >= 20) return feed;
  const ids = new Set(feed.map((p) => p.id));
  return [...feed, ...defaultsFeed.filter((p) => !ids.has(p.id))].slice(0, 20);
};

// get one platform's slice of config data plus a setter, for use inside an app
export const socialSlice = (config, update, key) => {
  const defaults = makeDefaultSocials();
  const feedKey = FEED_KEYS[key];
  const mergeBase = (base) => {
    const merged = { ...(base || defaults[key]) };
    if (feedKey) merged[feedKey] = topUpFeed(merged[feedKey], defaults[key][feedKey]);
    return merged;
  };
  const current = mergeBase((config.socials || {})[key]);
  const setData = (patch) => update((c) => {
    const socials = c.socials || makeDefaultSocials();
    const base = mergeBase(socials[key]);
    return { socials: { ...socials, [key]: { ...base, ...(typeof patch === "function" ? patch(base) : patch) } } };
  });
  return { data: current, setData };
};