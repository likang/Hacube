import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:hacube/event.dart';

class ClockWidget extends StatefulWidget {
  final bool running;
  final EventBus eventBus;
  ClockWidget({this.running = true, this.eventBus});

  @override
  _ClockWidgetState createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  int seconds = 0;
  Timer _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (widget.running) {
          seconds++;
        }
      });
    });

    if (widget.eventBus != null) {
      widget.eventBus.on<ClockResetEvent>().listen((event) {
        setState(() {
          seconds = 0;
        });
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int hour = seconds ~/ (60 * 60);
    int minutes = (seconds - hour * 60 * 60) ~/ (60);
    int sec = seconds % 60;

    return IgnorePointer(
      child: Opacity(
        opacity: 1,
        child: Text(
          '${hour.toString().padLeft(2, "0")}:'
          '${minutes.toString().padLeft(2, "0")}:'
          '${sec.toString().padLeft(2, "0")}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.cyanAccent, fontSize: 24, shadows: [
            Shadow(
              offset: Offset.zero,
              blurRadius: 12,
              color: Colors.cyanAccent,
            ),
          ]),
        ),
      ),
    );
  }
}
