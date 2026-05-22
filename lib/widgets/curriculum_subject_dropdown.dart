import 'package:flutter/material.dart';

import '../services/bped_curriculum_service.dart';

class CurriculumSubjectDropdown extends StatelessWidget {
  const CurriculumSubjectDropdown({
    super.key,
    required this.yearLevel,
    required this.semesterLabel,
    required this.selectedValue,
    required this.onChanged,
    this.labelText = 'Subject',
    this.enabled = true,
    this.preferredValue,
  });

  final int? yearLevel;
  final String semesterLabel;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final String labelText;
  final bool enabled;
  final String? preferredValue;

  @override
  Widget build(BuildContext context) {
    final options = BpedCurriculumService.subjectOptions(
      yearLevel: yearLevel,
      semesterLabel: semesterLabel,
    ).toList(growable: true);
    final resolvedValue = BpedCurriculumService.resolveSubjectSelection(
      currentValue: selectedValue,
      preferredValue: preferredValue,
      yearLevel: yearLevel,
      semesterLabel: semesterLabel,
    );

    if (resolvedValue != null &&
        resolvedValue.isNotEmpty &&
        !options.contains(resolvedValue)) {
      options.insert(0, resolvedValue);
    }

    return DropdownButtonFormField<String>(
      key: ValueKey(
        '$labelText-$yearLevel-$semesterLabel-${resolvedValue ?? ''}-${options.length}-$enabled',
      ),
      isExpanded: true,
      initialValue: resolvedValue,
      decoration: InputDecoration(
        labelText: labelText,
        helperText: yearLevel == null
            ? 'Select a year level to filter the static BPED curriculum.'
            : '${BpedCurriculumService.formatYearLevel(yearLevel!)} · $semesterLabel',
      ),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(option, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      selectedItemBuilder: (context) => options
          .map(
            (option) => Align(
              alignment: Alignment.centerLeft,
              child: Text(option, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}
