import { STOCK_PHOTOS } from "./osSocial";

// Webdeck - up to five fully editable mock websites. Every field below can be
// edited in-app (pencil mode) and saved to the Home saved card under Websites.

export const MAX_SITES = 5;

export const makeDefaultSites = () => ({
  sites: [
    {
      id: "ledger",
      name: "The Daily Ledger",
      url: "dailyledger.co",
      hue: "#B91C1C",
      tagline: "Independent news since 1962",
      nav: ["Home", "World", "Business", "Culture", "Opinion"],
      hero: {
        kicker: "Tuesday · Edition No. 214",
        heading: "Harbour lights return as the waterfront reopens",
        sub: "After three years behind scaffolding, the old dock district welcomes the public back this weekend.",
        cta: "Read the full story",
        image: STOCK_PHOTOS[1],
      },
      cards: [
        { id: "l1", title: "City council approves night-market pilot", body: "Forty stalls will trade on the pier every Friday from June, in a trial running through summer.", image: STOCK_PHOTOS[7] },
        { id: "l2", title: "Q&A: the luthier keeping violin-making alive", body: "She arrived in the city with one workbench and a suitcase of spruce. Her workshop now has a two-year waitlist.", image: "" },
        { id: "l3", title: "Five trails to try before the weather turns", body: "From the ridge walk above the reservoir to the fynbos loop behind the lighthouse - all doable before lunch.", image: STOCK_PHOTOS[6] },
      ],
      links: ["About", "Advertise", "Contact", "Privacy"],
      footNote: "© The Daily Ledger. All rights reserved.",
    },
    {
      id: "brewbean",
      name: "Brew & Bean",
      url: "brewandbean.coffee",
      hue: "#92400E",
      tagline: "Coffee, slowly",
      nav: ["Menu", "Roasts", "Stories", "Find Us"],
      hero: {
        kicker: "Est. 2016 · Bree Street",
        heading: "Slow mornings, faster coffee",
        sub: "Single-origin espresso, baked goods before eight, and a corner seat with your name on it.",
        cta: "See the menu",
        image: STOCK_PHOTOS[10],
      },
      cards: [
        { id: "b1", title: "House Blend: cocoa, hazelnut, a little smoke", body: "Our year-round espresso. Comfortable in a flat white, honest as an americano. Roasted every Tuesday.", image: "" },
        { id: "b2", title: "Roasted Tuesdays, shipped Fridays", body: "Subscription bags leave the roastery within 72 hours of the drum. Pause, skip or swap any time.", image: STOCK_PHOTOS[11] },
        { id: "b3", title: "The corner table: a short history", body: "Why the wobbly table by the window has hosted three book clubs, one wedding proposal and a small dog called Rosy.", image: "" },
      ],
      links: ["Origins", "Wholesale", "Jobs", "Contact"],
      footNote: "Brew & Bean Coffee Co.",
    },
    {
      id: "trailhead",
      name: "Trailhead Outfitters",
      url: "trailheadgear.com",
      hue: "#15803D",
      tagline: "Equipment for the long way round",
      nav: ["New", "Packs", "Tents", "Apparel", "Sale"],
      hero: {
        kicker: "Autumn drop",
        heading: "Gear that outlasts the trip",
        sub: "Field-tested packs, tents and layers - built for the mountain, priced for the valley.",
        cta: "Shop new arrivals",
        image: STOCK_PHOTOS[3],
      },
      cards: [
        { id: "t1", title: "Ridgeline 45L Pack", body: "Roll-top, alloy frame, ten-year repair promise. The pack our own rangers actually wear. R2 499.", image: STOCK_PHOTOS[0] },
        { id: "t2", title: "Basecamp 2P Tent", body: "Two doors, 1.9 kg, and a fly that shrugs off the south-easter. Pitched in under four minutes. R4 299.", image: STOCK_PHOTOS[4] },
        { id: "t3", title: "Stormshell Jacket", body: "Fully seam-sealed with a hood that fits over a helmet. Packs into its own chest pocket. R1 899.", image: "" },
      ],
      links: ["Shipping", "Returns", "Warranty", "Support"],
      footNote: "Trailhead Outfitters · Cape Town",
    },
    {
      id: "pixelforge",
      name: "PixelForge Studio",
      url: "pixelforge.studio",
      hue: "#5B21B6",
      tagline: "Design & code, in that order",
      nav: ["Work", "Studio", "Services", "Contact"],
      hero: {
        kicker: "Design & code studio",
        heading: "We build software people actually enjoy",
        sub: "A small team of designers and engineers shipping products for startups and studios.",
        cta: "Start a project",
        image: STOCK_PHOTOS[2],
      },
      cards: [
        { id: "p1", title: "Case study: Meridian's app relaunch", body: "How we cut onboarding from eleven screens to three - and doubled week-one retention.", image: "" },
        { id: "p2", title: "How we run two-week sprints", body: "One designer, one engineer, one ship date. The system behind our calmest work.", image: STOCK_PHOTOS[8] },
        { id: "p3", title: "Meet the team", body: "Seven people, two dogs, one espresso machine of considerable opinion. Say hello.", image: "" },
      ],
      links: ["Careers", "Press", "Legal", "hello@pixelforge.example"],
      footNote: "© PixelForge Studio",
    },
    {
      id: "meridian",
      name: "Meridian Weather",
      url: "meridianweather.net",
      hue: "#0369A1",
      tagline: "Forecasts you can argue with",
      nav: ["Today", "Hourly", "10-Day", "Maps"],
      hero: {
        kicker: "Cape Town · Sunday",
        heading: "22° and mostly sunny",
        sub: "Light south-easterly clearing by mid-morning. Sea temperature 16°. Sunset at 18:42.",
        cta: "Full forecast",
        image: STOCK_PHOTOS[5],
      },
      cards: [
        { id: "w1", title: "Tonight: 14°, clear skies", body: "Light winds from the south-east. A good night for the observatory.", image: "" },
        { id: "w2", title: "This week: warming trend into Thursday", body: "Temperatures climb to 26° inland before a weak front brushes the coast on Friday.", image: "" },
        { id: "w3", title: "Coastal wind advisory lifted", body: "The Table Mountain cableway reopened to visitors at noon.", image: STOCK_PHOTOS[6] },
      ],
      links: ["About", "Data sources", "Apps", "Contact"],
      footNote: "Meridian Weather · Mock forecast",
    },
  ],
});