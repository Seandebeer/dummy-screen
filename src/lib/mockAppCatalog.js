// catalog of mock ("downloaded") apps for the App Library - 20 categories,
// 10 apps each, every app tagged with its subcategory
import {
  MessageCircle, MessagesSquare, Users, Globe, Heart, HeartHandshake, Coffee,
  Video, Cast, Play, Tv, Headphones, Music, Mic, Podcast, Gamepad2, Swords,
  Book, BookOpen, Aperture, Camera, Clapperboard, Film, Drum, AudioLines,
  Palette, PenTool, FileText, Boxes, StickyNote, Files, BadgeCheck, ListTodo,
  LayoutDashboard, UserPlus, Hourglass, Timer, PenLine, GraduationCap,
  Lightbulb, Languages, Library, School, Presentation, Layers, ClipboardCheck,
  Landmark, Building2, CreditCard, Receipt, TrendingUp, PieChart, PiggyBank,
  Coins, Wallet, Zap, Store, Package, ShoppingBag, ShoppingCart, Bike, Truck,
  Shirt, Scissors, Wrench, Hammer, Navigation, Map, Route, Car, Train, Bus,
  Plane, Luggage, Hotel, Compass, Dumbbell, Footprints, Salad, Droplet, Brain,
  Wind, Stethoscope, Pill, Moon, Bed, ChefHat, Soup, Home, Sparkles, Brush,
  Flower2, Baby, Shapes, Newspaper, Radio, CloudSun, Umbrella, Search, MapPin,
  Folder, FolderOpen, ScanLine, KeyRound, Lock, Scale, Target, UserCog,
  Contact, Megaphone, Vote, Check, Siren, Cross, Wifi, Plug, WashingMachine,
  Sun, Trophy, Flag, Tent, Fish, Ticket, Sunrise, Church, Blocks, Puzzle,
  Gift, CalendarDays, Eye, Ruler, Box, DraftingCompass, FlaskConical,
  Microscope, HardHat, Anvil, Star, Dices, ShieldCheck, Binary, Flame,
  Calculator, Cpu, Sprout,
} from "lucide-react";

const app = (label, Icon, bg, sub) => ({ label, Icon, bg, sub });

export const categories = [
  {
    id: "social", name: "Social & Communication",
    apps: [
      app("Ping", MessageCircle, "#0A84FF", "Messaging"),
      app("Chattr", MessagesSquare, "#22C55E", "Messaging"),
      app("Buzz", Users, "#3B82F6", "Social networks"),
      app("Storyline", Globe, "#7C3AED", "Social networks"),
      app("Sparkd", Heart, "#FF2D55", "Dating"),
      app("Duoo", HeartHandshake, "#F472B6", "Dating"),
      app("Forumly", Coffee, "#92400E", "Forums & communities"),
      app("CircleHub", Users, "#0891B2", "Forums & communities"),
      app("Visage", Video, "#059669", "Video calling"),
      app("Beamcall", Cast, "#2563EB", "Video calling"),
    ],
  },
  {
    id: "entertainment", name: "Entertainment",
    apps: [
      app("Flixiq", Play, "#FF375F", "Video streaming"),
      app("Reelhouse", Tv, "#7C3AED", "Video streaming"),
      app("Waveform", Headphones, "#8B5CF6", "Music & audio"),
      app("Vinylize", Music, "#C026D3", "Music & audio"),
      app("Talkline", Mic, "#E11D48", "Podcasts"),
      app("Eardrift", Podcast, "#6D28D9", "Podcasts"),
      app("Questly", Gamepad2, "#A78BFA", "Games"),
      app("Pixelrun", Swords, "#DC2626", "Games"),
      app("Inkwell", Book, "#0F766E", "Books & comics"),
      app("Panelport", BookOpen, "#1D4ED8", "Books & comics"),
    ],
  },
  {
    id: "creative", name: "Creative & Media",
    apps: [
      app("Lumenlab", Aperture, "#0EA5E9", "Photo"),
      app("Darkroomr", Camera, "#111827", "Photo"),
      app("Cutroom", Clapperboard, "#FF375F", "Video"),
      app("Stopmo", Film, "#B45309", "Video"),
      app("Beatforge", Drum, "#DB2777", "Music production"),
      app("Synthlab", AudioLines, "#065F46", "Music production"),
      app("Sketchpad", Palette, "#F59E0B", "Drawing & design"),
      app("Vectorly", PenTool, "#0F172A", "Drawing & design"),
      app("Drafton", FileText, "#2563EB", "Writing"),
      app("Polyform", Boxes, "#6D28D9", "3D & animation"),
    ],
  },
  {
    id: "productivity", name: "Productivity & Work",
    apps: [
      app("Jottr", StickyNote, "#FACC15", "Notes"),
      app("Docstack", Files, "#1E40AF", "Documents"),
      app("Tickoff", BadgeCheck, "#16A34A", "Tasks"),
      app("Donely", ListTodo, "#0EA5E9", "Tasks"),
      app("Boardwalk", LayoutDashboard, "#F97316", "Project management"),
      app("Teamly", Users, "#2563EB", "Collaboration"),
      app("Cowrite", UserPlus, "#059669", "Collaboration"),
      app("Flowday", Hourglass, "#7C3AED", "Time management"),
      app("Pomodono", Timer, "#EA580C", "Time management"),
      app("Scribbly", PenLine, "#DB2777", "Notes"),
    ],
  },
  {
    id: "education", name: "Education & Learning",
    apps: [
      app("Lessonly", GraduationCap, "#2563EB", "Courses"),
      app("Skillbay", Lightbulb, "#F59E0B", "Courses"),
      app("Lingoo", Languages, "#0D9488", "Language learning"),
      app("Verbly", BookOpen, "#4F46E5", "Language learning"),
      app("Wikiport", Library, "#334155", "Reference"),
      app("Factshelf", Book, "#65A30D", "Reference"),
      app("Tutorme", School, "#7C2D12", "Tutoring"),
      app("Mentorline", Presentation, "#C026D3", "Tutoring"),
      app("Flashly", Layers, "#F59E0B", "Study tools"),
      app("Examize", ClipboardCheck, "#1D4ED8", "Study tools"),
    ],
  },
  {
    id: "finance", name: "Finance & Money",
    apps: [
      app("Trustbranch", Landmark, "#166534", "Banking"),
      app("Savebank", Building2, "#0F766E", "Banking"),
      app("Tapnpay", CreditCard, "#0EA5E9", "Payments"),
      app("Splitbill", Receipt, "#DB2777", "Payments"),
      app("Growfund", TrendingUp, "#16A34A", "Investing"),
      app("Portfoliq", PieChart, "#F97316", "Investing"),
      app("Coinbank", PiggyBank, "#F59E0B", "Budgeting"),
      app("Budgetly", Coins, "#475569", "Budgeting"),
      app("Walletto", Wallet, "#7C3AED", "Wallets"),
      app("Zingpay", Zap, "#FACC15", "Wallets"),
    ],
  },
  {
    id: "shopping", name: "Shopping & Commerce",
    apps: [
      app("Bazaarbay", Store, "#EA580C", "Marketplaces"),
      app("Swapshop", Package, "#0891B2", "Marketplaces"),
      app("Megastore", ShoppingBag, "#DB2777", "Retail"),
      app("Quickcart", ShoppingCart, "#16A34A", "Retail"),
      app("Forkspeed", Bike, "#F97316", "Food delivery"),
      app("Snackdash", Truck, "#E11D48", "Food delivery"),
      app("Threadly", Shirt, "#2563EB", "Fashion"),
      app("Runwayly", Scissors, "#F472B6", "Fashion"),
      app("Handyy", Wrench, "#0891B2", "Services"),
      app("Hirehub", Hammer, "#78350F", "Services"),
    ],
  },
  {
    id: "travel", name: "Travel & Transport",
    apps: [
      app("Pathfindr", Navigation, "#0E7490", "Maps & navigation"),
      app("Wandermap", Map, "#059669", "Maps & navigation"),
      app("Zippyride", Car, "#FACC15", "Ride-hailing"),
      app("Cruize", Route, "#DB2777", "Ride-hailing"),
      app("Metropass", Train, "#1D4ED8", "Public transport"),
      app("Busline", Bus, "#0EA5E9", "Public transport"),
      app("Skysail", Plane, "#2563EB", "Flights"),
      app("Jetsetter", Luggage, "#F59E0B", "Flights"),
      app("Stayinn", Hotel, "#7C3AED", "Hotels"),
      app("Tripweaver", Compass, "#F97316", "Travel planning"),
    ],
  },
  {
    id: "health", name: "Health & Fitness",
    apps: [
      app("Flexr", Dumbbell, "#FF9F0A", "Exercise"),
      app("Stride", Footprints, "#60A5FA", "Exercise"),
      app("Macronutri", Salad, "#16A34A", "Nutrition"),
      app("Hydrate", Droplet, "#0EA5E9", "Nutrition"),
      app("Zenwave", Brain, "#8B5CF6", "Meditation"),
      app("Breatheo", Wind, "#06B6D4", "Meditation"),
      app("Medcheck", Stethoscope, "#EF4444", "Medical"),
      app("Pillpal", Pill, "#F43F5E", "Medical"),
      app("Dreamtrack", Moon, "#7C3AED", "Sleep"),
      app("Slumberly", Bed, "#4F46E5", "Sleep"),
    ],
  },
  {
    id: "lifestyle", name: "Lifestyle",
    apps: [
      app("Recipebox", ChefHat, "#EA580C", "Food & recipes"),
      app("Simmersoup", Soup, "#F59E0B", "Food & recipes"),
      app("Havenest", Home, "#16A34A", "Home"),
      app("Tidyly", Sparkles, "#F472B6", "Home"),
      app("Glowup", Flower2, "#FF2D55", "Fashion & beauty"),
      app("Mirrormuse", Brush, "#8B5CF6", "Fashion & beauty"),
      app("Lovelens", Heart, "#F43F5E", "Dating & relationships"),
      app("Bondly", HeartHandshake, "#DB2777", "Dating & relationships"),
      app("Nests", Baby, "#FDE68A", "Parenting"),
      app("Craftcove", Shapes, "#0EA5E9", "Hobbies"),
    ],
  },
  {
    id: "news", name: "News & Information",
    apps: [
      app("Headlines24", Newspaper, "#DC2626", "News"),
      app("Scooppress", Radio, "#EA580C", "News"),
      app("Skycast", CloudSun, "#0EA5E9", "Weather"),
      app("Raincheck", Umbrella, "#3B82F6", "Weather"),
      app("Findit", Search, "#1E293B", "Search"),
      app("Whoogle", Globe, "#065F46", "Search"),
      app("Encyclo", Book, "#3F6212", "Reference"),
      app("Atlasly", MapPin, "#B91C1C", "Reference"),
      app("Glossely", BookOpen, "#DB2777", "Magazines"),
      app("Pagespin", Star, "#F59E0B", "Magazines"),
    ],
  },
  {
    id: "utilities", name: "Utilities & Tools",
    apps: [
      app("Numly", Calculator, "#334155", "Calculators"),
      app("Unitvert", Scale, "#0F766E", "Calculators"),
      app("Filenest", Folder, "#F59E0B", "File management"),
      app("Zipkeeper", FolderOpen, "#EA580C", "File management"),
      app("Scanr", ScanLine, "#1D4ED8", "Scanning"),
      app("Docucapture", Camera, "#374151", "Scanning"),
      app("Keypass", KeyRound, "#FBBF24", "Password managers"),
      app("Ciphersafe", Lock, "#312E81", "Password managers"),
      app("Devicetune", Cpu, "#64748B", "Device utilities"),
      app("Askly", Sparkles, "#8B5CF6", "AI assistants"),
    ],
  },
  {
    id: "business", name: "Business & Professional",
    apps: [
      app("Pipelinr", Users, "#2563EB", "CRM"),
      app("Contactly", Contact, "#0E7490", "CRM"),
      app("Balancebook", Landmark, "#166534", "Accounting"),
      app("Invoicely", FileText, "#0F766E", "Accounting"),
      app("Salespitch", TrendingUp, "#16A34A", "Sales"),
      app("Leadline", Target, "#F97316", "Sales"),
      app("Campaignly", Megaphone, "#FF375F", "Marketing"),
      app("Brandwave", BadgeCheck, "#7C3AED", "Marketing"),
      app("Peopledeck", UserCog, "#0891B2", "HR"),
      app("Suitely", Building2, "#475569", "Enterprise tools"),
    ],
  },
  {
    id: "government", name: "Government & Civic",
    apps: [
      app("Govportal", Landmark, "#334155", "Government services"),
      app("Formdesk", FileText, "#1E40AF", "Government services"),
      app("Votenow", Vote, "#2563EB", "Voting & elections"),
      app("Ballotbox", Check, "#0F766E", "Voting & elections"),
      app("Transitline", Bus, "#0EA5E9", "Public transport"),
      app("Metrolink", Train, "#1D4ED8", "Public transport"),
      app("Sosnow", Siren, "#DC2626", "Emergency services"),
      app("Respondr", Cross, "#B91C1C", "Emergency services"),
      app("Civicshare", HeartHandshake, "#059669", "Community services"),
      app("Townsquare", Flag, "#F59E0B", "Community services"),
    ],
  },
  {
    id: "smarthome", name: "Home & Smart Devices",
    apps: [
      app("Homelink", Wifi, "#0EA5E9", "Smart home"),
      app("Scenectl", Lightbulb, "#F59E0B", "Smart home"),
      app("Guardgate", ShieldCheck, "#166534", "Security"),
      app("Sentryhome", Eye, "#1E293B", "Security"),
      app("Appliancehub", Plug, "#0F766E", "Appliances"),
      app("Washwizard", WashingMachine, "#2563EB", "Appliances"),
      app("Wattly", Zap, "#FACC15", "Energy"),
      app("Solartrack", Sun, "#F59E0B", "Energy"),
      app("Nestcam", Video, "#DC2626", "Cameras"),
      app("Peephole", Camera, "#374151", "Cameras"),
    ],
  },
  {
    id: "sports", name: "Sports & Recreation",
    apps: [
      app("Matchday", Trophy, "#F59E0B", "Sports"),
      app("Scorezone", Flag, "#16A34A", "Sports"),
      app("Gymcrew", Dumbbell, "#FF9F0A", "Fitness communities"),
      app("Runclub", Footprints, "#60A5FA", "Fitness communities"),
      app("Trailsy", Tent, "#166534", "Outdoor activities"),
      app("Fishhook", Fish, "#0891B2", "Outdoor activities"),
      app("Ticketwave", Ticket, "#DB2777", "Events"),
      app("Livestage", Mic, "#7C3AED", "Events"),
      app("Fantasyleague", Dices, "#A78BFA", "Fantasy sports"),
      app("Rosterr", Star, "#F97316", "Fantasy sports"),
    ],
  },
  {
    id: "religion", name: "Religion & Spirituality",
    apps: [
      app("Congregation", Users, "#1E40AF", "Religious communities"),
      app("Faithcircle", Church, "#B91C1C", "Religious communities"),
      app("Versely", BookOpen, "#365314", "Scripture"),
      app("Chapterlight", Book, "#0F766E", "Scripture"),
      app("Prayzone", Sunrise, "#F59E0B", "Prayer & meditation"),
      app("Quiettime", Moon, "#7C3AED", "Prayer & meditation"),
      app("Hymnly", Music, "#8B5CF6", "Scripture"),
      app("Retreatly", Sprout, "#16A34A", "Spiritual education"),
      app("Soulschool", GraduationCap, "#7C2D12", "Spiritual education"),
      app("Pathwayz", Compass, "#0891B2", "Spiritual education"),
    ],
  },
  {
    id: "kids", name: "Kids & Family",
    apps: [
      app("Toonville", Tv, "#7C3AED", "Children's entertainment"),
      app("Playland", Blocks, "#F97316", "Children's entertainment"),
      app("Storytime", BookOpen, "#F59E0B", "Children's entertainment"),
      app("Abctown", Puzzle, "#16A34A", "Learning"),
      app("Mathlings", Binary, "#2563EB", "Learning"),
      app("Familyboard", Users, "#059669", "Family coordination"),
      app("Chorechart", ListTodo, "#0F766E", "Family coordination"),
      app("Kidkeeper", Baby, "#FDE68A", "Family coordination"),
      app("Safeblock", ShieldCheck, "#166534", "Parental controls"),
      app("Screenlimit", Lock, "#312E81", "Parental controls"),
    ],
  },
  {
    id: "dating", name: "Dating & Relationships",
    apps: [
      app("Blazee", Flame, "#FF375F", "Dating"),
      app("Cupidly", Heart, "#F43F5E", "Dating"),
      app("Vibechat", MessageCircle, "#22C55E", "Dating"),
      app("Datelens", Eye, "#7C3AED", "Dating"),
      app("Matchpair", HeartHandshake, "#DB2777", "Matchmaking"),
      app("Soulmatehq", Star, "#FFD60A", "Matchmaking"),
      app("Couplecare", Gift, "#DB2777", "Relationship tools"),
      app("Anniverly", CalendarDays, "#FF3B30", "Relationship tools"),
      app("Mixr", Users, "#8B5CF6", "Social discovery"),
      app("Nearbyy", MapPin, "#0EA5E9", "Social discovery"),
    ],
  },
  {
    id: "specialised", name: "Specialised / Professional Tools",
    apps: [
      app("Slatepro", Clapperboard, "#111827", "Film & production"),
      app("Callsheet", FileText, "#B91C1C", "Film & production"),
      app("Forcecalc", Ruler, "#1D4ED8", "Engineering"),
      app("Cadsmith", Box, "#334155", "Engineering"),
      app("Planchek", DraftingCompass, "#0F766E", "Architecture"),
      app("Labbench", FlaskConical, "#0D9488", "Science"),
      app("Researchr", Microscope, "#365314", "Science"),
      app("Lawdesk", Scale, "#1E293B", "Legal"),
      app("Buildsite", HardHat, "#F59E0B", "Construction"),
      app("Rivet", Anvil, "#57534E", "Industry-specific software"),
    ],
  },
];

const TILE_TYPES = ["flat", "duo", "gloss", "dark", "glass", "mono", "outline", "ring", "split", "badge", "pastel"];
// stripes and polka dots only suit playful brands - games only
const PLAYFUL_TYPES = ["stripes", "dots"];
const DUO_TINTS = ["#A78BFA", "#22C55E", "#60A5FA", "#F472B6", "#FCD34D", "#94A3B8", "#D946EF", "#FF9F0A"];

const luminance = (hex) => {
  const n = parseInt(hex.slice(1), 16);
  return (((n >> 16) & 255) * 0.299 + ((n >> 8) & 255) * 0.587 + (n & 255) * 0.114) / 255;
};

// every app gets its own tile look, always readable on its background
const tileFor = (bg, seed, playful = false) => {
  const L = luminance(bg);
  let pool = playful ? [...TILE_TYPES, ...PLAYFUL_TYPES] : TILE_TYPES;
  if (L > 0.62) pool = ["gloss", "mono", "outline", "pastel"];
  else if (L < 0.25) pool = TILE_TYPES.filter((t) => t !== "dark" && t !== "pastel");
  const type = pool[seed % pool.length];
  const tile = { type };
  if (["duo", "stripes", "dots", "ring", "split"].includes(type)) tile.bg2 = DUO_TINTS[(seed + type.length) % DUO_TINTS.length];
  if (L > 0.62) tile.fg = "#783509";
  return tile;
};

export const mockApps = categories.flatMap((cat, ci) =>
  cat.apps.map((a, i) => ({
    id: a.label.toLowerCase().replace(/[^a-z0-9]+/g, "-"),
    label: a.label,
    Icon: a.Icon,
    bg: a.bg,
    tile: tileFor(a.bg, ci * 3 + i, a.sub === "Games"),
    category: cat.id,
    categoryName: cat.name,
    sub: a.sub,
    ...(a.img ? { img: a.img } : {}),
  })),
);