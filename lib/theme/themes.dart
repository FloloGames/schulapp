import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final lightTheme = ThemeData.light().copyWith(
  cardColor: const Color.fromARGB(223, 206, 206, 206),
  textTheme: GoogleFonts.libreFranklinTextTheme(Typography.blackCupertino),
);

final darkTheme = ThemeData.dark().copyWith(
  cardColor: const Color.fromARGB(223, 12, 10, 12),
  textTheme: GoogleFonts.libreFranklinTextTheme(Typography.whiteCupertino),
  // textTheme: GoogleFonts.preahvihearTextTheme(Typography.whiteCupertino),
);
