import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend.dart';
import '../../shared/widgets.dart';
import '../../shared/backend_list.dart';

Future<void> showAccount(BuildContext context, {bool register = false}) =>
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AccountScreen(register: register),
      ),
    );

class AccountScreen extends ConsumerStatefulWidget {
  final bool register;
  final VoidCallback? onAuthenticated, onGuest;
  const AccountScreen({
    super.key,
    this.register = false,
    this.onAuthenticated,
    this.onGuest,
  });
  @override
  ConsumerState<AccountScreen> createState() => _AccountState();
}

class _AccountState extends ConsumerState<AccountScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  bool busy = false;
  bool passwordVisible = false;
  String? message;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final auth = ref.read(clientProvider).auth;
      if (widget.register) {
        final result = await auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'full_name': name.text.trim()},
        );
        if (result.session == null) {
          if (mounted) {
            setState(
              () => message =
                  'Check your email to confirm registration, then return here to log in.',
            );
          }
          return;
        }
      } else {
        await auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      if (mounted) {
        if (widget.onAuthenticated != null) {
          widget.onAuthenticated!();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) setState(() => message = backendError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  InputDecoration fieldDecoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20, color: const Color(0xFF789184)),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF3F7F2),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE9F0E7)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: primaryGreen, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 650;
    final heroHeight =
        (compact ? 205.0 : 254.0) + MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: heroHeight - 30),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(26, 56, 26, 24),
                      child: AutofillGroup(
                        child: Form(
                          key: form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                widget.register
                                    ? 'Create an account'
                                    : 'Welcome back',
                                style: const TextStyle(
                                  fontSize: 27,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                  letterSpacing: -.7,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.register
                                    ? 'Join a community that looks out for each other.'
                                    : 'Stay informed. Look out for your community.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: mutedText,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (widget.register) ...[
                                TextFormField(
                                  controller: name,
                                  enabled: !busy,
                                  autofillHints: const [AutofillHints.name],
                                  textInputAction: TextInputAction.next,
                                  decoration: fieldDecoration(
                                    'Full name',
                                    Icons.person_outline_rounded,
                                  ),
                                  maxLength: 200,
                                  validator: (v) => (v?.trim().isEmpty ?? true)
                                      ? 'Enter your name.'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                              ],
                              TextFormField(
                                controller: email,
                                enabled: !busy,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                autocorrect: false,
                                decoration: fieldDecoration(
                                  'Email',
                                  Icons.mail_outline_rounded,
                                ),
                                validator: (v) =>
                                    RegExp(
                                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                    ).hasMatch(v?.trim() ?? '')
                                    ? null
                                    : 'Enter a valid email.',
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: password,
                                enabled: !busy,
                                obscureText: !passwordVisible,
                                autocorrect: false,
                                enableSuggestions: false,
                                textInputAction: TextInputAction.done,
                                autofillHints: [
                                  widget.register
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                onFieldSubmitted: (_) {
                                  if (!busy && backendConfigured) submit();
                                },
                                decoration: fieldDecoration(
                                  'Password',
                                  Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    tooltip: passwordVisible
                                        ? 'Hide password'
                                        : 'Show password',
                                    onPressed: busy
                                        ? null
                                        : () => setState(
                                            () => passwordVisible =
                                                !passwordVisible,
                                          ),
                                    icon: Icon(
                                      passwordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: mutedText,
                                    ),
                                  ),
                                ),
                                validator: (v) =>
                                    (v?.length ?? 0) <
                                        (widget.register ? 12 : 1)
                                    ? 'Enter ${widget.register ? 'at least 12 characters' : 'your password'}.'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              if (message != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Container(
                                      padding: const EdgeInsets.all(13),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F6ED),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        message!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.5,
                                          color: ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              FilledButton(
                                onPressed: busy || !backendConfigured
                                    ? null
                                    : submit,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  backgroundColor: primaryGreen,
                                  disabledBackgroundColor: const Color(
                                    0xFFAAC8AE,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: Text(
                                  busy
                                      ? 'Please wait...'
                                      : widget.register
                                      ? 'Register'
                                      : 'Log In',
                                ),
                              ),
                              if (!widget.register)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: TextButton(
                                    onPressed: busy
                                        ? null
                                        : () => showAccount(
                                            context,
                                            register: true,
                                          ),
                                    child: const Text('Create an account'),
                                  ),
                                ),
                              if (widget.onAuthenticated != null &&
                                  ref.watch(userProvider) != null)
                                OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : widget.onAuthenticated,
                                  child: const Text(
                                    'Continue with signed-in account',
                                  ),
                                ),
                              if (widget.onGuest != null) ...[
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Expanded(
                                      child: Divider(color: Color(0xFFE6ECE4)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Text(
                                        'or',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: mutedText,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(color: Color(0xFFE6ECE4)),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: busy ? null : widget.onGuest,
                                  child: const Text('Continue as guest'),
                                ),
                              ],
                              const SizedBox(height: 12),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 14,
                                    color: Color(0xFF81977F),
                                  ),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Together, a more prepared community.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF81977F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _AccountHero(height: heroHeight),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountHero extends StatefulWidget {
  final double height;
  const _AccountHero({required this.height});
  @override
  State<_AccountHero> createState() => _AccountHeroState();
}

class _AccountHeroState extends State<_AccountHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  late final Animation<double> image = entrance.drive(
    CurveTween(curve: const Interval(0, .78, curve: Curves.easeOutCubic)),
  );
  late final Animation<double> text = entrance.drive(
    CurveTween(curve: const Interval(.20, 1, curve: Curves.easeOutCubic)),
  );
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      entrance.value = 1;
    } else if (!started) {
      started = true;
      entrance.forward();
    }
  }

  @override
  void dispose() {
    entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: const ValueKey('curved-login-header'),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(38)),
      child: SizedBox(
        height: widget.height,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF004D35), Color(0xFF238C45), Color(0xFFA4CD49)],
              stops: [0, .56, 1],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -65,
                top: -50,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x0FFFFFFF),
                  ),
                ),
              ),
              Positioned(
                right: -20,
                bottom: -90,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x0CFFFFFF),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  4,
                  Navigator.canPop(context) ? 44 : 16,
                  18,
                  14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 11,
                      child: FadeTransition(
                        opacity: image,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(.42, 0),
                            end: Offset.zero,
                          ).animate(image),
                          child: Image.asset(
                            'assets/stickers/user-login-icon.png',
                            key: const ValueKey('login-header-artwork'),
                            fit: BoxFit.contain,
                            cacheWidth: 900,
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 9,
                      child: FadeTransition(
                        opacity: text,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(.12, .08),
                            end: Offset.zero,
                          ).animate(text),
                          child: Column(
                            key: const ValueKey('login-header-copy'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'BAHAlerto',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    letterSpacing: -.8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Be aware.\nTravel prepared.',
                                style: TextStyle(
                                  color: Color(0xFFEAF5D9),
                                  fontSize: 13,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (Navigator.canPop(context))
                Positioned(
                  top: 5,
                  left: 10,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final profile = ref.watch(profileProvider);
    final roads = ref.watch(roadsProvider).asData?.value ?? [];
    return PageBody(
      title: 'Profile',
      subtitle: user?.email ?? 'Browse public information as a guest.',
      children: [
        if (!backendConfigured)
          const InfoCard(
            child: Text(
              'Backend is not configured. Start with the supplied mobile launch configuration.',
            ),
          ),
        if (user == null) ...[
          FilledButton(
            onPressed: !backendConfigured ? null : () => showAccount(context),
            child: const Text('Log In'),
          ),
          OutlinedButton(
            onPressed: !backendConfigured
                ? null
                : () => showAccount(context, register: true),
            child: const Text('Register'),
          ),
        ] else ...[
          profile.when(
            data: (p) => InfoCard(
              child: Text(
                '${p?['full_name'] ?? 'User'} ? ${p?['status'] ?? 'Unknown status'}',
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(backendError(e)),
          ),
          OutlinedButton(
            onPressed: () async {
              try {
                await ref
                    .read(clientProvider)
                    .auth
                    .signOut(scope: SignOutScope.local);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(backendError(e))));
                }
              }
            },
            child: const Text('Sign out'),
          ),
          const Text('Saved locations'),
          BackendList(
            value: ref.watch(savedProvider),
            refresh: () => ref.invalidate(savedProvider),
            empty: 'No saved locations.',
            item: (row) => ListTile(
              title: Text(
                roads.where((r) => r.id == row['road_id']).firstOrNull?.road ??
                    'Unavailable road',
              ),
              trailing: IconButton(
                tooltip: 'Remove saved location',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  try {
                    await ref
                        .read(clientProvider)
                        .from('saved_locations')
                        .delete()
                        .eq('id', row['id'])
                        .eq('owner_id', user.id);
                    ref.invalidate(savedProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(backendError(e))));
                    }
                  }
                },
              ),
            ),
          ),
          ref
              .watch(preferencesProvider)
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(backendError(e)),
                data: (p) => SwitchListTile(
                  title: const Text('Personalized alert preference'),
                  subtitle: const Text(
                    'Preference is saved. Push delivery is not enabled yet.',
                  ),
                  value: p?['personalized_alerts'] == true,
                  onChanged: (value) async {
                    try {
                      final table = ref
                          .read(clientProvider)
                          .from('notification_preferences');
                      if (p == null) {
                        await table.insert({
                          'owner_id': user.id,
                          'personalized_alerts': value,
                        });
                      } else {
                        await table
                            .update({'personalized_alerts': value})
                            .eq('owner_id', user.id);
                      }
                      ref.invalidate(preferencesProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(backendError(e))),
                        );
                      }
                    }
                  },
                ),
              ),
        ],
        const InfoCard(
          child: Text(
            'BAHAlerto - Published administrator information and community reporting. Avoid flooded roads and follow current official advisories.',
          ),
        ),
      ],
    );
  }
}
