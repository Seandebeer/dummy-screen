import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';

/// ATM menu for a landscape iPad mounted in a machine.
class AtmScreen extends StatefulWidget {
  const AtmScreen({super.key, required this.store, required this.device});

  final StageStore store;
  final PropDevice device;

  @override
  State<AtmScreen> createState() => _AtmScreenState();
}

class _AtmScreenState extends State<AtmScreen> {
  String _step = 'menu';
  String _pin = '';
  String _message = '';
  int _amount = 0;

  OsSettings get os => widget.device.os;

  void _go(String step) => setState(() {
    _step = step;
    _message = '';
    if (step == 'pin' || step == 'enter') _pin = '';
  });

  void _withdraw(int amount) {
    if (amount > os.bankBalance) {
      setState(() {
        _message = 'That amount is not available.';
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
      _step = 'confirm';
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
            final scale = (constraints.maxWidth / 1100).clamp(0.62, 1.15);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                22 * scale,
                16 * scale,
                22 * scale,
                12 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(name: os.bankName, now: now, scale: scale),
                  SizedBox(height: 14 * scale),
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
      case 'withdraw':
        return _sheet(
          scale,
          'Money Withdrawal',
          _amount == 0 ? 'Choose an amount' : '${os.bankCurrency} $_amount',
          [
            for (final amount in [20, 40, 60, 100])
              _choice(
                '${os.bankCurrency} $amount',
                () => _withdraw(amount),
                key: Key('atm-amount-$amount'),
              ),
          ],
        );
      case 'deposit':
        return _sheet(scale, 'Money Deposit', 'Notes stay on this screen.', [
          _choice('Deposit ${os.bankCurrency} 100', () {
            widget.store.updateOs(
              widget.device.id,
              (current) =>
                  current.copyWith(bankBalance: current.bankBalance + 100),
            );
            _go('confirm');
          }),
          _choice('Cancel', () => _go('menu')),
        ]);
      case 'balance':
        return _sheet(
          scale,
          'Balance Inquiry',
          '${os.bankCurrency} ${os.bankBalance}',
          [
            _choice('Receipt', () => _go('receipt')),
            _choice('Another transaction', () => _go('menu')),
          ],
        );
      case 'transfer':
        return _sheet(
          scale,
          'Internal Transfer',
          'Move ${os.bankCurrency} 50 to savings.',
          [
            _choice('Confirm transfer', () => _go('confirm')),
            _choice('Cancel', () => _go('menu')),
          ],
        );
      case 'bills':
        return _sheet(scale, 'Bill Payment', 'Power · ${os.bankCurrency} 40', [
          _choice('Pay', () {
            if (40 > os.bankBalance) {
              setState(() {
                _message = 'That amount is not available.';
                _step = 'error';
              });
            } else {
              widget.store.updateOs(
                widget.device.id,
                (current) =>
                    current.copyWith(bankBalance: current.bankBalance - 40),
              );
              _go('confirm');
            }
          }),
          _choice('Cancel', () => _go('menu')),
        ]);
      case 'statement':
        return _sheet(scale, 'Mini Statement', 'Market · Transit · Power', [
          _choice('Done', () => _go('menu')),
        ]);
      case 'pin':
        return _sheet(scale, 'PIN Change', _pin.padRight(4, '·'), [
          _pad(onDone: () => _go('confirm')),
        ]);
      case 'enter':
        return _sheet(scale, 'Enter PIN', _pin.padRight(4, '·'), [
          _pad(onDone: () => _go('menu')),
        ]);
      case 'card':
        return _sheet(scale, 'Insert card', 'The card stays on this screen.', [
          _choice(
            'Card inserted',
            () => _go('enter'),
            key: const Key('atm-inserted'),
          ),
          _choice('Cancel', () => _go('menu')),
        ]);
      case 'take':
        return _sheet(
          scale,
          'Please take your card',
          'The session is finished.',
          [
            _choice('Done', () => _go('menu')),
            _choice('New customer', () => _go('card')),
          ],
        );
      case 'confirm':
        return _sheet(scale, 'Confirmed', 'The transaction is complete.', [
          _choice('Receipt', () => _go('receipt')),
          _choice('Done', () => _go('menu')),
        ]);
      case 'receipt':
        return _sheet(
          scale,
          'Receipt',
          '${os.bankName}\n${os.bankHolder}\nBalance ${os.bankCurrency} ${os.bankBalance}',
          [_choice('Finish', () => _go('menu'))],
        );
      case 'error':
        return _sheet(
          scale,
          'Unable to continue',
          _message.isEmpty ? 'Try again.' : _message,
          [_choice('Back', () => _go('menu'))],
        );
      case 'down':
        return _sheet(scale, 'Out of service', 'This machine is closed.', [
          _choice('Restore', () => _go('menu'), key: const Key('atm-restore')),
        ]);
      default:
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
          onPin: () => _go('pin'),
          onTake: () => _go('take'),
        );
    }
  }

  Widget _sheet(double scale, String title, String body, List<Widget> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6 * scale),
        Text(
          body,
          style: TextStyle(
            color: const Color(0xFFB7B3C7),
            fontSize: 16 * scale,
          ),
        ),
        SizedBox(height: 16 * scale),
        Expanded(
          child: Align(
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: 10 * scale,
              runSpacing: 10 * scale,
              children: actions,
            ),
          ),
        ),
      ],
    );
  }

  Widget _choice(String label, VoidCallback onTap, {Key? key}) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2638),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _pad({required VoidCallback onDone}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var n = 1; n <= 9; n++) _digit('$n', onDone),
        _digit('0', onDone),
      ],
    );
  }

  Widget _digit(String n, VoidCallback onDone) {
    return GestureDetector(
      onTap: () => setState(() {
        if (_pin.length < 4) _pin += n;
        if (_pin.length == 4) onDone();
      }),
      child: Container(
        width: 56,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2638),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          n,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good $part, $holder',
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF16141C),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
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
    return Row(
      children: [
        const _Mark(),
        SizedBox(width: 10 * scale),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$month ${now.day}, $clock',
              style: TextStyle(
                color: const Color(0xFFB7B3C7),
                fontSize: 12 * scale,
              ),
            ),
            Text(
              '18°C',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(width: 8 * scale),
        Container(
          width: 42 * scale,
          height: 32 * scale,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.cloud,
            color: const Color(0xFF16141C),
            size: 18 * scale,
          ),
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
