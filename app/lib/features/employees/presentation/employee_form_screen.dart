import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_value_view.dart';
import '../application/employee_providers.dart';
import '../data/employee_repository.dart';
import '../domain/employee.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  const EmployeeFormScreen({super.key, this.id});
  final String? id;
  bool get isEdit => id != null;

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _full = TextEditingController();
  late final _email = TextEditingController();
  late final _phone = TextEditingController();
  late final _password = TextEditingController(text: 'changeme123');
  late final _department = TextEditingController();
  late final _trade = TextEditingController();
  late final _skill = TextEditingController();
  late final _salary = TextEditingController();
  late final _nationalId = TextEditingController();
  late final _emergencyContact = TextEditingController();
  late final _address = TextEditingController();
  EmployeeAvailability _availability = EmployeeAvailability.available;
  bool _submitting = false;
  String? _error;
  bool _hydrated = false;

  @override
  void dispose() {
    _full.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _department.dispose();
    _trade.dispose();
    _skill.dispose();
    _salary.dispose();
    _nationalId.dispose();
    _emergencyContact.dispose();
    _address.dispose();
    super.dispose();
  }

  void _hydrate(Employee e) {
    if (_hydrated) return;
    _hydrated = true;
    _full.text = e.fullName;
    _email.text = e.email ?? '';
    _phone.text = e.phone ?? '';
    _department.text = e.department ?? '';
    _trade.text = e.trade ?? '';
    _skill.text = e.skillCategory ?? '';
    _salary.text = e.salary == 0 ? '' : e.salary.toString();
    _nationalId.text = e.nationalId ?? '';
    _emergencyContact.text = e.emergencyContact ?? '';
    _address.text = e.address ?? '';
    _availability = e.availability;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(employeeRepositoryProvider);
      final payload = <String, dynamic>{
        'fullName': _full.text.trim(),
        'email': _email.text.trim(),
        if (!widget.isEdit) 'password': _password.text,
        'phone': _phone.text.trim(),
        'department': _department.text.trim(),
        'trade': _trade.text.trim(),
        'skillCategory': _skill.text.trim(),
        'salary': double.tryParse(_salary.text.trim()) ?? 0,
        'nationalId': _nationalId.text.trim(),
        'emergencyContact': _emergencyContact.text.trim(),
        'address': _address.text.trim(),
        'availability': _availability.value,
      }..removeWhere((k, v) => v is String && v.isEmpty);

      if (widget.isEdit) {
        await repo.update(widget.id!, payload);
      } else {
        await repo.create(payload);
      }
      ref.invalidate(employeeListProvider);
      if (widget.isEdit) ref.invalidate(employeeDetailProvider(widget.id!));
      if (!mounted) return;
      context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final asyncE = ref.watch(employeeDetailProvider(widget.id!));
      return Scaffold(
        appBar: AppBar(title: const Text('Edit employee')),
        body: AsyncValueView<Employee>(
          value: asyncE,
          dataBuilder: (e) {
            _hydrate(e);
            return _buildForm();
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Add employee')),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _full,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            if (!widget.isEdit) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(
                  labelText: 'Initial password',
                  helperText: 'Employee can reset after first login',
                ),
                validator: (v) =>
                    (v == null || v.length < 8) ? 'At least 8 characters' : null,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 12),
            TextFormField(controller: _department, decoration: const InputDecoration(labelText: 'Department')),
            const SizedBox(height: 12),
            TextFormField(controller: _trade, decoration: const InputDecoration(labelText: 'Trade / role')),
            const SizedBox(height: 12),
            TextFormField(controller: _skill, decoration: const InputDecoration(labelText: 'Skill category')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _salary,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monthly salary'),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _nationalId, decoration: const InputDecoration(labelText: 'National ID / Passport')),
            const SizedBox(height: 12),
            TextFormField(controller: _emergencyContact, decoration: const InputDecoration(labelText: 'Emergency contact')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EmployeeAvailability>(
              value: _availability,
              items: EmployeeAvailability.values
                  .map((a) => DropdownMenuItem(value: a, child: Text(a.label)))
                  .toList(),
              onChanged: (v) => setState(() => _availability = v ?? EmployeeAvailability.available),
              decoration: const InputDecoration(labelText: 'Availability'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.isEdit ? 'Save changes' : 'Create employee'),
            ),
          ],
        ),
      ),
    );
  }
}
