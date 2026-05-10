import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/common_widgets.dart';

class EditIncidentScreen extends StatefulWidget {
  const EditIncidentScreen({
    super.key,
    required this.incident,
    this.onSubmit,
    this.onCancel,
  });

  final Incident incident;
  final ValueChanged<IncidentUpdate>? onSubmit;
  final VoidCallback? onCancel;

  @override
  State<EditIncidentScreen> createState() => _EditIncidentScreenState();
}

class _EditIncidentScreenState extends State<EditIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.incident.title);
    _locationController = TextEditingController(text: widget.incident.location);
    _notesController = TextEditingController(text: widget.incident.notes);
    _active = widget.incident.active;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: MissionOutBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SectionShell(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        SectionEyebrow(label: l10n.updateIncidentEyebrow),
                        const SizedBox(height: 8),
                        Text(
                          l10n.editIncidentTitle,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.9,
                            color: AppPalette.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.editIncidentSubtitle,
                          style: const TextStyle(
                            color: AppPalette.textSoft,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 26),
                        _LabeledField(
                          label: l10n.incidentTitleLabel,
                          child: TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: l10n.incidentTitleLabel,
                            ),
                            validator: (value) => _requiredField(value, l10n),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _LabeledField(
                          label: l10n.incidentLocationLabel,
                          child: TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              hintText: l10n.incidentLocationLabel,
                            ),
                            validator: (value) => _requiredField(value, l10n),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _LabeledField(
                          label: l10n.incidentNotesLabel,
                          child: TextFormField(
                            controller: _notesController,
                            minLines: 5,
                            maxLines: 7,
                            decoration: InputDecoration(
                              hintText: l10n.incidentNotesEditHint,
                            ),
                            validator: (value) => _requiredField(value, l10n),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          decoration: BoxDecoration(
                            color: AppPalette.panelSoft,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppPalette.border),
                          ),
                          child: SwitchListTile.adaptive(
                            value: _active,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              l10n.incidentActiveTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppPalette.text,
                              ),
                            ),
                            subtitle: Text(
                              l10n.incidentActiveSubtitle,
                              style: const TextStyle(
                                color: AppPalette.textSoft,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() => _active = value);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                if (widget.onCancel != null) {
                                  widget.onCancel!();
                                  return;
                                }
                                Navigator.of(context).pop();
                              },
                              child: Text(l10n.cancelButton),
                            ),
                            FilledButton.icon(
                              onPressed: _submit,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(l10n.saveChangesButton),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredField(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.fieldRequired;
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final update = IncidentUpdate(
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      active: _active,
    );

    if (widget.onSubmit != null) {
      widget.onSubmit!(update);
      return;
    }

    Navigator.of(context).pop(update);
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppPalette.text,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
