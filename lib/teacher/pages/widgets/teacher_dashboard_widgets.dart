part of teacher_dashboard_page;

class _TeacherHero extends StatelessWidget {
  const _TeacherHero({required this.profile});

  final TeacherProfile profile;

  @override
  Widget build(BuildContext context) {
    final subtitle = profile.isCurator
        ? 'Куратор ${profile.curatorStudentsCount} студентов'
        : 'Кураторство пока не назначено';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradientFor(
          AppShellRole.teacher,
          Theme.of(context).brightness,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Faculty workspace',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  profile.email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.cast_for_education_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.todayLessons,
    required this.groupsCount,
    required this.messagesCount,
  });

  final int todayLessons;
  final int groupsCount;
  final int messagesCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _KpiCard(
            icon: Icons.today_rounded,
            label: 'Пар сегодня',
            value: '$todayLessons',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            icon: Icons.groups_rounded,
            label: 'Групп',
            value: '$groupsCount',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            icon: Icons.mark_chat_unread_rounded,
            label: 'Сообщений',
            value: '$messagesCount',
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.info),
            ),
            const SizedBox(height: 16),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.lessons,
    required this.weekdayLabel,
  });

  final List<TeacherLesson> lessons;
  final String Function(int weekday) weekdayLabel;

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<TeacherLesson>>{};
    for (final lesson in lessons) {
      grouped.putIfAbsent(lesson.weekday, () => <TeacherLesson>[]).add(lesson);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Мое расписание',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 12),
            if (lessons.isEmpty)
              Text(
                'В расписании пока нет пар для этого преподавателя.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (final entry in grouped.entries) ...<Widget>[
                _DayHeading(title: weekdayLabel(entry.key)),
                const SizedBox(height: 10),
                for (final lesson in entry.value) ...<Widget>[
                  _ScheduleItem(lesson: lesson),
                  if (lesson != entry.value.last) const SizedBox(height: 10),
                ],
                if (entry.key != grouped.keys.last) const SizedBox(height: 18),
              ],
          ],
        ),
      ),
    );
  }
}

class _DayHeading extends StatelessWidget {
  const _DayHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.teacherPrimary,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  const _ScheduleItem({required this.lesson});

  final TeacherLesson lesson;

  @override
  Widget build(BuildContext context) {
    final groups =
        lesson.groups.isEmpty ? 'Группы не указаны' : lesson.groups.join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  lesson.time,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lesson.subject,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                lesson.type,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Аудитория ${lesson.room}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Группы: $groups',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CuratorMessagesCard extends StatelessWidget {
  const _CuratorMessagesCard({
    required this.profile,
    required this.messages,
  });

  final TeacherProfile profile;
  final List<CuratorMessage> messages;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Сообщения куратора',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 12),
            if (!profile.isCurator)
              Text(
                'Этот преподаватель не назначен куратором.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else if (messages.isEmpty)
              Text(
                'Новых сообщений от студентов пока нет.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (final item in messages) ...<Widget>[
                _CuratorMessageItem(item: item),
                if (item != messages.last) const Divider(height: 24),
              ],
          ],
        ),
      ),
    );
  }
}

class _CuratorMessageItem extends StatelessWidget {
  const _CuratorMessageItem({required this.item});

  final CuratorMessage item;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<TeacherAppState>();
    final isBusy = appState.isUpdatingMessage(item.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.mail_outline_rounded,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${item.studentName} (${item.group})',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      _MessageStatusChip(status: item.statusLabel),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.dateLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (item.hasReply) ...<Widget>[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Ваш ответ',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  item.teacherReply,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (item.repliedAt.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    item.repliedAt,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton(
              onPressed: isBusy || !item.isNew
                  ? null
                  : () => _startWork(context, item.id),
              child: isBusy && !item.hasReply
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('В работу'),
            ),
            FilledButton(
              onPressed: isBusy ? null : () => _reply(context, item),
              child: isBusy && appState.activeCuratorMessageId == item.id
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(item.hasReply ? 'Обновить ответ' : 'Ответить'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _startWork(BuildContext context, String messageId) async {
    await context.read<TeacherAppState>().startCuratorMessageWork(messageId);
  }

  Future<void> _reply(BuildContext context, CuratorMessage item) async {
    final reply = await _askReply(context, initialValue: item.teacherReply);
    if (!context.mounted || reply == null) {
      return;
    }

    await context.read<TeacherAppState>().replyToCuratorMessage(
          messageId: item.id,
          reply: reply,
        );
  }
}

class _MessageStatusChip extends StatelessWidget {
  const _MessageStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final color = switch (normalized) {
      'отвечено' => AppColors.success,
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

class _InlineError extends StatelessWidget {
  const _InlineError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

Future<String?> _askReply(
  BuildContext context, {
  String initialValue = '',
}) async {
  final controller = TextEditingController(text: initialValue);
  String? validationError;

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Ответ студенту'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Ответ появится в личном кабинете студента в виде обновления от куратора.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Напишите ответ',
                    errorText: validationError,
                  ),
                  onChanged: (_) {
                    if (validationError == null) {
                      return;
                    }
                    setState(() {
                      validationError = null;
                    });
                  },
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isEmpty) {
                    setState(() {
                      validationError = 'Введите ответ студенту';
                    });
                    return;
                  }
                  Navigator.of(dialogContext).pop(value);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
  return result;
}
