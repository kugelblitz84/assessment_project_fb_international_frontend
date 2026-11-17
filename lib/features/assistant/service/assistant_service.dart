import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/request_access.dart';
import '../../../core/network/dio_provider.dart';
import '../../shared/service/demo_workshop.dart';
import '../model/assistant_message_model.dart';
import '../model/assistant_request_payload.dart';

final assistantServiceProvider = Provider(
  (ref) =>
      AssistantService(ref.watch(dioProvider), ref.watch(demoWorkshopProvider)),
);

class AssistantService {
  AssistantService(this.dio, this.demo);
  final Dio dio;
  final DemoWorkshop? demo;
  Future<AssistantMessageModel> send(AssistantRequestPayload payload) async {
    if (demo == null) {
      final response = await dio.post<Object?>(
        ApiEndpoints.assistantChat,
        data: payload.toJson(),
        options: Options(
          extra: {requestAccessKey: RequestAccess.optional},
          receiveTimeout: const Duration(seconds: 65),
        ),
      );
      final json = response.data;
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Invalid assistant response.');
      }
      return AssistantMessageModel.fromJson(json);
    }
    await demo!.pause();
    final prompt = payload.messages.last.text.toLowerCase();
    final ids = switch (prompt) {
      _ when prompt.contains('wash') || prompt.contains('clean') => [
        'exterior-wash',
        'interior-detail',
      ],
      _ when prompt.contains('trip') || prompt.contains('safe') => [
        'tyre-inspection',
        'battery-check',
        'oil-change',
      ],
      _ when prompt.contains('battery') => ['battery-check'],
      _ when prompt.contains('oil') || prompt.contains('engine') => [
        'oil-change',
      ],
      _ when prompt.contains('budget') || prompt.contains('price') => [
        'battery-check',
        'tyre-inspection',
        'exterior-wash',
      ],
      _ when prompt.contains('ac') || prompt.contains('cool') => [
        'ac-inspection',
      ],
      _ => ['exterior-wash', 'oil-change', 'tyre-inspection'],
    };
    final message = prompt.contains('wash')
        ? 'An exterior wash includes a foam wash, wheel and tyre cleaning, and a microfibre hand dry. For the cabin, take a look at interior detailing. Open a service below for its sample price and inclusions.'
        : 'Here are a few services from the sample catalogue that may be useful. Open a card to compare its price, duration and inclusions. For warning lights, unusual noises or safety concerns, arrange a technician’s inspection before deciding on a repair.';
    return AssistantMessageModel(
      id: 'reply-${DateTime.now().microsecondsSinceEpoch}',
      role: AssistantRole.assistant,
      text: message,
      actions: [
        for (final id in ids)
          AssistantAction(
            type: AssistantActionType.serviceDetails,
            serviceId: id,
          ),
        const AssistantAction(type: AssistantActionType.browseServices),
      ],
    );
  }
}
