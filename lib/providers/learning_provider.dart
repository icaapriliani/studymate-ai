import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/repositories/learning_repository.dart';
import '../models/material_model.dart';
import '../models/module_model.dart';
import '../models/module_progress_model.dart';

class LearningProvider extends ChangeNotifier {
  final LearningRepository _learningRepository;

  LearningProvider({required LearningRepository learningRepository})
      : _learningRepository = learningRepository;

  List<MaterialModel> _materials = [];
  Map<String, List<ModuleModel>> _allModules = {};
  Map<String, ModuleProgressModel> _allProgress = {};

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _progressSubscription;
  StreamSubscription? _materialsSubscription;
  final List<StreamSubscription> _modulesSubscriptions = [];

  List<MaterialModel> get materials => _materials;
  Map<String, List<ModuleModel>> get allModules => _allModules;
  Map<String, ModuleProgressModel> get allProgress => _allProgress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Check if a specific module is completed
  bool isModuleCompleted(String moduleId) {
    final prog = _allProgress[moduleId];
    return prog != null && prog.completed;
  }

  /// Get progress percentage of a specific material (0.0 to 1.0)
  double getMaterialProgress(String materialId) {
    final material = _materials.firstWhere((MaterialModel m) => m.id == materialId, orElse: () => const MaterialModel(
      id: '',
      title: '',
      modules: '',
      description: '',
      keyPoints: [],
      sampleQuestions: [],
      progress: 0.0,
      estimatedTime: '',
      color: Colors.grey,
      category: '',
    ));
    if (material.id.isEmpty) return 0.0;
    return material.progress;
  }

  /// Menjalankan seeder test sederhana untuk memverifikasi write permission ke Firestore
  Future<void> runSimpleSeederTest() async {
    debugPrint('[LearningProvider] runSimpleSeederTest() dipanggil.');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _learningRepository.runSimpleSeederTest();
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[LearningProvider] runSimpleSeederTest() GAGAL: $e');
      debugPrint('[LearningProvider] STACKTRACE: $stackTrace');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Initialize real-time streams for materials, modules, and progress
  Future<void> initLearning(String uid) async {
    debugPrint('[LearningProvider] initLearning() dipanggil untuk uid: $uid');
    if (uid.isEmpty) {
      debugPrint('[LearningProvider] uid kosong, membatalkan seluruh subkripsi.');
      _cancelSubscriptions();
      _materials = [];
      _allModules = {};
      _allProgress = {};
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Clean up legacy dummy data automatically
      debugPrint('[LearningProvider] Pembersihan otomatis data dummy di awal...');
      await _learningRepository.cleanupLegacyDummyData(uid);
      debugPrint('[LearningProvider] Pembersihan otomatis selesai.');

      // 2. Seed database with default materials if empty
      debugPrint('[LearningProvider] Mencoba seedDefaultMaterialsIfNeeded...');
      await _learningRepository.seedDefaultMaterialsIfNeeded();
      debugPrint('[LearningProvider] seedDefaultMaterialsIfNeeded() selesai sukses.');

      // 2. Cancel existing subscriptions
      _cancelSubscriptions();

      // 3. Listen to user progress
      debugPrint('[LearningProvider] Mendengarkan progres modul pengguna...');
      _progressSubscription = _learningRepository.streamUserModuleProgress(uid).listen(
        (progressList) {
          debugPrint('[LearningProvider] Progres stream menerima ${progressList.length} data.');
          _allProgress = {for (var p in progressList) p.moduleId: p};
          _rebuildMaterialsList();
        },
        onError: (error) {
          debugPrint('[LearningProvider] Error in progress stream: $error');
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
          notifyListeners();
        },
      );

      // 4. Fetch the list of materials to know which module collections to listen to
      // We will listen to the materials stream raw and dynamically subscribe to modules
      debugPrint('[LearningProvider] Mendengarkan perubahan koleksi materials...');
      _materialsSubscription = FirebaseFirestore.instance
          .collection('materials')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .listen(
        (snapshot) async {
          final List<String> materialIds = snapshot.docs.map((doc) => doc.id).toList();
          debugPrint('[LearningProvider] Snapshot materials mendeteksi materialIds: $materialIds');
          
          // Clear old modules subscriptions
          for (var sub in _modulesSubscriptions) {
            sub.cancel();
          }
          _modulesSubscriptions.clear();

          // Listen to modules for each material ID
          for (final matId in materialIds) {
            debugPrint('[LearningProvider] Mendengarkan subkoleksi modul untuk material: $matId');
            final sub = _learningRepository.streamModules(matId).listen(
              (modulesList) {
                debugPrint('[LearningProvider] Modul stream untuk $matId menerima ${modulesList.length} modul.');
                _allModules[matId] = modulesList;
                _rebuildMaterialsList();
              },
              onError: (error) {
                debugPrint('[LearningProvider] Error in modules stream for $matId: $error');
                _errorMessage = error.toString().replaceFirst('Exception: ', '');
                _isLoading = false;
                notifyListeners();
              },
            );
            _modulesSubscriptions.add(sub);
          }

          // Trigger build with raw documents initially
          _rebuildMaterialsListFromSnapshot(snapshot.docs);
          
          // Successfully loaded initial materials snapshot, stop loading state
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('[LearningProvider] Error in materials stream: $error');
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e, stackTrace) {
      debugPrint('[LearningProvider] Error during initialization: $e');
      debugPrint('[LearningProvider] STACKTRACE: $stackTrace');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  List<DocumentSnapshot> _lastRawMaterialsDocs = [];

  void _rebuildMaterialsListFromSnapshot(List<DocumentSnapshot> docs) {
    _lastRawMaterialsDocs = docs;
    _rebuildMaterialsList();
  }

  /// Rebuild the materials list by combining raw materials, modules, and user progress
  void _rebuildMaterialsList() {
    if (_lastRawMaterialsDocs.isEmpty) {
      debugPrint('[LearningProvider] _rebuildMaterialsList() dibatalkan karena _lastRawMaterialsDocs kosong.');
      return;
    }

    try {
      debugPrint('[LearningProvider] Memulai pembangunan kembali daftar materi (_rebuildMaterialsList)...');
      debugPrint('[LearningProvider] Status Progres: ${_allProgress.length} item dimuat di cache.');
      
      _materials = _lastRawMaterialsDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final materialId = doc.id;
        final title = data['title'] ?? 'Tanpa Judul';
        
        final modulesList = _allModules[materialId] ?? [];
        final totalModulesCount = modulesList.length;

        int completedModulesCount = 0;
        int totalMinutes = 0;
        for (final m in modulesList) {
          totalMinutes += m.estimatedMinutes;
          final prog = _allProgress[m.id];
          if (prog != null && prog.completed) {
            completedModulesCount++;
          }
        }

        final double progress = totalModulesCount > 0 
            ? completedModulesCount / totalModulesCount 
            : 0.0;

        debugPrint('[LearningProvider] KONTEN DIHITUNG UNTUK MATERI: id=$materialId, title="$title"');
        debugPrint('[LearningProvider]   - Jumlah modul: $totalModulesCount');
        debugPrint('[LearningProvider]   - Jumlah modul selesai: $completedModulesCount');
        debugPrint('[LearningProvider]   - Progres rasio: ${progress.toStringAsFixed(2)} (${(progress * 100).toStringAsFixed(0)}%)');
        debugPrint('[LearningProvider]   - Total estimasi waktu membaca: $totalMinutes menit');

        return MaterialModel.fromFirestore(
          data, 
          materialId, 
          progress: progress,
          totalModulesCount: totalModulesCount,
          completedModulesCount: completedModulesCount,
          overrideMinutes: totalMinutes > 0 ? totalMinutes : null,
        );
      }).toList();

      debugPrint('[LearningProvider] _rebuildMaterialsList() selesai. Total ${_materials.length} materi dibangun.');
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[LearningProvider] Error rebuilding materials list: $e');
      debugPrint('[LearningProvider] STACKTRACE: $stackTrace');
    }
  }

  /// Save user's module progress and update Firestore in real time
  Future<void> markModuleAsCompleted({
    required String uid,
    required String materialId,
    required String moduleId,
    required bool completed,
  }) async {
    if (uid.isEmpty) return;

    try {
      // Optimistic Update (Local State)
      final now = DateTime.now();
      _allProgress[moduleId] = ModuleProgressModel(
        moduleId: moduleId,
        materialId: materialId,
        completed: completed,
        completedAt: now,
        lastReadAt: now,
      );
      _rebuildMaterials();
      notifyListeners();

      // Remote Update
      await _learningRepository.saveModuleProgress(
        uid: uid,
        materialId: materialId,
        moduleId: moduleId,
        completed: completed,
      );

      debugPrint('[LearningProvider] Sukses menyimpan progress modul $moduleId ke Firestore');
    } catch (e) {
      debugPrint('[LearningProvider] Gagal menyimpan progress modul: $e');
      // Revert optimistic update by refreshing from server or error message
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  /// Membersihkan seluruh data legacy dummy dan test secara aman
  Future<void> cleanupLegacyDummyData(String uid) async {
    debugPrint('[LearningProvider] cleanupLegacyDummyData() dipanggil untuk uid: $uid');
    if (uid.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _learningRepository.cleanupLegacyDummyData(uid);
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[LearningProvider] cleanupLegacyDummyData() GAGAL: $e');
      debugPrint('[LearningProvider] STACKTRACE: $stackTrace');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void _rebuildMaterials() {
    _rebuildMaterialsList();
  }

  void _cancelSubscriptions() {
    _progressSubscription?.cancel();
    _materialsSubscription?.cancel();
    for (var sub in _modulesSubscriptions) {
      sub.cancel();
    }
    _modulesSubscriptions.clear();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
