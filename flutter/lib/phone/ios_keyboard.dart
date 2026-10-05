import 'package:flutter/material.dart';

/// Opens the prop keyboard. The field stays read-only so the device keyboard
/// never comes up over the filmed screen.
Future<void> openIosKeyboard(
  BuildContext context,
  TextEditingController controller, {
  bool numeric = false,
  ValueChanged<String>? onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFFD1D5DB),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
        child: numeric
            ? _rows(context, controller, onChanged, const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['⌫', '0', 'done'],
              ])
            : _rows(context, controller, onChanged, const [
                ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
                ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
                ['z', 'x', 'c', 'v', 'b', 'n', 'm', '⌫'],
                [' ', '.', 'done'],
              ]),
      );
    },
  );
}

Widget _rows(
  BuildContext context,
  TextEditingController controller,
  ValueChanged<String>? onChanged,
  List<List<String>> rows,
) {
  void type(String key) {
    final text = controller.text;
    final next = key == '⌫'
        ? (text.isEmpty ? text : text.substring(0, text.length - 1))
        : key == 'done'
            ? text
            : '$text${key == ' ' ? ' ' : key}';
    if (key == 'done') {
      Navigator.pop(context);
      return;
    }
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    onChanged?.call(next);
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final row in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              for (final key in row)
                Expanded(
                  flex: key == ' ' ? 4 : 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: key == 'done' ? const Color(0xFF0A84FF) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        onTap: () => type(key),
                        child: SizedBox(
                          height: 42,
                          child: Center(
                            child: Text(
                              key == ' ' ? 'space' : key,
                              style: TextStyle(
                                color: key == 'done' ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}
