import 'package:flutter/material.dart';

/// Ride hail for a phone. Branded reads as Uber. Generic reads as Zippyride.
class RideApp extends StatefulWidget {
  const RideApp({super.key, required this.branded});

  final bool branded;

  @override
  State<RideApp> createState() => _RideAppState();
}

class _RideOption {
  const _RideOption(this.name, this.generic, this.eta, this.price, this.seats);

  final String name;
  final String generic;
  final String eta;
  final String price;
  final int seats;
}

const _options = [
  _RideOption('UberX', 'City', '4 min', '\$12.40', 4),
  _RideOption('Comfort', 'Plus', '6 min', '\$18.10', 4),
  _RideOption('UberXL', 'Van', '8 min', '\$24.00', 6),
];

const _places = [
  'Central Station',
  'Airport',
  'City Hall',
  'Harbor Docks',
  'North Hospital',
];

const _pays = ['Visa •••• 4242', 'Mastercard •••• 1881', 'Cash'];

enum _Phase { plan, driver, trip, receipt }

class _RideAppState extends State<RideApp> {
  final _pickup = TextEditingController(text: 'Current location');
  final _destination = TextEditingController();
  int _ride = 0;
  int _pay = 0;
  _Phase _phase = _Phase.plan;

  @override
  void dispose() {
    _pickup.dispose();
    _destination.dispose();
    super.dispose();
  }

  String get _brand => widget.branded ? 'Uber' : 'Zippyride';

  _RideOption get _chosen => _options[_ride];

  String _rideName(_RideOption option) =>
      widget.branded ? option.name : option.generic;

  void _request() {
    if (_destination.text.trim().isEmpty) return;
    setState(() => _phase = _Phase.driver);
  }

  @override
  Widget build(BuildContext context) {
    final ink = const Color(0xFF111111);
    return ColoredBox(
      key: const Key('ride-app'),
      color: const Color(0xFF1B2830),
      child: Column(
        children: [
          Expanded(flex: 2, child: _Map(phase: _phase, brand: _brand)),
          Flexible(
            flex: 5,
            child: Material(
              color: Colors.white,
              child: switch (_phase) {
                _Phase.plan => _plan(ink),
                _Phase.driver => _scroll(_driver(ink, onTrip: true)),
                _Phase.trip => _scroll(_driver(ink, onTrip: false)),
                _Phase.receipt => _scroll(_receipt(ink)),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _scroll(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: child,
    );
  }

  Widget _plan(Color ink) {
    final ready = _destination.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            children: [
              Text(
                _brand,
                style: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _field(
                key: const Key('ride-pickup'),
                controller: _pickup,
                hint: 'Pickup',
                icon: Icons.trip_origin,
              ),
              const SizedBox(height: 8),
              _field(
                key: const Key('ride-destination'),
                controller: _destination,
                hint: 'Where to?',
                icon: Icons.place,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final place in _places)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(place),
                          onPressed: () {
                            _destination.text = place;
                            setState(() {});
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _options.length; i++) _rideRow(i, ink),
              InkWell(
                key: const Key('ride-pay'),
                onTap: () => setState(() => _pay = (_pay + 1) % _pays.length),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, size: 18),
                      const SizedBox(width: 8),
                      Text(_pays[_pay], style: TextStyle(color: ink, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FilledButton(
            key: const Key('ride-request'),
            style: FilledButton.styleFrom(
              backgroundColor: ink,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFB9B9B9),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: ready ? _request : null,
            child: Text('Request ${_rideName(_chosen)}'),
          ),
        ),
      ],
    );
  }

  Widget _rideRow(int index, Color ink) {
    final option = _options[index];
    final selected = index == _ride;
    return InkWell(
      key: Key('ride-option-$index'),
      onTap: () => setState(() => _ride = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? ink : const Color(0xFFE4E4E4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_car, color: ink, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _rideName(option),
                    style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${option.eta} · ${option.seats} seats',
                    style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(option.price, style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      key: key,
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _driver(Color ink, {required bool onTrip}) {
    return Column(
      key: const Key('ride-driver'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          onTrip ? 'Maya is on the way' : 'Heading to ${_destination.text.trim()}',
          style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          onTrip ? '4 min · ${_chosen.eta} pickup' : 'Toyota Camry · Silver',
          style: const TextStyle(color: Color(0xFF6B6B6B)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const CircleAvatar(child: Text('M')),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Maya Ortiz', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    '4.96 · ${_rideName(_chosen)}',
                    style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '7KXP214',
                key: Key('ride-plate'),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (onTrip)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('ride-cancel'),
                  onPressed: () => setState(() => _phase = _Phase.plan),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: const Key('ride-start'),
                  style: FilledButton.styleFrom(backgroundColor: ink),
                  onPressed: () => setState(() => _phase = _Phase.trip),
                  child: const Text('Start trip'),
                ),
              ),
            ],
          )
        else
          FilledButton(
            key: const Key('ride-end'),
            style: FilledButton.styleFrom(backgroundColor: ink),
            onPressed: () => setState(() => _phase = _Phase.receipt),
            child: const Text('End trip'),
          ),
      ],
    );
  }

  Widget _receipt(Color ink) {
    return Column(
      key: const Key('ride-receipt'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Trip complete', style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(_destination.text.trim(), style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          '${_rideName(_chosen)} · ${_chosen.price}',
          style: const TextStyle(color: Color(0xFF6B6B6B)),
        ),
        const SizedBox(height: 4),
        Text(_pays[_pay], style: const TextStyle(color: Color(0xFF6B6B6B))),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('ride-done'),
          style: FilledButton.styleFrom(backgroundColor: ink),
          onPressed: () {
            _destination.clear();
            setState(() => _phase = _Phase.plan);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _Map extends StatelessWidget {
  const _Map({required this.phase, required this.brand});

  final _Phase phase;
  final String brand;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StreetPainter(active: phase != _Phase.plan && phase != _Phase.receipt),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            brand,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _StreetPainter extends CustomPainter {
  const _StreetPainter({required this.active});

  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF24343C),
    );
    final road = Paint()
      ..color = const Color(0xFF3C4C54)
      ..strokeWidth = 14;
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.42), road);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.46, size.height), road);
    canvas.drawLine(Offset(0, size.height * 0.72), Offset(size.width, size.height * 0.6), road);
    if (!active) return;
    final route = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.7)
      ..lineTo(size.width * 0.42, size.height * 0.48)
      ..lineTo(size.width * 0.68, size.height * 0.4);
    canvas.drawPath(path, route);
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.7), 6, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.4),
      7,
      Paint()..color = const Color(0xFF111111),
    );
  }

  @override
  bool shouldRepaint(covariant _StreetPainter oldDelegate) => oldDelegate.active != active;
}
