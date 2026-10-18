import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_strings.dart';
import '../../core/routing/app_routes.dart';
import '../../core/utils/helpers.dart';
import '../../shared/widgets/common_widgets.dart';
import '../contacts/data/contacts_repository.dart';
import '../contacts/models/emergency_contact.dart';

/// Home for guardians: accept invites and see who you protect.
/// Live alerts arrive by SMS link (the guardian web page comes in phase 4).
class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  final _code = TextEditingController();
  List<ProtectedPerson> _people = [];
  bool _loading = true;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await ContactsRepository.instance.fetchPeopleIProtect();
      if (mounted) setState(() => _people = list);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(context, e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept() async {
    final token = ContactsRepository.extractToken(_code.text);
    if (token == null) {
      showMessage(context, context.tr('invite_invalid'), error: true);
      return;
    }
    setState(() => _accepting = true);
    try {
      final name = await ContactsRepository.instance.acceptInvite(token);
      if (!mounted) return;
      _code.clear();
      FocusScope.of(context).unfocus();
      showMessage(context, context.trArgs('invite_accepted', {'name': name}));
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(context, e), error: true);
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('guardian_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.tr('settings'),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            InfoCard(icon: Icons.shield_outlined, body: context.tr('guardian_info')),
            const SizedBox(height: 24),
            Text(context.tr('accept_invite_title'), style: text.titleMedium),
            const SizedBox(height: 10),
            AppTextField(
              controller: _code,
              label: context.tr('invite_code_label'),
              icon: Icons.link,
              onSubmitted: (_) => _accept(),
            ),
            PrimaryButton(
              label: context.tr('accept_invite'),
              onPressed: _accept,
              loading: _accepting,
            ),
            const SizedBox(height: 28),
            Text(context.tr('people_i_protect'), style: text.titleMedium),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_people.isEmpty)
              Text(context.tr('no_people_yet'), style: text.bodyMedium)
            else
              for (final p in _people)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(p.name.isEmpty ? '?' : p.name.characters.first.toUpperCase()),
                    ),
                    title: Text(p.name),
                    subtitle: Text(context.trArgs('added_you_as', {
                      'relation': context.tr('rel_${p.relation}'),
                    })),
                    trailing: p.phone.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.call_outlined),
                            onPressed: () => launchUrl(Uri(scheme: 'tel', path: p.phone)),
                          ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
