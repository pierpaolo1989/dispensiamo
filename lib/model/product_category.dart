import 'package:flutter/material.dart';

enum ProductCategory {
  uncategorized,
  food,
  beverages,
  personalCare,
  homeCare,
  pets,
  other;

  static ProductCategory fromId(Object? id) {
    for (final category in values) {
      if (category.name == id) return category;
    }
    return uncategorized;
  }

  Color get color => switch (this) {
        uncategorized => const Color(0xFF888888),
        food => const Color(0xFF4D8A35),
        beverages => const Color(0xFF3389A8),
        personalCare => const Color(0xFF8A61A8),
        homeCare => const Color(0xFFE08A36),
        pets => const Color(0xFFB65B58),
        other => const Color(0xFF526477),
      };

  static ProductCategory suggestForName(String name) {
        final normalized = _normalize(name);
        final sanitized = String.fromCharCodes(
          normalized.codeUnits.map(
            (character) => _isWordCharacter(character) ? character : 32,
          ),
        );
        final words = sanitized.split(' ').where((word) => word.isNotEmpty).toSet();
    for (final category in const [
      beverages,
      personalCare,
      homeCare,
      pets,
      food,
    ]) {
      if (words.any(_keywords[category]!.contains)) return category;
    }
    return uncategorized;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('à', 'a')
      .replaceAll('è', 'e')
      .replaceAll('é', 'e')
      .replaceAll('ì', 'i')
      .replaceAll('ò', 'o')
      .replaceAll('ù', 'u');

  static bool _isWordCharacter(int character) =>
      (character >= 97 && character <= 122) ||
      (character >= 48 && character <= 57);

  static const _keywords = <ProductCategory, Set<String>>{
    beverages: {
      'acqua',
      'acque',
      'birra',
      'birre',
      'vino',
      'vini',
      'succo',
      'succhi',
      'bibita',
      'bibite',
      'cola',
      'coca',
      'aranciata',
      'caffe',
      'te',
      'bevanda',
      'bevande',
      'water',
      'beer',
      'wine',
      'juice',
      'drink',
      'drinks',
      'coffee',
      'tea',
    },
    personalCare: {
      'shampoo',
      'balsamo',
      'dentifricio',
      'dentifrici',
      'spazzolino',
      'spazzolini',
      'deodorante',
      'deodoranti',
      'bagnoschiuma',
      'sapone',
      'saponi',
      'crema',
      'creme',
      'rasoio',
      'assorbenti',
      'pannolini',
      'cosmetici',
      'toothpaste',
      'toothbrush',
      'soap',
      'conditioner',
      'makeup',
      'diapers',
    },
    homeCare: {
      'detersivo',
      'detersivi',
      'candeggina',
      'ammorbidente',
      'sgrassatore',
      'spugna',
      'spugne',
      'carta',
      'cartaigienica',
      'sacchi',
      'sacchetto',
      'sacchetti',
      'anticalcare',
      'disinfettante',
      'pulitore',
      'lavatrice',
      'detergent',
      'bleach',
      'sponge',
      'paper',
      'cleaning',
      'disinfectant',
      'trash',
    },
    pets: {
      'cane',
      'cani',
      'gatto',
      'gatti',
      'crocchette',
      'lettiera',
      'mangime',
      'pet',
      'dog',
      'dogs',
      'cat',
      'cats',
      'litter',
      'kibble',
    },
    food: {
      'pasta',
      'riso',
      'farina',
      'pane',
      'latte',
      'yogurt',
      'formaggio',
      'formaggi',
      'mozzarella',
      'burro',
      'uova',
      'biscotti',
      'cracker',
      'carne',
      'pollo',
      'pesce',
      'tonno',
      'salmone',
      'prosciutto',
      'salame',
      'pomodoro',
      'pomodori',
      'insalata',
      'insalate',
      'mela',
      'mele',
      'frutta',
      'verdura',
      'verdure',
      'legumi',
      'fagioli',
      'ceci',
      'lenticchie',
      'olio',
      'zucchero',
      'sale',
      'sugo',
      'passata',
      'pizza',
      'gelato',
      'cioccolato',
      'snack',
      'salsiccia',
      'milk',
      'cheese',
      'eggs',
      'bread',
      'chicken',
      'fish',
      'beef',
      'apple',
      'apples',
      'vegetables',
      'flour',
      'sugar',
      'salt',
      'sauce',
      'chocolate',
      'cookies',
      'biscuit',
      'biscuits',
    },
  };
}
