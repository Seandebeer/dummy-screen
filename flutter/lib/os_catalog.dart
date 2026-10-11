import 'package:flutter/material.dart';

import 'models.dart';

/// Mirror of the Base44 OS settings catalogs: skins, themes, wallpapers,
/// languages, and the lock methods those screens write onto a device.
class OsSkin {
  const OsSkin({
    required this.id,
    required this.era,
    required this.name,
    required this.desc,
    required this.preset,
    required this.preview,
  });

  final String id;
  final String era;
  final String name;
  final String desc;
  final String preset;
  final List<Color> preview;
}

class OsThemeChoice {
  const OsThemeChoice({
    required this.id,
    required this.name,
    required this.light,
    required this.preset,
  });

  final String id;
  final String name;
  final bool light;
  final String preset;
}

class BgPreset {
  const BgPreset({
    required this.id,
    required this.name,
    required this.dark,
    required this.light,
  });

  final String id;
  final String name;
  final List<Color> dark;
  final List<Color> light;
}

class OsLanguage {
  const OsLanguage(this.code, this.native, {this.rtl = false});

  final String code;
  final String native;
  final bool rtl;
}

class OsCopy {
  const OsCopy({
    required this.settings,
    required this.themes,
    required this.background,
    required this.dialCodes,
    required this.language,
    this.answerCalls = 'Answer Calls',
    this.answerTap = 'Button Tap',
    this.answerSwipe = 'Swipe',
  });

  final String settings;
  final String themes;
  final String background;
  final String dialCodes;
  final String language;
  final String answerCalls;
  final String answerTap;
  final String answerSwipe;
}

class LockMethod {
  const LockMethod(this.id, this.label, this.hint, this.icon);

  final String id;
  final String label;
  final String hint;
  final IconData icon;
}

enum SkinChrome { modern, classic, tiles, android }

const osSkins = <OsSkin>[
  OsSkin(
    id: 'modern',
    era: 'modern',
    name: 'Current OS',
    desc: 'Modern premium look - squircle icons, glass dock, hub status bar.',
    preset: 'default',
    preview: [Color(0xFF1A1D2E), Color(0xFF0A0B14), Color(0xFF000000)],
  ),
  OsSkin(
    id: 'iphoneos',
    era: 'legacy',
    name: 'iPhone OS',
    desc: '2007 original iPhone. Glossy icons and a metal dock.',
    preset: 'iphoneos',
    preview: [Color(0xFF2A2A2E), Color(0xFF050506)],
  ),
  OsSkin(
    id: 'ios6',
    era: 'legacy',
    name: 'iOS 6',
    desc: '2012. Glossy icons, water wallpaper, and a glass dock.',
    preset: 'linen',
    preview: [Color(0xFF7EC8E3), Color(0xFF0E3A5A)],
  ),
  OsSkin(
    id: 'ios7',
    era: 'legacy',
    name: 'iOS 7',
    desc: '2013. Flat icons and a translucent dock.',
    preset: 'ios7',
    preview: [Color(0xFF3D6EA8), Color(0xFF0C1A33)],
  ),
  OsSkin(
    id: 'winphone',
    era: 'legacy',
    name: 'Windows Phone',
    desc: '2010. Metro live tiles and a three-button bar.',
    preset: 'wp',
    preview: [Color(0xFF000000), Color(0xFF1BA1E2)],
  ),
  OsSkin(
    id: 'holo',
    era: 'legacy',
    name: 'Android Holo',
    desc: '2011. Search, a clock, and a five-icon dock.',
    preset: 'holo',
    preview: [Color(0xFF2F80ED), Color(0xFF4A148C)],
  ),
  OsSkin(
    id: 'webos',
    era: 'legacy',
    name: 'webOS',
    desc: '2009. A launcher grid and a quick-launch dock.',
    preset: 'webos',
    preview: [Color(0xFF8D8A7A), Color(0xFF4E5248)],
  ),
  OsSkin(
    id: 'belle',
    era: 'legacy',
    name: 'Nokia Belle',
    desc: '2011. Widgets, name plates, and a status bar.',
    preset: 'belle',
    preview: [Color(0xFFF6B13A), Color(0xFF1B4F8A)],
  ),
  OsSkin(
    id: 'android',
    era: 'modern',
    name: 'Current Android',
    desc: 'Ribbon wallpaper, weather and Start, search, and a three-button bar.',
    preset: 'droid',
    preview: [Color(0xFFC8C4C0), Color(0xFFE6D5C4), Color(0xFF3C3840)],
  ),
];

const osThemes = <OsThemeChoice>[
  OsThemeChoice(id: 'graphite', name: 'Graphite', light: false, preset: 'default'),
  OsThemeChoice(id: 'ivory', name: 'Ivory', light: true, preset: 'mono'),
  OsThemeChoice(id: 'midnight', name: 'Midnight', light: false, preset: 'midnight'),
  OsThemeChoice(id: 'sunset', name: 'Sunset', light: true, preset: 'sunset'),
];

const bgPresets = <BgPreset>[
  BgPreset(
    id: 'default',
    name: 'Default',
    dark: [Color(0xFF1A1D2E), Color(0xFF0A0B14), Color(0xFF000000)],
    light: [Color(0xFFDFE3F0), Color(0xFFEEF1F8), Color(0xFFFFFFFF)],
  ),
  BgPreset(
    id: 'midnight',
    name: 'Midnight',
    dark: [Color(0xFF0B1030), Color(0xFF1A1040), Color(0xFF02030A)],
    light: [Color(0xFFC9D4FF), Color(0xFFE4E9FF), Color(0xFFFFFFFF)],
  ),
  BgPreset(
    id: 'sunset',
    name: 'Sunset',
    dark: [Color(0xFF2B1A3D), Color(0xFF6B2C56), Color(0xFF14090F)],
    light: [Color(0xFFFFD9A0), Color(0xFFFFB1C9), Color(0xFFFFF5EA)],
  ),
  BgPreset(
    id: 'mono',
    name: 'Mono',
    dark: [Color(0xFF0A0A0A), Color(0xFF0A0A0A)],
    light: [Color(0xFFF2F2F7), Color(0xFFF2F2F7)],
  ),
  BgPreset(
    id: 'aqua',
    name: 'OS 5',
    dark: [Color(0xFF4A6A8C), Color(0xFF6A8AA3), Color(0xFF8CA6B4)],
    light: [Color(0xFFC7D6E4), Color(0xFFE2EBF2), Color(0xFFF5F8FA)],
  ),
  BgPreset(
    id: 'droid',
    name: 'Tint',
    dark: [Color(0xFF101418), Color(0xFF14202A), Color(0xFF0A0E12)],
    light: [Color(0xFFD3E4F5), Color(0xFFCFE8D8), Color(0xFFF4F7FA)],
  ),
  BgPreset(
    id: 'iphoneos',
    name: 'iPhone OS',
    dark: [Color(0xFF1A222D), Color(0xFF0B0E14)],
    light: [Color(0xFFE9E9EE), Color(0xFFFFFFFF)],
  ),
  BgPreset(
    id: 'linen',
    name: 'Linen',
    dark: [Color(0xFF43434A), Color(0xFF2A2A30), Color(0xFF191A1F)],
    light: [Color(0xFFD8D5CC), Color(0xFFEFECE4)],
  ),
  BgPreset(
    id: 'ios7',
    name: 'OS 7',
    dark: [Color(0xFF123253), Color(0xFF0B1E38), Color(0xFF050D1A)],
    light: [Color(0xFFA7C9EA), Color(0xFFD6E7F8), Color(0xFFFFFFFF)],
  ),
  BgPreset(
    id: 'wp',
    name: 'Windows',
    dark: [Color(0xFF111111), Color(0xFF111111)],
    light: [Color(0xFF0A0A0A), Color(0xFF0A0A0A)],
  ),
  BgPreset(
    id: 'bb',
    name: 'BlackBerry',
    dark: [Color(0xFF101B2A), Color(0xFF060B13)],
    light: [Color(0xFFD5DDEA), Color(0xFFF4F7FB)],
  ),
  BgPreset(
    id: 'holo',
    name: 'Holo',
    dark: [Color(0xFF0D1420), Color(0xFF090C10), Color(0xFF05080C)],
    light: [Color(0xFFB8DBE8), Color(0xFFE8F4F8)],
  ),
  BgPreset(
    id: 'material',
    name: 'Material',
    dark: [Color(0xFF263238), Color(0xFF11181C)],
    light: [Color(0xFFCFE0E8), Color(0xFFF2F6F8)],
  ),
  BgPreset(
    id: 'webos',
    name: 'webOS',
    dark: [Color(0xFF8D8A7A), Color(0xFF4E5248)],
    light: [Color(0xFFCFD6E4), Color(0xFFEEF1F8)],
  ),
  BgPreset(
    id: 'belle',
    name: 'Belle',
    dark: [Color(0xFFF6B13A), Color(0xFF1B4F8A)],
    light: [Color(0xFFFFE0B2), Color(0xFF90CAF9)],
  ),
];

const osLanguages = <OsLanguage>[
  OsLanguage('en', 'English'),
  OsLanguage('es', 'Español'),
  OsLanguage('pt', 'Português'),
  OsLanguage('fr', 'Français'),
  OsLanguage('de', 'Deutsch'),
  OsLanguage('ja', '日本語'),
  OsLanguage('ko', '한국어'),
  OsLanguage('zh', '中文（简体）'),
  OsLanguage('ar', 'العربية', rtl: true),
  OsLanguage('hi', 'हिन्दी'),
  OsLanguage('it', 'Italiano'),
  OsLanguage('id', 'Bahasa Indonesia'),
  OsLanguage('tr', 'Türkçe'),
  OsLanguage('nl', 'Nederlands'),
  OsLanguage('pl', 'Polski'),
  OsLanguage('th', 'ไทย'),
  OsLanguage('vi', 'Tiếng Việt'),
  OsLanguage('uk', 'Українська'),
  OsLanguage('sv', 'Svenska'),
  OsLanguage('el', 'Ελληνικά'),
];

const lockMethods = <LockMethod>[
  LockMethod('none', 'Skin Default', 'era-accurate for this skin', Icons.auto_awesome),
  LockMethod('off', 'None', 'opens on the home screen', Icons.home_outlined),
  LockMethod('slide', 'Slide to Unlock', 'drag the slider right', Icons.keyboard_double_arrow_right),
  LockMethod('ring', 'Unlock Ring', 'drag the lock into the ring', Icons.album_outlined),
  LockMethod('passcode', 'Passcode', '4-digit keypad', Icons.tag),
  LockMethod('pattern', 'Pattern', 'connect-the-dots', Icons.grid_3x3),
  LockMethod('face', 'Face Scan', 'scan animation', Icons.face_retouching_natural),
  LockMethod('fingerprint', 'Fingerprint', 'press & hold sensor', Icons.fingerprint),
  LockMethod('swipe', 'Swipe Up', 'always swipe up', Icons.keyboard_arrow_up),
];

const _copies = <String, OsCopy>{
  'en': OsCopy(
    settings: 'Settings',
    themes: 'Themes',
    background: 'Wallpaper',
    dialCodes: 'Contacts Dial Codes',
    language: 'Language',
  ),
  'es': OsCopy(
    settings: 'Ajustes',
    themes: 'Temas',
    background: 'Fondo de pantalla',
    dialCodes: 'Códigos de contactos',
    language: 'Idioma',
  ),
  'pt': OsCopy(
    settings: 'Ajustes',
    themes: 'Temas',
    background: 'Papel de parede',
    dialCodes: 'Códigos dos contatos',
    language: 'Idioma',
  ),
  'fr': OsCopy(
    settings: 'Réglages',
    themes: 'Thèmes',
    background: "Fond d'écran",
    dialCodes: 'Codes des contacts',
    language: 'Langue',
  ),
  'de': OsCopy(
    settings: 'Einstellungen',
    themes: 'Designs',
    background: 'Hintergrundbild',
    dialCodes: 'Wählcodes für Kontakte',
    language: 'Sprache',
  ),
  'ja': OsCopy(
    settings: '設定',
    themes: 'テーマ',
    background: '壁紙',
    dialCodes: '連絡先の発信コード',
    language: '言語',
  ),
  'ko': OsCopy(
    settings: '설정',
    themes: '테마',
    background: '배경화면',
    dialCodes: '연락처 다이얼 코드',
    language: '언어',
  ),
  'zh': OsCopy(
    settings: '设置',
    themes: '主题',
    background: '壁纸',
    dialCodes: '联系人拨号代码',
    language: '语言',
  ),
  'ar': OsCopy(
    settings: 'الإعدادات',
    themes: 'السمات',
    background: 'الخلفية',
    dialCodes: 'رموز اتصال جهات الاتصال',
    language: 'اللغة',
  ),
  'hi': OsCopy(
    settings: 'सेटिंग्स',
    themes: 'थीम',
    background: 'वॉलपेपर',
    dialCodes: 'संपर्क डायल कोड',
    language: 'भाषा',
  ),
  'it': OsCopy(
    settings: 'Impostazioni',
    themes: 'Temi',
    background: 'Sfondo',
    dialCodes: 'Prefissi dei contatti',
    language: 'Lingua',
  ),
  'id': OsCopy(
    settings: 'Pengaturan',
    themes: 'Tema',
    background: 'Latar',
    dialCodes: 'Kode kontak',
    language: 'Bahasa',
  ),
  'tr': OsCopy(
    settings: 'Ayarlar',
    themes: 'Temalar',
    background: 'Duvar kağıdı',
    dialCodes: 'Kişi arama kodları',
    language: 'Dil',
  ),
  'nl': OsCopy(
    settings: 'Instellingen',
    themes: "Thema's",
    background: 'Achtergrond',
    dialCodes: 'Contactkiescodes',
    language: 'Taal',
  ),
  'pl': OsCopy(
    settings: 'Ustawienia',
    themes: 'Motywy',
    background: 'Tapeta',
    dialCodes: 'Kody wybierania kontaktów',
    language: 'Język',
  ),
  'th': OsCopy(
    settings: 'การตั้งค่า',
    themes: 'ธีม',
    background: 'วอลเปเปอร์',
    dialCodes: 'รหัสโทรผู้ติดต่อ',
    language: 'ภาษา',
  ),
  'vi': OsCopy(
    settings: 'Cài đặt',
    themes: 'Giao diện',
    background: 'Hình nền',
    dialCodes: 'Mã gọi danh bạ',
    language: 'Ngôn ngữ',
  ),
  'uk': OsCopy(
    settings: 'Налаштування',
    themes: 'Теми',
    background: 'Шпалери',
    dialCodes: 'Коди набору контактів',
    language: 'Мова',
  ),
  'sv': OsCopy(
    settings: 'Inställningar',
    themes: 'Temar',
    background: 'Bakgrund',
    dialCodes: 'Ringkoder för kontakter',
    language: 'Språk',
  ),
  'el': OsCopy(
    settings: 'Ρυθμίσεις',
    themes: 'Θέματα',
    background: 'Ταπετσαρία',
    dialCodes: 'Κωδικοί κλήσης επαφών',
    language: 'Γλώσσα',
  ),
};

/// Six prop contacts per language. English keeps the deck's hero names.
const _contactTables = <String, List<(String, String)>>{
  'en': [
    ('Sarah Chen', '555 0142'),
    ('Marcus Webb', '555 0198'),
    ('Elena Frost', '555 0177'),
    ('David Park', '555 0123'),
    ('Nora Vega', '555 0156'),
    ('Sam Ryder', '555 0119'),
  ],
  'es': [
    ('Alejandro García', '555 0142'),
    ('Lucía Rodríguez', '555 0198'),
    ('Carlos Martínez', '555 0177'),
    ('María López', '555 0123'),
    ('Javier Sánchez', '555 0156'),
    ('Carmen Fernández', '555 0119'),
  ],
  'pt': [
    ('João Silva', '555 0142'),
    ('Ana Santos', '555 0198'),
    ('Pedro Oliveira', '555 0177'),
    ('Beatriz Souza', '555 0123'),
    ('Lucas Costa', '555 0156'),
    ('Carolina Pereira', '555 0119'),
  ],
  'fr': [
    ('Louis Martin', '555 0142'),
    ('Camille Bernard', '555 0198'),
    ('Hugo Dubois', '555 0177'),
    ('Léa Thomas', '555 0123'),
    ('Gabriel Robert', '555 0156'),
    ('Manon Richard', '555 0119'),
  ],
  'de': [
    ('Lukas Müller', '555 0142'),
    ('Emma Schmidt', '555 0198'),
    ('Felix Schneider', '555 0177'),
    ('Hannah Fischer', '555 0123'),
    ('Leon Weber', '555 0156'),
    ('Mia Meyer', '555 0119'),
  ],
  'ja': [
    ('佐藤太郎', '555 0142'),
    ('鈴木花子', '555 0198'),
    ('高橋一郎', '555 0177'),
    ('田中美咲', '555 0123'),
    ('渡辺健太', '555 0156'),
    ('伊藤陽菜', '555 0119'),
  ],
  'ko': [
    ('김민준', '555 0142'),
    ('이서연', '555 0198'),
    ('박도윤', '555 0177'),
    ('최지우', '555 0123'),
    ('정시우', '555 0156'),
    ('강하윤', '555 0119'),
  ],
  'zh': [
    ('王伟', '555 0142'),
    ('李芳', '555 0198'),
    ('张娜', '555 0177'),
    ('刘敏', '555 0123'),
    ('陈静', '555 0156'),
    ('杨丽', '555 0119'),
  ],
  'ar': [
    ('محمد الحسن', '555 0142'),
    ('أحمد المصري', '555 0198'),
    ('فاطمة النجار', '555 0177'),
    ('عمر عبدالله', '555 0123'),
    ('ليلى الخطيب', '555 0156'),
    ('خالد الشريف', '555 0119'),
  ],
  'hi': [
    ('अर्जुन शर्मा', '555 0142'),
    ('प्रिया पटेल', '555 0198'),
    ('राहुल सिंह', '555 0177'),
    ('अनिता कुमार', '555 0123'),
    ('विक्रम गुप्ता', '555 0156'),
    ('स्नेहा वर्मा', '555 0119'),
  ],
  'it': [
    ('Alessandro Rossi', '555 0142'),
    ('Giulia Russo', '555 0198'),
    ('Lorenzo Ferrari', '555 0177'),
    ('Chiara Esposito', '555 0123'),
    ('Francesco Bianchi', '555 0156'),
    ('Alessia Romano', '555 0119'),
  ],
  'id': [
    ('Budi Wijaya', '555 0142'),
    ('Sari Saputra', '555 0198'),
    ('Agus Santoso', '555 0177'),
    ('Dewi Hidayat', '555 0123'),
    ('Joko Nugroho', '555 0156'),
    ('Sri Pratama', '555 0119'),
  ],
  'tr': [
    ('Mehmet Yılmaz', '555 0142'),
    ('Elif Kaya', '555 0198'),
    ('Mustafa Demir', '555 0177'),
    ('Zeynep Şahin', '555 0123'),
    ('Emre Çelik', '555 0156'),
    ('Ayşe Yıldız', '555 0119'),
  ],
  'nl': [
    ('Daan de Vries', '555 0142'),
    ('Sanne Jansen', '555 0198'),
    ('Sem van Dijk', '555 0177'),
    ('Lisa Bakker', '555 0123'),
    ('Luuk Visser', '555 0156'),
    ('Sophie Smit', '555 0119'),
  ],
  'pl': [
    ('Jakub Nowak', '555 0142'),
    ('Anna Kowalski', '555 0198'),
    ('Jan Wiśniewski', '555 0177'),
    ('Zofia Wójcik', '555 0123'),
    ('Piotr Kamiński', '555 0156'),
    ('Maria Lewandowski', '555 0119'),
  ],
  'th': [
    ('สมชาย บุญมี', '555 0142'),
    ('สมหญิง แสงทอง', '555 0198'),
    ('วิชัย ศรีสุข', '555 0177'),
    ('นภา ทองคำ', '555 0123'),
    ('ธนา สุวรรณ', '555 0156'),
    ('ปิยะ พงษ์เจริญ', '555 0119'),
  ],
  'vi': [
    ('Nguyễn Minh', '555 0142'),
    ('Trần Anh', '555 0198'),
    ('Lê Hương', '555 0177'),
    ('Phạm Lan', '555 0123'),
    ('Hoàng Tuấn', '555 0156'),
    ('Phan Hùng', '555 0119'),
  ],
  'uk': [
    ('Олександр Шевченко', '555 0142'),
    ('Марія Ковальчук', '555 0198'),
    ('Дмитро Бондаренко', '555 0177'),
    ('Анна Ткаченко', '555 0123'),
    ('Андрій Мельник', '555 0156'),
    ('Ольга Кравченко', '555 0119'),
  ],
  'sv': [
    ('Erik Andersson', '555 0142'),
    ('Anna Johansson', '555 0198'),
    ('Lars Karlsson', '555 0177'),
    ('Emma Nilsson', '555 0123'),
    ('Karl Eriksson', '555 0156'),
    ('Sara Larsson', '555 0119'),
  ],
  'el': [
    ('Γιώργος Παπαδόπουλος', '555 0142'),
    ('Μαρία Οικονόμου', '555 0198'),
    ('Νίκος Βασιλείου', '555 0177'),
    ('Ελένη Γεωργίου', '555 0123'),
    ('Κώστας Νικολάου', '555 0156'),
    ('Κατερίνα Δημητρίου', '555 0119'),
  ],
};

OsSkin? skinById(String id) {
  for (final skin in osSkins) {
    if (skin.id == id) return skin;
  }
  return null;
}

String skinDisplayName(String id) {
  final skin = skinById(id);
  if (skin != null) return skin.name;
  switch (id) {
    case 'classic':
      return 'OS 5';
    case 'tiles':
      return 'Windows Phone';
    default:
      return id;
  }
}

String? presetForSkin(String id) {
  final skin = skinById(id);
  if (skin != null) return skin.preset;
  switch (id) {
    case 'classic':
      return 'aqua';
    case 'tiles':
      return 'wp';
    default:
      return null;
  }
}

BgPreset bgPresetById(String id) {
  for (final preset in bgPresets) {
    if (preset.id == id) return preset;
  }
  return bgPresets.first;
}

OsCopy copyFor(String language) => _copies[language] ?? _copies['en']!;

OsLanguage languageByCode(String code) {
  for (final language in osLanguages) {
    if (language.code == code) return language;
  }
  return osLanguages.first;
}

SkinChrome chromeFor(String skin) {
  switch (skin) {
    case 'classic':
    case 'aqua':
    case 'iphoneos':
    case 'ios6':
    case 'ios7':
      return SkinChrome.classic;
    case 'tiles':
    case 'winphone':
      return SkinChrome.tiles;
    case 'android':
    case 'holo':
    case 'material':
    case 'belle':
    case 'blackberry':
      return SkinChrome.android;
    default:
      return SkinChrome.modern;
  }
}

/// Skin Default resolves the way the Base44 lock screen does.
String skinLockMethod(String skin) {
  switch (skin) {
    case 'classic':
    case 'aqua':
    case 'iphoneos':
    case 'ios6':
    case 'ios7':
      return 'slide';
    case 'holo':
      return 'ring';
    default:
      return 'swipe';
  }
}

String resolvedLockMethod(String skin, String type) {
  if (type == 'off') return 'off';
  if (type.isEmpty || type == 'none') return skinLockMethod(skin);
  return type;
}

String lockMethodLabel(String id) {
  for (final method in lockMethods) {
    if (method.id == id) return method.label;
  }
  return 'Swipe Up';
}

LinearGradient gradientFor(String presetId, {required bool light}) {
  final preset = bgPresetById(presetId);
  final colors = light ? preset.light : preset.dark;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: colors.length < 2 ? [colors.first, colors.first] : colors,
  );
}

class PhoneWallpaper {
  const PhoneWallpaper({required this.gradient, this.imagePath = ''});

  final LinearGradient gradient;
  final String imagePath;
}

PhoneWallpaper wallpaperFor(PropDevice device, {required bool locked}) {
  final os = device.os;
  if (locked) {
    final lockImage =
        os.lockBackgroundType == 'image' && os.lockBackgroundUrl.isNotEmpty;
    if (lockImage) {
      return PhoneWallpaper(
        gradient: gradientFor(os.lockBackgroundPreset, light: os.isLight),
        imagePath: os.lockBackgroundUrl,
      );
    }
    final customPreset = os.lockBackgroundPreset != 'default';
    if (!customPreset &&
        os.backgroundType == 'image' &&
        os.backgroundUrl.isNotEmpty) {
      return PhoneWallpaper(
        gradient: gradientFor(os.backgroundPreset, light: os.isLight),
        imagePath: os.backgroundUrl,
      );
    }
    final presetId = customPreset
        ? os.lockBackgroundPreset
        : os.backgroundPreset;
    return PhoneWallpaper(
      gradient: gradientFor(presetId, light: os.isLight),
    );
  }
  if (os.backgroundType == 'image' && os.backgroundUrl.isNotEmpty) {
    return PhoneWallpaper(
      gradient: gradientFor(os.backgroundPreset, light: os.isLight),
      imagePath: os.backgroundUrl,
    );
  }
  return PhoneWallpaper(
    gradient: gradientFor(os.backgroundPreset, light: os.isLight),
  );
}

List<ContactCard> contactsFor(OsSettings os) {
  final codes = os.dialCodes.isEmpty
      ? const ['026', '034', '049']
      : os.dialCodes;
  final table = _contactTables[os.language] ?? _contactTables['en']!;
  return [
    for (var i = 0; i < table.length; i++)
      ContactCard(table[i].$1, '${codes[i % codes.length]} ${table[i].$2}'),
    for (final person in os.people)
      if (person.name.trim().isNotEmpty)
        ContactCard(person.name, person.number),
  ];
}

bool validDialCode(String code) => RegExp(r'^\d{3}$').hasMatch(code);
