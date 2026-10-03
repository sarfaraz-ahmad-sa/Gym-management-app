import 'package:intl/intl.dart';
import 'format.dart';
import 'gym_store.dart';

const defaultPaymentTemplate = '''Assalam-o-Alaikum {member},

Aapki gym fees {pending_amount} pending hai, {due_date} ({due_month}) se. {last_payment_line}

Meherbani karke reception par apni fees jama karwa dein. Agar payment ho chuki hai to receipt hamari team ke saath share kar dein.

Shukriya!
Regards,
{workspace}

{tagline}''';
const defaultWelcomeTemplate = '''Assalam-o-Alaikum {member},

{workspace} mein khush aamdeed! Aapka membership plan {plan} hai. Hamari team aapke fitness goals mein aapke saath hai.

Regards,
{workspace}

{tagline}''';
const defaultRenewalTemplate = '''Assalam-o-Alaikum {member},

Aapki {workspace} membership ki expiry {expiry_date} hai. Apni fitness journey jari rakhne ke liye reception se renewal karwa lein.

Shukriya!
Regards,
{workspace}

{tagline}''';
const defaultTagline =
    'Har din ki chhoti mehnat, kal ka mazboot aap — keep showing up!';
String memberMessage(GymStore store, RecordData member, String type) {
  final id = member['id'] as int;
  final last = store.lastPayment(id), since = store.dueSince(id);
  final defaults = {
    'payment': defaultPaymentTemplate,
    'welcome': defaultWelcomeTemplate,
    'renewal': defaultRenewalTemplate,
  };
  var template = store.setting(
    'message_$type',
    defaults[type] ?? defaultPaymentTemplate,
  );
  final values = {
    'member': member['name'].toString(),
    'workspace': store.gymName,
    'pending_amount': money(store.memberDue(id), store.currency),
    'due_date': since == null ? '—' : dateLabel(since.millisecondsSinceEpoch),
    'due_month': since == null
        ? 'no pending fee'
        : DateFormat('MMMM yyyy').format(since),
    'last_payment_line': last == null
        ? 'Abhi tak koi completed payment record nahi hai.'
        : 'Aapki last payment ${money(last['amount'], store.currency)} thi, ${dateLabel(last['payment_date'])} ko.',
    'last_payment_amount': last == null
        ? '—'
        : money(last['amount'], store.currency),
    'last_payment_date': last == null ? '—' : dateLabel(last['payment_date']),
    'plan': store.label('membership_plans', member['plan_id']),
    'expiry_date': dateLabel(member['expiry_date']),
    'tagline': store.setting('message_tagline', defaultTagline),
  };
  // One-pass substitution prevents member names containing placeholders from being interpreted.
  return template.replaceAllMapped(
    RegExp(r'\{([a-z_]+)\}'),
    (m) => values[m[1]] ?? m[0]!,
  );
}
