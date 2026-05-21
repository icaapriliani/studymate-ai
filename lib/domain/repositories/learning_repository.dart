import '../../models/material_model.dart';
import '../../models/module_model.dart';
import '../../models/module_progress_model.dart';

abstract class LearningRepository {
  /// Mendapatkan aliran data daftar materi terdaftar
  Stream<List<MaterialModel>> streamMaterials({
    required Map<String, List<ModuleModel>> allModules,
    required Map<String, ModuleProgressModel> allProgress,
  });

  /// Mendapatkan aliran data modul untuk materi tertentu
  Stream<List<ModuleModel>> streamModules(String materialId);

  /// Mendapatkan aliran data progres modul pengguna secara real-time
  Stream<List<ModuleProgressModel>> streamUserModuleProgress(String uid);

  /// Menyimpan progres modul ke Firestore
  Future<void> saveModuleProgress({
    required String uid,
    required String materialId,
    required String moduleId,
    required bool completed,
  });

  /// Mengisi database secara otomatis jika kosong
  Future<void> seedDefaultMaterialsIfNeeded();

  /// Menjalankan seeder test sederhana untuk memverifikasi write access ke Firestore
  Future<void> runSimpleSeederTest();

  /// Membersihkan data dummy/test lama secara selektif
  Future<void> cleanupLegacyDummyData(String uid);
}
