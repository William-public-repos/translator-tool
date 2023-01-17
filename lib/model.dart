//Author: Phlus.com

import 'dart:convert';

Translation translationFromResponse(String response) =>
    Translation.fromJson(json.decode(response));

class Translation {
  String text = '';

  Translation.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      if (json['data']['translations'] != null) {
        final translations = json['data']['translations'];
        text = translations[0]['translatedText'];
      }
    }
  }
}
