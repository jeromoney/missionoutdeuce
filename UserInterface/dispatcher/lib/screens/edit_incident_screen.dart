import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';
import '../models/incident_update.dart';
import '../models/records.dart';
import '../widgets/common_widgets.dart';

class EditIncidentScreen extends StatefulWidget {
  const EditIncidentScreen({super.key, required this.incident});

  final Incident incident;

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
                        const SectionEyebrow(label: 'Update incident'),
                        const SizedBox(height: 8),
                        const Text(
                          'Edit live mission details',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.9,
                            color: AppPalette.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Keep dispatch information current as access, hazards, and mission status change.',
                          style: TextStyle(
                            color: AppPalette.textSoft,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 26),
                        _LabeledField(
                          label: 'Incident title',
                          child: TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: 'Incident title',
                            ),
                            validator: _requiredField,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _LabeledField(
                          label: 'Location',
                          child: TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              hintText: 'Location',
                            ),
                            validator: _requiredField,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _LabeledField(
                          label: 'Dispatch notes',
                          child: TextFormField(
                            controller: _notesController,
                            minLines: 5,
                            maxLines: 7,
                            decoration: const InputDecoration(
                              hintText: 'Updated incident notes',
                            ),
                            validator: _requiredField,
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
                            title: const Text(
                              'Incident active',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppPalette.text,
                              ),
                            ),
                            subtitle: const Text(
                              'Turn this off when the incident is resolved or no longer needs live response tracking.',
                              style: TextStyle(color: AppPalette.textSoft),
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
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            FilledButton.icon(
                              onPressed: _submit,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Save changes'),
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

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      IncidentUpdate(
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
        active: _active,
      ),
    );
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
