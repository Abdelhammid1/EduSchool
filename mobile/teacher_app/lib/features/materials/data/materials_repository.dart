import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../shared/models/material_item.dart';

final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  return MaterialsRepository(ref.watch(dioProvider));
});

class MaterialsRepository {
  final Dio _dio;
  MaterialsRepository(this._dio);

  Future<List<MaterialItem>> teacherList() async {
    try {
      final r = await _dio.get(Endpoints.teacherMaterials);
      final raw = (r.data['materials'] as List?) ?? const [];
      return raw
          .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw toApi(e);
    }
  }
}

final teacherMaterialsProvider =
    FutureProvider.autoDispose<List<MaterialItem>>((ref) {
  return ref.watch(materialsRepositoryProvider).teacherList();
});
