import 'package:flutter/material.dart';

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const CustomTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
  }

  @override
  void didUpdateWidget(covariant CustomTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTime != widget.initialTime) {
      setState(() {
        _hour = widget.initialTime.hour;
        _minute = widget.initialTime.minute;
      });
    }
  }

  void _notifyParent() {
    widget.onTimeChanged(TimeOfDay(hour: _hour, minute: _minute));
  }

  void _changeHour(int delta) {
    setState(() {
      _hour += delta;
      if (_hour > 23) _hour = 0;
      if (_hour < 0) _hour = 23;
    });
    _notifyParent();
  }

  void _changeMinute(int delta) {
    setState(() {
      _minute += delta;
      if (_minute >= 60) {
        _minute = 0;
        _changeHour(1);
      } else if (_minute < 0) {
        _minute = 59;
        _changeHour(-1);
      }
    });
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Preset buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPresetButton("Pagi ☀️", 7, 0),
            _buildPresetButton("Sore 🌤️", 16, 0),
          ],
        ),
        const SizedBox(height: 16),
        // Time picker with buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeControl(
              value: _hour,
              label: "JAM",
              onUp: () => _changeHour(1),
              onDown: () => _changeHour(-1),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                ":",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            _buildTimeControl(
              value: _minute,
              label: "MENIT",
              onUp: () => _changeMinute(1),
              onDown: () => _changeMinute(-1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, int h, int m) {
    bool isSelected = _hour == h && _minute == m;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _hour = h;
          _minute = m;
        });
        _notifyParent();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 2 : 0,
        side: BorderSide(color: isSelected ? Colors.green : Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTimeControl({
    required int value,
    required String label,
    required VoidCallback onUp,
    required VoidCallback onDown,
  }) {
    return Column(
      children: [
        // Up button
        InkWell(
          onTap: onUp,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 32,
              color: Colors.green,
            ),
          ),
        ),
        // Value display
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        // Label
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        // Down button
        InkWell(
          onTap: onDown,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 32,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }
}
