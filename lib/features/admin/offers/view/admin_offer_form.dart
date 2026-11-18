import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/core/widgets/async_state_view.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/controller/admin_offer_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/model/admin_offer.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/controller/offer_form_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/controller/admin_service_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/admin_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/admin_validation.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/view/admin_widgets.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/utils/workshop_time.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

class AdminOfferFormPage extends ConsumerWidget {
  const AdminOfferFormPage({super.key, this.id});
  final String? id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => id == null
      ? const _OfferDependencies()
      : AdminAsync(
          value: ref.watch(
            adminOfferProvider((owner: ref.watch(adminOwnerProvider), id: id!)),
          ),
          onRetry: () => ref.invalidate(
            adminOfferProvider((owner: ref.watch(adminOwnerProvider), id: id!)),
          ),
          builder: (item) => _OfferDependencies(item: item),
        );
}

class _OfferDependencies extends ConsumerWidget {
  const _OfferDependencies({this.item});
  final AdminOffer? item;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAsync(
    value: ref.watch(adminServicesProvider(ref.watch(adminOwnerProvider))),
    onRetry: () => ref.invalidate(adminServicesProvider),
    builder: (services) => services.isEmpty
        ? const StateMessage(
            title: 'Create a service first',
            message: 'Offers require an existing service or package.',
          )
        : _OfferForm(
            key: ValueKey(item?.id ?? 'new-offer'),
            item: item,
            services: services,
          ),
  );
}

class _OfferForm extends ConsumerStatefulWidget {
  const _OfferForm({super.key, this.item, required this.services});
  final AdminOffer? item;
  final List<AdminService> services;
  @override
  ConsumerState<_OfferForm> createState() => _OfferFormState();
}

class _OfferFormState extends ConsumerState<_OfferForm> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.item?.title ?? '');
  late final description = TextEditingController(
    text: widget.item?.description ?? '',
  );
  late final value = TextEditingController(
    text: widget.item?.discountValue.toString() ?? '',
  );
  late final start = TextEditingController(
    text: widget.item == null ? '' : WorkshopTime.input(widget.item!.startsAt),
  );
  late final end = TextEditingController(
    text: widget.item == null ? '' : WorkshopTime.input(widget.item!.endsAt),
  );
  late final editorProvider = offerFormProvider((
    owner: Object(),
    item: widget.item,
    firstServiceId: widget.services.first.id,
  ));
  @override
  void dispose() {
    for (final c in [title, description, value, start, end]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final result = await ref
        .read(editorProvider.notifier)
        .save(
          title: title.text,
          description: description.text,
          value: value.text,
          start: start.text,
          end: end.text,
        );
    if (!mounted || result == null) return;
    adminNotice(context, result, success: 'Offer saved.');
    if (result.success) {
      context.go(AppRoutes.adminOffersPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(editorProvider);
    final editor = ref.read(editorProvider.notifier);
    final busy = ref.watch(
      adminOfferMutationProvider.select((state) => state.busy),
    );
    return Form(
      key: form,
      child: AdminPageBody(
        form: true,
        children: [
          Text(
            widget.item == null ? 'Create offer' : 'Edit offer',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          DropdownButtonFormField<String>(
            initialValue: draft.serviceId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Service or package'),
            items: [
              for (final s in widget.services)
                DropdownMenuItem(
                  value: s.id,
                  child: Text(
                    '${s.service.name}${s.isActive ? '' : ' (inactive)'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: busy ? null : editor.selectService,
          ),
          TextFormField(
            controller: title,
            enabled: !busy,
            decoration: const InputDecoration(labelText: 'Title'),
            validator: AdminValidation.name,
          ),
          TextFormField(
            controller: description,
            enabled: !busy,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
            validator: AdminValidation.description,
          ),
          DropdownButtonFormField<String>(
            initialValue: draft.type,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Discount type'),
            items: const [
              DropdownMenuItem(value: 'PERCENTAGE', child: Text('Percentage')),
              DropdownMenuItem(
                value: 'FIXED_AMOUNT',
                child: Text('Fixed amount (BDT)'),
              ),
            ],
            onChanged: busy ? null : editor.selectType,
          ),
          TextFormField(
            controller: value,
            enabled: !busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Discount value'),
            validator: AdminValidation.money,
          ),
          const Text(
            'Dates use Asia/Dhaka time (UTC+06). Enter YYYY-MM-DD HH:mm.',
          ),
          TextFormField(
            controller: start,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: 'Start date and time',
              hintText: '2026-11-20 09:00',
            ),
            validator: (v) => WorkshopTime.parse(v ?? '') == null
                ? 'Use YYYY-MM-DD HH:mm.'
                : null,
          ),
          TextFormField(
            controller: end,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: 'End date and time',
              hintText: '2026-11-27 18:00',
            ),
            validator: (v) => WorkshopTime.parse(v ?? '') == null
                ? 'Use YYYY-MM-DD HH:mm.'
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            value: draft.active,
            onChanged: busy ? null : editor.setActive,
          ),
          if (draft.error != null)
            InlineNotice(message: draft.error!, error: true),
          Wrap(
            spacing: 12,
            children: [
              FilledButton(
                onPressed: busy ? null : save,
                child: Text(busy ? 'Saving…' : 'Save offer'),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => context.go(AppRoutes.adminOffersPath),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
