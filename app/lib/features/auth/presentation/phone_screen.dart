import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../settings/presentation/language_menu_button.dart';
import 'sign_in_controllers.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = await ref.read(sendCodeControllerProvider.notifier).sendCode(_controller.text);
    if (phone != null && mounted) {
      await context.push(Routes.otpFor(phone));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(sendCodeControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(actions: const [LanguageMenuButton()]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.water_drop, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(l10n.appTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 32),
            Text(l10n.authPhoneTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.authPhoneSubtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            // Phone numbers are always written left-to-right, even in Arabic.
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                key: const Key('phoneField'),
                controller: _controller,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-٠-٩۰-۹]'))],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l10n.authPhoneLabel,
                  hintText: l10n.authPhoneHint,
                  prefixIcon: const Icon(Icons.phone_android),
                  errorText: state.hasError ? l10n.errorMessage(state.error!) : null,
                  errorMaxLines: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('sendCodeButton'),
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.authSendCode),
            ),
          ],
        ),
      ),
    );
  }
}
