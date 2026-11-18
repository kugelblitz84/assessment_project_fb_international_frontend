import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/app/api_error_messages.dart';
import 'package:assessment_project_fb_international_frontend/app/shell/page_scaffold.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/provider/current_user_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/provider/session_identity_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/app_surface.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/async_state_view.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/page_container.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/controller/profile_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/view/widgets/profile_edit_form.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

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
                            message: AppErrorMessages.messageFor(
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
