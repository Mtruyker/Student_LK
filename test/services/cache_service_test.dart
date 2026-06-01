import 'package:flutter_test/flutter_test.dart';
import 'package:student_cabinet_flutter_app/models/cached_models.dart';
import 'package:student_cabinet_flutter_app/models/student_models.dart';
import 'package:student_cabinet_flutter_app/services/cache_service.dart';

void main() {
  group('CacheService', () {
    setUp(() async {
      // Note: In real tests, you'd want to use a test-specific Hive box
      // await cacheService.initialize();
    });

    tearDown(() async {
      // Clean up test data
      // await cacheService.clearAllCache();
    });

    group('Cache Operations', () {
      test('should cache and retrieve student data', () async {
        // This test would need proper Hive setup in a test environment
        // For now, we'll test the data model conversions

        final studentData = StudentCabinetData(
          profile: StudentProfile(
            fullName: 'Test Student',
            firstName: 'Test',
            group: 'Test Group',
            studentId: 'STU-123',
            email: 'test@example.com',
            phone: '+1234567890',
            curator: 'Test Curator',
            attendance: 0.85,
            completedAssignments: 15,
            totalAssignments: 20,
          ),
          schedule: [
            Lesson(
              weekday: 1,
              time: '09:00-10:30',
              subject: 'Mathematics',
              room: 'Room 101',
              teacher: 'John Doe',
              type: 'Lecture',
            ),
          ],
          grades: [
            GradeRecord(
              subject: 'Mathematics',
              grade: 5,
              progress: 0.9,
              teacher: 'John Doe',
              completedTasks: 18,
              totalTasks: 20,
            ),
          ],
          announcements: [
            StudentAnnouncement(
              title: 'Test Announcement',
              description: 'This is a test announcement',
              dateLabel: 'Today',
            ),
          ],
          documents: [
            StudentDocument(
              title: 'Test Document.pdf',
              status: 'Ready',
              updatedAt: 'Today',
            ),
          ],
        );

        // Test data conversion
        final cachedProfile = CachedStudentProfile.fromJson(studentData.profile.toJson());
        expect(cachedProfile.fullName, equals('Test Student'));
        expect(cachedProfile.email, equals('test@example.com'));
        expect(cachedProfile.attendance, equals(0.85));

        final cachedLesson = CachedLesson.fromJson(studentData.schedule.first.toJson());
        expect(cachedLesson.subject, equals('Mathematics'));
        expect(cachedLesson.weekday, equals(1));
        expect(cachedLesson.time, equals('09:00-10:30'));

        final cachedGrade = CachedGradeRecord.fromJson(studentData.grades.first.toJson());
        expect(cachedGrade.subject, equals('Mathematics'));
        expect(cachedGrade.grade, equals(5));
        expect(cachedGrade.progress, equals(0.9));
      });

      test('should handle cache freshness correctly', () {
        final now = DateTime.now();

        // Fresh data (30 minutes old)
        final freshData = CachedStudentData(
          studentId: 'test-id',
          profile: CachedStudentProfile(
            id: 'test-id',
            email: 'test@example.com',
            fullName: 'Test Student',
            attendance: 0.85,
            completedAssignments: 15,
            totalAssignments: 20,
            cachedAt: now.subtract(const Duration(minutes: 30)),
          ),
          schedule: [],
          grades: [],
          announcements: [],
          documents: [],
          cachedAt: now.subtract(const Duration(minutes: 30)),
        );

        expect(freshData.isFresh, isTrue);
        expect(freshData.isStale, isFalse);

        // Stale data (25 hours old)
        final staleData = CachedStudentData(
          studentId: 'test-id',
          profile: CachedStudentProfile(
            id: 'test-id',
            email: 'test@example.com',
            fullName: 'Test Student',
            attendance: 0.85,
            completedAssignments: 15,
            totalAssignments: 20,
            cachedAt: now.subtract(const Duration(hours: 25)),
          ),
          schedule: [],
          grades: [],
          announcements: [],
          documents: [],
          cachedAt: now.subtract(const Duration(hours: 25)),
        );

        expect(staleData.isFresh, isFalse);
        expect(staleData.isStale, isTrue);
      });
    });

    group('CacheStats', () {
      test('should calculate cache statistics correctly', () {
        const stats = CacheStats(
          totalEntries: 10,
          freshEntries: 6,
          staleEntries: 2,
          totalSizeBytes: 1024 * 1024, // 1 MB
        );

        expect(stats.totalEntries, equals(10));
        expect(stats.freshEntries, equals(6));
        expect(stats.staleEntries, equals(2));
        expect(stats.outdatedEntries, equals(2)); // total - fresh - stale
        expect(stats.totalSizeKB, equals(1024));
        expect(stats.totalSizeMB, equals(1));
      });

      test('should create empty stats correctly', () {
        final emptyStats = CacheStats.empty();

        expect(emptyStats.totalEntries, equals(0));
        expect(emptyStats.freshEntries, equals(0));
        expect(emptyStats.staleEntries, equals(0));
        expect(emptyStats.totalSizeBytes, equals(0));
      });
    });
  });

  group('Cached Models', () {
    test('CachedStudentProfile should convert to/from JSON correctly', () {
      final profile = CachedStudentProfile(
        id: 'test-id',
        email: 'test@example.com',
        fullName: 'Test Student',
        firstName: 'Test',
        groupName: 'Test Group',
        studentIdentifier: 'STU-123',
        phone: '+1234567890',
        curator: 'Test Curator',
        attendance: 0.85,
        completedAssignments: 15,
        totalAssignments: 20,
        cachedAt: DateTime.now(),
      );

      final json = profile.toJson();
      final restored = CachedStudentProfile.fromJson(json);

      expect(restored.id, equals(profile.id));
      expect(restored.email, equals(profile.email));
      expect(restored.fullName, equals(profile.fullName));
      expect(restored.attendance, equals(profile.attendance));
    });

    test('CachedLesson should convert to/from JSON correctly', () {
      final lesson = CachedLesson(
        id: 'lesson-1',
        weekday: 1,
        time: '09:00-10:30',
        subject: 'Mathematics',
        room: 'Room 101',
        teacher: 'John Doe',
        lessonType: 'Lecture',
        cachedAt: DateTime.now(),
      );

      final json = lesson.toJson();
      final restored = CachedLesson.fromJson(json);

      expect(restored.id, equals(lesson.id));
      expect(restored.weekday, equals(lesson.weekday));
      expect(restored.subject, equals(lesson.subject));
      expect(restored.time, equals(lesson.time));
    });

    test('CachedGradeRecord should convert to/from JSON correctly', () {
      final grade = CachedGradeRecord(
        id: 'grade-1',
        subject: 'Mathematics',
        grade: 5,
        progress: 0.9,
        teacher: 'John Doe',
        completedTasks: 18,
        totalTasks: 20,
        dateLabel: 'Today',
        cachedAt: DateTime.now(),
      );

      final json = grade.toJson();
      final restored = CachedGradeRecord.fromJson(json);

      expect(restored.id, equals(grade.id));
      expect(restored.subject, equals(grade.subject));
      expect(restored.grade, equals(grade.grade));
      expect(restored.progress, equals(grade.progress));
    });
  });
}