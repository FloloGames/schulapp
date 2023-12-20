import 'package:flutter/material.dart';

class SchoolTime {
  TimeOfDay _start;
  TimeOfDay _end;

  TimeOfDay get start => _start;
  TimeOfDay get end => _end;

  set start(TimeOfDay value) {
    //darf gesetzt werden? also gucken ob zu lang etc
    _start = value;
    // TODO: save..
  }

  set end(TimeOfDay value) {
    //darf gesetzt werden? also gucken ob zu lang etc
    _end = value;
    // TODO: save..
  }

  SchoolTime({
    required TimeOfDay start,
    required TimeOfDay end,
  })  : _end = end,
        _start = start;

  String getStartString() {
    String hour = start.hour < 10 ? "0${start.hour}" : start.hour.toString();
    String minute =
        start.minute < 10 ? "0${start.minute}" : start.minute.toString();
    return "$hour : $minute";
  }

  String getEndString() {
    String hour = end.hour < 10 ? "0${end.hour}" : end.hour.toString();
    String minute = end.minute < 10 ? "0${end.minute}" : end.minute.toString();
    return "$hour : $minute";
  }
}
