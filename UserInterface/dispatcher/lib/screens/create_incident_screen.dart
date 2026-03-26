import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';
import '../models/incident_draft.dart';
import '../widgets/common_widgets.dart';

class CreateIncidentScreen extends StatefulWidget {
  const CreateIncidentScreen({super.key});

  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _teamController = TextEditingController(text: 'Dispatch');
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _teamController.dispose();
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
                        const SectionEyebrow(label: 'New incident'),
                        const SizedBox(height: 8),
                        const Text(
                          'Dispatch a new incident',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.9,
                            color: AppPalette.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Capture the minimum information needed to launch the callout clearly and keep responders moving.',
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
                              hintText: 'Injured climber extraction',
                            ),
                            textInputAction: TextInputAction.next,
                            validator: _requiredField,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _LabeledField(
                          label: 'Team',
                          child: TextFormField(
                            controller: _teamController,
                            decoration: const InputDecoration(
                              hintText: 'Chaffee SAR',
                            ),
                            textInputAction: TextInputAction.next,
                            validator: _requiredField,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _LabeledField(
                          label: 'Location',
                          child: TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              hintText: 'Mt. Princeton Southwest Gully',
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
                              hintText:
                                  'Subject reports lower-leg injury above treeline. Include access notes, hazards, and requested resources.',
                            ),
                            validator: _requiredField,
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
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create incident'),
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
      IncidentDraft(
        title: _titleController.text.trim(),
        team: _teamController.text.trim(),
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
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
