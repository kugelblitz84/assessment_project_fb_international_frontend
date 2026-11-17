import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/async_state_view.dart';
import '../../../../routes/app_routes.dart';
import '../../media/controller/admin_image_controller.dart';
import '../../media/view/admin_image_field.dart';
import '../../shared/controller/admin_providers.dart';
import '../../shared/model/admin_models.dart';
import '../../shared/model/admin_validation.dart';
import '../../shared/view/admin_widgets.dart';

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
            value: ref.watch(
              adminServicesProvider(ref.watch(adminOwnerProvider)),
            ),
            onRetry: () => ref.invalidate(adminServicesProvider),
            builder: (services) => _ServiceForm(
              key: ValueKey(item?.id ?? 'new-package'),
              item: item,
              package: true,
              categories: categories,
              individuals: services.where((s) => !s.service.isPackage).toList(),
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
  late final inclusions = [
    for (final value in widget.item?.service.inclusions ?? <String>[])
      TextEditingController(text: value),
  ];
  late final quantities = {
    for (final item in widget.item?.items ?? <PackageItem>[])
      item.serviceId: TextEditingController(text: '${item.quantity}'),
  };
  late String category =
      widget.item?.service.categoryId ?? widget.categories.first.id;
  late bool active = widget.item?.isActive ?? true,
      featured = widget.item?.isFeatured ?? false;
  String? error;
  String get path => widget.package
      ? AppRoutes.adminPackagesPath
      : AppRoutes.adminServicesPath;
  @override
  void dispose() {
    for (final c in [
      name,
      slug,
      description,
      price,
      duration,
      order,
      ...inclusions,
      ...quantities.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final values = inclusions.map((c) => c.text.trim()).toList();
    final items = [
      for (final e in quantities.entries)
        PackageItem(
          serviceId: e.key,
          quantity: int.tryParse(e.value.text) ?? 0,
        ),
    ];
    final validation =
        AdminValidation.inclusions(values) ??
        (widget.package
            ? AdminValidation.packageItems(
                items,
                widget.individuals.map((s) => s.id).toSet(),
              )
            : null);
    setState(() => error = validation);
    if (validation != null) return;
    if (widget.item != null &&
        active != widget.item!.isActive &&
        !await adminConfirm(
          context,
          'Change item status?',
          'This changes customer catalog visibility.',
        )) {
      return;
    }
    if (!mounted) return;
    final image = ref.read(adminImageProvider(imageKey));
    if (image.busy) return;
    final result = await ref
        .read(adminMutationProvider.notifier)
        .save(ApiEndpoints.adminServices, {
          'name': name.text.trim(),
          if (slug.text.isNotEmpty) 'slug': slug.text,
          'description': description.text,
          'categoryId': category,
          'type': widget.package ? 'PACKAGE' : 'INDIVIDUAL',
          'price': price.text,
          'currency': 'BDT',
          'durationMinutes': int.parse(duration.text),
          'sortOrder': int.parse(order.text),
          'isActive': active,
          'isFeatured': featured,
          'imageUrl': image.url,
          'inclusions': values,
          'packageItems': items.map((i) => i.toJson()).toList(),
        }, id: widget.item?.id);
    if (!mounted) return;
    adminNotice(
      context,
      result,
      success: widget.package ? 'Package saved.' : 'Service saved.',
    );
    if (result.success) {
      if (widget.item != null) {
        ref.invalidate(
          adminServiceProvider((
            owner: ref.read(adminOwnerProvider),
            id: widget.item!.id,
          )),
        );
      }
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
    enabled: !ref.watch(adminMutationProvider),
    maxLines: lines,
    keyboardType: keyboard,
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );
  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(adminMutationProvider);
    final image = ref.watch(adminImageProvider(imageKey));
    final remaining = widget.individuals
        .where((s) => !quantities.containsKey(s.id))
        .toList();
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
            initialValue: category,
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
            onChanged: busy ? null : (v) => setState(() => category = v!),
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
          for (var i = 0; i < inclusions.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: field(
                    inclusions[i],
                    'Inclusion ${i + 1}',
                    (v) =>
                        v == null || v.trim().isEmpty || v.trim().length > 1000
                        ? 'Enter 1–1,000 characters.'
                        : null,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove inclusion',
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          inclusions.removeAt(i).dispose();
                        }),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: busy || inclusions.length >= 100
                  ? null
                  : () =>
                        setState(() => inclusions.add(TextEditingController())),
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
                key: ValueKey(quantities.keys.join(',')),
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
                onChanged: busy
                    ? null
                    : (id) {
                        if (id != null) {
                          setState(
                            () => quantities[id] = TextEditingController(
                              text: '1',
                            ),
                          );
                        }
                      },
              ),
            for (final entry in quantities.entries)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.individuals
                            .where((s) => s.id == entry.key)
                            .firstOrNull
                            ?.service
                            .name ??
                        'Unavailable component',
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: field(
                          entry.value,
                          'Quantity',
                          (v) => AdminValidation.integer(v, min: 1, max: 1000),
                          keyboard: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove package item',
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                quantities.remove(entry.key)?.dispose();
                              }),
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
            value: featured,
            onChanged: busy ? null : (v) => setState(() => featured = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            value: active,
            onChanged: busy ? null : (v) => setState(() => active = v),
          ),
          AdminImageField(fieldKey: imageKey, enabled: !busy),
          if (error != null) InlineNotice(message: error!, error: true),
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
