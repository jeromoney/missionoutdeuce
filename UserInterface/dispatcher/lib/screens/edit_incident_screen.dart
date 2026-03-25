import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../models/incident_update.dart';
import '../models/records.dart';

class EditIncidentScreen extends StatefulWidget {
  const EditIncidentScreen({
    super.key,
    required this.incident,
  });

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
      backgroundColor: AppPalette.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppPalette.text,
        title: const Text('Edit Incident'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppPalette.border),
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Update incident details',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use this view to keep dispatch information current as conditions change.',
                      style: TextStyle(
                        color: AppPalette.textSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _LabeledField(
                      label: 'Incident title',
                      child: TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration('Incident title'),
                        validator: _requiredField,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _LabeledField(
                      label: 'Location',
                      child: TextFormField(
                        controller: _locationController,
                        decoration: _inputDecoration('Location'),
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
                        decoration: _inputDecoration('Updated incident notes'),
                        validator: _requiredField,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _active,
                      activeThumbColor: AppPalette.success,
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
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppPalette.text,
                            side: const BorderSide(color: AppPalette.border),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.save_outlined),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppPalette.info,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                          ),
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
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF7FAFD),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppPalette.info, width: 1.4),
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
  const _LabeledField({
    required this.label,
    required this.child,
  });

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
