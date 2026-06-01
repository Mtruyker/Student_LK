library admin_dashboard_page;

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:provider/provider.dart';

import '../../shared/theme/app_colors.dart';
import '../constants/admin_groups.dart';
import '../models/admin_models.dart';
import '../services/schedule_excel_importer.dart';
import '../state/admin_app_state.dart';

part 'widgets/admin_dashboard_widgets.dart';

enum _EditorTab {
  profile,
  schedule,
  documents,
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _curatorController = TextEditingController();
  final TextEditingController _attendanceController = TextEditingController();
  final TextEditingController _completedController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();

  final List<_EditableLesson> _lessons = <_EditableLesson>[];
  AdminStudentDetails? _boundDetails;
  AdminStudentDetails? _pendingDetailsBinding;
  String _searchQuery = '';
  String _groupFilter = 'all';
  _EditorTab _selectedEditorTab = _EditorTab.profile;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fullNameController.dispose();
    _groupController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _curatorController.dispose();
    _attendanceController.dispose();
    _completedController.dispose();
    _totalController.dispose();
    for (final item in _lessons) {
      item.dispose();
    }
    super.dispose();
  }

  void _bindDetails(AdminStudentDetails details) {
    if (identical(_boundDetails, details)) {
      return;
    }

    _boundDetails = details;
    _fullNameController.text = details.profile.fullName;
    _groupController.text = details.profile.group;
    _emailController.text = details.profile.email;
    _phoneController.text = details.profile.phone;
    _curatorController.text = details.profile.curator;
    _attendanceController.text =
        (details.profile.attendance * 100).toStringAsFixed(1);
    _completedController.text = details.profile.completedAssignments.toString();
    _totalController.text = details.profile.totalAssignments.toString();

    for (final item in _lessons) {
      item.dispose();
    }
    _lessons
      ..clear()
      ..addAll(details.schedule.map(_EditableLesson.fromLesson));
    if (_lessons.isEmpty) {
      _lessons.add(_EditableLesson.empty());
    }
  }

  void _scheduleDetailsBinding(AdminStudentDetails details) {
    if (identical(_boundDetails, details) ||
        identical(_pendingDetailsBinding, details)) {
      return;
    }

    _pendingDetailsBinding = details;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_pendingDetailsBinding, details)) {
        return;
      }

      setState(() {
        _bindDetails(details);
        _pendingDetailsBinding = null;
      });
    });
  }

  Future<void> _saveProfile(AdminAppState appState) async {
    final current = appState.selectedStudent;
    if (current == null) {
      return;
    }

    final selectedGroup = canonicalAdminGroup(_groupController.text.trim());
    if (selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Р’С‹Р±РµСЂРёС‚Рµ РіСЂСѓРїРїСѓ РёР· СЃРїРёСЃРєР°: ${supportedAdminGroups.join(', ')}.',
          ),
        ),
      );
      return;
    }

    final attendanceInput =
        _attendanceController.text.trim().replaceAll(',', '.');
    final attendancePercent = double.tryParse(attendanceInput) ?? 0;
    final attendance = attendancePercent.clamp(0, 100).toDouble() / 100;
    final completed = int.tryParse(_completedController.text.trim()) ?? 0;
    final total = int.tryParse(_totalController.text.trim()) ?? 0;

    final profile = current.profile.copyWith(
      fullName: _fullNameController.text.trim(),
      group: selectedGroup,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      curator: _curatorController.text.trim(),
      attendance: attendance,
      completedAssignments: completed,
      totalAssignments: total < completed ? completed : total,
    );

    await appState.saveProfile(profile);
    if (!mounted) {
      return;
    }

    final error = appState.saveError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'РџСЂРѕС„РёР»СЊ СЃРѕС…СЂР°РЅРµРЅ.'),
      ),
    );
  }

  Future<void> _saveSchedule(AdminAppState appState) async {
    final invalidLesson = _lessons.firstWhere(
      (item) => !item.isValid,
      orElse: () => _EditableLesson.invalidMarker(),
    );
    if (invalidLesson.isMarker) {
      // no-op
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Р—Р°РїРѕР»РЅРёС‚Рµ РІСЃРµ РїРѕР»СЏ СѓСЂРѕРєР°: РґРµРЅСЊ, РІСЂРµРјСЏ, РїСЂРµРґРјРµС‚, Р°СѓРґРёС‚РѕСЂРёСЏ, РїСЂРµРїРѕРґР°РІР°С‚РµР»СЊ, С‚РёРї.',
          ),
        ),
      );
      return;
    }

    final schedule = _lessons.map((item) => item.toLesson()).toList();
    await appState.saveSchedule(schedule);
    if (!mounted) {
      return;
    }

    final error = appState.saveError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Р Р°СЃРїРёСЃР°РЅРёРµ СЃРѕС…СЂР°РЅРµРЅРѕ.'),
      ),
    );
  }

  Future<void> _importScheduleFromExcel(AdminAppState appState) async {
    const excelType = XTypeGroup(
      label: 'Excel',
      extensions: <String>['xlsx'],
    );
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[excelType],
      confirmButtonText: 'РРјРїРѕСЂС‚',
    );
    if (file == null) {
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      final groupHint = appState.selectedStudent?.profile.group;
      final importedLessons = ScheduleExcelImporter.parse(
        bytes,
        groupHint: groupHint,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        for (final item in _lessons) {
          item.dispose();
        }
        _lessons
          ..clear()
          ..addAll(importedLessons.map(_EditableLesson.fromLesson));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'РРјРїРѕСЂС‚РёСЂРѕРІР°РЅРѕ РїР°СЂ: ${importedLessons.length}. РќР°Р¶РјРёС‚Рµ "РЎРѕС…СЂР°РЅРёС‚СЊ СЂР°СЃРїРёСЃР°РЅРёРµ".',
          ),
        ),
      );
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('РћС€РёР±РєР° РёРјРїРѕСЂС‚Р°: ${error.message}'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('РќРµ СѓРґР°Р»РѕСЃСЊ РїСЂРѕС‡РёС‚Р°С‚СЊ Excel-С„Р°Р№Р».'),
        ),
      );
    }
  }

  Future<void> _importScheduleForAllStudents(AdminAppState appState) async {
    const excelType = XTypeGroup(
      label: 'Excel',
      extensions: <String>['xlsx'],
    );
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[excelType],
      confirmButtonText: 'РРјРїРѕСЂС‚ РґР»СЏ РІСЃРµС…',
    );
    if (file == null) {
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      final schedulesByGroup =
          ScheduleExcelImporter.parseGroupGridForAllGroups(bytes);
      final result =
          await appState.applySchedulesToAllStudents(schedulesByGroup);
      if (!mounted) {
        return;
      }

      final bulkError = appState.bulkImportError;
      if (bulkError != null && bulkError.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'РћС€РёР±РєР° РјР°СЃСЃРѕРІРѕРіРѕ РёРјРїРѕСЂС‚Р°: $bulkError'),
          ),
        );
        return;
      }

      final failedPreview = result.failedStudents.take(3).join('; ');
      final failedSuffix = result.failedCount > 0
          ? ' РћС€РёР±РєРё: ${result.failedCount}. ${failedPreview.isEmpty ? '' : failedPreview}'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'РРјРїРѕСЂС‚ РґР»СЏ РІСЃРµС… Р·Р°РІРµСЂС€РµРЅ. '
            'РЎС‚СѓРґРµРЅС‚РѕРІ: ${result.totalStudents}, '
            'СЃ СЃРѕРІРїР°РґР°СЋС‰РµР№ РіСЂСѓРїРїРѕР№: ${result.matchedStudents}, '
            'РѕР±РЅРѕРІР»РµРЅРѕ: ${result.updatedStudents}, '
            'РїСЂРѕРїСѓС‰РµРЅРѕ: ${result.skippedStudents}.'
            '$failedSuffix',
          ),
          duration: const Duration(seconds: 7),
        ),
      );
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('РћС€РёР±РєР° РёРјРїРѕСЂС‚Р°: ${error.message}'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'РќРµ СѓРґР°Р»РѕСЃСЊ РІС‹РїРѕР»РЅРёС‚СЊ РјР°СЃСЃРѕРІС‹Р№ РёРјРїРѕСЂС‚ СЂР°СЃРїРёСЃР°РЅРёСЏ.'),
        ),
      );
    }
  }

  Future<void> _editDocument(
    AdminAppState appState, {
    AdminStudentDocument? document,
  }) async {
    final titleController = TextEditingController(text: document?.title ?? '');
    const statuses = <String>[
      'Р—Р°РїСЂРѕС€РµРЅ',
      'Р’ СЂР°Р±РѕС‚Рµ',
      'Р“РѕС‚РѕРІ',
      'РўСЂРµР±СѓРµС‚ РїРѕРґРїРёСЃСЊ',
      'Р”РѕСЃС‚СѓРїРµРЅ',
    ];
    var selectedStatus = document?.status ?? statuses.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                document == null
                    ? 'РќРѕРІС‹Р№ РґРѕРєСѓРјРµРЅС‚'
                    : 'Р РµРґР°РєС‚РёСЂРѕРІР°РЅРёРµ РґРѕРєСѓРјРµРЅС‚Р°',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'РќР°Р·РІР°РЅРёРµ РґРѕРєСѓРјРµРЅС‚Р°',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'РЎС‚Р°С‚СѓСЃ',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: statuses
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('РћС‚РјРµРЅР°'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('РЎРѕС…СЂР°РЅРёС‚СЊ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) {
      titleController.dispose();
      return;
    }

    await appState.saveDocument(
      documentId: document?.id,
      title: titleController.text.trim(),
      status: selectedStatus,
    );
    titleController.dispose();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appState.saveError ??
              (document == null
                  ? 'Р”РѕРєСѓРјРµРЅС‚ РґРѕР±Р°РІР»РµРЅ.'
                  : 'Р”РѕРєСѓРјРµРЅС‚ РѕР±РЅРѕРІР»РµРЅ.'),
        ),
      ),
    );
  }

  Future<void> _updateCertificateRequestStatus(
    AdminAppState appState,
    AdminCertificateRequest request,
    String status,
  ) async {
    await appState.updateCertificateRequestStatus(
      requestId: request.id,
      status: status,
    );
    if (!mounted) {
      return;
    }

    final successText = switch (status) {
      'ready' =>
        'Р—Р°РїСЂРѕСЃ РѕС‚РјРµС‡РµРЅ РєР°Рє РіРѕС‚РѕРІС‹Р№, РґРѕРєСѓРјРµРЅС‚ РѕР±РЅРѕРІР»РµРЅ.',
      'processing' => 'Р—Р°РїСЂРѕСЃ РїРµСЂРµРІРµРґРµРЅ РІ СЂР°Р±РѕС‚Сѓ.',
      _ => 'РЎС‚Р°С‚СѓСЃ Р·Р°РїСЂРѕСЃР° РѕР±РЅРѕРІР»РµРЅ.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(appState.saveError ?? successText),
      ),
    );
  }

  List<AdminStudentSummary> _visibleStudents(AdminAppState appState) {
    return appState.students.where((item) {
      final matchesGroup = _groupFilter == 'all' || item.group == _groupFilter;
      final haystack =
          '${item.fullName} ${item.email} ${item.group} ${item.studentId}'
              .toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty || haystack.contains(_searchQuery);
      return matchesGroup && matchesSearch;
    }).toList(growable: false);
  }

  List<String> _groupOptions(AdminAppState appState) {
    final groups = appState.students.map((item) => item.group).toSet().toList()
      ..sort();
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AdminAppState>();
    final selected = appState.selectedStudent;
    final visibleStudents = _visibleStudents(appState);
    final groupOptions = _groupOptions(appState);

    if (selected != null) {
      _scheduleDetailsBinding(selected);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('РђРґРјРёРЅ-РїР°РЅРµР»СЊ СЂР°СЃРїРёСЃР°РЅРёСЏ'),
        actions: [
          IconButton(
            onPressed: appState.isLoadingStudents
                ? null
                : () => context.read<AdminAppState>().refreshStudents(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'РћР±РЅРѕРІРёС‚СЊ СЃРїРёСЃРѕРє',
          ),
          TextButton.icon(
            onPressed: appState.isBulkImporting
                ? null
                : () => _importScheduleForAllStudents(
                      context.read<AdminAppState>(),
                    ),
            icon: appState.isBulkImporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_upload_rounded),
            label: const Text('РРјРїРѕСЂС‚ РІСЃРµРј'),
          ),
          TextButton.icon(
            onPressed: () => context.read<AdminAppState>().signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Р’С‹Р№С‚Рё'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1180;
            final editor = selected == null
                ? const _EmptyEditor()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (appState.loadError != null) ...[
                          _InlineError(text: appState.loadError!),
                          const SizedBox(height: 12),
                        ],
                        if (appState.saveError != null) ...[
                          _InlineError(text: appState.saveError!),
                          const SizedBox(height: 12),
                        ],
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selected.profile.fullName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${selected.profile.group} вЂў ${selected.profile.email}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_selectedEditorTab ==
                                        _EditorTab.profile)
                                      FilledButton.icon(
                                        onPressed: appState.isSavingProfile
                                            ? null
                                            : () => _saveProfile(
                                                  context.read<AdminAppState>(),
                                                ),
                                        icon: appState.isSavingProfile
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.save_rounded),
                                        label: const Text(
                                            'РЎРѕС…СЂР°РЅРёС‚СЊ РїСЂРѕС„РёР»СЊ'),
                                      ),
                                    if (_selectedEditorTab ==
                                        _EditorTab.schedule)
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _importScheduleFromExcel(
                                              context.read<AdminAppState>(),
                                            ),
                                            icon: const Icon(
                                              Icons.upload_file_rounded,
                                            ),
                                            label: const Text('РРјРїРѕСЂС‚'),
                                          ),
                                          FilledButton.icon(
                                            onPressed: appState.isSavingSchedule
                                                ? null
                                                : () => _saveSchedule(
                                                      context.read<
                                                          AdminAppState>(),
                                                    ),
                                            icon: appState.isSavingSchedule
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.save_as_rounded,
                                                  ),
                                            label: const Text(
                                                'РЎРѕС…СЂР°РЅРёС‚СЊ СЂР°СЃРїРёСЃР°РЅРёРµ'),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SegmentedButton<_EditorTab>(
                                  segments: const [
                                    ButtonSegment<_EditorTab>(
                                      value: _EditorTab.profile,
                                      label: Text('РџСЂРѕС„РёР»СЊ'),
                                      icon: Icon(Icons.person_rounded),
                                    ),
                                    ButtonSegment<_EditorTab>(
                                      value: _EditorTab.schedule,
                                      label: Text('Р Р°СЃРїРёСЃР°РЅРёРµ'),
                                      icon: Icon(Icons.calendar_month_rounded),
                                    ),
                                    ButtonSegment<_EditorTab>(
                                      value: _EditorTab.documents,
                                      label: Text('Р”РѕРєСѓРјРµРЅС‚С‹'),
                                      icon: Icon(Icons.description_rounded),
                                    ),
                                  ],
                                  selected: <_EditorTab>{_selectedEditorTab},
                                  onSelectionChanged: (selection) {
                                    setState(() {
                                      _selectedEditorTab = selection.first;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_selectedEditorTab == _EditorTab.profile)
                          _buildProfileCard(appState, selected),
                        if (_selectedEditorTab == _EditorTab.schedule)
                          _buildScheduleCard(appState, selected),
                        if (_selectedEditorTab == _EditorTab.documents)
                          _buildDocumentsCard(appState, selected),
                      ],
                    ),
                  );

            final studentsPanel = _StudentsPanel(
              appState: appState,
              visibleStudents: visibleStudents,
              searchController: _searchController,
              groupOptions: groupOptions,
              groupFilter: _groupFilter,
              onGroupChanged: (value) {
                setState(() {
                  _groupFilter = value;
                });
              },
              onSelect: (id) => context.read<AdminAppState>().selectStudent(id),
            );

            if (!wide) {
              return Column(
                children: [
                  SizedBox(height: 360, child: studentsPanel),
                  const SizedBox(height: 12),
                  Expanded(child: editor),
                ],
              );
            }

            return Row(
              children: [
                SizedBox(width: 360, child: studentsPanel),
                const SizedBox(width: 16),
                Expanded(child: editor),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard(
      AdminAppState appState, AdminStudentDetails selected) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'РџСЂРѕС„РёР»СЊ СЃС‚СѓРґРµРЅС‚Р°',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10233B),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${selected.id} вЂў РЎС‚СѓРґРµРЅС‡РµСЃРєРёР№ ID: ${selected.profile.studentId}',
              style: const TextStyle(color: Color(0xFF5F6A79)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _wideField(
                  controller: _fullNameController,
                  label: 'Р¤РРћ',
                  icon: Icons.person_outline_rounded,
                ),
                _groupField(),
                _wideField(
                  controller: _emailController,
                  label: 'E-mail',
                  icon: Icons.alternate_email_rounded,
                  readOnly: true,
                  helperText:
                      'РњРµРЅСЏРµС‚СЃСЏ С‚РѕР»СЊРєРѕ РІ Supabase Auth, Р·РґРµСЃСЊ РґРѕСЃС‚СѓРїРµРЅ РїСЂРѕСЃРјРѕС‚СЂ.',
                ),
                _wideField(
                  controller: _phoneController,
                  label: 'РўРµР»РµС„РѕРЅ',
                  icon: Icons.phone_outlined,
                ),
                _wideField(
                  controller: _curatorController,
                  label: 'РљСѓСЂР°С‚РѕСЂ',
                  icon: Icons.support_agent_rounded,
                ),
                _smallField(
                  controller: _attendanceController,
                  label: 'РџРѕСЃРµС‰Р°РµРјРѕСЃС‚СЊ (%)',
                  icon: Icons.percent_rounded,
                ),
                _smallField(
                  controller: _completedController,
                  label: 'Р’С‹РїРѕР»РЅРµРЅРѕ Р·Р°РґР°РЅРёР№',
                  icon: Icons.task_alt_rounded,
                ),
                _smallField(
                  controller: _totalController,
                  label: 'Р’СЃРµРіРѕ Р·Р°РґР°РЅРёР№',
                  icon: Icons.playlist_add_check_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: appState.isSavingProfile
                  ? null
                  : () => _saveProfile(context.read<AdminAppState>()),
              icon: appState.isSavingProfile
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('РЎРѕС…СЂР°РЅРёС‚СЊ РїСЂРѕС„РёР»СЊ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(
      AdminAppState appState, AdminStudentDetails selected) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Р Р°СЃРїРёСЃР°РЅРёРµ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10233B),
                        ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _lessons.add(_EditableLesson.empty());
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Р”РѕР±Р°РІРёС‚СЊ РїР°СЂСѓ'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      _importScheduleFromExcel(context.read<AdminAppState>()),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('РРјРїРѕСЂС‚ РёР· Excel'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_lessons.isEmpty)
              const Text('Р Р°СЃРїРёСЃР°РЅРёРµ РїСѓСЃС‚РѕРµ.')
            else
              Column(
                children: [
                  for (var i = 0; i < _lessons.length; i++) ...[
                    _LessonEditor(
                      index: i,
                      lesson: _lessons[i],
                      onRemove: _lessons.length == 1
                          ? null
                          : () {
                              setState(() {
                                final removed = _lessons.removeAt(i);
                                removed.dispose();
                              });
                            },
                    ),
                    if (i != _lessons.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: appState.isSavingSchedule
                  ? null
                  : () => _saveSchedule(context.read<AdminAppState>()),
              icon: appState.isSavingSchedule
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_as_rounded),
              label: const Text('РЎРѕС…СЂР°РЅРёС‚СЊ СЂР°СЃРїРёСЃР°РЅРёРµ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard(
    AdminAppState appState,
    AdminStudentDetails selected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Р”РѕРєСѓРјРµРЅС‚С‹ Рё Р·Р°РїСЂРѕСЃС‹',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10233B),
                            ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: appState.isSavingDocuments
                          ? null
                          : () => _editDocument(context.read<AdminAppState>()),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Р”РѕР±Р°РІРёС‚СЊ РґРѕРєСѓРјРµРЅС‚'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Р—Р°РїСЂРѕСЃС‹ РЅР° СЃРїСЂР°РІРєРё',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'РЎС‚Р°С‚СѓСЃС‹ Р·Р°СЏРІРѕРє РјРѕР¶РЅРѕ РѕР±РЅРѕРІР»СЏС‚СЊ РїСЂСЏРјРѕ РѕС‚СЃСЋРґР°. Р”Р»СЏ РіРѕС‚РѕРІС‹С… Р·Р°РїСЂРѕСЃРѕРІ РґРѕРєСѓРјРµРЅС‚ Сѓ СЃС‚СѓРґРµРЅС‚Р° С‚РѕР¶Рµ РѕР±РЅРѕРІРёС‚СЃСЏ.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (selected.certificateRequests.isEmpty)
                  Text(
                    'РЈ СЌС‚РѕРіРѕ СЃС‚СѓРґРµРЅС‚Р° РїРѕРєР° РЅРµС‚ Р·Р°РїСЂРѕСЃРѕРІ РЅР° СЃРїСЂР°РІРєРё.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  for (final request in selected.certificateRequests) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.type,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      request.createdAt,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              _RequestStatusChip(status: request.statusLabel),
                            ],
                          ),
                          if (request.comment.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              request.comment,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: appState.isSavingDocuments ||
                                        request.isProcessing
                                    ? null
                                    : () => _updateCertificateRequestStatus(
                                          context.read<AdminAppState>(),
                                          request,
                                          'processing',
                                        ),
                                child: const Text('Р’ СЂР°Р±РѕС‚Сѓ'),
                              ),
                              FilledButton(
                                onPressed: appState.isSavingDocuments ||
                                        request.isReady
                                    ? null
                                    : () => _updateCertificateRequestStatus(
                                          context.read<AdminAppState>(),
                                          request,
                                          'ready',
                                        ),
                                child: const Text('Р“РѕС‚РѕРІРѕ'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (request != selected.certificateRequests.last)
                      const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegacyDocumentsCard(selected),
      ],
    );
  }

  Widget _buildLegacyDocumentsCard(AdminStudentDetails selected) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Р”РѕРєСѓРјРµРЅС‚С‹',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10233B),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'РўРµРєСѓС‰РёРµ РґРѕРєСѓРјРµРЅС‚С‹ Рё РёС… СЃС‚Р°С‚СѓСЃ.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (selected.documents.isEmpty)
              Text(
                'РЈ СЃС‚СѓРґРµРЅС‚Р° РїРѕРєР° РЅРµС‚ РґРѕРєСѓРјРµРЅС‚РѕРІ.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (final document in selected.documents) ...[
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppColors.adminPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${document.status} вЂў ${document.updatedAt}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editDocument(
                        context.read<AdminAppState>(),
                        document: document,
                      ),
                      tooltip: 'Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
                if (document != selected.documents.last)
                  const Divider(height: 20),
              ],
          ],
        ),
      ),
    );
  }

  Widget _wideField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    String? helperText,
  }) {
    return SizedBox(
      width: 320,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          helperText: helperText,
        ),
      ),
    );
  }

  Widget _groupField() {
    final currentGroup = _groupController.text.trim();
    final selectedGroup = canonicalAdminGroup(currentGroup);
    final hasUnsupportedGroup =
        currentGroup.isNotEmpty && !isSupportedAdminGroup(currentGroup);

    return SizedBox(
      width: 320,
      child: DropdownButtonFormField<String>(
        key: ValueKey<String?>(_boundDetails?.id),
        initialValue: selectedGroup,
        hint: Text(hasUnsupportedGroup
            ? currentGroup
            : 'Р’С‹Р±РµСЂРёС‚Рµ РіСЂСѓРїРїСѓ'),
        decoration: InputDecoration(
          labelText: 'Р“СЂСѓРїРїР°',
          prefixIcon: const Icon(Icons.groups_rounded),
          helperText: hasUnsupportedGroup
              ? 'РўРµРєСѓС‰Р°СЏ РіСЂСѓРїРїР° РЅРµ РїРѕРґРґРµСЂР¶РёРІР°РµС‚СЃСЏ. Р’С‹Р±РµСЂРёС‚Рµ РіСЂСѓРїРїСѓ РёР· С€Р°Р±Р»РѕРЅР°.'
              : 'Р”РѕСЃС‚СѓРїРЅС‹ С‚РѕР»СЊРєРѕ РіСЂСѓРїРїС‹ РёР· С€Р°Р±Р»РѕРЅР° Excel.',
        ),
        items: supportedAdminGroups
            .map(
              (group) => DropdownMenuItem<String>(
                value: group,
                child: Text(group),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() {
            _groupController.text = value;
          });
        },
      ),
    );
  }

  Widget _smallField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}
