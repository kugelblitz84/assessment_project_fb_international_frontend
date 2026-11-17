import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_handler.dart';
import '../controller/admin_image_controller.dart';

class AdminImageField extends ConsumerWidget {
  const AdminImageField({
    super.key,
    required this.fieldKey,
    this.enabled = true,
  });
  final AdminImageKey fieldKey;
  final bool enabled;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = adminImageProvider(fieldKey);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Image · JPEG, PNG or WebP · up to 2 MB'),
        const SizedBox(height: 8),
        if (state.bytes != null)
          SizedBox(
            height: 160,
            child: Image.memory(
              state.bytes!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Text('Unable to preview the selected file.'),
            ),
          )
        else if (state.url != null)
          SizedBox(
            height: 160,
            child: Image.network(
              state.url!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Text('Existing image is saved; preview unavailable.'),
            ),
          ),
        if (state.busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        if (state.errorCode != null)
          Text(
            '${ApiErrorHandler.messageFor(state.errorCode)} Previous saved image is retained.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        Wrap(
          spacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: enabled && !state.busy ? controller.select : null,
              icon: const Icon(Icons.upload),
              label: Text(state.busy ? 'Uploading…' : 'Choose image'),
            ),
            if (state.errorCode != null && state.bytes != null)
              TextButton(
                onPressed: enabled && !state.busy ? controller.upload : null,
                child: const Text('Retry upload'),
              ),
          ],
        ),
      ],
    );
  }
}
