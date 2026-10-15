import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../image_file.dart';
import '../models.dart';
import '../os_catalog.dart';
import '../store.dart';
import 'atm_chrome.dart';
import 'clock_settings.dart';
import 'place_settings.dart';

/// Landscape ATM for an iPad mounted in a machine.
///
/// The screen stays on welcome until a tap anywhere on it, then a 5-digit
/// PIN. Any five digits unlock it. A confirmed withdrawal waits on each
/// instruction, shows the amount, then asks for the card, the cash, and the
/// receipt before it returns to welcome. Settings can keep the pad on screen
/// or fill the PIN as if a physical keypad beside the machine is in use.
class AtmScreen extends StatefulWidget {
  const AtmScreen({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<AtmScreen> createState() => _AtmScreenState();
}

class _AtmScreenState extends State<AtmScreen> {
  String _step = 'welcome';
  String _pin = '';
  String _message = '';
  String _errorBack = 'menu';
  String _account = 'checking';
  String _action = '';
  int _amount = 0;
  String? _layoutPick;
  String? _settingsPage;
  bool _currenciesOpen = false;
  late final TextEditingController _bankName;
  late final TextEditingController _userName;
  late final TextEditingController _time;
  late final TextEditingController _temperature;
  late final TextEditingController _place;
  late final TextEditingController _date;
  late final TextEditingController _balance;
  late final TextEditingController _notes;
  late final TextEditingController _customAmount;
  Timer? _fundsTimer;
  Timer? _pinTimer;

  @override
  void initState() {
    super.initState();
    final current = _live;
    _bankName = TextEditingController(text: current.os.bankName);
    _userName = TextEditingController(text: current.os.bankHolder);
    _time = TextEditingController(
      text: formatOsClock(
        osNow(current.os),
        hour24: current.os.clockFormat == '24',
      ),
    );
    _temperature = TextEditingController(text: '${current.os.temperature}');
    _place = TextEditingController(text: current.os.place);
    _date = TextEditingController(text: formatDateField(current.os));
    _balance = TextEditingController(text: '${current.os.bankBalance}');
    _notes = TextEditingController(text: atmNotes(current.os).join(', '));
    _customAmount = TextEditingController();
  }

  @override
  void dispose() {
    _fundsTimer?.cancel();
    _pinTimer?.cancel();
    _bankName.dispose();
    _userName.dispose();
    _time.dispose();
    _temperature.dispose();
    _place.dispose();
    _date.dispose();
    _balance.dispose();
    _notes.dispose();
    _customAmount.dispose();
    super.dispose();
  }

  PropDevice get _live =>
      widget.store.deviceById(widget.device.id) ?? widget.device;

  OsSettings get os => _live.os;

  AtmSkin get skin => atmFaceSkin(os);

  double get _faceRadius => switch (os.face) {
    'vault' => 28,
    'kiosk' => 2,
    _ => 14,
  };

  String get _language => os.language;

  String _t(String key) => atmLine(_language, key);

  String _f(String key, Map<String, String> values) =>
      atmFill(_language, key, values);

  String _accountLabel(String id) =>
      _t(id == 'savings' ? 'savings' : 'checking');

  String _actionLabel(String id) => switch (id) {
    'deposit' => _t('actDeposit'),
    'balance' => _t('actBalance'),
    'transfer' => _t('actTransfer'),
    'bill' => _t('actBill'),
    _ => _t('actWithdraw'),
  };

  void _save(OsSettings Function(OsSettings current) change) {
    widget.store.updateOs(widget.device.id, change);
    setState(() {});
  }

  void _go(String step) {
    _fundsTimer?.cancel();
    _pinTimer?.cancel();
    setState(() {
      _step = step;
      _message = '';
      if (step == 'pin') _pin = '';
      if (step == 'settings') _balance.text = '${os.bankBalance}';
      if (step == 'menu') _settingsPage = null;
      if (step != 'layout') _layoutPick = null;
    });
    if (step == 'pin' && os.bankKeypad == 'external') _playExternalPin(0);
  }

  /// Dots fill as if someone is using a physical keypad that is not on screen.
  void _playExternalPin(int count) {
    _pinTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _step != 'pin' || os.bankKeypad != 'external') return;
      if (count >= 5) {
        _go('menu');
        return;
      }
      setState(() => _pin = '•' * (count + 1));
      _playExternalPin(count + 1);
    });
  }

  void _insufficientFunds() {
    _go('insufficient');
    _fundsTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _step != 'insufficient') return;
      _go('menu');
    });
  }

  void _digit(String value) {
    if (_pin.length >= 5) return;
    setState(() {
      _pin += value;
      if (_pin.length < 5) return;
      _pin = '';
      _step = 'menu';
    });
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _chooseAmount(int amount, {String errorBack = 'amount'}) {
    if (amount <= 0) return;
    if (amount > os.bankBalance) {
      _insufficientFunds();
      return;
    }
    if (!atmCanDispense(amount, atmNotes(os))) {
      setState(() {
        _message = _t('notNotes');
        _errorBack = errorBack;
        _step = 'error';
      });
      return;
    }
    setState(() {
      _amount = amount;
      _step = 'review';
    });
  }

  void _submitCustom() {
    final amount = int.tryParse(_customAmount.text.trim());
    if (amount == null) return;
    _chooseAmount(amount, errorBack: 'custom');
  }

  void _applyNotes(String value) {
    final notes = parseAtmNotes(value);
    if (notes.isEmpty) return;
    final saved = os.bankNotes;
    if (notes.length == saved.length) {
      var same = true;
      for (var i = 0; i < notes.length; i++) {
        if (notes[i] != saved[i]) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    _save((current) => current.copyWith(bankNotes: notes));
  }

  static const _withdrawBeats = [
    'dispense',
    'shown',
    'removeCard',
    'removeCash',
    'takeReceipt',
    'closing',
  ];

  void _commitWithdraw() {
    widget.store.updateOs(
      widget.device.id,
      (current) => current.copyWith(bankBalance: current.bankBalance - _amount),
    );
    setState(() => _action = 'withdraw');
    _playWithdraw(0);
  }

  void _playWithdraw(int index) {
    if (!mounted) return;
    if (index >= _withdrawBeats.length) {
      _go('welcome');
      return;
    }
    final step = _withdrawBeats[index];
    _go(step);
    _fundsTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _step != step) return;
      _playWithdraw(index + 1);
    });
  }

  void _commitDeposit(int amount) {
    widget.store.updateOs(
      widget.device.id,
      (current) => current.copyWith(bankBalance: current.bankBalance + amount),
    );
    setState(() {
      _amount = amount;
      _action = 'deposit';
      _step = 'accepted';
    });
  }

  void _payBill() {
    const amount = 40;
    if (amount > os.bankBalance) {
      setState(() {
        _message = _t('unavailable');
        _errorBack = 'bills';
        _step = 'error';
      });
      return;
    }
    widget.store.updateOs(
      widget.device.id,
      (current) => current.copyWith(bankBalance: current.bankBalance - amount),
    );
    setState(() {
      _amount = amount;
      _action = 'bill';
      _step = 'accepted';
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = osNow(_live.os);
    final image = os.backgroundType == 'image'
        ? imageProviderForPath(os.backgroundUrl)
        : null;
    return Directionality(
      textDirection: languageByCode(_language).rtl
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Stack(
        key: const Key('atm-home'),
        fit: StackFit.expand,
        children: [
          if (image != null)
            Positioned.fill(
              key: const Key('atm-custom-background'),
              child: Image(
                image: image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: CustomPaint(
              painter: _AtmBackdrop(skin: skin, veil: image != null),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = math
                  .min(constraints.maxWidth / 1000, constraints.maxHeight / 720)
                  .clamp(0.56, 1.15);
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  22 * scale,
                  16 * scale,
                  22 * scale,
                  12 * scale,
                ),
                child: Column(
                  children: [
                    _Header(
                      os: os,
                      name: os.bankName,
                      now: now,
                      temperature: os.temperature,
                      scale: scale,
                      skin: skin,
                    ),
                    SizedBox(height: 12 * scale),
                    Expanded(child: _body(scale, now)),
                    SizedBox(height: 8 * scale),
                    _Footer(
                      scale: scale,
                      skin: skin,
                      service: _t('service'),
                      onService: () => _go('down'),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_step == 'welcome')
            Positioned.fill(
              child: GestureDetector(
                key: const Key('atm-welcome'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _go('pin'),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(double scale, DateTime now) {
    switch (_step) {
      case 'welcome':
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t('welcome'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: skin.title,
                  fontSize: 48 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 12 * scale),
              Text(
                _t('welcomeHint'),
                textAlign: TextAlign.center,
                style: TextStyle(color: skin.muted, fontSize: 18 * scale),
              ),
            ],
          ),
        );
      case 'pin':
        return _pinStage(scale, _t('enterPin'), _t('pinHint'), entry: true);
      case 'menu':
        return _Menu(
          scale: scale,
          skin: skin,
          face: atmFaceId(os),
          greeting: atmGreeting(_language, now.hour, os.bankHolder),
          select: _t('select'),
          panels: atmPanels(os),
          labelFor: _t,
          onOpen: _openPanel,
        );
      case 'settings':
        return _settings(scale);
      case 'layout':
        return _layout(scale, now);
      case 'withdraw':
        return _prompt(scale, _t('actWithdraw'), _t('whichAccount'), [
          _choice(
            _t('checking'),
            () => setState(() {
              _account = 'checking';
              _step = 'amount';
            }),
            key: const Key('atm-account-checking'),
            primary: true,
          ),
          _choice(
            _t('savings'),
            () => setState(() {
              _account = 'savings';
              _step = 'amount';
            }),
            key: const Key('atm-account-savings'),
          ),
          _choice(_t('cancel'), () => _go('menu')),
        ]);
      case 'amount':
        final notes = atmNotes(os);
        return _prompt(
          scale,
          _t('chooseAmount'),
          _f('available', {
            'account': _accountLabel(_account),
            'currency': os.bankCurrency,
            'balance': '${os.bankBalance}',
          }),
          [
            for (final amount in notes)
              _choice(
                '${os.bankCurrency} $amount',
                () => _chooseAmount(amount),
                key: Key('atm-amount-$amount'),
                primary: amount == notes.first,
              ),
            _choice(_t('customAmount'), () {
              _customAmount.clear();
              _go('custom');
            }, key: const Key('atm-custom-open')),
            _choice(_t('back'), () => _go('withdraw')),
          ],
        );
      case 'custom':
        return _prompt(
          scale,
          _t('customAmount'),
          _f('available', {
            'account': _accountLabel(_account),
            'currency': os.bankCurrency,
            'balance': '${os.bankBalance}',
          }),
          [
            _choice(
              _t('customUse'),
              _submitCustom,
              key: const Key('atm-custom-use'),
              primary: true,
            ),
            _choice(_t('back'), () => _go('amount')),
          ],
          field: _customAmountInput(scale),
        );
      case 'review':
        return _prompt(
          scale,
          _t('confirmWithdrawal'),
          _f('fromAccount', {
            'currency': os.bankCurrency,
            'amount': '$_amount',
            'account': _accountLabel(_account),
          }),
          [
            _choice(
              'Confirm',
              _commitWithdraw,
              key: const Key('atm-confirm'),
              primary: true,
            ),
            _choice(_t('cancel'), () => _go('menu')),
          ],
        );
      case 'dispense':
        return _prompt(scale, _t('pleaseWait'), '', const []);
      case 'shown':
        return _prompt(
          scale,
          _t('actWithdraw'),
          _f('fromAccount', {
            'currency': os.bankCurrency,
            'amount': '$_amount',
            'account': _accountLabel(_account),
          }),
          const [],
          figure: '${os.bankCurrency} $_amount',
        );
      case 'removeCard':
        return _prompt(scale, _t('removeCard'), '', const []);
      case 'removeCash':
        return _prompt(
          scale,
          _t('removeCash'),
          '${os.bankCurrency} $_amount',
          const [],
        );
      case 'takeReceipt':
        return _prompt(scale, _t('takeReceipt'), '', const []);
      case 'closing':
        return _prompt(scale, _t('sessionClosed'), _t('sessionDone'), const []);
      case 'cash':
        return _prompt(scale, _t('takeCash'), '${os.bankCurrency} $_amount', [
          _choice(
            _t('cashTaken'),
            () => _go('receiptAsk'),
            key: const Key('atm-cash-taken'),
            primary: true,
          ),
        ]);
      case 'receiptAsk':
        return _prompt(scale, _t('receiptAsk'), '', [
          _choice(_t('printReceipt'), () => _go('receipt'), primary: true),
          _choice(
            _t('noReceipt'),
            () => _go('another'),
            key: const Key('atm-no-receipt'),
          ),
        ]);
      case 'receipt':
        return _prompt(
          scale,
          _t('receipt'),
          '${os.bankName}\n${os.bankHolder}\n${_actionLabel(_action)}\n${os.bankCurrency} $_amount\n${os.bankCurrency} ${os.bankBalance}',
          [_choice(_t('finish'), () => _go('another'), primary: true)],
        );
      case 'another':
        return _prompt(scale, _t('another'), '', [
          _choice(_t('yes'), () => _go('menu'), primary: true),
          _choice(
            _t('no'),
            () => _go('card'),
            key: const Key('atm-no-another'),
          ),
        ]);
      case 'card':
        return _prompt(scale, _t('takeCard'), _t('sessionDone'), [
          _choice(
            _t('done'),
            () => _go('welcome'),
            key: const Key('atm-card-done'),
            primary: true,
          ),
        ]);
      case 'deposit':
        return _prompt(scale, _t('depositTitle'), _t('depositHint'), [
          for (final amount in [20, 50, 100])
            _choice(
              '${os.bankCurrency} $amount',
              () => setState(() {
                _amount = amount;
                _step = 'depositReview';
              }),
              primary: amount == 20,
            ),
          _choice(_t('cancel'), () => _go('menu')),
        ]);
      case 'depositReview':
        return _prompt(
          scale,
          _t('confirmDeposit'),
          _f('intoChecking', {
            'currency': os.bankCurrency,
            'amount': '$_amount',
          }),
          [
            _choice(_t('yes'), () => _commitDeposit(_amount), primary: true),
            _choice(_t('cancel'), () => _go('menu')),
          ],
        );
      case 'accepted':
        return _prompt(
          scale,
          _f('accepted', {'action': _actionLabel(_action)}),
          '${os.bankCurrency} $_amount\n${os.bankCurrency} ${os.bankBalance}',
          [
            _choice(_t('receipt'), () => _go('receipt'), primary: true),
            _choice(_t('done'), () => _go('another')),
          ],
        );
      case 'balance':
        return _prompt(scale, _t('balanceTitle'), os.bankHolder, [
          _choice(_t('receipt'), () {
            setState(() {
              _action = 'balance';
              _amount = os.bankBalance;
            });
            _go('receipt');
          }, primary: true),
          _choice(_t('anotherTx'), () => _go('menu')),
        ], figure: '${os.bankCurrency} ${os.bankBalance}');
      case 'transfer':
        return _prompt(
          scale,
          _t('transferTitle'),
          _f('transferBody', {'currency': os.bankCurrency}),
          [
            _choice(_t('confirmTransfer'), () {
              setState(() {
                _action = 'transfer';
                _amount = 50;
                _step = 'accepted';
                _message = '';
              });
            }, primary: true),
            _choice(_t('cancel'), () => _go('menu')),
          ],
        );
      case 'bills':
        return _prompt(
          scale,
          _t('billTitle'),
          _f('billBody', {'currency': os.bankCurrency}),
          [
            _choice(_t('pay'), _payBill, primary: true),
            _choice(_t('cancel'), () => _go('menu')),
          ],
        );
      case 'statement':
        return _prompt(
          scale,
          _t('statementTitle'),
          _f('statementBody', {'currency': os.bankCurrency}),
          [_choice(_t('done'), () => _go('menu'), primary: true)],
        );
      case 'insufficient':
        return _prompt(scale, _t('insufficient'), '', const []);
      case 'error':
        return _prompt(
          scale,
          _t('unable'),
          _message.isEmpty ? _t('back') : _message,
          [_choice(_t('back'), () => _go(_errorBack), primary: true)],
        );
      case 'down':
        return _prompt(scale, _t('out'), _t('closed'), [
          _choice(
            _t('restore'),
            () => _go('welcome'),
            key: const Key('atm-restore'),
            primary: true,
          ),
        ]);
      default:
        return _pinStage(scale, _t('enterPin'), _t('pinHint'), entry: true);
    }
  }

  void _openPanel(String id) {
    switch (id) {
      case 'withdraw':
        _go('withdraw');
      case 'deposit':
        _go('deposit');
      case 'balance':
        _go('balance');
      case 'bills':
        _go('bills');
      case 'statement':
        _go('statement');
      case 'transfer':
        _go('transfer');
      case 'settings':
        _go('settings');
      case 'take':
        _go('card');
    }
  }

  void _swapPanel(String id) {
    if (_layoutPick == null || _layoutPick == id) {
      setState(() => _layoutPick = _layoutPick == id ? null : id);
      return;
    }
    final order = List<String>.from(atmPanels(os));
    final first = order.indexOf(_layoutPick!);
    final second = order.indexOf(id);
    if (first < 0 || second < 0) return;
    final held = order[first];
    order[first] = order[second];
    order[second] = held;
    _layoutPick = null;
    _save((current) => current.copyWith(homeOrder: order));
  }

  Future<void> _uploadBackground() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null || !mounted) return;
    final path = await persistPickedImage(file);
    if (path == null || !mounted) return;
    _save(
      (current) =>
          current.copyWith(backgroundType: 'image', backgroundUrl: path),
    );
  }

  Widget _settings(double scale) {
    final hasImage =
        os.backgroundType == 'image' && os.backgroundUrl.isNotEmpty;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              _t('settingsTitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: skin.title,
                fontSize: 28 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 14 * scale),
            if (_settingsPage != null)
              _chip(
                _t('back'),
                false,
                () => setState(() => _settingsPage = null),
                key: const Key('atm-settings-back'),
              ),
            if (_settingsPage == null) ...[
              _chip('Display', false, () => setState(() => _settingsPage = 'display'), key: const Key('atm-cat-display')),
              SizedBox(height: 8 * scale),
              _chip('Status', false, () => setState(() => _settingsPage = 'status'), key: const Key('atm-cat-status')),
              SizedBox(height: 8 * scale),
              _chip('Bank', false, () => setState(() => _settingsPage = 'bank'), key: const Key('atm-cat-bank')),
              SizedBox(height: 8 * scale),
              _chip('Language', false, () => setState(() => _settingsPage = 'language'), key: const Key('atm-cat-language')),
            ],
            if (_settingsPage == 'display') ...[
            _section('Interface', scale),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final face in const [
                  ('teller', 'Night Teller'),
                  ('vault', 'Vault Desk'),
                  ('kiosk', 'Kiosk Grid'),
                ])
                  _chip(
                    face.$2,
                    atmFaceId(os) == face.$1,
                    () => _save((current) => current.copyWith(face: face.$1)),
                    key: Key('atm-face-${face.$1}'),
                  ),
              ],
            ),
            _section(_t('keypad'), scale),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  _t('keypadScreen'),
                  os.bankKeypad != 'external',
                  () => _save(
                    (current) => current.copyWith(bankKeypad: 'screen'),
                  ),
                  key: const Key('atm-keypad-screen'),
                ),
                _chip(
                  _t('keypadExternal'),
                  os.bankKeypad == 'external',
                  () => _save(
                    (current) => current.copyWith(bankKeypad: 'external'),
                  ),
                  key: const Key('atm-keypad-external'),
                ),
              ],
            ),
            ],
            if (_settingsPage == 'bank') ...[
            _nameField(
              scale,
              _t('bankName'),
              _bankName,
              (name) => _save((current) => current.copyWith(bankName: name)),
              key: const Key('atm-bank-name'),
            ),
            SizedBox(height: 22 * scale),
            _nameField(
              scale,
              _t('userName'),
              _userName,
              (name) => _save((current) => current.copyWith(bankHolder: name)),
              key: const Key('atm-user-name'),
            ),
            SizedBox(height: 22 * scale),
            _nameField(
              scale,
              _t('accountBalance'),
              _balance,
              _applyBalance,
              key: const Key('atm-account-balance'),
              keyboardType: TextInputType.number,
              suffix: os.bankCurrency,
            ),
            ],
            if (_settingsPage == 'status') ...[
            _nameField(
              scale,
              'Place',
              _place,
              (value) => _save((current) => current.copyWith(place: value)),
              key: const Key('atm-place'),
            ),
            SizedBox(height: 22 * scale),
            _nameField(
              scale,
              _t('time'),
              _time,
              _applyTime,
              key: const Key('atm-time'),
              keyboardType: TextInputType.datetime,
            ),
            SizedBox(height: 22 * scale),
            _nameField(
              scale,
              _t('temperature'),
              _temperature,
              _applyTemperature,
              key: const Key('atm-temperature'),
              keyboardType: TextInputType.number,
              suffix: '°C',
            ),
            SizedBox(height: 22 * scale),
            _nameField(
              scale,
              'Date',
              _date,
              _applyDate,
              key: const Key('atm-date'),
              keyboardType: TextInputType.datetime,
              allowEmpty: true,
            ),
            SizedBox(height: 28 * scale),
            Theme(
              data: ThemeData.dark(useMaterial3: true),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClockSettings(store: widget.store, device: _live),
                    PlaceSettings(store: widget.store, device: _live),
                  ],
                ),
              ),
            ),
            ],
            if (_settingsPage == 'display') ...[
            _section(_t('theme'), scale),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in kAtmSkins)
                  _chip(
                    item.name,
                    skin.id == item.id,
                    () => _save((current) => current.copyWith(shell: item.id)),
                    key: Key('atm-skin-${item.id}'),
                    swatch: item.major,
                  ),
              ],
            ),
            ],
            if (_settingsPage == 'bank') ...[
            _section(_t('currency'), scale),
            _currencyMenu(scale),
            SizedBox(height: 14 * scale),
            _nameField(
              scale,
              _t('notes'),
              _notes,
              _applyNotes,
              key: const Key('atm-notes'),
            ),
            ],
            if (_settingsPage == 'language') ...[
            _section(_t('language'), scale),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final language in osLanguages)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _chip(
                        language.native,
                        os.language == language.code,
                        () => _save(
                          (current) =>
                              current.copyWith(language: language.code),
                        ),
                        key: Key('atm-language-${language.code}'),
                      ),
                    ),
                ],
              ),
            ),
            ],
            if (_settingsPage == 'display') ...[
            _section(_t('background'), scale),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  _t('upload'),
                  false,
                  _uploadBackground,
                  key: const Key('atm-upload-background'),
                ),
                if (hasImage)
                  _chip(
                    _t('removeBg'),
                    false,
                    () => _save(
                      (current) => current.copyWith(
                        backgroundType: 'preset',
                        backgroundUrl: '',
                      ),
                    ),
                    key: const Key('atm-remove-background'),
                  ),
              ],
            ),
            SizedBox(height: 14 * scale),
            _section(_t('panels'), scale),
            _choice(
              _t('editLayout'),
              () => _go('layout'),
              key: const Key('atm-edit-layout'),
              primary: true,
            ),
            ],
            SizedBox(height: 12 * scale),
            _choice(
              _t('done'),
              () => _go('menu'),
              key: const Key('atm-settings-done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _layout(double scale, DateTime now) {
    return Column(
      children: [
        Text(
          _t('layoutHint'),
          textAlign: TextAlign.center,
          style: TextStyle(color: skin.muted, fontSize: 14 * scale),
        ),
        SizedBox(height: 8 * scale),
        Expanded(
          child: _Menu(
            scale: scale,
            skin: skin,
            face: atmFaceId(os),
            greeting: atmGreeting(_language, now.hour, os.bankHolder),
            select: _t('select'),
            panels: atmPanels(os),
            labelFor: _t,
            selected: _layoutPick,
            onOpen: _swapPanel,
          ),
        ),
        _choice(
          _t('done'),
          () => _go('settings'),
          key: const Key('atm-layout-done'),
          primary: true,
        ),
      ],
    );
  }

  Widget _customAmountInput(double scale) {
    return Center(
      child: SizedBox(
        width: 280,
        child: Material(
          color: skin.keyFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_faceRadius),
            side: BorderSide(color: skin.rule),
          ),
          clipBehavior: Clip.antiAlias,
          child: TextField(
            key: const Key('atm-custom-amount'),
            controller: _customAmount,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: skin.keyInk,
              fontSize: 32 * scale,
              fontWeight: FontWeight.w800,
            ),
            cursorColor: skin.primary,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
            ),
            onSubmitted: (_) => _submitCustom(),
          ),
        ),
      ),
    );
  }

  void _applyTime(String value) {
    final parsed = parseClockText(value);
    if (parsed == null) return;
    widget.store.updateOs(
      widget.device.id,
      (current) => pinClock(current, parsed.$1, parsed.$2),
    );
    setState(() {});
  }

  void _applyDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _save((current) => current.copyWith(dateYear: 0, dateMonth: 0, dateDay: 0));
      return;
    }
    final parsed = parseDateText(trimmed);
    if (parsed == null) return;
    _save(
      (current) => current.copyWith(
        dateYear: parsed.$1,
        dateMonth: parsed.$2,
        dateDay: parsed.$3,
      ),
    );
  }

  void _applyTemperature(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < -99 || parsed > 99) return;
    if (parsed == os.temperature) return;
    _save((current) => current.copyWith(temperature: parsed));
  }

  void _applyBalance(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0 || parsed > 100000000) return;
    if (parsed == os.bankBalance) return;
    _save((current) => current.copyWith(bankBalance: parsed));
  }

  Widget _nameField(
    double scale,
    String label,
    TextEditingController controller,
    ValueChanged<String> onName, {
    required Key key,
    TextInputType? keyboardType,
    String? suffix,
    bool allowEmpty = false,
  }) {
    return Column(
      children: [
        _section(label, scale),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: skin.keyFill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_faceRadius),
                side: BorderSide(color: skin.rule),
              ),
              clipBehavior: Clip.antiAlias,
              child: TextField(
                key: key,
                controller: controller,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: skin.keyInk,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w700,
                ),
                cursorColor: skin.primary,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  suffixText: suffix,
                  suffixStyle: TextStyle(
                    color: skin.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onChanged: (value) {
                  final name = value.trim();
                  if (name.isEmpty && !allowEmpty) return;
                  onName(allowEmpty ? value : name);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _currencyMenu(double scale) {
    final choices = atmCurrencyChoices(os.bankCurrency);
    final current = choices.where((item) => item.code == os.bankCurrency);
    final shown = current.isEmpty ? os.bankCurrency : current.first.label;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: skin.keyFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_faceRadius),
            side: BorderSide(color: skin.rule),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              GestureDetector(
                key: const Key('atm-currency'),
                onTap: () => setState(() => _currenciesOpen = !_currenciesOpen),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          shown,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: skin.keyInk,
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        _currenciesOpen ? Icons.expand_less : Icons.expand_more,
                        color: skin.keyInk,
                      ),
                    ],
                  ),
                ),
              ),
              if (_currenciesOpen)
                SizedBox(
                  height: 220,
                  child: SingleChildScrollView(
                    key: const Key('atm-currency-list'),
                    child: Column(
                      children: [
                        for (final currency in choices)
                          ListTile(
                            key: Key('atm-currency-${currency.code}'),
                            dense: true,
                            title: Text(
                              currency.label,
                              style: TextStyle(color: skin.keyInk, fontWeight: FontWeight.w600),
                            ),
                            trailing: currency.code == os.bankCurrency
                                ? Icon(Icons.check, color: skin.primary, size: 18)
                                : null,
                            onTap: () {
                              _save((current) => current.copyWith(bankCurrency: currency.code));
                              setState(() => _currenciesOpen = false);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String label, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: skin.muted,
          fontSize: 13 * scale,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _chip(
    String label,
    bool selected,
    VoidCallback onTap, {
    Key? key,
    Color? swatch,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? skin.primary : skin.keyFill,
          borderRadius: BorderRadius.circular(_faceRadius),
          border: Border.all(
            color: selected ? skin.primaryInk : skin.rule,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (swatch != null) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(color: skin.title, width: 1),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? skin.primaryInk : skin.keyInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinStage(
    double scale,
    String title,
    String subtitle, {
    bool entry = false,
  }) {
    final external = os.bankKeypad == 'external';
    return Column(
      mainAxisAlignment: external
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Text(
          title,
          key: entry ? const Key('atm-enter-pin') : null,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: skin.title,
            fontSize: 28 * scale,
            fontWeight: FontWeight.w800,
          ),
        ),
        if ((external ? _t('externalPin') : subtitle).isNotEmpty) ...[
          SizedBox(height: 6 * scale),
          Text(
            external ? _t('externalPin') : subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: skin.muted, fontSize: 16 * scale),
          ),
        ],
        SizedBox(height: 12 * scale),
        _dots(scale),
        if (!external) ...[
          SizedBox(height: 12 * scale),
          Expanded(child: _pad()),
        ],
      ],
    );
  }

  Widget _dots(double scale) {
    final dot = 22.0 * scale;
    return Row(
      key: const Key('atm-pin-dots'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 5; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: dot,
            height: dot,
            margin: EdgeInsets.symmetric(horizontal: 8 * scale),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _pin.length ? skin.title : Colors.transparent,
              border: Border.all(color: skin.title, width: 2),
            ),
          ),
      ],
    );
  }

  Widget _pad() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 3;
        const rows = 4;
        final gap = constraints.maxHeight < 320 ? 8.0 : 16.0;
        final keyH = math.max(
          36.0,
          (constraints.maxHeight - gap * (rows - 1)) / rows,
        );
        var keyW = (constraints.maxWidth - gap * (cols - 1)) / cols;
        if (keyW > keyH * 1.55) keyW = keyH * 1.55;
        Widget key(String label, VoidCallback onTap, {Key? widgetKey}) {
          return GestureDetector(
            key: widgetKey,
            onTap: onTap,
            child: Container(
              width: keyW,
              height: keyH,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: skin.keyFill,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: skin.keyInk,
                  fontSize: keyH * 0.42,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }

        final rowsOf = [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ];
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final row in rowsOf) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final n in row) ...[
                      key(n, () => _digit(n), widgetKey: Key('atm-digit-$n')),
                      if (n != row.last) SizedBox(width: gap),
                    ],
                  ],
                ),
                SizedBox(height: gap),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  key(
                    'C',
                    () => setState(() => _pin = ''),
                    widgetKey: const Key('atm-pin-clear'),
                  ),
                  SizedBox(width: gap),
                  key(
                    '0',
                    () => _digit('0'),
                    widgetKey: const Key('atm-digit-0'),
                  ),
                  SizedBox(width: gap),
                  key('⌫', _backspace, widgetKey: const Key('atm-pin-delete')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _prompt(
    double scale,
    String title,
    String body,
    List<Widget> actions, {
    String figure = '',
    Widget? field,
  }) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: skin.title,
                fontSize: 28 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (body.isNotEmpty) ...[
              SizedBox(height: 10 * scale),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: skin.muted,
                  fontSize: 16 * scale,
                  height: 1.35,
                ),
              ),
            ],
            if (figure.isNotEmpty) ...[
              SizedBox(height: 18 * scale),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    figure,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: skin.title,
                      fontSize: 72 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
            if (field != null) ...[SizedBox(height: 18 * scale), field],
            SizedBox(height: 18 * scale),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12 * scale,
              runSpacing: 12 * scale,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(
    String label,
    VoidCallback onTap, {
    Key? key,
    bool primary = false,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: UnconstrainedBox(
        child: Container(
          constraints: const BoxConstraints(minWidth: 200, minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? skin.primary : skin.keyFill,
            borderRadius: BorderRadius.circular(_faceRadius),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primary ? skin.primaryInk : skin.keyInk,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({
    required this.scale,
    required this.skin,
    required this.face,
    required this.greeting,
    required this.select,
    required this.panels,
    required this.labelFor,
    required this.onOpen,
    this.selected,
  });

  final double scale;
  final AtmSkin skin;
  final String face;
  final String greeting;
  final String select;
  final List<String> panels;
  final String Function(String key) labelFor;
  final ValueChanged<String> onOpen;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    if (face == 'vault') return _vault();
    if (face == 'kiosk') return _kiosk();
    final majors = panels.take(2).toList();
    final minors = panels.skip(2).toList();
    return Column(
      children: [
        Text(
          greeting,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: skin.title,
            fontSize: 26 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          select,
          textAlign: TextAlign.center,
          style: TextStyle(color: skin.muted, fontSize: 14 * scale),
        ),
        SizedBox(height: 14 * scale),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      for (var i = 0; i < majors.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: skin.majorInk.withValues(alpha: 0.12),
                          ),
                        Expanded(child: _slot(majors[i], i, major: true)),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: ColoredBox(
                    color: skin.minor,
                    child: Column(
                      children: [
                        for (var row = 0; row < 2; row++) ...[
                          if (row > 0)
                            Divider(height: 1, thickness: 1, color: skin.rule),
                          Expanded(
                            child: Row(
                              children: [
                                for (var col = 0; col < 3; col++) ...[
                                  if (col > 0)
                                    Container(width: 1, color: skin.rule),
                                  Expanded(
                                    child: _slot(
                                      minors[row * 3 + col],
                                      2 + row * 3 + col,
                                      major: false,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _banner(String text, {required BorderRadius radius}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 12),
      decoration: BoxDecoration(color: skin.major, borderRadius: radius),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: skin.majorInk, fontSize: 22 * scale, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _vault() {
    const cols = 4;
    final rows = <List<String>>[];
    for (var i = 0; i < panels.length; i += cols) {
      rows.add(panels.sublist(i, math.min(i + cols, panels.length)));
    }
    return Column(
      children: [
        _banner(greeting, radius: BorderRadius.circular(22)),
        SizedBox(height: 6 * scale),
        Text(select, style: TextStyle(color: skin.muted, fontSize: 13 * scale)),
        SizedBox(height: 8 * scale),
        Expanded(
          child: Column(
            children: [
              for (final row in rows)
                Expanded(
                  child: Row(
                    children: [
                      for (final id in row)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: _vaultIcon(id),
                          ),
                        ),
                      for (var i = row.length; i < cols; i++)
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vaultIcon(String id) {
    final on = selected == id;
    return GestureDetector(
      key: Key('atm-$id'),
      onTap: () => onOpen(id),
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: on ? skin.primary : skin.minor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: on ? skin.primaryInk : skin.rule, width: 2),
                ),
                child: Icon(
                  _icon(id),
                  color: on ? skin.primaryInk : skin.minorInk,
                  size: 34,
                ),
              ),
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            labelFor(id),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: skin.title,
              fontSize: 11 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kiosk() {
    final rows = <List<String>>[];
    for (var i = 0; i < panels.length; i += 2) {
      rows.add(panels.sublist(i, math.min(i + 2, panels.length)));
    }
    return Column(
      children: [
        _banner(greeting, radius: BorderRadius.zero),
        SizedBox(height: 8 * scale),
        Expanded(
          child: Column(
            children: [
              for (final row in rows)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        for (final id in row)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                key: Key('atm-$id'),
                                onTap: () => onOpen(id),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: selected == id ? skin.primary : skin.major,
                                    border: Border.all(color: skin.rule, width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      labelFor(id),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: selected == id ? skin.primaryInk : skin.majorInk,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13 * scale,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (row.length == 1) const Expanded(child: SizedBox()),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _slot(String id, int index, {required bool major}) {
    final tile = major
        ? _Major(
            icon: _icon(id),
            label: labelFor(id),
            skin: skin,
            selected: selected == id,
            onTap: () => onOpen(id),
            tileKey: Key('atm-$id'),
          )
        : _Minor(
            icon: _icon(id),
            label: labelFor(id),
            skin: skin,
            selected: selected == id,
            onTap: () => onOpen(id),
            tileKey: Key('atm-$id'),
          );
    return KeyedSubtree(key: Key('atm-slot-$index'), child: tile);
  }

  IconData _icon(String id) {
    return switch (id) {
      'deposit' => Icons.arrow_upward,
      'balance' => Icons.attach_money,
      'bills' => Icons.description_outlined,
      'statement' => Icons.receipt_long,
      'transfer' => Icons.public,
      'settings' => Icons.settings,
      'take' => Icons.credit_card,
      _ => Icons.arrow_downward,
    };
  }
}

class _Major extends StatelessWidget {
  const _Major({
    required this.icon,
    required this.label,
    required this.skin,
    required this.onTap,
    required this.tileKey,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final AtmSkin skin;
  final VoidCallback onTap;
  final Key tileKey;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: tileKey,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: skin.major,
          border: selected ? Border.all(color: skin.primary, width: 3) : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: skin.majorInk, width: 2),
                ),
                child: Icon(icon, color: skin.majorInk, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: skin.majorInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Minor extends StatelessWidget {
  const _Minor({
    required this.icon,
    required this.label,
    required this.skin,
    required this.onTap,
    required this.tileKey,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final AtmSkin skin;
  final VoidCallback onTap;
  final Key tileKey;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: tileKey,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: selected ? Border.all(color: skin.primary, width: 3) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: skin.minorInk, width: 1.4),
                ),
                child: Icon(icon, color: skin.minorInk, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: skin.minorInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.os,
    required this.name,
    required this.now,
    required this.temperature,
    required this.scale,
    required this.skin,
  });

  final OsSettings os;
  final String name;
  final DateTime now;
  final int temperature;
  final double scale;
  final AtmSkin skin;

  @override
  Widget build(BuildContext context) {
    final month = _months[now.month - 1];
    final clock = formatOsClock(now, hour24: os.clockFormat == '24');
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _Mark(),
            SizedBox(width: 10 * scale),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: skin.title,
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6 * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              os.showClock ? '$month ${now.day}, $clock' : '$month ${now.day}',
              style: TextStyle(color: skin.muted, fontSize: 12 * scale),
            ),
            SizedBox(width: 10 * scale),
            Text(
              '$temperature°C',
              style: TextStyle(
                color: skin.title,
                fontSize: 14 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 6 * scale),
            Icon(Icons.cloud, color: skin.title, size: 16 * scale),
          ],
        ),
      ],
    );
  }
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const CustomPaint(painter: _PeakPainter()),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.scale,
    required this.skin,
    required this.service,
    required this.onService,
  });

  final double scale;
  final AtmSkin skin;
  final String service;
  final VoidCallback onService;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: skin.muted, fontSize: 12 * scale);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.phone, color: skin.muted, size: 14 * scale),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Contact center: 0800 414 220    Free SMS: 414 220',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          key: const Key('atm-service'),
          onTap: onService,
          child: Text(service, style: style),
        ),
      ],
    );
  }
}

class _PeakPainter extends CustomPainter {
  const _PeakPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF16141C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.62)
      ..lineTo(size.width * 0.5, size.height * 0.28)
      ..lineTo(size.width * 0.78, size.height * 0.62);
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.72),
      Offset(size.width * 0.66, size.height * 0.72),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AtmBackdrop extends CustomPainter {
  const _AtmBackdrop({required this.skin, required this.veil});

  final AtmSkin skin;
  final bool veil;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (veil) {
      canvas.drawRect(
        rect,
        Paint()..color = skin.washB.withValues(alpha: 0.78),
      );
      return;
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [skin.washA, skin.washB, skin.washC],
        ).createShader(rect),
    );
    final dot = Paint()
      ..color = skin.light ? const Color(0x18000000) : const Color(0x12FFFFFF);
    const gap = 22.0;
    for (var y = 0.0; y < size.height; y += gap) {
      for (
        var x = (y ~/ gap) % 2 == 0 ? 0.0 : gap / 2;
        x < size.width;
        x += gap
      ) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AtmBackdrop oldDelegate) =>
      oldDelegate.skin.id != skin.id || oldDelegate.veil != veil;
}
