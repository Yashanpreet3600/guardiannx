enum InviteStatus { pending, accepted, declined }

/// Relation keys. Each has a translated label "rel_<key>" in app_strings.dart.
const contactRelations = ['parent', 'sibling', 'partner', 'friend', 'relative', 'other'];

class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
    required this.isBackup,
    required this.priority,
    required this.inviteToken,
    required this.inviteStatus,
    this.inviteSentAt,
  });

  final String id;
  final String name;
  final String phone;
  final String relation;

  /// Backup contacts are alerted only if no main contact responds.
  final bool isBackup;
  final int priority;
  final String inviteToken;
  final InviteStatus inviteStatus;
  final DateTime? inviteSentAt;

  factory EmergencyContact.fromMap(Map<String, dynamic> m) => EmergencyContact(
        id: m['id'] as String,
        name: m['name'] as String,
        phone: m['phone'] as String,
        relation: (m['relation'] as String?) ?? 'other',
        isBackup: (m['is_backup'] as bool?) ?? false,
        priority: (m['priority'] as num?)?.toInt() ?? 0,
        inviteToken: m['invite_token'] as String,
        inviteStatus:
            InviteStatus.values.asNameMap()[m['invite_status']] ?? InviteStatus.pending,
        inviteSentAt: m['invite_sent_at'] == null
            ? null
            : DateTime.parse(m['invite_sent_at'] as String),
      );

  /// Same column names as the database, so the cache can use [fromMap].
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relation': relation,
        'is_backup': isBackup,
        'priority': priority,
        'invite_token': inviteToken,
        'invite_status': inviteStatus.name,
        'invite_sent_at': inviteSentAt?.toIso8601String(),
      };
}

/// What the user filled in before the contact is saved.
class ContactDraft {
  const ContactDraft({
    required this.name,
    required this.phone,
    required this.relation,
    required this.isBackup,
  });

  final String name;
  final String phone;
  final String relation;
  final bool isBackup;
}

/// Someone who added the signed-in user as their guardian.
class ProtectedPerson {
  const ProtectedPerson({
    required this.contactId,
    required this.name,
    required this.phone,
    required this.relation,
  });

  final String contactId;
  final String name;
  final String phone;

  /// What they set the guardian as, e.g. "parent".
  final String relation;

  factory ProtectedPerson.fromMap(Map<String, dynamic> m) {
    final owner = (m['profiles'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return ProtectedPerson(
      contactId: m['id'] as String,
      name: (owner['full_name'] as String?) ?? '',
      phone: (owner['phone'] as String?) ?? '',
      relation: (m['relation'] as String?) ?? 'other',
    );
  }
}
