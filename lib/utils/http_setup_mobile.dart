import 'dart:io';
import 'package:gold_app/utils/custom_http_overrides.dart';

void setupHttpOverrides() {
  HttpOverrides.global = CustomHttpOverrides();
}
