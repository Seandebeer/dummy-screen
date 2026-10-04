import 'package:flutter/material.dart';

import 'catalog.dart';

/// Mock App Library catalog from `src/lib/mockAppCatalog.js`.
class CatalogApp {
  const CatalogApp(this.id, this.label, this.color, this.icon, this.category, this.categoryName, this.sub);

  final String id;
  final String label;
  final Color color;
  final IconData icon;
  final String category;
  final String categoryName;
  final String sub;
}

class CatalogSection {
  const CatalogSection(this.id, this.name, this.apps);

  final String id;
  final String name;
  final List<CatalogApp> apps;
}

const mockCatalog = <CatalogSection>[
  CatalogSection('social', 'Social & Communication', [
    CatalogApp('ping', 'Ping', Color(0xFF0A84FF), Icons.chat_bubble_outline, 'social', 'Social & Communication', 'Messaging'),
    CatalogApp('chattr', 'Chattr', Color(0xFF22C55E), Icons.forum_outlined, 'social', 'Social & Communication', 'Messaging'),
    CatalogApp('buzz', 'Buzz', Color(0xFF3B82F6), Icons.groups_outlined, 'social', 'Social & Communication', 'Social networks'),
    CatalogApp('storyline', 'Storyline', Color(0xFF7C3AED), Icons.public, 'social', 'Social & Communication', 'Social networks'),
    CatalogApp('sparkd', 'Sparkd', Color(0xFFFF2D55), Icons.favorite_border, 'social', 'Social & Communication', 'Dating'),
    CatalogApp('duoo', 'Duoo', Color(0xFFF472B6), Icons.favorite_outline, 'social', 'Social & Communication', 'Dating'),
    CatalogApp('forumly', 'Forumly', Color(0xFF92400E), Icons.coffee_outlined, 'social', 'Social & Communication', 'Forums & communities'),
    CatalogApp('circlehub', 'CircleHub', Color(0xFF0891B2), Icons.groups_outlined, 'social', 'Social & Communication', 'Forums & communities'),
    CatalogApp('visage', 'Visage', Color(0xFF059669), Icons.videocam_outlined, 'social', 'Social & Communication', 'Video calling'),
    CatalogApp('beamcall', 'Beamcall', Color(0xFF2563EB), Icons.cast, 'social', 'Social & Communication', 'Video calling'),
  ]),
  CatalogSection('entertainment', 'Entertainment', [
    CatalogApp('flixiq', 'Flixiq', Color(0xFFFF375F), Icons.play_arrow, 'entertainment', 'Entertainment', 'Video streaming'),
    CatalogApp('reelhouse', 'Reelhouse', Color(0xFF7C3AED), Icons.tv, 'entertainment', 'Entertainment', 'Video streaming'),
    CatalogApp('waveform', 'Waveform', Color(0xFF8B5CF6), Icons.headphones, 'entertainment', 'Entertainment', 'Music & audio'),
    CatalogApp('vinylize', 'Vinylize', Color(0xFFC026D3), Icons.music_note, 'entertainment', 'Entertainment', 'Music & audio'),
    CatalogApp('talkline', 'Talkline', Color(0xFFE11D48), Icons.mic_none, 'entertainment', 'Entertainment', 'Podcasts'),
    CatalogApp('eardrift', 'Eardrift', Color(0xFF6D28D9), Icons.podcasts, 'entertainment', 'Entertainment', 'Podcasts'),
    CatalogApp('questly', 'Questly', Color(0xFFA78BFA), Icons.sports_esports_outlined, 'entertainment', 'Entertainment', 'Games'),
    CatalogApp('pixelrun', 'Pixelrun', Color(0xFFDC2626), Icons.sports_kabaddi, 'entertainment', 'Entertainment', 'Games'),
    CatalogApp('inkwell', 'Inkwell', Color(0xFF0F766E), Icons.menu_book_outlined, 'entertainment', 'Entertainment', 'Books & comics'),
    CatalogApp('panelport', 'Panelport', Color(0xFF1D4ED8), Icons.auto_stories_outlined, 'entertainment', 'Entertainment', 'Books & comics'),
  ]),
  CatalogSection('creative', 'Creative & Media', [
    CatalogApp('lumenlab', 'Lumenlab', Color(0xFF0EA5E9), Icons.camera, 'creative', 'Creative & Media', 'Photo'),
    CatalogApp('darkroomr', 'Darkroomr', Color(0xFF111827), Icons.photo_camera_outlined, 'creative', 'Creative & Media', 'Photo'),
    CatalogApp('cutroom', 'Cutroom', Color(0xFFFF375F), Icons.movie_outlined, 'creative', 'Creative & Media', 'Video'),
    CatalogApp('stopmo', 'Stopmo', Color(0xFFB45309), Icons.movie_creation_outlined, 'creative', 'Creative & Media', 'Video'),
    CatalogApp('beatforge', 'Beatforge', Color(0xFFDB2777), Icons.audiotrack, 'creative', 'Creative & Media', 'Music production'),
    CatalogApp('synthlab', 'Synthlab', Color(0xFF065F46), Icons.graphic_eq, 'creative', 'Creative & Media', 'Music production'),
    CatalogApp('sketchpad', 'Sketchpad', Color(0xFFF59E0B), Icons.palette_outlined, 'creative', 'Creative & Media', 'Drawing & design'),
    CatalogApp('vectorly', 'Vectorly', Color(0xFF0F172A), Icons.draw_outlined, 'creative', 'Creative & Media', 'Drawing & design'),
    CatalogApp('drafton', 'Drafton', Color(0xFF2563EB), Icons.description_outlined, 'creative', 'Creative & Media', 'Writing'),
    CatalogApp('polyform', 'Polyform', Color(0xFF6D28D9), Icons.view_in_ar_outlined, 'creative', 'Creative & Media', '3D & animation'),
  ]),
  CatalogSection('productivity', 'Productivity & Work', [
    CatalogApp('jottr', 'Jottr', Color(0xFFFACC15), Icons.sticky_note_2_outlined, 'productivity', 'Productivity & Work', 'Notes'),
    CatalogApp('docstack', 'Docstack', Color(0xFF1E40AF), Icons.folder_copy_outlined, 'productivity', 'Productivity & Work', 'Documents'),
    CatalogApp('tickoff', 'Tickoff', Color(0xFF16A34A), Icons.verified_outlined, 'productivity', 'Productivity & Work', 'Tasks'),
    CatalogApp('donely', 'Donely', Color(0xFF0EA5E9), Icons.checklist, 'productivity', 'Productivity & Work', 'Tasks'),
    CatalogApp('boardwalk', 'Boardwalk', Color(0xFFF97316), Icons.dashboard_outlined, 'productivity', 'Productivity & Work', 'Project management'),
    CatalogApp('teamly', 'Teamly', Color(0xFF2563EB), Icons.groups_outlined, 'productivity', 'Productivity & Work', 'Collaboration'),
    CatalogApp('cowrite', 'Cowrite', Color(0xFF059669), Icons.person_add_alt, 'productivity', 'Productivity & Work', 'Collaboration'),
    CatalogApp('flowday', 'Flowday', Color(0xFF7C3AED), Icons.hourglass_empty, 'productivity', 'Productivity & Work', 'Time management'),
    CatalogApp('pomodono', 'Pomodono', Color(0xFFEA580C), Icons.timer_outlined, 'productivity', 'Productivity & Work', 'Time management'),
    CatalogApp('scribbly', 'Scribbly', Color(0xFFDB2777), Icons.edit_outlined, 'productivity', 'Productivity & Work', 'Notes'),
  ]),
  CatalogSection('education', 'Education & Learning', [
    CatalogApp('lessonly', 'Lessonly', Color(0xFF2563EB), Icons.school_outlined, 'education', 'Education & Learning', 'Courses'),
    CatalogApp('skillbay', 'Skillbay', Color(0xFFF59E0B), Icons.lightbulb_outline, 'education', 'Education & Learning', 'Courses'),
    CatalogApp('lingoo', 'Lingoo', Color(0xFF0D9488), Icons.translate, 'education', 'Education & Learning', 'Language learning'),
    CatalogApp('verbly', 'Verbly', Color(0xFF4F46E5), Icons.auto_stories_outlined, 'education', 'Education & Learning', 'Language learning'),
    CatalogApp('wikiport', 'Wikiport', Color(0xFF334155), Icons.local_library_outlined, 'education', 'Education & Learning', 'Reference'),
    CatalogApp('factshelf', 'Factshelf', Color(0xFF65A30D), Icons.menu_book_outlined, 'education', 'Education & Learning', 'Reference'),
    CatalogApp('tutorme', 'Tutorme', Color(0xFF7C2D12), Icons.school, 'education', 'Education & Learning', 'Tutoring'),
    CatalogApp('mentorline', 'Mentorline', Color(0xFFC026D3), Icons.present_to_all, 'education', 'Education & Learning', 'Tutoring'),
    CatalogApp('flashly', 'Flashly', Color(0xFFF59E0B), Icons.layers_outlined, 'education', 'Education & Learning', 'Study tools'),
    CatalogApp('examize', 'Examize', Color(0xFF1D4ED8), Icons.fact_check_outlined, 'education', 'Education & Learning', 'Study tools'),
  ]),
  CatalogSection('finance', 'Finance & Money', [
    CatalogApp('trustbranch', 'Trustbranch', Color(0xFF166534), Icons.account_balance, 'finance', 'Finance & Money', 'Banking'),
    CatalogApp('savebank', 'Savebank', Color(0xFF0F766E), Icons.apartment, 'finance', 'Finance & Money', 'Banking'),
    CatalogApp('tapnpay', 'Tapnpay', Color(0xFF0EA5E9), Icons.credit_card, 'finance', 'Finance & Money', 'Payments'),
    CatalogApp('splitbill', 'Splitbill', Color(0xFFDB2777), Icons.receipt_long, 'finance', 'Finance & Money', 'Payments'),
    CatalogApp('growfund', 'Growfund', Color(0xFF16A34A), Icons.trending_up, 'finance', 'Finance & Money', 'Investing'),
    CatalogApp('portfoliq', 'Portfoliq', Color(0xFFF97316), Icons.pie_chart_outline, 'finance', 'Finance & Money', 'Investing'),
    CatalogApp('coinbank', 'Coinbank', Color(0xFFF59E0B), Icons.savings_outlined, 'finance', 'Finance & Money', 'Budgeting'),
    CatalogApp('budgetly', 'Budgetly', Color(0xFF475569), Icons.monetization_on_outlined, 'finance', 'Finance & Money', 'Budgeting'),
    CatalogApp('walletto', 'Walletto', Color(0xFF7C3AED), Icons.account_balance_wallet_outlined, 'finance', 'Finance & Money', 'Wallets'),
    CatalogApp('zingpay', 'Zingpay', Color(0xFFFACC15), Icons.bolt, 'finance', 'Finance & Money', 'Wallets'),
  ]),
  CatalogSection('shopping', 'Shopping & Commerce', [
    CatalogApp('bazaarbay', 'Bazaarbay', Color(0xFFEA580C), Icons.storefront_outlined, 'shopping', 'Shopping & Commerce', 'Marketplaces'),
    CatalogApp('swapshop', 'Swapshop', Color(0xFF0891B2), Icons.inventory_2_outlined, 'shopping', 'Shopping & Commerce', 'Marketplaces'),
    CatalogApp('megastore', 'Megastore', Color(0xFFDB2777), Icons.shopping_bag_outlined, 'shopping', 'Shopping & Commerce', 'Retail'),
    CatalogApp('quickcart', 'Quickcart', Color(0xFF16A34A), Icons.shopping_cart_outlined, 'shopping', 'Shopping & Commerce', 'Retail'),
    CatalogApp('forkspeed', 'Forkspeed', Color(0xFFF97316), Icons.pedal_bike, 'shopping', 'Shopping & Commerce', 'Food delivery'),
    CatalogApp('snackdash', 'Snackdash', Color(0xFFE11D48), Icons.local_shipping_outlined, 'shopping', 'Shopping & Commerce', 'Food delivery'),
    CatalogApp('threadly', 'Threadly', Color(0xFF2563EB), Icons.checkroom, 'shopping', 'Shopping & Commerce', 'Fashion'),
    CatalogApp('runwayly', 'Runwayly', Color(0xFFF472B6), Icons.content_cut, 'shopping', 'Shopping & Commerce', 'Fashion'),
    CatalogApp('handyy', 'Handyy', Color(0xFF0891B2), Icons.build_outlined, 'shopping', 'Shopping & Commerce', 'Services'),
    CatalogApp('hirehub', 'Hirehub', Color(0xFF78350F), Icons.handyman_outlined, 'shopping', 'Shopping & Commerce', 'Services'),
  ]),
  CatalogSection('travel', 'Travel & Transport', [
    CatalogApp('pathfindr', 'Pathfindr', Color(0xFF0E7490), Icons.navigation_outlined, 'travel', 'Travel & Transport', 'Maps & navigation'),
    CatalogApp('wandermap', 'Wandermap', Color(0xFF059669), Icons.map_outlined, 'travel', 'Travel & Transport', 'Maps & navigation'),
    CatalogApp('zippyride', 'Zippyride', Color(0xFFFACC15), Icons.directions_car_outlined, 'travel', 'Travel & Transport', 'Ride-hailing'),
    CatalogApp('cruize', 'Cruize', Color(0xFFDB2777), Icons.alt_route, 'travel', 'Travel & Transport', 'Ride-hailing'),
    CatalogApp('metropass', 'Metropass', Color(0xFF1D4ED8), Icons.train, 'travel', 'Travel & Transport', 'Public transport'),
    CatalogApp('busline', 'Busline', Color(0xFF0EA5E9), Icons.directions_bus_outlined, 'travel', 'Travel & Transport', 'Public transport'),
    CatalogApp('skysail', 'Skysail', Color(0xFF2563EB), Icons.flight, 'travel', 'Travel & Transport', 'Flights'),
    CatalogApp('jetsetter', 'Jetsetter', Color(0xFFF59E0B), Icons.luggage, 'travel', 'Travel & Transport', 'Flights'),
    CatalogApp('stayinn', 'Stayinn', Color(0xFF7C3AED), Icons.hotel, 'travel', 'Travel & Transport', 'Hotels'),
    CatalogApp('tripweaver', 'Tripweaver', Color(0xFFF97316), Icons.explore_outlined, 'travel', 'Travel & Transport', 'Travel planning'),
  ]),
  CatalogSection('health', 'Health & Fitness', [
    CatalogApp('flexr', 'Flexr', Color(0xFFFF9F0A), Icons.fitness_center, 'health', 'Health & Fitness', 'Exercise'),
    CatalogApp('stride', 'Stride', Color(0xFF60A5FA), Icons.directions_walk, 'health', 'Health & Fitness', 'Exercise'),
    CatalogApp('macronutri', 'Macronutri', Color(0xFF16A34A), Icons.restaurant_outlined, 'health', 'Health & Fitness', 'Nutrition'),
    CatalogApp('hydrate', 'Hydrate', Color(0xFF0EA5E9), Icons.water_drop_outlined, 'health', 'Health & Fitness', 'Nutrition'),
    CatalogApp('zenwave', 'Zenwave', Color(0xFF8B5CF6), Icons.psychology_outlined, 'health', 'Health & Fitness', 'Meditation'),
    CatalogApp('breatheo', 'Breatheo', Color(0xFF06B6D4), Icons.air, 'health', 'Health & Fitness', 'Meditation'),
    CatalogApp('medcheck', 'Medcheck', Color(0xFFEF4444), Icons.medical_services_outlined, 'health', 'Health & Fitness', 'Medical'),
    CatalogApp('pillpal', 'Pillpal', Color(0xFFF43F5E), Icons.medication_outlined, 'health', 'Health & Fitness', 'Medical'),
    CatalogApp('dreamtrack', 'Dreamtrack', Color(0xFF7C3AED), Icons.nightlight_outlined, 'health', 'Health & Fitness', 'Sleep'),
    CatalogApp('slumberly', 'Slumberly', Color(0xFF4F46E5), Icons.bed_outlined, 'health', 'Health & Fitness', 'Sleep'),
  ]),
  CatalogSection('lifestyle', 'Lifestyle', [
    CatalogApp('recipebox', 'Recipebox', Color(0xFFEA580C), Icons.restaurant, 'lifestyle', 'Lifestyle', 'Food & recipes'),
    CatalogApp('simmersoup', 'Simmersoup', Color(0xFFF59E0B), Icons.ramen_dining, 'lifestyle', 'Lifestyle', 'Food & recipes'),
    CatalogApp('havenest', 'Havenest', Color(0xFF16A34A), Icons.home_outlined, 'lifestyle', 'Lifestyle', 'Home'),
    CatalogApp('tidyly', 'Tidyly', Color(0xFFF472B6), Icons.auto_awesome, 'lifestyle', 'Lifestyle', 'Home'),
    CatalogApp('glowup', 'Glowup', Color(0xFFFF2D55), Icons.local_florist_outlined, 'lifestyle', 'Lifestyle', 'Fashion & beauty'),
    CatalogApp('mirrormuse', 'Mirrormuse', Color(0xFF8B5CF6), Icons.brush_outlined, 'lifestyle', 'Lifestyle', 'Fashion & beauty'),
    CatalogApp('lovelens', 'Lovelens', Color(0xFFF43F5E), Icons.favorite_border, 'lifestyle', 'Lifestyle', 'Dating & relationships'),
    CatalogApp('bondly', 'Bondly', Color(0xFFDB2777), Icons.favorite_outline, 'lifestyle', 'Lifestyle', 'Dating & relationships'),
    CatalogApp('nests', 'Nests', Color(0xFFFDE68A), Icons.child_care, 'lifestyle', 'Lifestyle', 'Parenting'),
    CatalogApp('craftcove', 'Craftcove', Color(0xFF0EA5E9), Icons.category_outlined, 'lifestyle', 'Lifestyle', 'Hobbies'),
  ]),
  CatalogSection('news', 'News & Information', [
    CatalogApp('headlines24', 'Headlines24', Color(0xFFDC2626), Icons.newspaper, 'news', 'News & Information', 'News'),
    CatalogApp('scooppress', 'Scooppress', Color(0xFFEA580C), Icons.radio, 'news', 'News & Information', 'News'),
    CatalogApp('skycast', 'Skycast', Color(0xFF0EA5E9), Icons.wb_cloudy_outlined, 'news', 'News & Information', 'Weather'),
    CatalogApp('raincheck', 'Raincheck', Color(0xFF3B82F6), Icons.beach_access, 'news', 'News & Information', 'Weather'),
    CatalogApp('findit', 'Findit', Color(0xFF1E293B), Icons.search, 'news', 'News & Information', 'Search'),
    CatalogApp('whoogle', 'Whoogle', Color(0xFF065F46), Icons.public, 'news', 'News & Information', 'Search'),
    CatalogApp('encyclo', 'Encyclo', Color(0xFF3F6212), Icons.menu_book_outlined, 'news', 'News & Information', 'Reference'),
    CatalogApp('atlasly', 'Atlasly', Color(0xFFB91C1C), Icons.place_outlined, 'news', 'News & Information', 'Reference'),
    CatalogApp('glossely', 'Glossely', Color(0xFFDB2777), Icons.auto_stories_outlined, 'news', 'News & Information', 'Magazines'),
    CatalogApp('pagespin', 'Pagespin', Color(0xFFF59E0B), Icons.star_outline, 'news', 'News & Information', 'Magazines'),
  ]),
  CatalogSection('utilities', 'Utilities & Tools', [
    CatalogApp('numly', 'Numly', Color(0xFF334155), Icons.calculate, 'utilities', 'Utilities & Tools', 'Calculators'),
    CatalogApp('unitvert', 'Unitvert', Color(0xFF0F766E), Icons.balance, 'utilities', 'Utilities & Tools', 'Calculators'),
    CatalogApp('filenest', 'Filenest', Color(0xFFF59E0B), Icons.folder_outlined, 'utilities', 'Utilities & Tools', 'File management'),
    CatalogApp('zipkeeper', 'Zipkeeper', Color(0xFFEA580C), Icons.folder_open, 'utilities', 'Utilities & Tools', 'File management'),
    CatalogApp('scanr', 'Scanr', Color(0xFF1D4ED8), Icons.document_scanner_outlined, 'utilities', 'Utilities & Tools', 'Scanning'),
    CatalogApp('docucapture', 'Docucapture', Color(0xFF374151), Icons.photo_camera_outlined, 'utilities', 'Utilities & Tools', 'Scanning'),
    CatalogApp('keypass', 'Keypass', Color(0xFFFBBF24), Icons.key_outlined, 'utilities', 'Utilities & Tools', 'Password managers'),
    CatalogApp('ciphersafe', 'Ciphersafe', Color(0xFF312E81), Icons.lock_outline, 'utilities', 'Utilities & Tools', 'Password managers'),
    CatalogApp('devicetune', 'Devicetune', Color(0xFF64748B), Icons.memory, 'utilities', 'Utilities & Tools', 'Device utilities'),
    CatalogApp('askly', 'Askly', Color(0xFF8B5CF6), Icons.auto_awesome, 'utilities', 'Utilities & Tools', 'AI assistants'),
  ]),
  CatalogSection('business', 'Business & Professional', [
    CatalogApp('pipelinr', 'Pipelinr', Color(0xFF2563EB), Icons.groups_outlined, 'business', 'Business & Professional', 'CRM'),
    CatalogApp('contactly', 'Contactly', Color(0xFF0E7490), Icons.contact_page_outlined, 'business', 'Business & Professional', 'CRM'),
    CatalogApp('balancebook', 'Balancebook', Color(0xFF166534), Icons.account_balance, 'business', 'Business & Professional', 'Accounting'),
    CatalogApp('invoicely', 'Invoicely', Color(0xFF0F766E), Icons.description_outlined, 'business', 'Business & Professional', 'Accounting'),
    CatalogApp('salespitch', 'Salespitch', Color(0xFF16A34A), Icons.trending_up, 'business', 'Business & Professional', 'Sales'),
    CatalogApp('leadline', 'Leadline', Color(0xFFF97316), Icons.track_changes, 'business', 'Business & Professional', 'Sales'),
    CatalogApp('campaignly', 'Campaignly', Color(0xFFFF375F), Icons.campaign_outlined, 'business', 'Business & Professional', 'Marketing'),
    CatalogApp('brandwave', 'Brandwave', Color(0xFF7C3AED), Icons.verified_outlined, 'business', 'Business & Professional', 'Marketing'),
    CatalogApp('peopledeck', 'Peopledeck', Color(0xFF0891B2), Icons.manage_accounts_outlined, 'business', 'Business & Professional', 'HR'),
    CatalogApp('suitely', 'Suitely', Color(0xFF475569), Icons.apartment, 'business', 'Business & Professional', 'Enterprise tools'),
  ]),
  CatalogSection('government', 'Government & Civic', [
    CatalogApp('govportal', 'Govportal', Color(0xFF334155), Icons.account_balance, 'government', 'Government & Civic', 'Government services'),
    CatalogApp('formdesk', 'Formdesk', Color(0xFF1E40AF), Icons.description_outlined, 'government', 'Government & Civic', 'Government services'),
    CatalogApp('votenow', 'Votenow', Color(0xFF2563EB), Icons.how_to_vote, 'government', 'Government & Civic', 'Voting & elections'),
    CatalogApp('ballotbox', 'Ballotbox', Color(0xFF0F766E), Icons.check_circle_outline, 'government', 'Government & Civic', 'Voting & elections'),
    CatalogApp('transitline', 'Transitline', Color(0xFF0EA5E9), Icons.directions_bus_outlined, 'government', 'Government & Civic', 'Public transport'),
    CatalogApp('metrolink', 'Metrolink', Color(0xFF1D4ED8), Icons.train, 'government', 'Government & Civic', 'Public transport'),
    CatalogApp('sosnow', 'Sosnow', Color(0xFFDC2626), Icons.campaign_outlined, 'government', 'Government & Civic', 'Emergency services'),
    CatalogApp('respondr', 'Respondr', Color(0xFFB91C1C), Icons.local_hospital_outlined, 'government', 'Government & Civic', 'Emergency services'),
    CatalogApp('civicshare', 'Civicshare', Color(0xFF059669), Icons.favorite_outline, 'government', 'Government & Civic', 'Community services'),
    CatalogApp('townsquare', 'Townsquare', Color(0xFFF59E0B), Icons.flag_outlined, 'government', 'Government & Civic', 'Community services'),
  ]),
  CatalogSection('smarthome', 'Home & Smart Devices', [
    CatalogApp('homelink', 'Homelink', Color(0xFF0EA5E9), Icons.wifi, 'smarthome', 'Home & Smart Devices', 'Smart home'),
    CatalogApp('scenectl', 'Scenectl', Color(0xFFF59E0B), Icons.lightbulb_outline, 'smarthome', 'Home & Smart Devices', 'Smart home'),
    CatalogApp('guardgate', 'Guardgate', Color(0xFF166534), Icons.verified_user_outlined, 'smarthome', 'Home & Smart Devices', 'Security'),
    CatalogApp('sentryhome', 'Sentryhome', Color(0xFF1E293B), Icons.visibility_outlined, 'smarthome', 'Home & Smart Devices', 'Security'),
    CatalogApp('appliancehub', 'Appliancehub', Color(0xFF0F766E), Icons.power, 'smarthome', 'Home & Smart Devices', 'Appliances'),
    CatalogApp('washwizard', 'Washwizard', Color(0xFF2563EB), Icons.local_laundry_service, 'smarthome', 'Home & Smart Devices', 'Appliances'),
    CatalogApp('wattly', 'Wattly', Color(0xFFFACC15), Icons.bolt, 'smarthome', 'Home & Smart Devices', 'Energy'),
    CatalogApp('solartrack', 'Solartrack', Color(0xFFF59E0B), Icons.wb_sunny_outlined, 'smarthome', 'Home & Smart Devices', 'Energy'),
    CatalogApp('nestcam', 'Nestcam', Color(0xFFDC2626), Icons.videocam_outlined, 'smarthome', 'Home & Smart Devices', 'Cameras'),
    CatalogApp('peephole', 'Peephole', Color(0xFF374151), Icons.photo_camera_outlined, 'smarthome', 'Home & Smart Devices', 'Cameras'),
  ]),
  CatalogSection('sports', 'Sports & Recreation', [
    CatalogApp('matchday', 'Matchday', Color(0xFFF59E0B), Icons.emoji_events_outlined, 'sports', 'Sports & Recreation', 'Sports'),
    CatalogApp('scorezone', 'Scorezone', Color(0xFF16A34A), Icons.flag_outlined, 'sports', 'Sports & Recreation', 'Sports'),
    CatalogApp('gymcrew', 'Gymcrew', Color(0xFFFF9F0A), Icons.fitness_center, 'sports', 'Sports & Recreation', 'Fitness communities'),
    CatalogApp('runclub', 'Runclub', Color(0xFF60A5FA), Icons.directions_walk, 'sports', 'Sports & Recreation', 'Fitness communities'),
    CatalogApp('trailsy', 'Trailsy', Color(0xFF166534), Icons.park_outlined, 'sports', 'Sports & Recreation', 'Outdoor activities'),
    CatalogApp('fishhook', 'Fishhook', Color(0xFF0891B2), Icons.set_meal, 'sports', 'Sports & Recreation', 'Outdoor activities'),
    CatalogApp('ticketwave', 'Ticketwave', Color(0xFFDB2777), Icons.confirmation_number_outlined, 'sports', 'Sports & Recreation', 'Events'),
    CatalogApp('livestage', 'Livestage', Color(0xFF7C3AED), Icons.mic_none, 'sports', 'Sports & Recreation', 'Events'),
    CatalogApp('fantasyleague', 'Fantasyleague', Color(0xFFA78BFA), Icons.casino_outlined, 'sports', 'Sports & Recreation', 'Fantasy sports'),
    CatalogApp('rosterr', 'Rosterr', Color(0xFFF97316), Icons.star_outline, 'sports', 'Sports & Recreation', 'Fantasy sports'),
  ]),
  CatalogSection('religion', 'Religion & Spirituality', [
    CatalogApp('congregation', 'Congregation', Color(0xFF1E40AF), Icons.groups_outlined, 'religion', 'Religion & Spirituality', 'Religious communities'),
    CatalogApp('faithcircle', 'Faithcircle', Color(0xFFB91C1C), Icons.church, 'religion', 'Religion & Spirituality', 'Religious communities'),
    CatalogApp('versely', 'Versely', Color(0xFF365314), Icons.auto_stories_outlined, 'religion', 'Religion & Spirituality', 'Scripture'),
    CatalogApp('chapterlight', 'Chapterlight', Color(0xFF0F766E), Icons.menu_book_outlined, 'religion', 'Religion & Spirituality', 'Scripture'),
    CatalogApp('prayzone', 'Prayzone', Color(0xFFF59E0B), Icons.wb_twilight, 'religion', 'Religion & Spirituality', 'Prayer & meditation'),
    CatalogApp('quiettime', 'Quiettime', Color(0xFF7C3AED), Icons.nightlight_outlined, 'religion', 'Religion & Spirituality', 'Prayer & meditation'),
    CatalogApp('hymnly', 'Hymnly', Color(0xFF8B5CF6), Icons.music_note, 'religion', 'Religion & Spirituality', 'Scripture'),
    CatalogApp('retreatly', 'Retreatly', Color(0xFF16A34A), Icons.energy_savings_leaf, 'religion', 'Religion & Spirituality', 'Spiritual education'),
    CatalogApp('soulschool', 'Soulschool', Color(0xFF7C2D12), Icons.school_outlined, 'religion', 'Religion & Spirituality', 'Spiritual education'),
    CatalogApp('pathwayz', 'Pathwayz', Color(0xFF0891B2), Icons.explore_outlined, 'religion', 'Religion & Spirituality', 'Spiritual education'),
  ]),
  CatalogSection('kids', 'Kids & Family', [
    CatalogApp('toonville', 'Toonville', Color(0xFF7C3AED), Icons.tv, 'kids', 'Kids & Family', 'Children\'s entertainment'),
    CatalogApp('playland', 'Playland', Color(0xFFF97316), Icons.widgets_outlined, 'kids', 'Kids & Family', 'Children\'s entertainment'),
    CatalogApp('storytime', 'Storytime', Color(0xFFF59E0B), Icons.auto_stories_outlined, 'kids', 'Kids & Family', 'Children\'s entertainment'),
    CatalogApp('abctown', 'Abctown', Color(0xFF16A34A), Icons.extension_outlined, 'kids', 'Kids & Family', 'Learning'),
    CatalogApp('mathlings', 'Mathlings', Color(0xFF2563EB), Icons.calculate_outlined, 'kids', 'Kids & Family', 'Learning'),
    CatalogApp('familyboard', 'Familyboard', Color(0xFF059669), Icons.groups_outlined, 'kids', 'Kids & Family', 'Family coordination'),
    CatalogApp('chorechart', 'Chorechart', Color(0xFF0F766E), Icons.checklist, 'kids', 'Kids & Family', 'Family coordination'),
    CatalogApp('kidkeeper', 'Kidkeeper', Color(0xFFFDE68A), Icons.child_care, 'kids', 'Kids & Family', 'Family coordination'),
    CatalogApp('safeblock', 'Safeblock', Color(0xFF166534), Icons.verified_user_outlined, 'kids', 'Kids & Family', 'Parental controls'),
    CatalogApp('screenlimit', 'Screenlimit', Color(0xFF312E81), Icons.lock_outline, 'kids', 'Kids & Family', 'Parental controls'),
  ]),
  CatalogSection('dating', 'Dating & Relationships', [
    CatalogApp('blazee', 'Blazee', Color(0xFFFF375F), Icons.local_fire_department_outlined, 'dating', 'Dating & Relationships', 'Dating'),
    CatalogApp('cupidly', 'Cupidly', Color(0xFFF43F5E), Icons.favorite_border, 'dating', 'Dating & Relationships', 'Dating'),
    CatalogApp('vibechat', 'Vibechat', Color(0xFF22C55E), Icons.chat_bubble_outline, 'dating', 'Dating & Relationships', 'Dating'),
    CatalogApp('datelens', 'Datelens', Color(0xFF7C3AED), Icons.visibility_outlined, 'dating', 'Dating & Relationships', 'Dating'),
    CatalogApp('matchpair', 'Matchpair', Color(0xFFDB2777), Icons.favorite_outline, 'dating', 'Dating & Relationships', 'Matchmaking'),
    CatalogApp('soulmatehq', 'Soulmatehq', Color(0xFFFFD60A), Icons.star_outline, 'dating', 'Dating & Relationships', 'Matchmaking'),
    CatalogApp('couplecare', 'Couplecare', Color(0xFFDB2777), Icons.card_giftcard, 'dating', 'Dating & Relationships', 'Relationship tools'),
    CatalogApp('anniverly', 'Anniverly', Color(0xFFFF3B30), Icons.calendar_month, 'dating', 'Dating & Relationships', 'Relationship tools'),
    CatalogApp('mixr', 'Mixr', Color(0xFF8B5CF6), Icons.groups_outlined, 'dating', 'Dating & Relationships', 'Social discovery'),
    CatalogApp('nearbyy', 'Nearbyy', Color(0xFF0EA5E9), Icons.place_outlined, 'dating', 'Dating & Relationships', 'Social discovery'),
  ]),
  CatalogSection('specialised', 'Specialised / Professional Tools', [
    CatalogApp('slatepro', 'Slatepro', Color(0xFF111827), Icons.movie_outlined, 'specialised', 'Specialised / Professional Tools', 'Film & production'),
    CatalogApp('callsheet', 'Callsheet', Color(0xFFB91C1C), Icons.description_outlined, 'specialised', 'Specialised / Professional Tools', 'Film & production'),
    CatalogApp('forcecalc', 'Forcecalc', Color(0xFF1D4ED8), Icons.straighten, 'specialised', 'Specialised / Professional Tools', 'Engineering'),
    CatalogApp('cadsmith', 'Cadsmith', Color(0xFF334155), Icons.inventory_outlined, 'specialised', 'Specialised / Professional Tools', 'Engineering'),
    CatalogApp('planchek', 'Planchek', Color(0xFF0F766E), Icons.architecture, 'specialised', 'Specialised / Professional Tools', 'Architecture'),
    CatalogApp('labbench', 'Labbench', Color(0xFF0D9488), Icons.science_outlined, 'specialised', 'Specialised / Professional Tools', 'Science'),
    CatalogApp('researchr', 'Researchr', Color(0xFF365314), Icons.biotech, 'specialised', 'Specialised / Professional Tools', 'Science'),
    CatalogApp('lawdesk', 'Lawdesk', Color(0xFF1E293B), Icons.balance, 'specialised', 'Specialised / Professional Tools', 'Legal'),
    CatalogApp('buildsite', 'Buildsite', Color(0xFFF59E0B), Icons.engineering_outlined, 'specialised', 'Specialised / Professional Tools', 'Construction'),
    CatalogApp('rivet', 'Rivet', Color(0xFF57534E), Icons.handyman_outlined, 'specialised', 'Specialised / Professional Tools', 'Industry-specific software'),
  ]),
];

CatalogApp? catalogAppById(String id) {
  for (final section in mockCatalog) {
    for (final app in section.apps) {
      if (app.id == id) return app;
    }
  }
  return null;
}

/// Home-screen icon for a real phone app, or a catalog app added from the library.
PropApp? homeAppFor(String id) {
  final known = propAppById(id);
  if (known != null) return known;
  final mock = catalogAppById(id);
  if (mock == null) return null;
  return PropApp(mock.id, mock.label, mock.color, mock.icon);
}

