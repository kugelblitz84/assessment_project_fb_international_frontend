import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/core/widgets/async_state_view.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/controller/admin_category_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/model/admin_category.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/controller/admin_image_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/view/admin_image_field.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/controller/admin_service_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/admin_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/controller/service_form_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/admin_validation.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/view/admin_widgets.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

class AdminServiceFormPage extends ConsumerWidget {
  const AdminServiceFormPage({super.key, this.id, this.package = false});
  final String? id;
  final bool package;
  @override
  Widget build(BuildContext context, WidgetRef ref) => id == null
      ? _Dependencies(package: package)
      : AdminAsync(
          value: ref.watch(
            adminServiceProvider((
              owner: ref.watch(adminOwnerProvider),
              id: id!,
            )),
          ),
          onRetry: () => ref.invalidate(
            adminServiceProvider((
              owner: ref.watch(adminOwnerProvider),
              id: id!,
            )),
          ),
          builder: (item) => item.service.isPackage != package
              ? const StateMessage(
                  title: 'Different catalog type',
                  message:
                      'Open this item from its correct service or package list.',
                )
              : _Dependencies(item: item, package: package),
        );
}

class _Dependencies extends ConsumerWidget {
  const _Dependencies({this.item, required this.package});
  final AdminService? item;
  final bool package;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAsync(
    value: ref.watch(adminCategoriesProvider(ref.watch(adminOwnerProvider))),
    onRetry: () => ref.invalidate(adminCategoriesProvider),
    builder: (categories) => categories.isEmpty
        ? StateMessage(
            title: 'Create a category first',
            message: 'Services and packages need a live category.',
            action: FilledButton(
              onPressed: () =>
                  context.go('${AppRoutes.adminCategoriesPath}/new'),
              child: const Text('Add category'),
            ),
          )
        : package
        ? AdminAsync(
            value: ref.watch(adminIndividualServicesProvider),
            onRetry: () => ref.invalidate(adminServicesProvider),
            builder: (services) => _ServiceForm(
              key: ValueKey(item?.id ?? 'new-package'),
              item: item,
              package: true,
              categories: categories,
              individuals: services,
            ),
          )
        : _ServiceForm(
            key: ValueKey(item?.id ?? 'new-service'),
            item: item,
            package: false,
            categories: categories,
          ),
  );
}

class _ServiceForm extends ConsumerStatefulWidget {
  const _ServiceForm({
    super.key,
    this.item,
    required this.package,
    required this.categories,
    this.individuals = const [],
  });
  final AdminService? item;
  final bool package;
  final List<AdminCategory> categories;
  final List<AdminService> individuals;
  @override
  ConsumerState<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends ConsumerState<_ServiceForm> {
  final form = GlobalKey<FormState>();
  late final imageKey = (
    owner: Object(),
    initialUrl: widget.item?.service.imageUrl,
  );
  late final name = TextEditingController(
    text: widget.item?.service.name ?? '',
  );
  late final slug = TextEditingController(text: widget.item?.slug ?? '');
  late final description = TextEditingController(
    text: widget.item?.service.description ?? '',
  );
  late final price = TextEditingController(
    text: widget.item?.service.price.toString() ?? '',
  );
  late final duration = TextEditingController(
    text: widget.item?.service.durationMinutes.toString() ?? '',
  );
  late final order = TextEditingController(
    text: '${widget.item?.sortOrder ?? 0}',
  );
  late final editorProvider = serviceFormProvider((
    image: imageKey,
    item: widget.item,
    package: widget.package,
    firstCategoryId: widget.categories.first.id,
    individuals: widget.individuals,
  ));
  String get path => widget.package
      ? AppRoutes.adminPackagesPath
      : AppRoutes.adminServicesPath;
  @override
  void dispose() {
    for (final c in [name, slug, description, price, duration, order]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final editor = ref.read(editorProvider.notifier);
    if (editor.requiresStatusConfirmation &&
        !await adminConfirm(
          context,
          'Change item status?',
          'This changes customer catalog visibility.',
        )) {
      return;
    }
    if (!mounted) return;
    final result = await editor.save(
      name: name.text,
      slug: slug.text,
      description: description.text,
      price: price.text,
      duration: duration.text,
      sortOrder: order.text,
    );
    if (!mounted || result == null) return;
    adminNotice(
      context,
      result,
      success: widget.package ? 'Package saved.' : 'Service saved.',
    );
    if (result.success) {
      context.go(path);
    }
  }

  Widget field(
    TextEditingController c,
    String label,
    String? Function(String?) validator, {
    int lines = 1,
    TextInputType? keyboard,
  }) => TextFormField(
    controller: c,
    enabled: !ref.watch(
      adminServiceMutationProvider.select((state) => state.busy),
    ),
    maxLines: lines,
    keyboardType: keyboard,
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );
  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(
      adminServiceMutationProvider.select((state) => state.busy),
    );
    final image = ref.watch(adminImageProvider(imageKey));
    final draft = ref.watch(editorProvider);
    final editor = ref.read(editorProvider.notifier);
    final remaining = editor.remaining;
    return Form(
      key: form,
      child: AdminPageBody(
        form: true,
        children: [
          Text(
            '${widget.item == null ? 'Create' : 'Edit'} ${widget.package ? 'package' : 'service'}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          field(name, 'Name', AdminValidation.name),
          field(slug, 'Slug (optional)', AdminValidation.slug),
          field(
            description,
            'Description',
            AdminValidation.description,
            lines: 3,
          ),
          DropdownButtonFormField<String>(
            initialValue: draft.categoryId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final c in widget.categories)
                DropdownMenuItem(
                  value: c.id,
                  child: Text(
                    '${c.name}${c.isActive ? '' : ' (inactive)'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: busy ? null : editor.selectCategory,
            validator: (v) => v == null ? 'Choose a category.' : null,
          ),
          field(
            price,
            widget.package ? 'Package price (BDT)' : 'Price (BDT)',
            AdminValidation.money,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          field(
            duration,
            'Duration (minutes)',
            (v) => AdminValidation.integer(v, min: 1, max: 1440),
            keyboard: TextInputType.number,
          ),
          field(
            order,
            'Sort order',
            AdminValidation.integer,
            keyboard: const TextInputType.numberWithOptions(signed: true),
          ),
          Text('Inclusions', style: Theme.of(context).textTheme.titleMedium),
          for (final entry in draft.inclusions.entries)
            Row(
              key: ValueKey(('inclusion', entry.key)),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: entry.value,
                    enabled: !busy,
                    onChanged: (value) =>
                        editor.updateInclusion(entry.key, value),
                    decoration: InputDecoration(
                      labelText:
                          'Inclusion ${draft.inclusions.keys.toList().indexOf(entry.key) + 1}',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty || v.trim().length > 1000
                        ? 'Enter 1–1,000 characters.'
                        : null,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove inclusion',
                  onPressed: busy
                      ? null
                      : () => editor.removeInclusion(entry.key),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: busy || draft.inclusions.length >= 100
                  ? null
                  : editor.addInclusion,
              icon: const Icon(Icons.add),
              label: const Text('Add inclusion'),
            ),
          ),
          if (widget.package) ...[
            Text(
              'Package services',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'Select individual services. The package price above is independent of component prices.',
            ),
            if (remaining.isNotEmpty)
              DropdownButtonFormField<String>(
                key: ValueKey(draft.quantities.keys.join(',')),
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Add individual service',
                ),
                items: [
                  for (final s in remaining)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        '${s.service.name}${s.isActive ? '' : ' (inactive)'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: busy ? null : editor.addItem,
              ),
            for (final entry in draft.quantities.entries)
              Column(
                key: ValueKey(('quantity', entry.key)),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editor.componentNames[entry.key] ?? 'Unavailable component',
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: entry.value,
                          enabled: !busy,
                          onChanged: (value) =>
                              editor.updateQuantity(entry.key, value),
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                          ),
                          validator: (v) =>
                              AdminValidation.integer(v, min: 1, max: 1000),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove package item',
                        onPressed: busy
                            ? null
                            : () => editor.removeItem(entry.key),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Featured'),
            value: draft.featured,
            onChanged: busy ? null : editor.setFeatured,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            value: draft.active,
            onChanged: busy ? null : editor.setActive,
          ),
          AdminImageField(fieldKey: imageKey, enabled: !busy),
          if (draft.error != null)
            InlineNotice(message: draft.error!, error: true),
          Wrap(
            spacing: 12,
            children: [
              FilledButton(
                onPressed: busy || image.busy ? null : save,
                child: Text(
                  busy
                      ? 'Saving…'
                      : 'Save ${widget.package ? 'package' : 'service'}',
                ),
              ),
              TextButton(
                onPressed: busy ? null : () => context.go(path),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
