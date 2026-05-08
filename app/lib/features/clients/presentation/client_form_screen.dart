import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_value_view.dart';
import '../application/client_providers.dart';
import '../data/client_repository.dart';
import '../domain/client.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  const ClientFormScreen({super.key, this.id});
  final String? id;
  bool get isEdit => id != null;

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _industry = TextEditingController();
  final _address = TextEditingController();
  final _billing = TextEditingController();
  final _taxId = TextEditingController();
  final _notes = TextEditingController();
  bool _portalAccount = false;
  bool _submitting = false;
  String? _error;
  bool _hydrated = false;

  @override
  void dispose() {
    _company.dispose();
    _contact.dispose();
    _email.dispose();
    _phone.dispose();
    _industry.dispose();
    _address.dispose();
    _billing.dispose();
    _taxId.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _hydrate(Client c) {
    if (_hydrated) return;
    _hydrated = true;
    _company.text = c.companyName;
    _contact.text = c.contactPerson ?? '';
    _email.text = c.email ?? '';
    _phone.text = c.phone ?? '';
    _industry.text = c.industry ?? '';
    _address.text = c.address ?? '';
    _billing.text = c.billingAddress ?? '';
    _taxId.text = c.taxId ?? '';
    _notes.text = c.notes ?? '';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(clientRepositoryProvider);
      final payload = <String, dynamic>{
        'companyName': _company.text.trim(),
        'contactPerson': _contact.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'industry': _industry.text.trim(),
        'address': _address.text.trim(),
        'billingAddress': _billing.text.trim(),
        'taxId': _taxId.text.trim(),
        'notes': _notes.text.trim(),
        if (!widget.isEdit) 'createPortalAccount': _portalAccount,
      }..removeWhere((k, v) => v is String && v.isEmpty);

      if (widget.isEdit) {
        await repo.update(widget.id!, payload);
      } else {
        await repo.create(payload);
      }
      ref.invalidate(clientListProvider);
      if (widget.isEdit) ref.invalidate(clientDetailProvider(widget.id!));
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
      final asyncC = ref.watch(clientDetailProvider(widget.id!));
      return Scaffold(
        appBar: AppBar(title: const Text('Edit client')),
        body: AsyncValueView<Client>(
          value: asyncC,
          dataBuilder: (c) {
            _hydrate(c);
            return _buildForm();
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Add client')),
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
              controller: _company,
              decoration: const InputDecoration(labelText: 'Company name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _contact, decoration: const InputDecoration(labelText: 'Contact person')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 12),
            TextFormField(controller: _industry, decoration: const InputDecoration(labelText: 'Industry')),
            const SizedBox(height: 12),
            TextFormField(controller: _address, maxLines: 2, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            TextFormField(controller: _billing, maxLines: 2, decoration: const InputDecoration(labelText: 'Billing address')),
            const SizedBox(height: 12),
            TextFormField(controller: _taxId, decoration: const InputDecoration(labelText: 'Tax ID')),
            const SizedBox(height: 12),
            TextFormField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes')),
            if (!widget.isEdit) ...[
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Create portal account for this client'),
                subtitle: const Text('Allows them to log in and view deployments / invoices.'),
                value: _portalAccount,
                onChanged: (v) => setState(() => _portalAccount = v),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.isEdit ? 'Save changes' : 'Create client'),
            ),
          ],
        ),
      ),
    );
  }
}
