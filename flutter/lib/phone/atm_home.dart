import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';

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
  String _draft = '';
  String _message = '';
  String _errorBack = 'menu';
  String _account = 'Checking';
  String _action = '';
  int _amount = 0;

  OsSettings get os {
    final live = widget.store.deviceById(widget.device.id);
    return live?.os ?? widget.device.os;
  }

  void _go(String step) => setState(() {
    _step = step;
    _message = '';
    if (step == 'pin' || step == 'pinchange' || step == 'pinagain') {
      _pin = '';
    }
  });

  void _digit(String value) {
    if (_pin.length >= 5) return;
    setState(() {
      _pin += value;
      if (_pin.length < 5) return;
      if (_step == 'pin') {
        _pin = '';
        _step = 'menu';
      } else if (_step == 'pinchange') {
        _draft = _pin;
        _pin = '';
        _step = 'pinagain';
      } else if (_step == 'pinagain') {
        final matched = _pin == _draft;
        _pin = '';
        if (matched) {
          _step = 'pinchanged';
        } else {
          _message = 'Those PINs do not match.';
          _errorBack = 'pinchange';
          _step = 'error';
        }
      }
    });
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _chooseAmount(int amount) {
    if (amount > os.bankBalance) {
      setState(() {
        _message = 'That amount is not available.';
        _errorBack = 'amount';
        _step = 'error';
      });
      return;
    }
    setState(() {
      _amount = amount;
      _step = 'review';
    });
  }

  void _commitWithdraw() {
    widget.store.updateOs(
      widget.device.id,
      (current) => current.copyWith(bankBalance: current.bankBalance - _amount),
    );
    setState(() {
      _action = 'Withdrawal';
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
      _action = 'Deposit';
      _step = 'accepted';
    });
  }

  void _payBill() {
    const amount = 40;
    if (amount > os.bankBalance) {
      setState(() {
        _message = 'That amount is not available.';
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
      _action = 'Bill payment';
      _step = 'accepted';
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = propNow(widget.device.clockOffsetMinutes);
    return Stack(
      key: const Key('atm-home'),
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: CustomPaint(painter: _AtmBackdrop())),
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
                  _Header(name: os.bankName, now: now, scale: scale),
                  SizedBox(height: 12 * scale),
                  Expanded(child: _body(scale, now)),
                  SizedBox(height: 8 * scale),
                  _Footer(scale: scale, onService: () => _go('down')),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _body(double scale, DateTime now) {
    switch (_step) {
      case 'pin':
        return _pinStage(
          scale,
          'Enter PIN',
          'Any 5 digits unlock this machine.',
        );
      case 'pinchange':
        return _pinStage(scale, 'Choose a new PIN', 'Enter 5 digits.');
      case 'pinagain':
        return _pinStage(scale, 'Enter it again', 'Repeat the new PIN.');
      case 'menu':
        return _Menu(
          scale: scale,
          holder: os.bankHolder,
          now: now,
          onWithdraw: () => _go('withdraw'),
          onDeposit: () => _go('deposit'),
          onBalance: () => _go('balance'),
          onBills: () => _go('bills'),
          onStatement: () => _go('statement'),
          onTransfer: () => _go('transfer'),
          onPin: () => _go('pinchange'),
          onTake: () => _go('card'),
        );
      case 'withdraw':
        return _prompt(scale, 'Withdrawal', 'Which account?', [
          _choice(
            'Checking',
            () => setState(() {
              _account = 'Checking';
              _step = 'amount';
            }),
            key: const Key('atm-account-checking'),
            primary: true,
          ),
          _choice(
            'Savings',
            () => setState(() {
              _account = 'Savings';
              _step = 'amount';
            }),
            key: const Key('atm-account-savings'),
          ),
          _choice('Cancel', () => _go('menu')),
        ]);
      case 'amount':
        return _prompt(
          scale,
          'Choose an amount',
          '$_account · ${os.bankCurrency} ${os.bankBalance} available',
          [
            for (final amount in [20, 40, 60, 100])
              _choice(
                '${os.bankCurrency} $amount',
                () => _chooseAmount(amount),
                key: Key('atm-amount-$amount'),
                primary: amount == 20,
              ),
            _choice('Back', () => _go('withdraw')),
          ],
        );
      case 'review':
        return _prompt(
          scale,
          'Confirm withdrawal',
          '${os.bankCurrency} $_amount from $_account',
          [
            _choice(
              'Confirm',
              _commitWithdraw,
              key: const Key('atm-confirm'),
              primary: true,
            ),
            _choice('Cancel', () => _go('menu')),
          ],
        );
      case 'cash':
        return _prompt(
          scale,
          'Please take your cash',
          '${os.bankCurrency} $_amount',
          [
            _choice(
              'Cash taken',
              () => _go('receiptAsk'),
              key: const Key('atm-cash-taken'),
              primary: true,
            ),
          ],
        );
      case 'receiptAsk':
        return _prompt(scale, 'Would you like a receipt?', '', [
          _choice('Print receipt', () => _go('receipt'), primary: true),
          _choice(
            'No receipt',
            () => _go('another'),
            key: const Key('atm-no-receipt'),
          ),
        ]);
      case 'receipt':
        return _prompt(
          scale,
          'Receipt',
          '${os.bankName}\n${os.bankHolder}\n$_action\n${os.bankCurrency} $_amount\nBalance ${os.bankCurrency} ${os.bankBalance}',
          [_choice('Finish', () => _go('another'), primary: true)],
        );
      case 'another':
        return _prompt(scale, 'Another transaction?', '', [
          _choice('Yes', () => _go('menu'), primary: true),
          _choice('No', () => _go('card'), key: const Key('atm-no-another')),
        ]);
      case 'card':
        return _prompt(
          scale,
          'Please take your card',
          'This session is finished.',
          [
            _choice(
              'Done',
              () => _go('pin'),
              key: const Key('atm-card-done'),
              primary: true,
            ),
          ],
        );
      case 'deposit':
        return _prompt(scale, 'Deposit', 'Choose an amount to add.', [
          for (final amount in [20, 50, 100])
            _choice(
              '${os.bankCurrency} $amount',
              () => setState(() {
                _amount = amount;
                _step = 'depositReview';
              }),
              primary: amount == 20,
            ),
          _choice('Cancel', () => _go('menu')),
        ]);
      case 'depositReview':
        return _prompt(
          scale,
          'Confirm deposit',
          '${os.bankCurrency} $_amount into Checking',
          [
            _choice('Confirm', () => _commitDeposit(_amount), primary: true),
            _choice('Cancel', () => _go('menu')),
          ],
        );
      case 'accepted':
        return _prompt(
          scale,
          '$_action accepted',
          '${os.bankCurrency} $_amount\nBalance ${os.bankCurrency} ${os.bankBalance}',
          [
            _choice('Receipt', () => _go('receipt'), primary: true),
            _choice('Done', () => _go('another')),
          ],
        );
      case 'balance':
        return _prompt(
          scale,
          'Balance Inquiry',
          '${os.bankHolder}\n${os.bankCurrency} ${os.bankBalance}',
          [
            _choice('Receipt', () {
              setState(() {
                _action = 'Balance';
                _amount = os.bankBalance;
              });
              _go('receipt');
            }, primary: true),
            _choice('Another transaction', () => _go('menu')),
          ],
        );
      case 'transfer':
        return _prompt(
          scale,
          'Internal transfer',
          'Move ${os.bankCurrency} 50 from Checking to Savings.',
          [
            _choice('Confirm transfer', () {
              setState(() {
                _action = 'Transfer';
                _amount = 50;
                _step = 'accepted';
                _message = '';
              });
            }, primary: true),
            _choice('Cancel', () => _go('menu')),
          ],
        );
      case 'bills':
        return _prompt(scale, 'Bill payment', 'Power · ${os.bankCurrency} 40', [
          _choice('Pay', _payBill, primary: true),
          _choice('Cancel', () => _go('menu')),
        ]);
      case 'statement':
        return _prompt(
          scale,
          'Mini statement',
          'Market · ${os.bankCurrency} 18\nTransit · ${os.bankCurrency} 12\nPower · ${os.bankCurrency} 40',
          [_choice('Done', () => _go('menu'), primary: true)],
        );
      case 'pinchanged':
        return _prompt(scale, 'PIN updated', 'The next customer can use it.', [
          _choice('Done', () => _go('menu'), primary: true),
        ]);
      case 'error':
        return _prompt(
          scale,
          'Unable to continue',
          _message.isEmpty ? 'Try again.' : _message,
          [_choice('Back', () => _go(_errorBack), primary: true)],
        );
      case 'down':
        return _prompt(scale, 'Out of service', 'This machine is closed.', [
          _choice(
            'Restore',
            () => _go('pin'),
            key: const Key('atm-restore'),
            primary: true,
          ),
        ]);
      default:
        return _prompt(scale, 'Enter PIN', '', [
          _choice('Continue', () => _go('pin'), primary: true),
        ]);
    }
  }

  Widget _pinStage(double scale, String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          key: title == 'Enter PIN' ? const Key('atm-enter-pin') : null,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28 * scale,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6 * scale),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFB7B3C7),
            fontSize: 14 * scale,
          ),
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
              color: i < _pin.length ? Colors.white : Colors.transparent,
              border: Border.all(color: Colors.white, width: 1.6),
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
            color: const Color(0xFF2A2638),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
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
    List<Widget> actions,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
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
                  color: const Color(0xFFB7B3C7),
                  fontSize: 16 * scale,
                  height: 1.35,
                ),
              ),
            ],
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
      child: Container(
        constraints: const BoxConstraints(minWidth: 148, minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? const Color(0xFFF4F1EA) : const Color(0xFF2A2638),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primary ? const Color(0xFF16141C) : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({
    required this.scale,
    required this.holder,
    required this.now,
    required this.onWithdraw,
    required this.onDeposit,
    required this.onBalance,
    required this.onBills,
    required this.onStatement,
    required this.onTransfer,
    required this.onPin,
    required this.onTake,
  });

  final double scale;
  final String holder;
  final DateTime now;
  final VoidCallback onWithdraw;
  final VoidCallback onDeposit;
  final VoidCallback onBalance;
  final VoidCallback onBills;
  final VoidCallback onStatement;
  final VoidCallback onTransfer;
  final VoidCallback onPin;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final part = now.hour < 12
        ? 'Morning'
        : now.hour < 17
        ? 'Afternoon'
        : 'Evening';
    return Column(
      children: [
        Text(
          'Good $part, $holder',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          'Please select your transaction',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFB7B3C7),
            fontSize: 14 * scale,
          ),
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
                      Expanded(
                        child: _Major(
                          icon: Icons.arrow_downward,
                          label: 'Money\nWithdrawal',
                          onTap: onWithdraw,
                          tileKey: const Key('atm-withdraw'),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0x14000000),
                      ),
                      Expanded(
                        child: _Major(
                          icon: Icons.arrow_upward,
                          label: 'Money\nDeposit',
                          onTap: onDeposit,
                          tileKey: const Key('atm-deposit'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: ColoredBox(
                    color: const Color(0xFF221F2C),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _minor(
                                Icons.attach_money,
                                'Balance Inquiry',
                                onBalance,
                                const Key('atm-balance'),
                              ),
                              _rule(),
                              _minor(
                                Icons.description_outlined,
                                'Bill Payment',
                                onBills,
                                const Key('atm-bills'),
                              ),
                              _rule(),
                              _minor(
                                Icons.receipt_long,
                                'Mini Statement',
                                onStatement,
                                const Key('atm-statement'),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0x22FFFFFF),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              _minor(
                                Icons.public,
                                'Internal Transfer',
                                onTransfer,
                                const Key('atm-transfer'),
                              ),
                              _rule(),
                              _minor(
                                Icons.dialpad,
                                'PIN Change',
                                onPin,
                                const Key('atm-pin'),
                              ),
                              _rule(),
                              _minor(
                                Icons.credit_card,
                                'Take card',
                                onTake,
                                const Key('atm-take'),
                              ),
                            ],
                          ),
                        ),
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

  Widget _minor(IconData icon, String label, VoidCallback onTap, Key key) {
    return Expanded(
      child: _Minor(icon: icon, label: label, onTap: onTap, tileKey: key),
    );
  }

  Widget _rule() => Container(width: 1, color: const Color(0x22FFFFFF));
}

class _Major extends StatelessWidget {
  const _Major({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tileKey,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Key tileKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: tileKey,
      onTap: onTap,
      child: ColoredBox(
        color: const Color(0xFFF4F1EA),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF16141C), width: 2),
                ),
                child: Icon(icon, color: const Color(0xFF16141C), size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF16141C),
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
    required this.onTap,
    required this.tileKey,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Key tileKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: tileKey,
      onTap: onTap,
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
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.now, required this.scale});

  final String name;
  final DateTime now;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final month = _months[now.month - 1];
    final clock =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
                  color: Colors.white,
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
              style: TextStyle(
                color: const Color(0xFFB7B3C7),
                fontSize: 12 * scale,
              ),
            ),
            SizedBox(width: 10 * scale),
            Text(
              '18°C',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 6 * scale),
            Icon(Icons.cloud, color: Colors.white, size: 16 * scale),
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
  const _Footer({required this.scale, required this.onService});

  final double scale;
  final VoidCallback onService;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: const Color(0xFFB7B3C7),
      fontSize: 12 * scale,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.phone, color: const Color(0xFFB7B3C7), size: 14 * scale),
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
          child: Text('Service', style: style),
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
  const _AtmBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF221C38), Color(0xFF14121C), Color(0xFF10141E)],
        ).createShader(rect),
    );
    final dot = Paint()..color = const Color(0x12FFFFFF);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
