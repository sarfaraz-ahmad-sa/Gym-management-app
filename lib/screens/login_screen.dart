import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _gym = TextEditingController(),
      _username = TextEditingController(),
      _password = TextEditingController(),
      _setupCode = TextEditingController(),
      _server = TextEditingController();
  bool _busy = false, _obscure = true;
  String? _error;
  @override
  void dispose() {
    for (final c in [_name, _gym, _username, _password, _setupCode, _server]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(AuthService auth) async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (auth.needsServerAddress) await auth.setServerAddress(_server.text);
      if (auth.needsSetup) {
        await auth.setup(
          name: _name.text.trim(),
          gymName: _gym.text.trim(),
          username: _username.text.trim(),
          password: _password.text,
          setupCode: _setupCode.text.trim(),
        );
      } else if (!await auth.login(_username.text, _password.text)) {
        if (mounted) {
          setState(() => _error = 'The username or password is incorrect.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final setup = auth.needsSetup;
    if (_server.text.isEmpty && auth.api.baseUrl.isNotEmpty) {
      _server.text = auth.api.baseUrl;
    }
    final form = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Brand(),
                const SizedBox(height: 42),
                Text(
                  setup ? 'Make it your workspace.' : 'Welcome back.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  setup
                      ? 'Set up your club and owner account. Your next chapter starts here.'
                      : 'Sign in and pick up where your club left off.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                if (auth.needsServerAddress) ...[
                  _text(
                    _server,
                    'FitGuide server address',
                    Icons.cloud_outlined,
                    hint: 'https://your-fitguide.vercel.app',
                  ),
                  const SizedBox(height: 16),
                ],
                if (setup) ...[
                  _text(_name, 'Your full name', Icons.person_outline),
                  const SizedBox(height: 16),
                  _text(
                    _gym,
                    'Workspace / gym name',
                    Icons.storefront_outlined,
                  ),
                  if (auth.cloudMode) ...[
                    const SizedBox(height: 16),
                    _text(
                      _setupCode,
                      'Workspace setup code',
                      Icons.key_outlined,
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                _text(
                  _username,
                  'Username',
                  Icons.alternate_email,
                  hint: 'e.g. irfan',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  enabled: !_busy,
                  autofillHints: [
                    setup ? AutofillHints.newPassword : AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  onFieldSubmitted: (_) {
                    if (!_busy) _submit(auth);
                  },
                  validator: (v) => v == null || v.isEmpty
                      ? 'Enter your password'
                      : setup && v.length < 8
                      ? 'Use at least 8 characters'
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : () => _submit(auth),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(setup ? 'Create my workspace' : 'Sign in'),
                  ),
                ),
                if (auth.cloudMode)
                  Center(
                    child: TextButton(
                      onPressed: _busy ? null : () => auth.showSetup(!setup),
                      child: Text(
                        setup
                            ? 'Already registered? Sign in'
                            : 'Create an owner account & workspace',
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'or take a look around',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : auth.enterDemo,
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    label: const Text('Explore demo workspace'),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  auth.cloudMode
                      ? 'Sign in with the same owner account on mobile and web. Demo records stay separate.'
                      : 'Your records stay on this device. Demo data is kept in a separate workspace.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, c) {
            if (c.maxWidth < 950) return SingleChildScrollView(child: form);
            return Row(
              children: [
                Expanded(child: _story()),
                Expanded(child: SingleChildScrollView(child: form)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _text(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
  }) => TextFormField(
    controller: controller,
    enabled: !_busy,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
    ),
    validator: (v) =>
        v == null || v.trim().isEmpty ? 'Enter ${label.toLowerCase()}' : null,
  );
  Widget _story() => Container(
    margin: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF174EA6), Color(0xFF1A73E8), Color(0xFF5198FA)],
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'BUILT FOR YOUR EVERYDAY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Run your gym.\nGrow your\ncommunity.',
              style: TextStyle(
                fontSize: 48,
                height: 1.1,
                letterSpacing: -1.7,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Members, memberships, payments and the people\nwho make your club feel like home. All together.',
              style: TextStyle(
                color: Color(0xFFD2E3FC),
                height: 1.7,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                border: Border.all(color: Colors.white.withValues(alpha: .2)),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  for (final entry in [
                    (
                      'People first',
                      'Member profiles & tailored programs',
                      Icons.people_outline,
                    ),
                    (
                      'Less paperwork',
                      'Payments, renewals & daily check-ins',
                      Icons.task_alt,
                    ),
                    (
                      'Room to grow',
                      'Real insights, on mobile & web',
                      Icons.insights,
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(entry.$3, color: Colors.white, size: 22),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.$1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  entry.$2,
                                  style: const TextStyle(
                                    color: Color(0xFFD2E3FC),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            const Text(
              'A stronger club starts with a simpler day.',
              style: TextStyle(color: Color(0xFFD2E3FC), fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
