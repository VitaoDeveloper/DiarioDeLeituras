import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const Locale appLocale = Locale('pt', 'BR');

Future<void> initializeFormatting() =>
    initializeDateFormatting(appLocale.toString());

String formatDate(DateTime value) =>
    DateFormat('dd/MM/yyyy', appLocale.toString()).format(value);

String formatMonthYear(DateTime value) =>
    DateFormat('MMMM yyyy', appLocale.toString()).format(value);

String formatMonthShort(int month) =>
    DateFormat.MMM(appLocale.toString()).format(DateTime(2020, month));

String formatInteger(double value) =>
    NumberFormat('#,##0', appLocale.toString()).format(value.round());

/// Rótulo curto de dia usado nos tooltips dos gráficos mensais.
String formatDayMonth(int day, DateTime reference) => DateFormat(
  "d 'de' MMM",
  appLocale.toString(),
).format(DateTime(reference.year, reference.month, day)).replaceAll('.', '');

String formatDateTime(DateTime value) =>
    DateFormat('dd/MM/yyyy HH:mm', appLocale.toString()).format(value);

String formatRating(double value) =>
    NumberFormat('#,##0.0', appLocale.toString()).format(value);
