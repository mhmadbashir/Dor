import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/phone_number.dart';
import 'sign_in_controllers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final PhoneNumber phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    // On success the router redirects away from this screen.
    await ref.read(verifyCodeControllerProvider.notifier).verify(widget.phone, _controller.text);
  }

  Future<void> _resend() async {
    final sent = await ref.read(verifyCodeControllerProvider.notifier).resend(widget.phone);
    if (sent && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.authCodeResent)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(verifyCodeControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l10n.authOtpTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              // Keep the number LTR inside the (possibly RTL) sentence.
              l10n.authOtpSubtitle('\u2066${widget.phone.display}\u2069'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                key: const Key('otpField'),
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 12),
                maxLength: VerifyCodeController.codeLength,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]'))],
                onChanged: (value) {
                  if (value.length == VerifyCodeController.codeLength) _verify();
                },
                decoration: InputDecoration(
                  labelText: l10n.authOtpLabel,
                  counterText: '',
                  errorText: state.hasError ? l10n.errorMessage(state.error!) : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('verifyButton'),
              onPressed: state.isLoading ? null : _verify,
              child: state.isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.authVerify),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: state.isLoading ? null : _resend,
                  child: Text(l10n.authResendCode),
                ),
                TextButton(onPressed: () => context.pop(), child: Text(l10n.authChangeNumber)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
