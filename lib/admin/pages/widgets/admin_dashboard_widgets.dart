part of admin_dashboard_page;

class _RequestStatusChip extends StatelessWidget {
  const _RequestStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final color = switch (normalized) {
      'готово' => AppColors.success,
      'в работе' => AppColors.info,
      _ => AppColors.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _StudentsPanel extends StatelessWidget {
  const _StudentsPanel({
    required this.appState,
    required this.visibleStudents,
    required this.searchController,
    required this.groupOptions,
    required this.groupFilter,
    required this.onGroupChanged,
    required this.onSelect,
  });

  final AdminAppState appState;
  final List<AdminStudentSummary> visibleStudents;
  final TextEditingController searchController;
  final List<String> groupOptions;
  final String groupFilter;
  final ValueChanged<String> onGroupChanged;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Control Center',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Всего: ${appState.students.length} • Показано: ${visibleStudents.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Поиск по ФИО, e-mail или ID',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Все'),
                        selected: groupFilter == 'all',
                        onSelected: (_) => onGroupChanged('all'),
                      ),
                      for (final group in groupOptions) ...[
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(group),
                          selected: groupFilter == group,
                          onSelected: (_) => onGroupChanged(group),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFF3F5FA),
          child: const Text(
            'Студенты',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF10233B),
            ),
          ),
        ),
        if (appState.isLoadingStudents)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: visibleStudents.isEmpty
              ? const Center(
                  child: Text(
                    'Список студентов пуст.',
                    style: TextStyle(color: Color(0xFF5F6A79)),
                  ),
                )
              : ListView.builder(
                  itemCount: visibleStudents.length,
                  itemBuilder: (context, index) {
                    final item = visibleStudents[index];
                    final selected = item.id == appState.selectedStudentId;
                    return Material(
                      color: selected
                          ? const Color(0xFFE3EEFF)
                          : Colors.transparent,
                      child: ListTile(
                        title: Text(
                          item.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${item.group} • ${item.email}'),
                        selected: selected,
                        onTap: () => onSelect(item.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _LessonEditor extends StatefulWidget {
  const _LessonEditor({
    required this.index,
    required this.lesson,
    required this.onRemove,
  });

  final int index;
  final _EditableLesson lesson;
  final VoidCallback? onRemove;

  @override
  State<_LessonEditor> createState() => _LessonEditorState();
}

class _LessonEditorState extends State<_LessonEditor> {
  @override
  Widget build(BuildContext context) {
    final item = widget.lesson;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD9E0EF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Пара #${widget.index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10233B),
                ),
              ),
              const Spacer(),
              if (widget.onRemove != null)
                IconButton(
                  onPressed: widget.onRemove,
                  tooltip: 'Удалить',
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int>(
                  initialValue: item.weekday,
                  decoration: const InputDecoration(
                    labelText: 'День недели',
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Понедельник')),
                    DropdownMenuItem(value: 2, child: Text('Вторник')),
                    DropdownMenuItem(value: 3, child: Text('Среда')),
                    DropdownMenuItem(value: 4, child: Text('Четверг')),
                    DropdownMenuItem(value: 5, child: Text('Пятница')),
                    DropdownMenuItem(value: 6, child: Text('Суббота')),
                    DropdownMenuItem(value: 7, child: Text('Воскресенье')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      item.weekday = value;
                    });
                  },
                ),
              ),
              _lessonField(
                controller: item.timeController,
                label: 'Время (HH:MM или HH:MM-HH:MM)',
                width: 140,
              ),
              _lessonField(
                controller: item.subjectController,
                label: 'Предмет',
                width: 220,
              ),
              _lessonField(
                controller: item.roomController,
                label: 'Аудитория',
                width: 140,
              ),
              _lessonField(
                controller: item.teacherController,
                label: 'Преподаватель',
                width: 220,
              ),
              _lessonField(
                controller: item.typeController,
                label: 'Тип',
                width: 180,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lessonField({
    required TextEditingController controller,
    required String label,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _EditableLesson {
  _EditableLesson({
    required this.weekday,
    required this.timeController,
    required this.subjectController,
    required this.roomController,
    required this.teacherController,
    required this.typeController,
    this.isMarker = false,
  });

  factory _EditableLesson.fromLesson(AdminLesson lesson) {
    return _EditableLesson(
      weekday: lesson.weekday,
      timeController: TextEditingController(text: lesson.time),
      subjectController: TextEditingController(text: lesson.subject),
      roomController: TextEditingController(text: lesson.room),
      teacherController: TextEditingController(text: lesson.teacher),
      typeController: TextEditingController(text: lesson.type),
    );
  }

  factory _EditableLesson.empty() {
    return _EditableLesson(
      weekday: DateTime.monday,
      timeController: TextEditingController(),
      subjectController: TextEditingController(),
      roomController: TextEditingController(),
      teacherController: TextEditingController(),
      typeController: TextEditingController(),
    );
  }

  factory _EditableLesson.invalidMarker() {
    return _EditableLesson(
      weekday: DateTime.monday,
      timeController: TextEditingController(),
      subjectController: TextEditingController(),
      roomController: TextEditingController(),
      teacherController: TextEditingController(),
      typeController: TextEditingController(),
      isMarker: true,
    );
  }

  int weekday;
  final TextEditingController timeController;
  final TextEditingController subjectController;
  final TextEditingController roomController;
  final TextEditingController teacherController;
  final TextEditingController typeController;
  final bool isMarker;

  bool get isValid {
    return weekday >= 1 &&
        weekday <= 7 &&
        timeController.text.trim().isNotEmpty &&
        subjectController.text.trim().isNotEmpty &&
        roomController.text.trim().isNotEmpty &&
        teacherController.text.trim().isNotEmpty &&
        typeController.text.trim().isNotEmpty;
  }

  AdminLesson toLesson() {
    return AdminLesson(
      weekday: weekday,
      time: timeController.text.trim(),
      subject: subjectController.text.trim(),
      room: roomController.text.trim(),
      teacher: teacherController.text.trim(),
      type: typeController.text.trim(),
    );
  }

  void dispose() {
    timeController.dispose();
    subjectController.dispose();
    roomController.dispose();
    teacherController.dispose();
    typeController.dispose();
  }
}

class _EmptyEditor extends StatelessWidget {
  const _EmptyEditor();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Выберите студента слева, чтобы отредактировать профиль и расписание.',
        style: TextStyle(
          color: Color(0xFF5F6A79),
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE9E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8E2B1F),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
