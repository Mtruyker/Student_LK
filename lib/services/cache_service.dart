import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/cached_models.dart';
import '../models/student_models.dart';

/// Service for managing offline data cache using Hive
class CacheService {
  CacheService._();

  static final CacheService _instance = CacheService._();
  static CacheService get instance => _instance;

  static const String _studentDataBoxName = 'student_data';
  static const String _metadataBoxName = 'cache_metadata';

  Box<CachedStudentData>? _studentDataBox;
  Box<Map>? _metadataBox;

  bool _isInitialized = false;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CachedStudentProfileAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(CachedLessonAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CachedGradeRecordAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(CachedAnnouncementAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(CachedStudentDocumentAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(CachedStudentDataAdapter());
      }

      // Open boxes
      _studentDataBox = await Hive.openBox<CachedStudentData>(_studentDataBoxName);
      _metadataBox = await Hive.openBox<Map>(_metadataBoxName);

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('Cache service initialized successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to initialize cache service: $error');
      }
      rethrow;
    }
  }

  /// Cache student data
  Future<void> cacheStudentData(String studentId, StudentCabinetData data) async {
    await _ensureInitialized();

    try {
      final cachedData = CachedStudentData(
        studentId: studentId,
        profile: CachedStudentProfile.fromJson(data.profile.toJson()),
        schedule: data.schedule.map((lesson) => CachedLesson.fromJson(lesson.toJson())).toList(),
        grades: data.grades.map((grade) => CachedGradeRecord.fromJson(grade.toJson())).toList(),
        announcements: data.announcements.map((announcement) => CachedAnnouncement.fromJson(announcement.toJson())).toList(),
        documents: data.documents.map((document) => CachedStudentDocument.fromJson(document.toJson())).toList(),
        cachedAt: DateTime.now(),
      );

      await _studentDataBox!.put(studentId, cachedData);

      // Update metadata
      await _updateCacheMetadata(studentId, {
        'last_cached': DateTime.now().toIso8601String(),
        'data_size': _calculateDataSize(cachedData),
      });

      if (kDebugMode) {
        debugPrint('Cached student data for $studentId');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to cache student data: $error');
      }
      rethrow;
    }
  }

  /// Get cached student data
  Future<StudentCabinetData?> getCachedStudentData(String studentId) async {
    await _ensureInitialized();

    try {
      final cachedData = _studentDataBox!.get(studentId);
      if (cachedData == null) return null;

      // Convert cached data back to domain models
      return StudentCabinetData(
        profile: StudentProfile.fromJson(cachedData.profile.toJson()),
        schedule: cachedData.schedule.map((lesson) => Lesson.fromJson(lesson.toJson())).toList(),
        grades: cachedData.grades.map((grade) => GradeRecord.fromJson(grade.toJson())).toList(),
        announcements: cachedData.announcements.map((announcement) => StudentAnnouncement.fromJson(announcement.toJson())).toList(),
        documents: cachedData.documents.map((document) => StudentDocument.fromJson(document.toJson())).toList(),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to get cached student data: $error');
      }
      return null;
    }
  }

  /// Check if cached data exists for student
  Future<bool> hasCachedData(String studentId) async {
    await _ensureInitialized();
    return _studentDataBox!.containsKey(studentId);
  }

  /// Check if cached data is fresh (less than 1 hour old)
  Future<bool> isCachedDataFresh(String studentId) async {
    await _ensureInitialized();

    final cachedData = _studentDataBox!.get(studentId);
    if (cachedData == null) return false;

    return cachedData.isFresh;
  }

  /// Check if cached data is stale (more than 24 hours old)
  Future<bool> isCachedDataStale(String studentId) async {
    await _ensureInitialized();

    final cachedData = _studentDataBox!.get(studentId);
    if (cachedData == null) return true;

    return cachedData.isStale;
  }

  /// Get cache age for student data
  Future<Duration?> getCacheAge(String studentId) async {
    await _ensureInitialized();

    final cachedData = _studentDataBox!.get(studentId);
    if (cachedData == null) return null;

    return cachedData.age;
  }

  /// Clear cached data for specific student
  Future<void> clearStudentCache(String studentId) async {
    await _ensureInitialized();

    try {
      await _studentDataBox!.delete(studentId);
      await _metadataBox!.delete('student_$studentId');

      if (kDebugMode) {
        debugPrint('Cleared cache for student $studentId');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to clear student cache: $error');
      }
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _ensureInitialized();

    try {
      await _studentDataBox!.clear();
      await _metadataBox!.clear();

      if (kDebugMode) {
        debugPrint('Cleared all cache data');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to clear all cache: $error');
      }
    }
  }

  /// Clean up stale cache entries (older than 7 days)
  Future<void> cleanupStaleCache() async {
    await _ensureInitialized();

    try {
      final keysToDelete = <String>[];
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

      for (final key in _studentDataBox!.keys) {
        final cachedData = _studentDataBox!.get(key);
        if (cachedData != null && cachedData.cachedAt.isBefore(cutoffDate)) {
          keysToDelete.add(key as String);
        }
      }

      for (final key in keysToDelete) {
        await _studentDataBox!.delete(key);
        await _metadataBox!.delete('student_$key');
      }

      if (kDebugMode && keysToDelete.isNotEmpty) {
        debugPrint('Cleaned up ${keysToDelete.length} stale cache entries');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to cleanup stale cache: $error');
      }
    }
  }

  /// Get cache statistics
  Future<CacheStats> getCacheStats() async {
    await _ensureInitialized();

    try {
      final totalEntries = _studentDataBox!.length;
      var totalSize = 0;
      var freshEntries = 0;
      var staleEntries = 0;

      for (final cachedData in _studentDataBox!.values) {
        totalSize += _calculateDataSize(cachedData);
        if (cachedData.isFresh) {
          freshEntries++;
        } else if (cachedData.isStale) {
          staleEntries++;
        }
      }

      return CacheStats(
        totalEntries: totalEntries,
        freshEntries: freshEntries,
        staleEntries: staleEntries,
        totalSizeBytes: totalSize,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to get cache stats: $error');
      }
      return CacheStats.empty();
    }
  }

  /// Update cache metadata
  Future<void> _updateCacheMetadata(String studentId, Map<String, dynamic> metadata) async {
    try {
      await _metadataBox!.put('student_$studentId', metadata);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to update cache metadata: $error');
      }
    }
  }

  /// Calculate approximate data size
  int _calculateDataSize(CachedStudentData data) {
    // Rough estimation based on string lengths and object counts
    var size = 0;

    // Profile
    size += data.profile.fullName.length * 2; // UTF-16
    size += (data.profile.email.length + (data.profile.groupName?.length ?? 0)) * 2;

    // Schedule
    size += data.schedule.length * 100; // Rough estimate per lesson

    // Grades
    size += data.grades.length * 80; // Rough estimate per grade

    // Announcements
    for (final announcement in data.announcements) {
      size += (announcement.title.length + announcement.description.length) * 2;
    }

    // Documents
    size += data.documents.length * 50; // Rough estimate per document

    return size;
  }

  /// Ensure cache service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Close the cache service
  Future<void> close() async {
    if (_isInitialized) {
      await _studentDataBox?.close();
      await _metadataBox?.close();
      _isInitialized = false;
    }
  }
}

/// Cache statistics
class CacheStats {
  final int totalEntries;
  final int freshEntries;
  final int staleEntries;
  final int totalSizeBytes;

  const CacheStats({
    required this.totalEntries,
    required this.freshEntries,
    required this.staleEntries,
    required this.totalSizeBytes,
  });

  factory CacheStats.empty() {
    return const CacheStats(
      totalEntries: 0,
      freshEntries: 0,
      staleEntries: 0,
      totalSizeBytes: 0,
    );
  }

  double get totalSizeKB => totalSizeBytes / 1024;
  double get totalSizeMB => totalSizeKB / 1024;

  int get outdatedEntries => totalEntries - freshEntries - staleEntries;

  @override
  String toString() {
    return 'CacheStats(total: $totalEntries, fresh: $freshEntries, stale: $staleEntries, size: ${totalSizeKB.toStringAsFixed(1)}KB)';
  }
}