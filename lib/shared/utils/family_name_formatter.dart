const String _familyPrefix = 'عائلة';

/// Strip the "عائلة" prefix and collapse whitespace, producing the bare
/// family name suitable for DB storage.
///
/// Storage form is "الأحمد" (no prefix). Display surfaces add the prefix
/// via [formatFamilyGroupDisplayName] so the user can't end up with
/// "عائلة عائلة …" by typing the prefix themselves.
String normalizeFamilyGroupName(String input) {
  var name = input.trim();
  while (name.startsWith(_familyPrefix)) {
    name = name.substring(_familyPrefix.length).trimLeft();
  }
  return name.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Idempotent display form: prepends "عائلة" to the bare name.
///
/// Accepts already-prefixed input ("عائلة الأحمد") and bare input
/// ("الأحمد") and returns the same display string in both cases.
String formatFamilyGroupDisplayName(String input) {
  final bare = normalizeFamilyGroupName(input);
  if (bare.isEmpty) return '';
  return '$_familyPrefix $bare';
}
