const List<String> supportedAdminGroups = <String>[
  'В-11',
  'МР-11',
  'П-11',
  'ПК-11',
  'ЭР-11',
  'В-21',
  'МР-21',
  'П-21',
  'ПК-21',
  'ЭР-21',
  'В-31',
  'П-31',
  'ПК-31',
  'ЭР-31',
  'П-41',
  'ПК-41',
];

String normalizeAdminGroup(String value) {
  final lowered = value.toLowerCase().trim();
  return lowered.replaceAll(RegExp(r'[^a-zа-я0-9]'), '');
}

final Map<String, String> _canonicalGroupByNormalized = <String, String>{
  for (final group in supportedAdminGroups) normalizeAdminGroup(group): group,
};

final Set<String> supportedAdminNormalizedGroups =
    _canonicalGroupByNormalized.keys.toSet();

bool isSupportedAdminGroup(String value) {
  return supportedAdminNormalizedGroups.contains(normalizeAdminGroup(value));
}

String? canonicalAdminGroup(String value) {
  return _canonicalGroupByNormalized[normalizeAdminGroup(value)];
}
