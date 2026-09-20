import { STOCK_PHOTOS } from "./osSocial";

// Bulletin - editable mock news app content
export const makeDefaultNews = () => ({
  name: "Bulletin",
  tagline: "The world, twice daily",
  articles: [
    { id: "n1", tag: "Breaking", title: "Night shoot wraps early as storm front clears the coast", body: "Production confirmed the final scene wrapped at 21:40, an hour ahead of schedule, after the forecast squall swung south. Crew call for Monday stands at 07:00.", image: STOCK_PHOTOS[1] },
    { id: "n2", tag: "Local", title: "Waterfront night market opens to long queues", body: "Forty stalls traded on the pier on Friday night, with organisers reporting more than 4 000 visitors before close.", image: STOCK_PHOTOS[7] },
    { id: "n3", tag: "Culture", title: "The violin maker with a two-year waitlist", body: "Her workshop now holds three benches, two apprentices and a small dog called Rosy.", image: STOCK_PHOTOS[8] },
    { id: "n4", tag: "Sport", title: "Harbour swim returns after three-year break", body: "Two hundred swimmers entered the bay crossing, the first since the event paused in 2023.", image: STOCK_PHOTOS[5] },
    { id: "n5", tag: "Weather", title: "Warming trend into Thursday, weak front Friday", body: "Temperatures climb to 26° inland midweek before a light shower brushes the coast to end the week.", image: STOCK_PHOTOS[6] },
  ],
});

// Realty - editable mock property app content
export const makeDefaultProperty = () => ({
  name: "Realty",
  tagline: "Find the one",
  listings: [
    { id: "p1", price: "R 4 250 000", address: "22 Vlei Road, Cape Town", beds: "3", baths: "2", size: "142 m²", blurb: "North-facing family home steps from the vlei, with a courtyard braai and restored oregan floors.", image: STOCK_PHOTOS[0] },
    { id: "p2", price: "R 2 995 000", address: "8A Kloof Street, Gardens", beds: "2", baths: "1", size: "94 m²", blurb: "Apartment in a Victorian block with mountain views from the shared roof terrace.", image: STOCK_PHOTOS[9] },
    { id: "p3", price: "R 6 750 000", address: "14 Protea Lane, Constantia", beds: "4", baths: "3", size: "210 m²", blurb: "Classic gable with a mature garden, pool and cottage ideal for guests or a studio.", image: STOCK_PHOTOS[4] },
    { id: "p4", price: "R 1 695 000", address: "77 Beach Road, Sea Point", beds: "1", baths: "1", size: "58 m²", blurb: "Compact studio a block off the promenade, ideal first step onto the ladder.", image: STOCK_PHOTOS[2] },
  ],
});