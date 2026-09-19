// language registry + localized name pools for the mock OS
export const LANGUAGES = [
  { code: "en", native: "English", phone: { recents: "Recents", keypad: "Keypad", noCalls: "No recent calls", missed: "Missed", incoming: "Incoming", outgoing: "Outgoing" }, ui: { settings: "Settings", themes: "Themes", background: "Background", dialCodes: "Dial Codes", language: "Language", contacts: "Contacts", search: "Search", add: "Add", cancel: "Cancel", save: "Save", edit: "Edit", newContact: "New Contact", editContact: "Edit Contact", noContacts: "No contacts", call: "call", message: "message", email: "email", apps: "Apps", done: "Done", answerCalls: "Answer Calls", answerTap: "Button Tap", answerSwipe: "Swipe Up" } },
  { code: "es", native: "Español", phone: { recents: "Recientes", keypad: "Teclado", noCalls: "Sin llamadas recientes", missed: "Perdida", incoming: "Entrante", outgoing: "Saliente" }, ui: { settings: "Ajustes", themes: "Temas", background: "Fondo", dialCodes: "Códigos de marcado", language: "Idioma", contacts: "Contactos", search: "Buscar", add: "Añadir", cancel: "Cancelar", save: "Guardar", edit: "Editar", newContact: "Nuevo contacto", editContact: "Editar contacto", noContacts: "Sin contactos", call: "llamar", message: "mensaje", email: "correo", apps: "Apps", done: "OK" } },
  { code: "pt", native: "Português", phone: { recents: "Recentes", keypad: "Teclado", noCalls: "Sem chamadas recentes", missed: "Perdida", incoming: "Recebida", outgoing: "Efetuada" }, ui: { settings: "Ajustes", themes: "Temas", background: "Fundo", dialCodes: "Códigos de discagem", language: "Idioma", contacts: "Contatos", search: "Buscar", add: "Adicionar", cancel: "Cancelar", save: "Salvar", edit: "Editar", newContact: "Novo contato", editContact: "Editar contato", noContacts: "Sem contatos", call: "ligar", message: "mensagem", email: "e-mail", apps: "Apps", done: "OK" } },
  { code: "fr", native: "Français", phone: { recents: "Récents", keypad: "Clavier", noCalls: "Aucun appel récent", missed: "Manqué", incoming: "Entrant", outgoing: "Sortant" }, ui: { settings: "Réglages", themes: "Thèmes", background: "Fond d'écran", dialCodes: "Codes d'appel", language: "Langue", contacts: "Contacts", search: "Recherche", add: "Ajouter", cancel: "Annuler", save: "Enregistrer", edit: "Modifier", newContact: "Nouveau contact", editContact: "Modifier le contact", noContacts: "Aucun contact", call: "appeler", message: "message", email: "e-mail", apps: "Apps", done: "OK" } },
  { code: "de", native: "Deutsch", phone: { recents: "Letzte", keypad: "Tastenfeld", noCalls: "Keine letzten Anrufe", missed: "Verpasst", incoming: "Eingehend", outgoing: "Ausgehend" }, ui: { settings: "Einstellungen", themes: "Designs", background: "Hintergrund", dialCodes: "Wählcodes", language: "Sprache", contacts: "Kontakte", search: "Suchen", add: "Neu", cancel: "Abbrechen", save: "Fertig", edit: "Bearbeiten", newContact: "Neuer Kontakt", editContact: "Kontakt bearbeiten", noContacts: "Keine Kontakte", call: "anrufen", message: "Nachricht", email: "E-Mail", apps: "Apps", done: "OK" } },
  { code: "ja", native: "日本語", phone: { recents: "履歴", keypad: "キーパッド", noCalls: "履歴なし", missed: "不在着信", incoming: "着信", outgoing: "発信" }, ui: { settings: "設定", themes: "テーマ", background: "壁紙", dialCodes: "発信コード", language: "言語", contacts: "連絡先", search: "検索", add: "追加", cancel: "キャンセル", save: "保存", edit: "編集", newContact: "新規連絡先", editContact: "連絡先を編集", noContacts: "連絡先なし", call: "通話", message: "メッセージ", email: "メール", apps: "アプリ", done: "完了" } },
  { code: "ko", native: "한국어", phone: { recents: "최근", keypad: "키패드", noCalls: "최근 통화 없음", missed: "부재중", incoming: "수신", outgoing: "발신" }, ui: { settings: "설정", themes: "테마", background: "배경", dialCodes: "다이얼 코드", language: "언어", contacts: "연락처", search: "검색", add: "추가", cancel: "취소", save: "저장", edit: "편집", newContact: "새 연락처", editContact: "연락처 편집", noContacts: "연락처 없음", call: "통화", message: "메시지", email: "이메일", apps: "앱", done: "완료" } },
  { code: "zh", native: "中文（简体）", phone: { recents: "最近通话", keypad: "键盘", noCalls: "无最近通话", missed: "未接", incoming: "来电", outgoing: "去电" }, ui: { settings: "设置", themes: "主题", background: "壁纸", dialCodes: "拨号代码", language: "语言", contacts: "通讯录", search: "搜索", add: "添加", cancel: "取消", save: "保存", edit: "编辑", newContact: "新建联系人", editContact: "编辑联系人", noContacts: "没有联系人", call: "通话", message: "信息", email: "邮件", apps: "应用", done: "完成" } },
  { code: "ar", native: "العربية", rtl: true, phone: { recents: "الأخيرة", keypad: "لوحة المفاتيح", noCalls: "لا مكالمات حديثة", missed: "لم يتم الرد", incoming: "واردة", outgoing: "صادرة" }, ui: { settings: "الإعدادات", themes: "السمات", background: "الخلفية", dialCodes: "رموز الاتصال", language: "اللغة", contacts: "جهات الاتصال", search: "بحث", add: "إضافة", cancel: "إلغاء", save: "حفظ", edit: "تعديل", newContact: "جهة اتصال جديدة", editContact: "تعديل جهة الاتصال", noContacts: "لا توجد جهات اتصال", call: "اتصال", message: "رسالة", email: "بريد", apps: "تطبيقات", done: "تم" } },
  { code: "hi", native: "हिन्दी", phone: { recents: "हाल के कॉल", keypad: "कीपैड", noCalls: "कोई हाल की कॉल नहीं", missed: "मिस्ड", incoming: "इनकमिंग", outgoing: "आउटगोइंग" }, ui: { settings: "सेटिंग्स", themes: "थीम", background: "वॉलपेपर", dialCodes: "डायल कोड", language: "भाषा", contacts: "संपर्क", search: "खोज", add: "जोड़ें", cancel: "रद्द करें", save: "सहेजें", edit: "संपादित करें", newContact: "नया संपर्क", editContact: "संपर्क संपादित करें", noContacts: "कोई संपर्क नहीं", call: "कॉल", message: "संदेश", email: "ईमेल", apps: "ऐप्स", done: "पूर्ण" } },
  { code: "it", native: "Italiano", phone: { recents: "Recenti", keypad: "Tastiera", noCalls: "Nessuna chiamata recente", missed: "Persa", incoming: "In arrivo", outgoing: "In uscita" }, ui: { settings: "Impostazioni", themes: "Temi", background: "Sfondo", dialCodes: "Prefissi di chiamata", language: "Lingua", contacts: "Contatti", search: "Cerca", add: "Aggiungi", cancel: "Annulla", save: "Salva", edit: "Modifica", newContact: "Nuovo contatto", editContact: "Modifica contatto", noContacts: "Nessun contatto", call: "chiama", message: "messaggio", email: "email", apps: "App", done: "Fine" } },
  { code: "id", native: "Bahasa Indonesia", phone: { recents: "Terbaru", keypad: "Papan tombol", noCalls: "Tidak ada panggilan terbaru", missed: "Tak terjawab", incoming: "Masuk", outgoing: "Keluar" }, ui: { settings: "Pengaturan", themes: "Tema", background: "Latar", dialCodes: "Kode panggilan", language: "Bahasa", contacts: "Kontak", search: "Cari", add: "Tambah", cancel: "Batal", save: "Simpan", edit: "Ubah", newContact: "Kontak baru", editContact: "Ubah kontak", noContacts: "Tidak ada kontak", call: "panggil", message: "pesan", email: "email", apps: "Aplikasi", done: "Selesai" } },
  { code: "tr", native: "Türkçe", phone: { recents: "Son Aramalar", keypad: "Tuş Takımı", noCalls: "Son arama yok", missed: "Cevapsız", incoming: "Gelen", outgoing: "Giden" }, ui: { settings: "Ayarlar", themes: "Temalar", background: "Duvar kağıdı", dialCodes: "Arama kodları", language: "Dil", contacts: "Kişiler", search: "Ara", add: "Ekle", cancel: "İptal", save: "Kaydet", edit: "Düzenle", newContact: "Yeni kişi", editContact: "Kişiyi düzenle", noContacts: "Kişi yok", call: "ara", message: "mesaj", email: "e-posta", apps: "Uygulamalar", done: "Bitti" } },
  { code: "nl", native: "Nederlands", phone: { recents: "Recent", keypad: "Toetsenbord", noCalls: "Geen recente oproepen", missed: "Gemist", incoming: "Inkomend", outgoing: "Uitgaand" }, ui: { settings: "Instellingen", themes: "Thema's", background: "Achtergrond", dialCodes: "Kiescodes", language: "Taal", contacts: "Contacten", search: "Zoek", add: "Nieuw", cancel: "Annuleer", save: "OK", edit: "Bewerk", newContact: "Nieuw contact", editContact: "Bewerk contact", noContacts: "Geen contacten", call: "bel", message: "bericht", email: "e-mail", apps: "Apps", done: "Gereed" } },
  { code: "pl", native: "Polski", phone: { recents: "Ostatnie", keypad: "Klawiatura", noCalls: "Brak ostatnich połączeń", missed: "Nieodebrane", incoming: "Przychodzące", outgoing: "Wychodzące" }, ui: { settings: "Ustawienia", themes: "Motywy", background: "Tapeta", dialCodes: "Kody wybierania", language: "Język", contacts: "Kontakty", search: "Szukaj", add: "Dodaj", cancel: "Anuluj", save: "Zapisz", edit: "Edytuj", newContact: "Nowy kontakt", editContact: "Edytuj kontakt", noContacts: "Brak kontaktów", call: "zadzwoń", message: "wiadomość", email: "e-mail", apps: "Aplikacje", done: "Gotowe" } },
  { code: "th", native: "ไทย", phone: { recents: "ล่าสุด", keypad: "แป้นพิมพ์", noCalls: "ไม่มีสายเรียกเข้าล่าสุด", missed: "ไม่ตอบสาย", incoming: "สายเข้า", outgoing: "สายออก" }, ui: { settings: "การตั้งค่า", themes: "ธีม", background: "วอลเปเปอร์", dialCodes: "รหัสโทร", language: "ภาษา", contacts: "ผู้ติดต่อ", search: "ค้นหา", add: "เพิ่ม", cancel: "ยกเลิก", save: "บันทึก", edit: "แก้ไข", newContact: "ผู้ติดต่อใหม่", editContact: "แก้ไขผู้ติดต่อ", noContacts: "ไม่มีผู้ติดต่อ", call: "โทร", message: "ข้อความ", email: "อีเมล", apps: "แอป", done: "เสร็จสิ้น" } },
  { code: "vi", native: "Tiếng Việt", phone: { recents: "Gần đây", keypad: "Bàn phím", noCalls: "Không có cuộc gọi gần đây", missed: "Gọi nhỡ", incoming: "Gọi đến", outgoing: "Gọi đi" }, ui: { settings: "Cài đặt", themes: "Giao diện", background: "Hình nền", dialCodes: "Mã gọi", language: "Ngôn ngữ", contacts: "Danh bạ", search: "Tìm kiếm", add: "Thêm", cancel: "Hủy", save: "Lưu", edit: "Chỉnh sửa", newContact: "Liên hệ mới", editContact: "Chỉnh sửa liên hệ", noContacts: "Không có liên hệ", call: "gọi", message: "tin nhắn", email: "email", apps: "Ứng dụng", done: "Xong" } },
  { code: "uk", native: "Українська", phone: { recents: "Нещодавні", keypad: "Клавіатура", noCalls: "Немає нещодавніх дзвінків", missed: "Пропущений", incoming: "Вхідний", outgoing: "Вихідний" }, ui: { settings: "Налаштування", themes: "Теми", background: "Шпалери", dialCodes: "Коди набору", language: "Мова", contacts: "Контакти", search: "Пошук", add: "Додати", cancel: "Скасувати", save: "Зберегти", edit: "Редагувати", newContact: "Новий контакт", editContact: "Редагувати контакт", noContacts: "Немає контактів", call: "подзвонити", message: "повідомлення", email: "е-пошта", apps: "Програми", done: "Готово" } },
  { code: "sv", native: "Svenska", phone: { recents: "Senaste", keypad: "Knappsats", noCalls: "Inga senaste samtal", missed: "Missat", incoming: "Inkommande", outgoing: "Utgående" }, ui: { settings: "Inställningar", themes: "Temar", background: "Bakgrund", dialCodes: "Ringkoder", language: "Språk", contacts: "Kontakter", search: "Sök", add: "Ny", cancel: "Avbryt", save: "Spara", edit: "Redigera", newContact: "Ny kontakt", editContact: "Redigera kontakt", noContacts: "Inga kontakter", call: "ring", message: "meddelande", email: "e-post", apps: "Appar", done: "Klar" } },
  { code: "el", native: "Ελληνικά", phone: { recents: "Πρόσφατα", keypad: "Πληκτρολόγιο", noCalls: "Καμία πρόσφατη κλήση", missed: "Αναπάντητη", incoming: "Εισερχόμενη", outgoing: "Εξερχόμενη" }, ui: { settings: "Ρυθμίσεις", themes: "Θέματα", background: "Ταπετσαρία", dialCodes: "Κωδικοί κλήσης", language: "Γλώσσα", contacts: "Επαφές", search: "Αναζήτηση", add: "Προσθήκη", cancel: "Ακύρωση", save: "Αποθήκευση", edit: "Επεξεργασία", newContact: "Νέα επαφή", editContact: "Επεξεργασία επαφής", noContacts: "Καμία επαφή", call: "κλήση", message: "μήνυμα", email: "email", apps: "Εφαρμογές", done: "Έτοιμο" } },
];

export const uiFor = (lang) => LANGUAGES.find((l) => l.code === lang)?.ui || LANGUAGES[0].ui;

// per-language name pools - 20 given + 20 family names each
const POOLS = {
  en: {
    first: ["James", "Sarah", "Michael", "Emma", "David", "Olivia", "Daniel", "Sophia", "Matthew", "Ava", "Christopher", "Mia", "Andrew", "Isabella", "Joshua", "Amelia", "Ethan", "Harper", "Ryan", "Evelyn"],
    last: ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Wilson", "Anderson", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Clark", "Walker", "Hall", "Young", "King"],
  },
  es: {
    first: ["Alejandro", "Lucía", "Carlos", "María", "Javier", "Carmen", "Diego", "Sofía", "Pablo", "Elena", "Fernando", "Paula", "Andrés", "Marta", "Luis", "Laura", "Miguel", "Valeria", "Rafael", "Inés"],
    last: ["García", "Rodríguez", "Martínez", "López", "Sánchez", "Fernández", "Pérez", "Gómez", "Ruiz", "Díaz", "Hernández", "Álvarez", "Romero", "Navarro", "Torres", "Vargas", "Castillo", "Ortiz", "Rubio", "Molina"],
  },
  pt: {
    first: ["João", "Ana", "Pedro", "Beatriz", "Lucas", "Carolina", "Mateus", "Mariana", "Gabriel", "Sofia", "Rafael", "Camila", "Thiago", "Larissa", "Bruno", "Júlia", "Felipe", "Isabela", "André", "Renata"],
    last: ["Silva", "Santos", "Oliveira", "Souza", "Costa", "Pereira", "Almeida", "Ferreira", "Ribeiro", "Carvalho", "Gomes", "Martins", "Rocha", "Barbosa", "Araújo", "Lima", "Melo", "Cardoso", "Teixeira", "Moraes"],
  },
  fr: {
    first: ["Louis", "Camille", "Hugo", "Léa", "Gabriel", "Manon", "Raphaël", "Chloé", "Arthur", "Emma", "Jules", "Louise", "Théo", "Juliette", "Lucas", "Alice", "Nathan", "Clara", "Maxime", "Inès"],
    last: ["Martin", "Bernard", "Dubois", "Thomas", "Robert", "Richard", "Petit", "Durand", "Leroy", "Moreau", "Simon", "Laurent", "Lefebvre", "Michel", "Garcia", "David", "Bertrand", "Roux", "Vincent", "Fournier"],
  },
  de: {
    first: ["Lukas", "Emma", "Felix", "Hannah", "Maximilian", "Sophia", "Leon", "Mia", "Paul", "Lena", "Jonas", "Anna", "Jakob", "Marie", "David", "Sophie", "Noah", "Klara", "Erik", "Greta"],
    last: ["Müller", "Schmidt", "Schneider", "Fischer", "Weber", "Meyer", "Wagner", "Becker", "Schulz", "Hoffmann", "Koch", "Bauer", "Richter", "Klein", "Wolf", "Schröder", "Neumann", "Braun", "Zimmermann", "Krüger"],
  },
  ja: {
    first: ["太郎", "花子", "一郎", "美咲", "健太", "陽菜", "翔太", "愛", "大輔", "由美", "拓海", "桜", "悠真", "瞳", "健一", "麻衣", "峻", "結衣", "誠", "明日香"],
    last: ["佐藤", "鈴木", "高橋", "田中", "渡辺", "伊藤", "山本", "中村", "小林", "加藤", "吉田", "山田", "佐々木", "山口", "松本", "井上", "木村", "林", "斎藤", "清水"],
    lastFirst: true, glue: "",
  },
  ko: {
    first: ["민준", "서연", "도윤", "지우", "시우", "하윤", "지호", "서준", "예은", "수아", "은우", "하은", "지안", "유준", "지민", "수빈", "현우", "예원", "우진", "소율"],
    last: ["김", "이", "박", "최", "정", "강", "조", "윤", "장", "임", "한", "오", "서", "신", "권", "황", "안", "송", "류", "전"],
    lastFirst: true, glue: "",
  },
  zh: {
    first: ["伟", "芳", "娜", "敏", "静", "丽", "强", "磊", "军", "洋", "勇", "艳", "杰", "娟", "涛", "明", "超", "霞", "秀英", "平"],
    last: ["王", "李", "张", "刘", "陈", "杨", "黄", "赵", "吴", "周", "徐", "孙", "马", "朱", "胡", "郭", "何", "高", "林", "罗"],
    lastFirst: true, glue: "",
  },
  ar: {
    first: ["محمد", "أحمد", "فاطمة", "عمر", "ليلى", "خالد", "نور", "يوسف", "مريم", "علي", "زينب", "حسن", "سارة", "إبراهيم", "هدى", "مصطفى", "آية", "كريم", "جميلة", "سمير"],
    last: ["الحسن", "المصري", "النجار", "عبدالله", "الخطيب", "الشريف", "منصور", "العلي", "حمدان", "السيد", "فارس", "الدباس", "سلطان", "عبدالعزيز", "النمر", "كامل", "الأحمد", "رشيد", "سعيد", "مكي"],
  },
  hi: {
    first: ["अर्जुन", "प्रिया", "राहुल", "अनिता", "विक्रम", "स्नेहा", "रोहित", "पूजा", "आरव", "आयशा", "कबीर", "दिव्या", "आकाश", "नेहा", "राज", "अंजलि", "अमन", "काजल", "विवेक", "श्रेया"],
    last: ["शर्मा", "पटेल", "सिंह", "कुमार", "गुप्ता", "वर्मा", "शाह", "मेहता", "जोशी", "राव", "देसाई", "चौहान", "मिश्रा", "अग्रवाल", "भट", "यादव", "रेड्डी", "कपूर", "मल्होत्रा", "खुराना"],
  },
  it: {
    first: ["Alessandro", "Giulia", "Lorenzo", "Chiara", "Francesco", "Alessia", "Matteo", "Sofia", "Andrea", "Martina", "Davide", "Sara", "Luca", "Valentina", "Marco", "Elena", "Simone", "Francesca", "Giuseppe", "Rosa"],
    last: ["Rossi", "Russo", "Ferrari", "Esposito", "Bianchi", "Romano", "Colombo", "Ricci", "Marino", "Greco", "Bruno", "Gallo", "Conti", "De Luca", "Costa", "Giordano", "Mancini", "Rizzo", "Lombardi", "Moretti"],
  },
  id: {
    first: ["Budi", "Sari", "Agus", "Dewi", "Joko", "Sri", "Rizky", "Putri", "Andi", "Ayu", "Bayu", "Intan", "Dedi", "Ratna", "Eko", "Lestari", "Hendra", "Maya", "Fajar", "Indah"],
    last: ["Wijaya", "Saputra", "Santoso", "Hidayat", "Nugroho", "Pratama", "Sutanto", "Wibowo", "Kusuma", "Halim", "Gunawan", "Setiawan", "Rahayu", "Susanto", "Hartono", "Permata", "Tanjung", "Iskandar", "Prasetyo", "Utami"],
  },
  tr: {
    first: ["Mehmet", "Elif", "Mustafa", "Zeynep", "Emre", "Ayşe", "Ahmet", "Fatma", "Burak", "Merve", "Yusuf", "Selin", "Kerem", "Ece", "Can", "Zehra", "Onur", "Deniz", "Volkan", "Gamze"],
    last: ["Yılmaz", "Kaya", "Demir", "Şahin", "Çelik", "Yıldız", "Yıldırım", "Öztürk", "Aydın", "Özdemir", "Arslan", "Doğan", "Kılıç", "Aslan", "Çetin", "Kara", "Koç", "Kurt", "Özkan", "Şimşek"],
  },
  nl: {
    first: ["Daan", "Sanne", "Sem", "Lisa", "Luuk", "Sophie", "Thijs", "Anna", "Jesse", "Lotte", "Lars", "Eva", "Bram", "Julie", "Tim", "Iris", "Niels", "Mila", "Ruben", "Roos"],
    last: ["de Vries", "Jansen", "van Dijk", "Bakker", "Visser", "Smit", "Meijer", "de Boer", "Mulder", "de Groot", "Bos", "Vos", "Peters", "Hendriks", "van Leeuwen", "Dekker", "Brouwer", "de Wit", "Dijkstra", "Kuipers"],
  },
  pl: {
    first: ["Jakub", "Anna", "Jan", "Zofia", "Piotr", "Maria", "Kacper", "Maja", "Szymon", "Aleksandra", "Michał", "Julia", "Wojciech", "Oliwia", "Bartosz", "Hanna", "Filip", "Zuzanna", "Tomasz", "Lena"],
    last: ["Nowak", "Kowalski", "Wiśniewski", "Wójcik", "Kamiński", "Lewandowski", "Zieliński", "Szymański", "Woźniak", "Dąbrowski", "Kozłowski", "Mazur", "Jankowski", "Wojciechowski", "Kwiatkowski", "Krawczyk", "Kaczmarek", "Piotrowski", "Grabowski", "Nowicki"],
  },
  th: {
    first: ["สมชาย", "สมหญิง", "วิชัย", "นภา", "ธนา", "ปิยะ", "สุรชัย", "อรทัย", "เดชา", "มาลี", "ประเสริฐ", "กนก", "วรรณา", "ธีรภัทร", "พรทิพย์", "อนันต์", "จิระ", "สายฝน", "ปวีณา", "วิภา"],
    last: ["บุญมี", "แสงทอง", "ศรีสุข", "ทองคำ", "สุวรรณ", "พงษ์เจริญ", "คำแสง", "ปิ่นทอง", "บุญเรือง", "ชูเกียรติ", "มีสุข", "แก้วมณี", "รุ่งเรือง", "สายรุ้ง", "บุญชู", "วงศ์สกุล", "จันทร์เพ็ญ", "ดีประเสริฐ", "อินทร์", "สุขุม"],
  },
  vi: {
    first: ["Minh", "Anh", "Hương", "Lan", "Tuấn", "Hùng", "Hoa", "Mai", "Nam", "Thảo", "Dũng", "Linh", "Trang", "Sơn", "Hà", "Chi", "Long", "Nga", "Vy", "Quân"],
    last: ["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Phan", "Vũ", "Đặng", "Bùi", "Đỗ", "Hồ", "Ngô", "Dương", "Đinh", "Lý", "Đoàn", "Vương", "Trịnh", "Võ", "Cao"],
    lastFirst: true,
  },
  uk: {
    first: ["Олександр", "Марія", "Дмитро", "Анна", "Андрій", "Ольга", "Іван", "Софія", "Максим", "Ірина", "Тарас", "Катерина", "Богдан", "Оксана", "Антон", "Наталія", "Володимир", "Юлія", "Сергій", "Дарина"],
    last: ["Шевченко", "Ковальчук", "Бондаренко", "Ткаченко", "Мельник", "Кравченко", "Коваленко", "Овчаренко", "Іваненко", "Гончаренко", "Савченко", "Лисенко", "Поліщук", "Литвин", "Мороз", "Гнатенко", "Руденко", "Кушнір", "Ващенко", "Ткачук"],
  },
  sv: {
    first: ["Erik", "Anna", "Lars", "Emma", "Karl", "Sara", "Anders", "Lisa", "Johan", "Maria", "Peter", "Elin", "Oskar", "Amanda", "Gustav", "Ida", "Axel", "Linnéa", "Viktor", "Elsa"],
    last: ["Andersson", "Johansson", "Karlsson", "Nilsson", "Eriksson", "Larsson", "Olsson", "Persson", "Svensson", "Gustafsson", "Lindberg", "Lindqvist", "Bergström", "Lundgren", "Sandberg", "Holmberg", "Forsberg", "Nyström", "Ekström", "Berg"],
  },
  el: {
    first: ["Γιώργος", "Μαρία", "Νίκος", "Ελένη", "Κώστας", "Κατερίνα", "Δημήτρης", "Σοφία", "Παύλος", "Άννα", "Θανάσης", "Βασιλική", "Γιάννης", "Δέσποινα", "Σταύρος", "Χαρά", "Μιχάλης", "Ιωάννα", "Πέτρος", "Λία"],
    last: ["Παπαδόπουλος", "Οικονόμου", "Βασιλείου", "Γεωργίου", "Νικολάου", "Δημητρίου", "Αντωνόπουλος", "Καραμάνης", "Μακρής", "Σταθόπουλος", "Κωνσταντίνου", "Αλεξίου", "Παπανικολάου", "Γκίκας", "Σταύρου", "Κατσούλης", "Λάμπρου", "Ρίζος", "Βλάχος", "Μητσόπουλος"],
  },
};

// 100 distinct full names per language, honouring each culture's name order
export const makeNames = (lang = "en") => {
  const pool = POOLS[lang] || POOLS.en;
  const n = pool.first.length;
  const names = [];
  for (let i = 0; i < 100; i++) {
    const f = pool.first[i % n];
    const l = pool.last[(i % n + Math.floor(i / n)) % pool.last.length];
    names.push(pool.lastFirst ? (pool.glue === "" ? l + f : `${l} ${f}`) : `${f} ${l}`);
  }
  return names;
};

export const isRtlLanguage = (lang) => lang === "ar";