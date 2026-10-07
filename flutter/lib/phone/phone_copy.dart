/// Phone-app strings from `src/lib/osLanguages.js`. History is the English
/// fallback the web uses, because that table has no `history` key.
class PhoneCopy {
  const PhoneCopy({
    required this.recents,
    required this.keypad,
    required this.noCalls,
    required this.missed,
    required this.incoming,
    required this.outgoing,
  });

  final String recents;
  final String keypad;
  final String noCalls;
  final String missed;
  final String incoming;
  final String outgoing;

  String typeLabel(String type) {
    switch (type) {
      case 'missed':
        return missed;
      case 'incoming':
        return incoming;
      default:
        return outgoing;
    }
  }
}

const _english = PhoneCopy(
  recents: 'Recents',
  keypad: 'Keypad',
  noCalls: 'No recent calls',
  missed: 'Missed',
  incoming: 'Incoming',
  outgoing: 'Outgoing',
);

const phoneCopies = <String, PhoneCopy>{
  'en': _english,
  'es': PhoneCopy(
    recents: 'Recientes',
    keypad: 'Teclado',
    noCalls: 'Sin llamadas recientes',
    missed: 'Perdida',
    incoming: 'Entrante',
    outgoing: 'Saliente',
  ),
  'pt': PhoneCopy(
    recents: 'Recentes',
    keypad: 'Teclado',
    noCalls: 'Sem chamadas recentes',
    missed: 'Perdida',
    incoming: 'Recebida',
    outgoing: 'Efetuada',
  ),
  'fr': PhoneCopy(
    recents: 'Récents',
    keypad: 'Clavier',
    noCalls: 'Aucun appel récent',
    missed: 'Manqué',
    incoming: 'Entrant',
    outgoing: 'Sortant',
  ),
  'de': PhoneCopy(
    recents: 'Letzte',
    keypad: 'Tastenfeld',
    noCalls: 'Keine letzten Anrufe',
    missed: 'Verpasst',
    incoming: 'Eingehend',
    outgoing: 'Ausgehend',
  ),
  'ja': PhoneCopy(
    recents: '履歴',
    keypad: 'キーパッド',
    noCalls: '履歴なし',
    missed: '不在着信',
    incoming: '着信',
    outgoing: '発信',
  ),
  'ko': PhoneCopy(
    recents: '최근',
    keypad: '키패드',
    noCalls: '최근 통화 없음',
    missed: '부재중',
    incoming: '수신',
    outgoing: '발신',
  ),
  'zh': PhoneCopy(
    recents: '最近通话',
    keypad: '键盘',
    noCalls: '无最近通话',
    missed: '未接',
    incoming: '来电',
    outgoing: '去电',
  ),
  'ar': PhoneCopy(
    recents: 'الأخيرة',
    keypad: 'لوحة المفاتيح',
    noCalls: 'لا مكالمات حديثة',
    missed: 'لم يتم الرد',
    incoming: 'واردة',
    outgoing: 'صادرة',
  ),
  'hi': PhoneCopy(
    recents: 'हाल के कॉल',
    keypad: 'कीपैड',
    noCalls: 'कोई हाल की कॉल नहीं',
    missed: 'मिस्ड',
    incoming: 'इनकमिंग',
    outgoing: 'आउटगोइंग',
  ),
  'it': PhoneCopy(
    recents: 'Recenti',
    keypad: 'Tastiera',
    noCalls: 'Nessuna chiamata recente',
    missed: 'Persa',
    incoming: 'In arrivo',
    outgoing: 'In uscita',
  ),
  'id': PhoneCopy(
    recents: 'Terbaru',
    keypad: 'Papan tombol',
    noCalls: 'Tidak ada panggilan terbaru',
    missed: 'Tak terjawab',
    incoming: 'Masuk',
    outgoing: 'Keluar',
  ),
  'tr': PhoneCopy(
    recents: 'Son Aramalar',
    keypad: 'Tuş Takımı',
    noCalls: 'Son arama yok',
    missed: 'Cevapsız',
    incoming: 'Gelen',
    outgoing: 'Giden',
  ),
  'nl': PhoneCopy(
    recents: 'Recent',
    keypad: 'Toetsenbord',
    noCalls: 'Geen recente oproepen',
    missed: 'Gemist',
    incoming: 'Inkomend',
    outgoing: 'Uitgaand',
  ),
  'pl': PhoneCopy(
    recents: 'Ostatnie',
    keypad: 'Klawiatura',
    noCalls: 'Brak ostatnich połączeń',
    missed: 'Nieodebrane',
    incoming: 'Przychodzące',
    outgoing: 'Wychodzące',
  ),
  'th': PhoneCopy(
    recents: 'ล่าสุด',
    keypad: 'แป้นพิมพ์',
    noCalls: 'ไม่มีสายเรียกเข้าล่าสุด',
    missed: 'ไม่ตอบสาย',
    incoming: 'สายเข้า',
    outgoing: 'สายออก',
  ),
  'vi': PhoneCopy(
    recents: 'Gần đây',
    keypad: 'Bàn phím',
    noCalls: 'Không có cuộc gọi gần đây',
    missed: 'Gọi nhỡ',
    incoming: 'Gọi đến',
    outgoing: 'Gọi đi',
  ),
  'uk': PhoneCopy(
    recents: 'Нещодавні',
    keypad: 'Клавіатура',
    noCalls: 'Немає нещодавніх дзвінків',
    missed: 'Пропущений',
    incoming: 'Вхідний',
    outgoing: 'Вихідний',
  ),
  'sv': PhoneCopy(
    recents: 'Senaste',
    keypad: 'Knappsats',
    noCalls: 'Inga senaste samtal',
    missed: 'Missat',
    incoming: 'Inkommande',
    outgoing: 'Utgående',
  ),
  'el': PhoneCopy(
    recents: 'Πρόσφατα',
    keypad: 'Πληκτρολόγιο',
    noCalls: 'Καμία πρόσφατη κλήση',
    missed: 'Αναπάντητη',
    incoming: 'Εισερχόμενη',
    outgoing: 'Εξερχόμενη',
  ),
};

PhoneCopy phoneCopy(String code) => phoneCopies[code] ?? _english;
