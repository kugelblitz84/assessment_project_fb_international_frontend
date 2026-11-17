import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/navigation/page_scaffold.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/current_user_provider.dart';
import '../../../core/session/application/session_identity_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/page_container.dart';
import '../../../routes/app_routes.dart';
import '../controller/profile_controller.dart';
import 'widgets/profile_edit_form.dart';

class EditProfilePage extends ConsumerWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);
    final controller = ref.watch(profileControllerProvider.notifier);
    final user = ref.watch(currentUserProvider);
    final identity = ref.watch(sessionIdentityProvider);
    ref.listen(profileControllerProvider.select((state) => state.saved), (
      previous,
      saved,
    ) {
      if (!saved || previous == true) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(AppRoutes.profile);
      }
    });
    return AppPageScaffold(
      title: 'Edit profile',
      body: SingleChildScrollView(
        child: PageContainer(
          maxWidth: 560,
          child: AppSurface(
            child: Padding(
              padding: AppSize.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your details',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: AppSize.vertical(8)),
                  const Text(
                    'Keep your account information up to date.',
                    style: TextStyle(color: AppColors.secondary),
                  ),
                  SizedBox(height: AppSize.vertical(28)),
                  ProfileEditForm(
                    key: ValueKey(identity),
                    initialName: user?.name ?? '',
                    initialEmail: user?.email ?? '',
                    saving: state.saving,
                    onSubmit: controller.save,
                    error: state.errorCode == null
                        ? null
                        : InlineNotice(
                            message: ApiErrorHandler.messageFor(
                              state.errorCode,
                            ),
                            error: true,
                          ),
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
