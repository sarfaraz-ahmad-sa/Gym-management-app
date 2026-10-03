/// Diet plan for fat loss (72 -> 68 kg) + abs. Indian-friendly, high protein.

class Meal {
  final String time;
  final String emoji;
  final List<String> options;
  const Meal({required this.time, required this.emoji, required this.options});
}

class DietData {
  static const String summary =
      'Target: ~300-500 kcal deficit roz, protein high (~115-130g), '
      'enough water (3-4L). Abs 80% kitchen mein bante hain.';

  static const List<String> rules = [
    'Protein har meal mein: ande, chicken, paneer, dal, soya, dahi, dudh.',
    'Sugar, fried food, cold drink, maida → minimum.',
    'Roz 3-4 litre paani.',
    'Carbs workout ke aas-paas zyada (roti, rice, oats).',
    'Subzi/salad har meal mein — fibre + fullness.',
    'Cheat meal: hafte mein 1 (control mein).',
    'Neend 7-8 ghante — fat loss + recovery ke liye must.',
  ];

  static const List<Meal> meals = [
    Meal(time: 'Subah uthte hi', emoji: '💧', options: [
      '1 glass garam paani + nimbu',
      '5-6 bheege badam',
    ]),
    Meal(time: 'Breakfast', emoji: '🍳', options: [
      '3 ande (2 whole + 1 white) + 2 brown bread/roti',
      'Oats 50g + dudh + 1 fruit',
      'Besan/moong cheela + dahi',
    ]),
    Meal(time: 'Mid-morning', emoji: '🍎', options: [
      '1 fruit (apple/banana) ya mutthi bhar nuts',
      'Green tea / black coffee',
    ]),
    Meal(time: 'Lunch', emoji: '🍛', options: [
      '2 roti + dal + 100-150g chicken/paneer + salad',
      'Brown rice (1 cup) + rajma/chana + dahi + salad',
      'Veg + dal + soya chunks + salad',
    ]),
    Meal(time: 'Pre-workout', emoji: '⚡', options: [
      '1 banana + black coffee (30 min pehle)',
      'Handful peanuts + 1 fruit',
    ]),
    Meal(time: 'Post-workout', emoji: '🥤', options: [
      'Whey protein 1 scoop ya 4 egg whites',
      'Dahi + 1 fruit',
    ]),
    Meal(time: 'Dinner', emoji: '🍽️', options: [
      '2 roti + sabzi + grilled chicken/paneer/tofu + salad',
      'Moong dal khichdi + dahi + salad (light)',
      'Egg bhurji (4) + 1 roti + salad',
    ]),
    Meal(time: 'Sone se pehle', emoji: '🥛', options: [
      '1 glass dudh (cow/skimmed) ya casein',
      'Soch lo: aaj deficit hua ya nahi',
    ]),
  ];
}
