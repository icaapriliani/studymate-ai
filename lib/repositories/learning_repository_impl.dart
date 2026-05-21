import 'package:flutter/foundation.dart';
import '../domain/repositories/learning_repository.dart';
import '../models/material_model.dart';
import '../models/module_model.dart';
import '../models/module_progress_model.dart';
import '../services/learning_service.dart';

class LearningRepositoryImpl implements LearningRepository {
  final LearningService _learningService;

  LearningRepositoryImpl({required LearningService learningService})
      : _learningService = learningService;

  @override
  Stream<List<MaterialModel>> streamMaterials({
    required Map<String, List<ModuleModel>> allModules,
    required Map<String, ModuleProgressModel> allProgress,
  }) {
    return _learningService.streamMaterials().map((snapshot) {
      debugPrint('[LearningRepositoryImpl] Memulai pemetaan streamMaterials untuk ${snapshot.docs.length} dokumen...');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final materialId = doc.id;
        final title = data['title'] ?? 'Tanpa Judul';
        
        final modulesList = allModules[materialId] ?? [];
        final totalModulesCount = modulesList.length;

        int completedModulesCount = 0;
        for (final m in modulesList) {
          final prog = allProgress[m.id];
          if (prog != null && prog.completed) {
            completedModulesCount++;
          }
        }

        final double progress = totalModulesCount > 0 
            ? completedModulesCount / totalModulesCount 
            : 0.0;

        debugPrint('[LearningRepositoryImpl] PROGRES DIHITUNG DI STREAM: id=$materialId, title="$title"');
        debugPrint('[LearningRepositoryImpl]   - Modul total: $totalModulesCount');
        debugPrint('[LearningRepositoryImpl]   - Modul selesai: $completedModulesCount');
        debugPrint('[LearningRepositoryImpl]   - Progres rasio: ${progress.toStringAsFixed(2)}');

        return MaterialModel.fromFirestore(
          data, 
          materialId, 
          progress: progress,
          totalModulesCount: totalModulesCount,
          completedModulesCount: completedModulesCount,
        );
      }).toList();
    }).handleError((e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    });
  }

  @override
  Stream<List<ModuleModel>> streamModules(String materialId) {
    return _learningService.streamModules(materialId).map((snapshot) {
      return snapshot.docs.map((doc) {
        return ModuleModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    }).handleError((e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    });
  }

  @override
  Stream<List<ModuleProgressModel>> streamUserModuleProgress(String uid) {
    return _learningService.streamUserModuleProgress(uid).map((snapshot) {
      return snapshot.docs.map((doc) {
        return ModuleProgressModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    }).handleError((e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    });
  }

  @override
  Future<void> saveModuleProgress({
    required String uid,
    required String materialId,
    required String moduleId,
    required bool completed,
  }) async {
    try {
      await _learningService.saveModuleProgress(uid, materialId, moduleId, completed);
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<void> seedDefaultMaterialsIfNeeded() async {
    try {
      await _learningService.seedDefaultMaterialsIfNeeded();
    } catch (e, stackTrace) {
      debugPrint('[LearningRepositoryImpl] seedDefaultMaterialsIfNeeded() GAGAL: $e');
      debugPrint('[LearningRepositoryImpl] STACKTRACE: $stackTrace');
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<void> runSimpleSeederTest() async {
    try {
      await _learningService.runSimpleSeederTest();
    } catch (e, stackTrace) {
      debugPrint('[LearningRepositoryImpl] runSimpleSeederTest() GAGAL: $e');
      debugPrint('[LearningRepositoryImpl] STACKTRACE: $stackTrace');
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<void> cleanupLegacyDummyData(String uid) async {
    try {
      await _learningService.cleanupLegacyDummyData(uid);
    } catch (e, stackTrace) {
      debugPrint('[LearningRepositoryImpl] cleanupLegacyDummyData() GAGAL: $e');
      debugPrint('[LearningRepositoryImpl] STACKTRACE: $stackTrace');
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  /// Low-level database error translation into helpful Indonesian messages.
  String _mapErrorToUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission_denied') ||
        errorString.contains('permission-denied') ||
        errorString.contains('rules')) {
      return 'Akses database ditolak. Harap pastikan aturan keamanan (Security Rules) Firestore Anda sudah dikonfigurasi ke publik/mode pengujian di Firebase Console.\n(Error Asli: $error)';
    }

    if (errorString.contains('api_disabled') ||
        errorString.contains('firestore api has not been used') ||
        errorString.contains('not-found')) {
      return 'Layanan Cloud Firestore belum diaktifkan pada proyek Firebase Anda. Harap buat database Firestore di Firebase Console.\n(Error Asli: $error)';
    }

    return 'Terjadi kesalahan sistem saat mengakses data pembelajaran: $error';
  }
}
