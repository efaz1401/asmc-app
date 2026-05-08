import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/role_badge.dart';
import '../../clients/application/client_providers.dart';
import '../../clients/domain/client.dart';
import '../../employees/domain/employee.dart';
import '../application/deployment_providers.dart';
import '../data/deployment_repository.dart';
import '../domain/deployment.dart';

class DeploymentFormScreen extends ConsumerStatefulWidget {
  const DeploymentFormScreen({super.key, this.id});
  final String? id;
  bool get isEdit => id != null;

  @override
  ConsumerState<DeploymentFormScreen> createState() => _DeploymentFormScreenState();
}

class _DeploymentFormScreenState extends ConsumerState<DeploymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _project = TextEditingController();
  final _notes = TextEditingController();
  String? _employeeId;
  String? _clientId;
  Shift? _shift = Shift.fullDay;
  DeploymentStatus _status = DeploymentStatus.scheduled;
  DateTime? _start;
  DateTime? _end;
  bool _submitting = false;
  String? _error;
  bool _hydrated = false;

  @override
  void dispose() {
    _project.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _hydrate(Deployment d) {
    if (_hydrated) return;
    _hydrated = true;
    _project.text = d.projectName ?? '';
    _notes.text = d.notes ?? '';
    _employeeId = d.employeeId;
    _clientId = d.clientId;
    _shift = d.shift;
    _status = d.status;
    _start = d.startDate;
    _end = d.endDate;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? (_start ?? DateTime.now()) : (_end ?? _start ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_employeeId == null || _clientId == null || _start == null) {
      setState(() => _error = 'Employee, client, and start date are required.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(deploymentRepositoryProvider);
      final payload = <String, dynamic>{
        'employeeId': _employeeId,
        'clientId': _clientId,
        'projectName': _project.text.trim(),
        'shift': _shift?.value,
        'status': _status.value,
        'startDate': _start!.toIso8601String(),
        if (_end != null) 'endDate': _end!.toIso8601String(),
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      }..removeWhere((k, v) => v is String && v.isEmpty);

      if (widget.isEdit) {
        await repo.update(widget.id!, payload);
      } else {
        await repo.create(payload);
      }
      ref.invalidate(deploymentListProvider);
      ref.invalidate(deploymentStatsProvider);
      if (widget.isEdit) ref.invalidate(deploymentDetailProvider(widget.id!));
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
      final asyncD = ref.watch(deploymentDetailProvider(widget.id!));
      return Scaffold(
        appBar: AppBar(title: const Text('Edit deployment')),
        body: AsyncValueView<Deployment>(
          value: asyncD,
          dataBuilder: (d) {
            _hydrate(d);
            return _buildForm();
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Assign deployment')),
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
              controller: _project,
              decoration: const InputDecoration(labelText: 'Project name'),
            ),
            const SizedBox(height: 12),
            _ClientPicker(
              selectedId: _clientId,
              onChanged: (v) => setState(() => _clientId = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(_start == null ? 'Pick a date' : Formatters.date(_start)),
              trailing: const Icon(Icons.event),
              onTap: () => _pickDate(isStart: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End date (optional)'),
              subtitle: Text(_end == null ? 'Open-ended' : Formatters.date(_end)),
              trailing: const Icon(Icons.event_available),
              onTap: () => _pickDate(isStart: false),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<Shift>(
              value: _shift,
              items: Shift.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _shift = v),
              decoration: const InputDecoration(labelText: 'Shift'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DeploymentStatus>(
              value: _status,
              items: DeploymentStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? DeploymentStatus.scheduled),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 16),
            Text('Available employees',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              _start == null
                  ? 'Pick a start date to see who is available.'
                  : 'Showing employees with no overlapping deployment in the selected window.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (_start != null)
              _AvailabilityList(
                args: AvailabilityArgs(startDate: _start!, endDate: _end),
                selectedId: _employeeId,
                onSelect: (id) => setState(() => _employeeId = id),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
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
                  : Text(widget.isEdit ? 'Save changes' : 'Create deployment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientPicker extends ConsumerWidget {
  const _ClientPicker({required this.selectedId, required this.onChanged});
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientListProvider);
    return AsyncValueView<ClientPage>(
      value: clients,
      dataBuilder: (page) {
        return DropdownButtonFormField<String>(
          value: selectedId,
          items: page.items
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.companyName)))
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(labelText: 'Client'),
        );
      },
    );
  }
}

class _AvailabilityList extends ConsumerWidget {
  const _AvailabilityList({required this.args, required this.selectedId, required this.onSelect});
  final AvailabilityArgs args;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(availableEmployeesProvider(args));
    return AsyncValueView<List<Employee>>(
      value: list,
      dataBuilder: (items) {
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.4)),
            ),
            child: const Text('No employees available in this window. Pick different dates.'),
          );
        }
        return Column(
          children: [
            for (final e in items)
              Card(
                margin: const EdgeInsets.only(bottom: 6),
                color: e.id == selectedId
                    ? AppColors.emerald600.withOpacity(0.10)
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.navy700.withOpacity(0.12),
                    child: Text(_initials(e.fullName), style: const TextStyle(color: AppColors.navy700)),
                  ),
                  title: Text(e.fullName),
                  subtitle: Text([e.employeeCode, if (e.trade != null) e.trade].whereType<String>().join(' · ')),
                  trailing: e.id == selectedId
                      ? const Icon(Icons.check_circle, color: AppColors.emerald600)
                      : const StatusPill(label: 'Available', color: AppColors.emerald600),
                  onTap: () => onSelect(e.id),
                ),
              ),
          ],
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
