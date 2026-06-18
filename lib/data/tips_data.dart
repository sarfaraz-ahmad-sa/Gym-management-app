/// Guidance / coaching tips shown in the Guide tab.

class TipSection {
  final String title;
  final String emoji;
  final List<String> points;
  const TipSection({required this.title, required this.emoji, required this.points});
}

class TipsData {
  static const List<TipSection> sections = [
    TipSection(title: 'Beginner ke liye golden rules', emoji: '⭐', points: [
      'Form > weight. Pehle technique, phir bhaari.',
      'Consistency sabse bada raaz hai. 1 din miss = tension nahi, agle din wapas.',
      'Progressive overload: har week thoda weight ya reps badhao.',
      'Ego lift mat karo — chot lag sakti hai.',
    ]),
    TipSection(title: '6-pack ka sach', emoji: '🔥', points: [
      'Abs sabke paas hote hain — wo fat ke neeche chhipe hain.',
      'Dikhne ke liye body fat ~10-12% chahiye (male).',
      'Sirf crunches se abs nahi dikhte — fat loss zaroori.',
      'Diet 70-80%, training 20-30% — abs kitchen mein bante hain.',
    ]),
    TipSection(title: 'Fat loss formula', emoji: '📉', points: [
      'Calorie deficit (jitna khaya usse kam) = fat loss.',
      'Healthy rate: hafte mein 0.3-0.5 kg. 3 mahine mein 4 kg realistic.',
      'Crash diet mat karo — muscle bhi jaayegi, abs nahi dikhenge.',
      'Cardio + weights dono — sirf cardio se muscle bhi ghatti hai.',
    ]),
    TipSection(title: 'Recovery & neend', emoji: '😴', points: [
      'Muscle gym mein nahi, aaram mein banti hai.',
      '7-8 ghante neend = better fat loss + hormones.',
      'Rest day pe walk/stretch karo, total aaram bhi theek.',
      'Dard (soreness) normal hai; teekha/jhatke wala dard nahi.',
    ]),
    TipSection(title: 'Safety / chot se bacho', emoji: '🛡️', points: [
      'Warm-up kabhi skip mat karo.',
      'Sudden bhaari weight se shuru mat karo.',
      'Saans rok ke heavy mat lifts karo — exhale on push.',
      'Dard ho to ruk jao, zabardasti nahi.',
    ]),
    TipSection(title: 'Motivation', emoji: '💪', points: [
      'Apne se compare karo, dusron se nahi.',
      'Har hafte photo/weight log dekho — chhoti progress bhi badi.',
      'Result 4-6 hafte mein dikhna shuru hota hai. Patience.',
      'Discipline tab kaam aati hai jab motivation nahi hoti.',
    ]),
  ];
}
