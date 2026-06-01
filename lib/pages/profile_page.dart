library profile_page;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/student_models.dart';
import '../shared/theme/app_colors.dart';
import '../state/student_app_state.dart';

part 'widgets/profile_page_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<StudentAppState>();
    final profile = appState.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: <Widget>[
        _ProfileHero(profile: profile),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Контакты и учебный контекст',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 16),
                _InfoTile(
                  icon: Icons.badge_outlined,
                  label: 'ID студента',
                  value: profile.studentId,
                ),
                _InfoTile(
                  icon: Icons.alternate_email_rounded,
                  label: 'E-mail',
                  value: profile.email,
                ),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Телефон',
                  value: profile.phone,
                ),
                _InfoTile(
                  icon: Icons.support_agent_rounded,
                  label: 'Куратор',
                  value: profile.curator,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppLocalizations.of(context)!.appearance,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: <ButtonSegment<ThemeMode>>[
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode_rounded),
                        label: Text(AppLocalizations.of(context)!.themeLight),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.settings_suggest_rounded),
                        label: Text(AppLocalizations.of(context)!.themeAuto),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_rounded),
                        label: Text(AppLocalizations.of(context)!.themeDark),
                      ),
                    ],
                    selected: <ThemeMode>{appState.themeMode},
                    onSelectionChanged: (Set<ThemeMode> selection) {
                      appState.setThemeMode(selection.first);
                    },
                    showSelectedIcon: false,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Сервисы',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  icon: Icons.file_present_rounded,
                  label: 'Запросить справку',
                  isLoading: appState.isSubmittingCertificateRequest,
                  onPressed: appState.isSubmittingCertificateRequest
                      ? null
                      : () => _requestCertificate(
                            context,
                            context.read<StudentAppState>(),
                          ),
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  icon: Icons.payments_outlined,
                  label: 'Посмотреть квитанции',
                  onPressed: () => _showPaymentsSheet(
                    context,
                    appState.documents,
                  ),
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Связаться с куратором',
                  isLoading: appState.isSendingCuratorMessage,
                  onPressed: appState.isSendingCuratorMessage
                      ? null
                      : () => _contactCurator(
                            context,
                            context.read<StudentAppState>(),
                          ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Документы',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                            ),
                      ),
                    ),
                    if (appState.documents.isNotEmpty)
                      Text(
                        '${appState.documents.length}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.studentPrimary,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (appState.documents.isEmpty)
                  const _SectionEmptyText(
                    text:
                        'Документы пока не добавлены. Запросы на справки появятся здесь со статусом обработки.',
                  )
                else
                  for (final document in appState.documents) ...<Widget>[
                    _DocumentTile(document: document),
                    if (document != appState.documents.last)
                      const Divider(height: 20),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _requestCertificate(
    BuildContext context,
    StudentAppState appState,
  ) async {
    final draft = await _askCertificateRequest(context);
    if (!context.mounted || draft == null) {
      return;
    }

    final success = await appState.requestCertificate(
      type: draft.type,
      comment: draft.comment,
    );
    if (!context.mounted) {
      return;
    }

    if (success) {
      _showMessage(
        context,
        'Запрос на справку отправлен. Следите за статусом в разделе документов.',
      );
      return;
    }

    _showMessage(
      context,
      appState.loadError ??
          appState.authError ??
          'Не удалось отправить запрос.',
    );
  }

  Future<void> _contactCurator(
    BuildContext context,
    StudentAppState appState,
  ) async {
    final message = await _askCuratorMessage(context);
    if (!context.mounted || message == null) {
      return;
    }

    final success = await appState.contactCurator(message: message);
    if (!context.mounted) {
      return;
    }

    if (success) {
      _showMessage(
        context,
        'Сообщение отправлено куратору. Ответ появится на главной в объявлениях.',
      );
      return;
    }

    _showMessage(
      context,
      appState.loadError ??
          appState.authError ??
          'Не удалось отправить сообщение.',
    );
  }

  Future<_CertificateRequestDraft?> _askCertificateRequest(
    BuildContext context,
  ) async {
    const options = <String>[
      'Справка об обучении',
      'Справка для стипендии',
      'Справка по месту требования',
    ];

    final commentController = TextEditingController();
    var selectedType = options.first;

    final result = await showDialog<_CertificateRequestDraft>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Новая справка'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Тип справки',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    items: options
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        selectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Комментарий',
                      hintText: 'Например: нужна для стипендии или военкомата',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
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
                    Navigator.of(dialogContext).pop(
                      _CertificateRequestDraft(
                        type: selectedType,
                        comment: commentController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Отправить'),
                ),
              ],
            );
          },
        );
      },
    );

    commentController.dispose();
    return result;
  }

  Future<String?> _askCuratorMessage(BuildContext context) async {
    String draft = '';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Сообщение куратору'),
          content: TextField(
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            onChanged: (value) {
              draft = value;
            },
            decoration: const InputDecoration(
              hintText: 'Напишите сообщение',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final value = draft.trim();
                if (value.isEmpty) {
                  return;
                }
                FocusScope.of(dialogContext).unfocus();
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Отправить'),
            ),
          ],
        );
      },
    );

    return result;
  }

  void _showPaymentsSheet(
    BuildContext context,
    List<StudentDocument> documents,
  ) {
    final paymentDocuments = documents.where((document) {
      final text = document.title.toLowerCase();
      return text.contains('квитан') ||
          text.contains('оплат') ||
          text.contains('договор');
    }).toList(growable: false);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Квитанции и платежные документы',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  paymentDocuments.isEmpty
                      ? 'Пока нет отдельных платежных документов. Когда учебная часть добавит их, они появятся здесь.'
                      : 'Доступные документы, связанные с оплатой или договором.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (paymentDocuments.isEmpty)
                  const _SectionEmptyText(
                    text:
                        'Раздел пуст. Можно проверить общий список документов ниже в профиле.',
                  )
                else
                  SizedBox(
                    height: 260,
                    child: ListView.separated(
                      itemCount: paymentDocuments.length,
                      separatorBuilder: (_, __) => const Divider(height: 20),
                      itemBuilder: (context, index) {
                        final document = paymentDocuments[index];
                        return _PaymentDocumentRow(document: document);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}

class _CertificateRequestDraft {
  const _CertificateRequestDraft({
    required this.type,
    required this.comment,
  });

  final String type;
  final String comment;
}
