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

/// Landscape ATM for an iPad mounted in a machine.
///
/// The screen opens on a 5-digit PIN. Any five digits unlock it. Every
/// later screen stays centered, and withdrawal runs from account through
/// cash, receipt, and card.
class AtmScreen extends StatefulWidget {
  const AtmScreen({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<AtmScreen> createState() => _AtmScreenState();
}

class _AtmScreenState extends State<AtmScreen> {
  String _step = 'pin';
  String _pin = '';
  String _message = '';
  String _errorBack = 'menu';
  String _account = 'checking';
  String _action = '';
  int _amount = 0;
  String? _layoutPick;
  late final TextEditingController _bankName;
  late final TextEditingController _userName;
  late final TextEditingController _time;
  late final TextEditingController _temperature;
  late final TextEditingController _balance;
  late final TextEditingController _notes;
  late final TextEditingController _customAmount;
  Timer? _fundsTimer;

  @override
  void initState() {
    super.initState();
    final current = _live;
    _bankName = TextEditingController(text: current.os.bankName);
    _userName = TextEditingController(text: current.os.bankHolder);
    _time = TextEditingController(
      text: atmClock(propNow(current.clockOffsetMinutes)),
    );
    _temperature = TextEditingController(text: '${current.os.temperature}');
    _balance = TextEditingController(text: '${current.os.bankBalance}');
    _notes = TextEditingController(text: atmNotes(current.os).join(', '));
    _customAmount = TextEditingController();
  }

  @override
  void dispose() {
    _fundsTimer?.cancel();
    _bankName.dispose();
    _userName.dispose();
    _time.dispose();
    _temperature.dispose();
    _balance.dispose();
    _notes.dispose();
    _customAmount.dispose();
    super.dispose();
  }

  PropDevice get _live =>
      widget.store.deviceById(widget.device.id) ?? widget.device;

  OsSettings get os => _live.os;

  AtmSkin get skin => atmSkinFor(os.shell);

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
    setState(() {
      _step = step;
      _message = '';
      if (step == 'pin') _pin = '';
      if (step == 'settings') _balance.text = '${os.bankBalance}';
      if (step != 'layout') _layoutPick = null;
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

  void _commitWithdraw() {
    widget.store.updateOs(
      widget.device.id,
      (current) => current.copyWith(bankBalance: current.bankBalance - _amount),
    );
    setState(() {
      _action = 'withdraw';
      _step = 'cash';
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
    final now = propNow(_live.clockOffsetMinutes);
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
        ],
      ),
    );
  }

  Widget _body(double scale, DateTime now) {
    switch (_step) {
      case 'pin':
        return _pinStage(scale, _t('enterPin'), _t('pinHint'), entry: true);
      case 'menu':
        return _Menu(
          scale: scale,
          skin: skin,
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
            () => _go('pin'),
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
            () => _go('pin'),
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
            _nameField(
              scale,
              _t('bankName'),
              _bankName,
              (name) => _save((current) => current.copyWith(bankName: name)),
              key: const Key('atm-bank-name'),
            ),
            SizedBox(height: 14 * scale),
            _nameField(
              scale,
              _t('userName'),
              _userName,
              (name) => _save((current) => current.copyWith(bankHolder: name)),
              key: const Key('atm-user-name'),
            ),
            SizedBox(height: 14 * scale),
            _nameField(
              scale,
              _t('accountBalance'),
              _balance,
              _applyBalance,
              key: const Key('atm-account-balance'),
              keyboardType: TextInputType.number,
              suffix: os.bankCurrency,
            ),
            SizedBox(height: 14 * scale),
            _nameField(
              scale,
              _t('time'),
              _time,
              _applyTime,
              key: const Key('atm-time'),
              keyboardType: TextInputType.datetime,
            ),
            SizedBox(height: 14 * scale),
            _nameField(
              scale,
              _t('temperature'),
              _temperature,
              _applyTemperature,
              key: const Key('atm-temperature'),
              keyboardType: TextInputType.number,
              suffix: '°C',
            ),
            SizedBox(height: 14 * scale),
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
            SizedBox(height: 14 * scale),
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
            SizedBox(height: 14 * scale),
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
            SizedBox(height: 14 * scale),
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
            borderRadius: BorderRadius.circular(14),
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
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return;
    final shown = propNow(_live.clockOffsetMinutes);
    final delta = (hour * 60 + minute) - (shown.hour * 60 + shown.minute);
    widget.store.setClockOffset(
      widget.device.id,
      _live.clockOffsetMinutes + delta,
    );
    setState(() {});
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
                borderRadius: BorderRadius.circular(14),
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
                  if (name.isEmpty) return;
                  onName(name);
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
    final value = choices.any((item) => item.code == os.bankCurrency)
        ? os.bankCurrency
        : 'USD';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: skin.keyFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: skin.rule),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('atm-currency'),
                isExpanded: true,
                value: value,
                menuMaxHeight: 320,
                dropdownColor: skin.keyFill,
                borderRadius: BorderRadius.circular(14),
                iconEnabledColor: skin.keyInk,
                style: TextStyle(
                  color: skin.keyInk,
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  for (final currency in choices)
                    DropdownMenuItem(
                      key: Key('atm-currency-${currency.code}'),
                      value: currency.code,
                      child: Text(
                        currency.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: skin.keyInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
                onChanged: (code) {
                  if (code == null) return;
                  _save((current) => current.copyWith(bankCurrency: code));
                },
              ),
            ),
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
          borderRadius: BorderRadius.circular(14),
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
    return Column(
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
        SizedBox(height: 6 * scale),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: skin.muted, fontSize: 14 * scale),
        ),
        SizedBox(height: 14 * scale),
        _dots(scale),
        SizedBox(height: 16 * scale),
        Expanded(
          child: FittedBox(fit: BoxFit.scaleDown, child: _pad(scale)),
        ),
      ],
    );
  }

  Widget _dots(double scale) {
    return Row(
      key: const Key('atm-pin-dots'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            width: 16 * scale,
            height: 16 * scale,
            margin: EdgeInsets.symmetric(horizontal: 6 * scale),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _pin.length ? skin.title : Colors.transparent,
              border: Border.all(color: skin.title, width: 1.6),
            ),
          ),
      ],
    );
  }

  Widget _pad(double scale) {
    final gap = 10 * scale;
    Widget key(String label, VoidCallback onTap, {Key? widgetKey}) {
      return GestureDetector(
        key: widgetKey,
        onTap: onTap,
        child: Container(
          width: 74 * scale,
          height: 58 * scale,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: skin.keyFill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: skin.keyInk,
              fontSize: 22 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows) ...[
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
            key('0', () => _digit('0'), widgetKey: const Key('atm-digit-0')),
            SizedBox(width: gap),
            key('⌫', _backspace, widgetKey: const Key('atm-pin-delete')),
          ],
        ),
      ],
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
            borderRadius: BorderRadius.circular(14),
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
    required this.greeting,
    required this.select,
    required this.panels,
    required this.labelFor,
    required this.onOpen,
    this.selected,
  });

  final double scale;
  final AtmSkin skin;
  final String greeting;
  final String select;
  final List<String> panels;
  final String Function(String key) labelFor;
  final ValueChanged<String> onOpen;
  final String? selected;

  @override
  Widget build(BuildContext context) {
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
    required this.name,
    required this.now,
    required this.temperature,
    required this.scale,
    required this.skin,
  });

  final String name;
  final DateTime now;
  final int temperature;
  final double scale;
  final AtmSkin skin;

  @override
  Widget build(BuildContext context) {
    final month = _months[now.month - 1];
    final clock = atmClock(now);
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
              '$month ${now.day}, $clock',
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

String atmClock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

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
