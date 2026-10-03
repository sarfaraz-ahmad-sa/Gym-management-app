/// Trainer-style how-to guides for exercises.
/// Each exercise in the plan is auto-matched to a guide by keywords in its
/// name, so we never have to hand-tag every entry.

class ExerciseGuide {
  final String category;
  final String asset; // SVG illustration
  final List<String> steps;
  final List<String> mistakes;
  final String breathing;

  const ExerciseGuide({
    required this.category,
    required this.asset,
    required this.steps,
    required this.mistakes,
    required this.breathing,
  });
}

class ExerciseGuides {
  static const _base = 'assets/exercises/';

  static const Map<String, ExerciseGuide> _byCategory = {
    'squat': ExerciseGuide(
      category: 'Squat',
      asset: '${_base}squat.svg',
      steps: [
        'Pair shoulder-width, toes thoda bahar.',
        'Chest up, peeth seedhi, core tight karo.',
        'Hips peeche le jaate hue ghutne mod ke neeche baitho.',
        'Thigh parallel tak jao, phir edi se push kar ke upar aao.',
      ],
      mistakes: [
        'Ghutne andar girna (toes ke direction mein rakho).',
        'Edi uthana — pura pair zameen pe.',
        'Peeth ka round hona.',
      ],
      breathing: 'Neeche jaate waqt saans bharo, upar push pe chhodo.',
    ),
    'lunge': ExerciseGuide(
      category: 'Lunge',
      asset: '${_base}lunge.svg',
      steps: [
        'Ek pair aage, dusra peeche — lamba step.',
        'Dono ghutne 90° tak mod ke neeche jao.',
        'Aage wali edi se push kar ke wapas aao.',
        'Pair badal ke repeat karo.',
      ],
      mistakes: [
        'Aage ka ghutna toe se bahut aage nikalna.',
        'Aage jhukna — torso seedha rakho.',
      ],
      breathing: 'Neeche saans bharo, upar chhodo.',
    ),
    'hinge': ExerciseGuide(
      category: 'Deadlift / RDL',
      asset: '${_base}hinge.svg',
      steps: [
        'Pair hip-width, bar/dumbbell saamne.',
        'Hips peeche dhakelo, ghutne halka mudo.',
        'Peeth seedhi rakhte hue weight neeche le jao (hamstring stretch).',
        'Glutes squeeze karte hue seedhe khade ho jao.',
      ],
      mistakes: [
        'Peeth round karna — sabse khatarnaak galti.',
        'Sirf ghutne se uthana (ye squat nahi hai).',
      ],
      breathing: 'Upar core tight + saans rok ke (light), upar aate chhodo.',
    ),
    'legpress': ExerciseGuide(
      category: 'Leg Press',
      asset: '${_base}legpress.svg',
      steps: [
        'Seat pe peeth tikao, pair platform pe shoulder-width.',
        'Safety hatao, ghutne control se chest ki taraf lao.',
        '90° tak jao, phir edi se push kar ke pair seedha (lock mat karo).',
      ],
      mistakes: [
        'Ghutne pura lock karna.',
        'Lower back seat se uthana.',
      ],
      breathing: 'Neeche saans bharo, push pe chhodo.',
    ),
    'legmachine': ExerciseGuide(
      category: 'Leg Curl / Extension',
      asset: '${_base}legmachine.svg',
      steps: [
        'Machine seat/pad adjust karo taaki ghutna joint sahi ho.',
        'Control se weight uthao, top pe 1 sec squeeze.',
        'Dheere se wapas — jhatka nahi.',
      ],
      mistakes: [
        'Momentum se jhatka dena.',
        'Bahut heavy le ke half reps karna.',
      ],
      breathing: 'Effort pe chhodo, wapas pe bharo.',
    ),
    'chestpress': ExerciseGuide(
      category: 'Chest Press / Push-up',
      asset: '${_base}chestpress.svg',
      steps: [
        'Bench pe leto, pair zameen pe, kandhe peeche.',
        'Bar/dumbbell chest ke level pe, kohni ~45°.',
        'Control se chest tak neeche, phir upar push (lock na karo).',
      ],
      mistakes: [
        'Kohni 90° bahar flare karna (kandhe pe stress).',
        'Bar bounce karna chest pe.',
      ],
      breathing: 'Neeche saans bharo, push pe chhodo.',
    ),
    'incline': ExerciseGuide(
      category: 'Incline Press',
      asset: '${_base}incline.svg',
      steps: [
        'Bench ~30-45° incline pe set karo.',
        'Dumbbell upper-chest ke level se shuru.',
        'Upar push, top pe halka squeeze, control se neeche.',
      ],
      mistakes: [
        'Bench bahut upar (ye shoulder press ban jaata).',
        'Peeth arch zyada karna.',
      ],
      breathing: 'Push pe chhodo, neeche bharo.',
    ),
    'shoulderpress': ExerciseGuide(
      category: 'Shoulder / Overhead Press',
      asset: '${_base}shoulderpress.svg',
      steps: [
        'Baith ke ya khade ho ke core tight.',
        'Weight kandhe ke level pe, kohni saamne.',
        'Seedha upar push, sar ke upar lock ke kareeb.',
        'Control se wapas kandhe tak.',
      ],
      mistakes: [
        'Peeth peeche jhukana (lower back stress).',
        'Weight sar ke peeche le jana.',
      ],
      breathing: 'Push pe chhodo, neeche bharo.',
    ),
    'lateralraise': ExerciseGuide(
      category: 'Lateral Raise / Face Pull',
      asset: '${_base}lateralraise.svg',
      steps: [
        'Halka dumbbell, kohni thodi mudi.',
        'Baazu side se shoulder-height tak uthao.',
        'Top pe 1 sec ruko, dheere neeche.',
      ],
      mistakes: [
        'Bahut heavy le ke jhatka dena.',
        'Kandhe kaan tak shrug karna.',
      ],
      breathing: 'Uthate waqt chhodo, neeche bharo.',
    ),
    'pull': ExerciseGuide(
      category: 'Pull-up / Row / Pulldown',
      asset: '${_base}pull.svg',
      steps: [
        'Bar/handle pakdo, kandhe neeche-peeche set karo.',
        'Kohni ko peeche-neeche kheencho (back se, haath se nahi).',
        'Squeeze top/bottom pe, control se wapas full stretch.',
      ],
      mistakes: [
        'Sirf biceps se kheenchna — back lagao.',
        'Momentum/swing karna.',
      ],
      breathing: 'Kheenchte waqt chhodo, wapas bharo.',
    ),
    'curl': ExerciseGuide(
      category: 'Bicep Curl',
      asset: '${_base}curl.svg',
      steps: [
        'Kohni body se chipki, dumbbell neeche.',
        'Sirf forearm move karte hue upar curl.',
        'Top pe squeeze, dheere neeche (negative).',
      ],
      mistakes: [
        'Kohni aage-peeche swing karna.',
        'Body jhula ke weight uthana.',
      ],
      breathing: 'Upar chhodo, neeche bharo.',
    ),
    'triceps': ExerciseGuide(
      category: 'Triceps Pushdown / Dip',
      asset: '${_base}triceps.svg',
      steps: [
        'Kohni body se chipki rakho.',
        'Sirf forearm se weight neeche push, pura extend.',
        'Control se wapas.',
      ],
      mistakes: [
        'Kohni bahar/aage jana.',
        'Pure body se dhakka dena.',
      ],
      breathing: 'Push pe chhodo, wapas bharo.',
    ),
    'plank': ExerciseGuide(
      category: 'Plank',
      asset: '${_base}plank.svg',
      steps: [
        'Forearm aur toes pe body uthao.',
        'Sar se edi tak ek seedhi line.',
        'Core + glutes tight, normal saans lete raho.',
      ],
      mistakes: [
        'Kamar neeche girna ya hips upar uthana.',
        'Saans rokna.',
      ],
      breathing: 'Steady normal breathing — rokna nahi.',
    ),
    'core': ExerciseGuide(
      category: 'Abs / Core',
      asset: '${_base}core.svg',
      steps: [
        'Control se move karo, jhatka nahi.',
        'Har rep pe abs squeeze feel karo.',
        'Lower back zameen se chipki rakho (crunch/leg raise mein).',
      ],
      mistakes: [
        'Gardan se kheenchna (haath sar ke peeche sirf support).',
        'Momentum use karna.',
      ],
      breathing: 'Squeeze pe chhodo, wapas bharo.',
    ),
    'cardio': ExerciseGuide(
      category: 'Cardio / HIIT',
      asset: '${_base}cardio.svg',
      steps: [
        'Steady: comfortable pace pe jisme baat kar sako.',
        'HIIT: 30 sec tez + 60 sec slow, repeat.',
        'Posture seedhi, kandhe relax.',
      ],
      mistakes: [
        'Bina warm-up sprint karna.',
        'Roz over-cardio (recovery zaroori).',
      ],
      breathing: 'Rhythm mein — naak se andar, muh se bahar.',
    ),
  };

  /// Ordered keyword -> category map (first match wins).
  static const List<List<String>> _rules = [
    ['squat', 'goblet'],
    ['lunge'],
    ['deadlift', 'romanian', 'rdl', 'hinge'],
    ['leg press'],
    ['leg curl', 'leg extension', 'calf'],
    ['incline'],
    ['bench', 'chest press', 'push-up', 'push up', 'pushup', 'fly'],
    ['overhead', 'shoulder press'],
    ['lateral', 'face pull'],
    ['pull-up', 'pull up', 'pullup', 'pulldown', 'row', 'lat '],
    ['bicep', 'curl', 'hammer'],
    ['tricep', 'dip', 'pushdown'],
    ['plank'],
    ['crunch', 'leg raise', 'russian', 'bicycle', 'core', 'sit'],
    ['hiit', 'cardio', 'walk', 'run', 'cycle', 'sprint'],
  ];

  static const List<String> _cats = [
    'squat',
    'lunge',
    'hinge',
    'legpress',
    'legmachine',
    'incline',
    'chestpress',
    'shoulderpress',
    'lateralraise',
    'pull',
    'curl',
    'triceps',
    'plank',
    'core',
    'cardio',
  ];

  static ExerciseGuide forName(String name) {
    final n = name.toLowerCase();
    for (var i = 0; i < _rules.length; i++) {
      for (final kw in _rules[i]) {
        if (n.contains(kw)) {
          return _byCategory[_cats[i]]!;
        }
      }
    }
    return _byCategory['core']!; // sensible default
  }
}
