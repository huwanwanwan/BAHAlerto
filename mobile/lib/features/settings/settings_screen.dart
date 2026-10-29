import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend.dart';
import '../../shared/widgets.dart';
import '../../shared/phone_viewport.dart';
import '../../shared/backend_list.dart';
import '../../shared/module_page.dart';

Future<void> showAccount(
  BuildContext context, {
  bool register = false,
  VoidCallback? onAuthenticated,
  VoidCallback? onGuest,
}) => Navigator.push(
  context,
  PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    pageBuilder: (_, animation, secondaryAnimation) =>
        AccountScreen(register: register, onAuthenticated: onAuthenticated, onGuest: onGuest),
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

class _AccountState extends ConsumerState<AccountScreen>
    with TickerProviderStateMixin {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  bool busy = false;
  bool awaitingGoogle = false;
  bool passwordVisible = false;
  final bool keepMeSignedIn = true;
  String? message;

  late final AnimationController entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> cardContentOpacity = entrance.drive(
    CurveTween(curve: const Interval(0, 0.75, curve: Curves.easeInOut)),
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

  Future<void> signInWithGoogle() async {
    setState(() {
      busy = true;
      awaitingGoogle = true;
      message = null;
    });
    try {
      final launched = await ref
          .read(clientProvider)
          .auth
          .signInWithOAuth(
            OAuthProvider.google,
            redirectTo: kIsWeb
                ? Uri.base.replace(query: '', fragment: '').toString()
                : 'com.bahalerto.app://login-callback/',
          );
      if (!launched) {
        throw const AuthException('Could not open Google sign-in.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          awaitingGoogle = false;
          message = backendError(e);
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  InputDecoration fieldDecoration(
    String label,
    IconData icon, {
    String? hintText,
    Widget? suffix,
  }) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 15, color: Color(0xFF5D7566)),
    hintText: hintText,
    hintStyle: const TextStyle(
      fontSize: 15,
      color: Color(0xFFA0B5A7),
      fontWeight: FontWeight.w400,
    ),
    helperText: widget.register ? null : ' ',
    helperStyle: const TextStyle(
      fontSize: 12,
      height: 1.1,
      color: Colors.transparent,
    ),
    errorStyle: const TextStyle(
      fontSize: 12,
      height: 1.1,
      color: Color(0xFFD32F2F),
    ),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 12, right: 6),
      child: Icon(icon, size: 21, color: const Color(0xFF4A7856)),
    ),
    suffixIcon: suffix != null
        ? Padding(padding: const EdgeInsets.only(right: 8), child: suffix)
        : null,
    filled: true,
    fillColor: const Color(0xFFF2F6F1),
    contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: Color(0xFFE5EDE3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: Color(0xFF0F7533), width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    ref.listen<User?>(userProvider, (previous, next) {
      if (awaitingGoogle && next != null) {
        awaitingGoogle = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (widget.onAuthenticated != null) {
            widget.onAuthenticated!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      }
    });
    final compact = MediaQuery.sizeOf(context).height < 650;
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    // Preserve the artwork/header geometry; only raise the white form card.
    final heroHeight = (compact ? 170.0 : 280.0) + topPadding;

    return HeaderStatusScope(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final overlap = compact ? 24.0 : 90.0;
              final minCardHeight =
                  (constraints.maxHeight - (heroHeight - overlap)).clamp(
                    0.0,
                    double.infinity,
                  );

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: _AccountHero(
                            height: heroHeight - overlap + 48,
                            entrance: entrance,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: heroHeight - overlap),
                          child: SizedBox(
                            child: FadeTransition(
                              opacity: cardContentOpacity,
                              child: Container(
                                constraints: BoxConstraints(
                                  minHeight: minCardHeight,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(32),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 16,
                                      offset: Offset(0, -4),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.fromLTRB(
                                  26,
                                  widget.register ? 14 : (compact ? 16 : 22),
                                  26,
                                  math.max(
                                    compact ? 14.0 : 18.0,
                                    bottomPadding + 6.0,
                                  ),
                                ),
                                child: AutofillGroup(
                                  child: Form(
                                    key: form,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          widget.register
                                              ? 'Create an account'
                                              : 'Welcome back',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            height: 1.2,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF142925),
                                            letterSpacing: -.7,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (!widget.register) Text(
                                          widget.register
                                              ? 'Join a community that looks out for each other.'
                                              : 'Sign in to access the BAHAlerto app.',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF8C8E8E),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        SizedBox(height: widget.register ? 6 : (compact ? 8 : 12)),
                                        if (widget.register) ...[
                                          TextFormField(
                                            controller: name,
                                            enabled: !busy,
                                            autofillHints: const [
                                              AutofillHints.name,
                                            ],
                                            textInputAction:
                                                TextInputAction.next,
                                            decoration: fieldDecoration(
                                              'Full name',
                                              Icons.person_outline_rounded,
                                            ).copyWith(counterText: ''),
                                            maxLength: 200,
                                            validator: (v) =>
                                                (v?.trim().isEmpty ?? true)
                                                ? 'Enter your name.'
                                                : null,
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        TextFormField(
                                          controller: email,
                                          enabled: !busy,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.email,
                                          ],
                                          autocorrect: false,
                                          decoration: fieldDecoration(
                                            'Email',
                                            Icons.mail_outline_rounded,
                                            hintText: 'example@gmail.com',
                                          ),
                                          validator: (v) =>
                                              RegExp(
                                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                              ).hasMatch(v?.trim() ?? '')
                                              ? null
                                              : 'Enter a valid email.',
                                        ),
                                        SizedBox(height: compact ? 6 : 10),
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
                                            if (!busy && backendConfigured) {
                                              submit();
                                            }
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
                                                    ? Icons
                                                          .visibility_off_outlined
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
                                        SizedBox(height: compact ? 8 : 12),
                                        if (!widget.register) Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Semantics(
                                                  checked: true,
                                                  label: 'Stay signed in on this device',
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 20,
                                                        height: 20,
                                                        decoration: BoxDecoration(
                                                          color: keepMeSignedIn
                                                              ? const Color(
                                                                  0xFF0F7533,
                                                                )
                                                              : Colors
                                                                    .transparent,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                keepMeSignedIn
                                                                ? const Color(
                                                                    0xFF0F7533,
                                                                  )
                                                                : const Color(
                                                                    0xFFCFE1D2,
                                                                  ),
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: keepMeSignedIn
                                                            ? const Icon(
                                                                Icons
                                                                    .check_rounded,
                                                                size: 15,
                                                                color: Colors
                                                                    .white,
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Text(
                                                        'Keep me signed in',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Color(
                                                            0xFF5D7566,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Password reset instructions will be sent to your email.',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: Size.zero,
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  child: const Text(
                                                    'Forgot Password?',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF4A7856),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: compact ? 10 : 14),
                                        if (message != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child: Semantics(
                                              liveRegion: true,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  13,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF0F6ED,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
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
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF036033),
                                                Color(0xFF0F7533),
                                                Color(0xFF22973E),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF0F7533,
                                                ).withValues(alpha: 0.28),
                                                blurRadius: 14,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: FilledButton(
                                            onPressed:
                                                busy || !backendConfigured
                                                ? null
                                                : submit,
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              minimumSize:
                                                  const Size.fromHeight(56),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(28),
                                              ),
                                              textStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  busy
                                                      ? 'Please wait...'
                                                      : widget.register
                                                      ? 'Register'
                                                      : 'Log In',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                if (!busy &&
                                                    !widget.register) ...[
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    size: 20,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (widget.onAuthenticated != null &&
                                            ref.watch(userProvider) !=
                                                null) ...[
                                          const SizedBox(height: 14),
                                          OutlinedButton(
                                            onPressed: busy
                                                ? null
                                                : widget.onAuthenticated,
                                            style: OutlinedButton.styleFrom(
                                              minimumSize:
                                                  const Size.fromHeight(56),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              textStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            child: const Text(
                                              'Continue with signed-in account',
                                            ),
                                          ),
                                        ],
                                        SizedBox(height: compact ? 8 : 10),
                                        Row(
                                          children: [
                                            const Expanded(
                                              child: Divider(
                                                color: Color(0xFFE9F0E7),
                                                thickness: 1.2,
                                              ),
                                            ),
                                            Flexible(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    'Or continue with',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Expanded(
                                              child: Divider(
                                                color: Color(0xFFE9F0E7),
                                                thickness: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: compact ? 8 : 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF3F7F2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(28),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFE9F0E7,
                                                    ),
                                                  ),
                                                ),
                                                child: InkWell(
                                                  onTap:
                                                      busy || !backendConfigured
                                                      ? null
                                                      : signInWithGoogle,
                                                  borderRadius:
                                                      BorderRadius.circular(28),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Image.asset(
                                                        'assets/google-logo.png',
                                                        height: 22,
                                                        width: 22,
                                                        fit: BoxFit.contain,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => const Text(
                                                              'G',
                                                              style: TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                color: Color(
                                                                  0xFF4285F4,
                                                                ),
                                                              ),
                                                            ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Flexible(
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                            'Google',
                                                            style: TextStyle(
                                                              fontSize: 14.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: Color(
                                                                0xFF23392C,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Container(
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF3F7F2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(28),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFE9F0E7,
                                                    ),
                                                  ),
                                                ),
                                                child: InkWell(
                                                  onTap: busy
                                                      ? null
                                                      : (widget.onGuest ?? () {
                                                          if (Navigator.canPop(context)) Navigator.pop(context);
                                                        }),
                                                  borderRadius:
                                                      BorderRadius.circular(28),
                                                  child: const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .person_outline_rounded,
                                                        size: 20,
                                                        color: primaryGreen,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Flexible(
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                            'Continue as guest',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: Color(
                                                                0xFF23392C,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: compact ? 8 : 10),
                                        Center(
                                          child: TextButton(
                                            onPressed: busy
                                                ? null
                                                : () {
                                                    if (widget.register) {
                                                      if (Navigator.canPop(
                                                        context,
                                                      )) {
                                                        Navigator.pop(context);
                                                      } else {
                                                        showAccount(
                                                          context,
                                                          register: false,
                                                        );
                                                      }
                                                    } else {
                                                      showAccount(
                                                        context,
                                                        register: true,
                                                        onGuest: () {
                                                          Navigator.pop(context);
                                                          widget.onGuest?.call();
                                                        },
                                                        onAuthenticated: () {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          widget.onAuthenticated
                                                              ?.call();
                                                        },
                                                      );
                                                    }
                                                  },
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                    horizontal: 12,
                                                  ),
                                              splashFactory:
                                                  NoSplash.splashFactory,
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text.rich(
                                                TextSpan(
                                                  text: widget.register
                                                      ? 'Already have an account? '
                                                      : "Don't have an account? ",
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF6B7280),
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: widget.register
                                                          ? 'Sign In'
                                                          : 'Sign Up',
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF0F7533,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AccountHero extends StatefulWidget {
  final double height;
  final AnimationController entrance;
  const _AccountHero({required this.height, required this.entrance});
  @override
  State<_AccountHero> createState() => _AccountHeroState();
}

class _AccountHeroState extends State<_AccountHero> {
  bool showSecond = false;
  Timer? artworkTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    artworkTimer?.cancel();
    if (!MediaQuery.disableAnimationsOf(context)) {
      artworkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) setState(() => showSecond = !showSecond);
      });
    }
  }

  @override
  void dispose() {
    artworkTimer?.cancel();
    super.dispose();
  }

  Widget artwork(String asset, bool visible) => AnimatedOpacity(
    opacity: visible ? 1 : 0,
    duration: const Duration(milliseconds: 750),
    curve: Curves.easeInOut,
    child: Image.asset(asset, fit: BoxFit.contain,
      alignment: Alignment.bottomRight, cacheWidth: 1200,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  );


  late final Animation<double> textOpacity = widget.entrance.drive(
    CurveTween(curve: const Interval(0, 0.75, curve: Curves.easeInOut)),
  );

  late final Animation<double> imageOpacity = widget.entrance.drive(
    CurveTween(curve: const Interval(0, 0.75, curve: Curves.easeInOut)),
  );


  @override
  Widget build(BuildContext context) {
    final compact = widget.height < 255;
    final topInset = MediaQuery.paddingOf(context).top;
    final topPadding = topInset > 0 ? topInset + 12.0 : (compact ? 20.0 : 24.0);
    const bottomPadding = 60.0;

    return SizedBox(
      key: const ValueKey('curved-login-header'),
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/green-riverside-town-header.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stackTrace) => const DecoratedBox(
              decoration: BoxDecoration(gradient: loginHeaderGradient),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, topPadding, 0, bottomPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 8,
                  child: Padding(
                    padding: EdgeInsets.only(top: compact ? 12.0 : 18.0),
                    child: FadeTransition(
                      opacity: textOpacity,
                      child: SizedBox(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 185),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Column(
                              key: const ValueKey('login-header-copy'),
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text.rich(
                                  TextSpan(
                                    style: TextStyle(
                                      fontSize: 29,
                                      letterSpacing: -.8,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          color: Color(0x66000000),
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'BAHA',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      TextSpan(
                                        text: 'lerto',
                                        style: TextStyle(
                                          color: Color(0xFFF05A28),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Be aware.\nStay prepared.',
                                  style: TextStyle(
                                    color: Color(0xFFE2F4DF),
                                    fontSize: 14,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                        color: Color(0x66000000),
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 16,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: FadeTransition(
                      opacity: imageOpacity,
                      child: SizedBox(
                        child: Transform.translate(
                          offset: const Offset(0, 46),
                          child: Transform.scale(
                            scale: 1.48,
                            alignment: Alignment.bottomRight,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: compact ? 180 : 280,
                              ),
                              child: AspectRatio(
                                aspectRatio: 1.5,
                                child: Stack(
                                  key: const ValueKey('login-header-artwork'),
                                  fit: StackFit.expand,
                                  children: [
                                    artwork('assets/flood-alert-mascot.png', !showSecond),
                                    artwork('assets/flood-alert-adventure.png', showSecond),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (Navigator.canPop(context))
            Positioned(
              top: math.max(0.0, topInset - 6),
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
    return ModulePage(
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
          const InfoCard(child: Column(children: [CircleAvatar(radius: 30, backgroundColor: Color(0xFFEAF5EE), child: Icon(Icons.person_outline, size: 32, color: ink)), SizedBox(height: 12), Text('Your BAHAlerto account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), SizedBox(height: 6), Text('Sign in to view your reports and saved locations.', textAlign: TextAlign.center, style: TextStyle(color: mutedText, height: 1.5))])),
          FilledButton(
            onPressed: !backendConfigured ? null : () => showAccount(context),
            child: const Text('Log In'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: !backendConfigured
                ? null
                : () => showAccount(context, register: true),
            child: const Text('Register'),
          ),
        ] else ...[
          profile.when(
            data: (p) => InfoCard(
              child: Column(children: [
                const CircleAvatar(radius: 32, backgroundColor: Color(0xFFEAF5EE), child: Icon(Icons.person_outline, size: 34, color: ink)),
                const SizedBox(height: 12),
                Text(p?['full_name'] ?? 'User', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink)),
                const SizedBox(height: 8),
                Tag(p?['status'] ?? 'Unknown status'),
              ]),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(backendError(e)),
          ),
          const ModuleSectionTitle('Saved locations'),
          BackendList(
            value: ref.watch(savedProvider),
            refresh: () => ref.invalidate(savedProvider),
            empty: 'No saved locations.',
            item: (row) => InfoCard(child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bookmark_outline, color: ink),
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
            )),
          ),
          const ModuleSectionTitle('Notifications'),
          ref
              .watch(preferencesProvider)
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(backendError(e)),
                data: (p) => InfoCard(child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
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
                )),
              ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 18),
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
