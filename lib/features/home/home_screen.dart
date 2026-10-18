import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_strings.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../shared/widgets/common_widgets.dart';
import '../contacts/data/contacts_repository.dart';
import '../contacts/models/emergency_contact.dart';
import '../profile/data/profile_repository.dart';
import '../profile/models/user_profile.dart';
import '../sos/data/sos_settings_repository.dart';
import '../sos/models/sos_settings.dart';
import '../sos/services/location_service.dart';
import '../sos/services/sos_engine.dart';
import '../sos/sos_actions.dart';
import '../sos/widgets/sos_button.dart';

/// Home for people who want protection: the SOS button, level choice,
/// setup status and helplines.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _engine = SosEngine.instance;

  UserProfile? _profile;
  List<EmergencyContact> _contacts = ContactsRepository.instance.cachedContacts;
  SosSettings _settings = SosSettingsRepository.instance.cached;
  late int _level = _settings.defaultLevel;

  @override
  void initState() {
    super.initState();
    _engine.addListener(_refresh);
    LocationService.instance.warmUp();
    _load();
  }

  @override
  void dispose() {
    _engine.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final settings = await SosSettingsRepository.instance.load();
    if (mounted) {
      setState(() {
        _level = settings.defaultLevel == _settings.defaultLevel ? _level : settings.defaultLevel;
        _settings = settings;
      });
    }
    try {
      final results = await Future.wait([
        ProfileRepository.instance.fetchMine(),
        ContactsRepository.instance.fetchMine(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserProfile?;
        _contacts = results[1] as List<EmergencyContact>;
      });
    } catch (_) {
      // Offline: cached name and contacts stay. SOS still works.
    }
  }

  Future<void> _call(String number) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: number));
    if (!ok && mounted) showMessage(context, context.tr('err_generic'), error: true);
  }

  Future<void> _open(String route, {Object? arguments}) async {
    await Navigator.pushNamed(context, route, arguments: arguments);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final name = _profile?.firstName ?? (ProfileRepository.cachedName ?? '').split(' ').first;
    final role = _profile?.role ?? ProfileRepository.cachedRole ?? UserRole.protected;
    final accepted = _contacts.where((c) => c.inviteStatus == InviteStatus.accepted).length;
    final bloodGroup = _profile?.bloodGroup;
    final active = _engine.isVisiblyActive;

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isEmpty ? 'GuardianX' : context.trArgs('hello', {'name': name})),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.tr('settings'),
            onPressed: () => _open(AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (active) ...[
              Material(
                color: AppTheme.sosRed,
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.sosActive),
                  leading: const Icon(Icons.warning_rounded, color: Colors.white),
                  title: Text(
                    context.tr('sos_running_banner'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (!active) ...[
              SegmentedButton<int>(
                segments: [
                  for (final l in const [1, 2, 3])
                    ButtonSegment(value: l, label: Text(context.tr('level_${l}_short'))),
                ],
                selected: {_level},
                onSelectionChanged: (v) => setState(() => _level = v.first),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('level_${_level}_desc'),
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
            ],
            Center(
              child: SosButton(
                requireArming: _settings.requireArming,
                active: _engine.isActive,
                onSend: () => SosActions.trigger(context, level: _level),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _engine.isActive
                  ? context.tr('sos_running_hint')
                  : _settings.requireArming
                      ? context.tr('sos_hint_arming')
                      : context.trArgs('sos_hint_direct', {'n': '${_settings.countdownSeconds}'}),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.group_outlined),
                    title: Text(context.tr('emergency_contacts')),
                    subtitle: Text(context.trArgs('contacts_accepted_count', {
                      'accepted': '$accepted',
                      'total': '${_contacts.length}',
                    })),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(AppRoutes.contactsSetup, arguments: true),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: Text(context.tr('safety_profile')),
                    subtitle: Text(
                      bloodGroup != null
                          ? '${context.tr('blood_group')}: $bloodGroup'
                          : context.tr('profile_incomplete'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(AppRoutes.safetyProfile, arguments: true),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: Text(context.tr('sos_settings')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(AppRoutes.sosSettings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(context.tr('helplines'), style: text.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final h in const [
                  ('112', 'helpline_112'),
                  ('1091', 'helpline_1091'),
                  ('181', 'helpline_181'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _HelplineButton(
                        number: h.$1,
                        label: context.tr(h.$2),
                        onTap: () => _call(h.$1),
                      ),
                    ),
                  ),
              ],
            ),
            if (role == UserRole.both) ...[
              const SizedBox(height: 24),
              SecondaryButton(
                label: context.tr('people_i_protect'),
                icon: Icons.visibility_outlined,
                onPressed: () => _open(AppRoutes.guardianHome),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HelplineButton extends StatelessWidget {
  const _HelplineButton({required this.number, required this.label, required this.onTap});

  final String number;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
