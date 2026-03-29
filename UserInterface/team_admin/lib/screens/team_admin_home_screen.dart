import 'package:flutter/material.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';
import '../models/team_admin_models.dart';
import '../services/team_admin_repository.dart';

class TeamAdminHomeScreen extends StatefulWidget {
  const TeamAdminHomeScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<TeamAdminHomeScreen> createState() => _TeamAdminHomeScreenState();
}

class _TeamAdminHomeScreenState extends State<TeamAdminHomeScreen> {
  final repository = TeamAdminRepository();
  TeamAdminTeam team = const TeamAdminTeam(
    id: 0,
    name: 'Loading team',
    organization: 'MissionOut',
    region: 'Current team scope',
    dispatchChannel: 'API-managed',
    notes:
        'Team Admin manages memberships, roles, device readiness, and team visibility for one existing operational team.',
    members: [],
    incidents: [],
    responses: [],
  );
  bool loading = true;
  bool memberCrudSupported = false;
  bool usingLiveData = false;
  String? statusMessage;
  String connectionLabel = 'Connecting';
  String connectionDetail = '';

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 1200;
    final activeMembers = team.members
        .where((member) => member.isActive)
        .length;
    final admins = team.members
        .where((member) => member.roles.contains('team_admin'))
        .length;
    final unhealthyDevices = team.members
        .where((member) => member.deviceHealth != 'Healthy')
        .length;
    final responding = team.responses
        .where((response) => response.status == 'Responding')
        .length;

    return Scaffold(
      body: MissionOutBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Header(
                  team: team,
                  userInitials: widget.auth.currentUser?.initials ?? '--',
                  connectionLabel: connectionLabel,
                  connectionDetail: connectionDetail,
                  usingLiveData: usingLiveData,
                  onLogout: widget.auth.logout,
                ),
                if (statusMessage != null) ...[
                  const SizedBox(height: 16),
                  _StatusBanner(message: statusMessage!),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _SummaryCard(
                      title: 'Active members',
                      value: '$activeMembers',
                      subtitle:
                          'Users currently active in this one managed team.',
                      icon: Icons.badge_outlined,
                      color: TeamAdminPalette.accent,
                    ),
                    _SummaryCard(
                      title: 'Team admins',
                      value: '$admins',
                      subtitle: 'Members who can manage roles and activation.',
                      icon: Icons.admin_panel_settings_outlined,
                      color: TeamAdminPalette.success,
                    ),
                    _SummaryCard(
                      title: 'Device issues',
                      value: '$unhealthyDevices',
                      subtitle: 'Members with device state needing follow-up.',
                      icon: Icons.phonelink_erase_rounded,
                      color: TeamAdminPalette.secondaryAccent,
                    ),
                    _SummaryCard(
                      title: 'Active responses',
                      value: '$responding',
                      subtitle:
                          'Acknowledgement activity across this team\'s last-7-days incident feed.',
                      icon: Icons.assignment_turned_in_outlined,
                      color: TeamAdminPalette.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : compact
                      ? ListView(
                          children: [
                            SizedBox(
                              height: 580,
                              child: _MembersPanel(
                                team: team,
                                memberCrudSupported: memberCrudSupported,
                                onCreateMember: _openCreateMember,
                                onEditMember: _openEditMember,
                                onToggleMember: _toggleMemberActive,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 260,
                              child: _TeamContextPanel(team: team),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 260,
                              child: _ResponsesPanel(responses: team.responses),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 260,
                              child: _IncidentsPanel(incidents: team.incidents),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _MembersPanel(
                                team: team,
                                memberCrudSupported: memberCrudSupported,
                                onCreateMember: _openCreateMember,
                                onEditMember: _openEditMember,
                                onToggleMember: _toggleMemberActive,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _TeamContextPanel(team: team),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: _ResponsesPanel(
                                      responses: team.responses,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: _IncidentsPanel(
                                      incidents: team.incidents,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadWorkspace() async {
    setState(() {
      loading = true;
      statusMessage = null;
    });

    final workspace = await repository.loadWorkspace(
      memberships: widget.auth.currentUser?.teamMemberships ?? const [],
      userEmail: widget.auth.currentUser?.email,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      team = workspace.team;
      loading = false;
      memberCrudSupported = workspace.memberCrudSupported;
      usingLiveData = workspace.usingLiveData;
      connectionLabel = workspace.connectionLabel;
      connectionDetail = workspace.connectionDetail;
      statusMessage = workspace.statusMessage;
    });
  }

  Future<void> _openCreateMember() async {
    if (!memberCrudSupported) {
      setState(() {
        statusMessage =
            'This backend does not expose team membership CRUD yet. Live incident and response data are connected, but member invites and device management still need backend routes.';
      });
      return;
    }

    final draft = await showDialog<TeamAdminMemberDraft>(
      context: context,
      builder: (context) => const _MemberEditorDialog(),
    );

    if (draft == null || !mounted) {
      return;
    }

    try {
      final updatedTeam = await repository.createMember(draft);
      if (!mounted) {
        return;
      }
      setState(() {
        team = updatedTeam;
        statusMessage = 'Added ${draft.name} to ${team.name}.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(
        () => statusMessage = error.toString().replaceFirst(
          'Unsupported operation: ',
          '',
        ),
      );
    }
  }

  Future<void> _openEditMember(TeamAdminMember member) async {
    if (!memberCrudSupported) {
      setState(() {
        statusMessage =
            'This backend does not expose team membership CRUD yet. Live incident and response data are connected, but member role edits still need backend routes.';
      });
      return;
    }

    final draft = await showDialog<TeamAdminMemberDraft>(
      context: context,
      builder: (context) => _MemberEditorDialog(member: member),
    );

    if (draft == null || !mounted) {
      return;
    }

    try {
      final updatedTeam = await repository.updateMember(member.id, draft);
      if (!mounted) {
        return;
      }
      setState(() {
        team = updatedTeam;
        statusMessage = 'Updated ${member.name}.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(
        () => statusMessage = error.toString().replaceFirst(
          'Unsupported operation: ',
          '',
        ),
      );
    }
  }

  Future<void> _toggleMemberActive(TeamAdminMember member) async {
    if (!memberCrudSupported) {
      setState(() {
        statusMessage =
            'This backend does not expose activate/deactivate membership routes yet. Operational history is live, but member state changes still need backend support.';
      });
      return;
    }

    final nextState = !member.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nextState ? 'Activate member?' : 'Deactivate member?'),
        content: Text(
          nextState
              ? 'Reactivate ${member.name} for ${team.name}?'
              : 'Deactivate ${member.name}? Team Admin should prefer deactivation over hard deletion so operational history remains auditable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(nextState ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final updatedTeam = await repository.setMemberActive(
        member.id,
        nextState,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        team = updatedTeam;
        statusMessage = nextState
            ? 'Activated ${member.name}.'
            : 'Deactivated ${member.name}.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(
        () => statusMessage = error.toString().replaceFirst(
          'Unsupported operation: ',
          '',
        ),
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.team,
    required this.userInitials,
    required this.connectionLabel,
    required this.connectionDetail,
    required this.usingLiveData,
    required this.onLogout,
  });

  final TeamAdminTeam team;
  final String userInitials;
  final String connectionLabel;
  final String connectionDetail;
  final bool usingLiveData;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TeamAdminPalette.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: TeamAdminPalette.border),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MissionOutBrandLockup(
                  subtitle:
                      'Team Admin workspace for ${team.name}. Manage one team only: memberships, team-scoped roles, device readiness, and team-level visibility.',
                  logoSize: 60,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Pill(
                      label: connectionLabel,
                      color: usingLiveData
                          ? TeamAdminPalette.success
                          : TeamAdminPalette.warning,
                    ),
                    _Pill(label: team.name, color: TeamAdminPalette.accent),
                    _Pill(
                      label: team.organization,
                      color: TeamAdminPalette.success,
                    ),
                    _Pill(
                      label: team.region,
                      color: TeamAdminPalette.secondaryAccent,
                    ),
                    _Pill(
                      label: team.dispatchChannel,
                      color: TeamAdminPalette.warning,
                    ),
                    if (connectionDetail.isNotEmpty)
                      _Pill(
                        label: connectionDetail,
                        color: TeamAdminPalette.secondaryAccent,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TeamAdminPalette.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  userInitials,
                  style: const TextStyle(
                    color: TeamAdminPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: onLogout, child: const Text('Log out')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MembersPanel extends StatelessWidget {
  const _MembersPanel({
    required this.team,
    required this.memberCrudSupported,
    required this.onCreateMember,
    required this.onEditMember,
    required this.onToggleMember,
  });

  final TeamAdminTeam team;
  final bool memberCrudSupported;
  final VoidCallback onCreateMember;
  final ValueChanged<TeamAdminMember> onEditMember;
  final ValueChanged<TeamAdminMember> onToggleMember;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Team memberships',
      subtitle:
          'Invite, activate, deactivate, and role-manage users for this one existing team.',
      action: OutlinedButton.icon(
        onPressed: memberCrudSupported ? onCreateMember : null,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(memberCrudSupported ? 'Add member' : 'CRUD unavailable'),
      ),
      child: team.members.isEmpty
          ? Center(
              child: Text(
                memberCrudSupported
                    ? 'No team members returned yet.'
                    : 'This backend is connected, but it does not expose team membership data yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: TeamAdminPalette.textSoft,
                  height: 1.5,
                ),
              ),
            )
          : ListView.separated(
              itemCount: team.members.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final member = team.members[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TeamAdminPalette.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: member.isActive
                            ? TeamAdminPalette.accent
                            : TeamAdminPalette.warning,
                        foregroundColor: TeamAdminPalette.primary,
                        child: Text(member.name.substring(0, 1)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    member.name,
                                    style: const TextStyle(
                                      color: TeamAdminPalette.text,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _Pill(
                                  label: member.isActive
                                      ? member.status
                                      : 'Inactive',
                                  color: member.isActive
                                      ? _statusColor(member.status)
                                      : TeamAdminPalette.warning,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${member.email} | ${member.phone}',
                              style: const TextStyle(
                                color: TeamAdminPalette.textSoft,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final role in member.roles)
                                  _Pill(
                                    label: role,
                                    color: role == 'team_admin'
                                        ? TeamAdminPalette.accent
                                        : role == 'dispatcher'
                                        ? TeamAdminPalette.success
                                        : TeamAdminPalette.secondaryAccent,
                                  ),
                                _Pill(
                                  label:
                                      '${member.devicePlatform} | ${member.deviceHealth}',
                                  color: member.deviceHealth == 'Healthy'
                                      ? TeamAdminPalette.success
                                      : TeamAdminPalette.secondaryAccent,
                                ),
                                _Pill(
                                  label: 'Last seen ${member.lastSeen}',
                                  color: TeamAdminPalette.warning,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          IconButton(
                            onPressed: memberCrudSupported
                                ? () => onEditMember(member)
                                : null,
                            icon: const Icon(Icons.edit_outlined),
                            color: TeamAdminPalette.text,
                          ),
                          IconButton(
                            onPressed: memberCrudSupported
                                ? () => onToggleMember(member)
                                : null,
                            icon: Icon(
                              member.isActive
                                  ? Icons.person_off_outlined
                                  : Icons.person_add_alt_1_rounded,
                            ),
                            color: member.isActive
                                ? TeamAdminPalette.warning
                                : TeamAdminPalette.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _TeamContextPanel extends StatelessWidget {
  const _TeamContextPanel({required this.team});

  final TeamAdminTeam team;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Team context',
      subtitle:
          'This app manages one existing team only. Team creation and global administration live elsewhere.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(label: team.organization, color: TeamAdminPalette.success),
              _Pill(
                label: team.region,
                color: TeamAdminPalette.secondaryAccent,
              ),
              _Pill(
                label: team.dispatchChannel,
                color: TeamAdminPalette.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            team.notes,
            style: const TextStyle(
              color: TeamAdminPalette.textSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentsPanel extends StatelessWidget {
  const _IncidentsPanel({required this.incidents});

  final List<TeamIncidentSummary> incidents;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Team incidents',
      subtitle:
          'Read-only visibility into this team\'s recent incident feed and response history.',
      child: ListView.separated(
        itemCount: incidents.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final incident = incidents[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TeamAdminPalette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        incident.title,
                        style: const TextStyle(
                          color: TeamAdminPalette.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _Pill(
                      label: incident.state,
                      color: incident.state == 'Active'
                          ? TeamAdminPalette.accent
                          : TeamAdminPalette.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${incident.location} | ${incident.time}',
                  style: const TextStyle(color: TeamAdminPalette.textSoft),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ResponsesPanel extends StatelessWidget {
  const _ResponsesPanel({required this.responses});

  final List<TeamResponseSummary> responses;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Recent responses',
      subtitle:
          'Read-only acknowledgement history for incidents in this team\'s recent feed.',
      child: ListView.separated(
        itemCount: responses.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final response = responses[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TeamAdminPalette.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        response.memberName,
                        style: const TextStyle(
                          color: TeamAdminPalette.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        response.incidentTitle,
                        style: const TextStyle(
                          color: TeamAdminPalette.textSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Pill(
                      label: response.status,
                      color: _statusColor(response.status),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      response.time,
                      style: const TextStyle(color: TeamAdminPalette.textSoft),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: TeamAdminPalette.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: TeamAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: TeamAdminPalette.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: TeamAdminPalette.textSoft,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TeamAdminPalette.card.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: TeamAdminPalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 22),
            Text(
              value,
              style: const TextStyle(
                color: TeamAdminPalette.text,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: TeamAdminPalette.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: TeamAdminPalette.textSoft,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: TeamAdminPalette.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TeamAdminPalette.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.admin_panel_settings_outlined,
            color: TeamAdminPalette.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: TeamAdminPalette.textSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MemberEditorDialog extends StatefulWidget {
  const _MemberEditorDialog({this.member});

  final TeamAdminMember? member;

  @override
  State<_MemberEditorDialog> createState() => _MemberEditorDialogState();
}

class _MemberEditorDialogState extends State<_MemberEditorDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController lastSeenController;
  late final TextEditingController devicePlatformController;
  late final TextEditingController deviceHealthController;
  late String status;
  late bool isActive;
  late bool isTeamAdmin;
  late bool isDispatcher;
  late bool isResponder;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    nameController = TextEditingController(text: member?.name ?? '');
    emailController = TextEditingController(text: member?.email ?? '');
    phoneController = TextEditingController(text: member?.phone ?? '');
    lastSeenController = TextEditingController(
      text: member?.lastSeen ?? 'Just now',
    );
    devicePlatformController = TextEditingController(
      text: member?.devicePlatform ?? 'Android',
    );
    deviceHealthController = TextEditingController(
      text: member?.deviceHealth ?? 'Healthy',
    );
    status = member?.status ?? 'Available';
    isActive = member?.isActive ?? true;
    isTeamAdmin = member?.roles.contains('team_admin') ?? false;
    isDispatcher = member?.roles.contains('dispatcher') ?? false;
    isResponder = member?.roles.contains('responder') ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    lastSeenController.dispose();
    devicePlatformController.dispose();
    deviceHealthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.member == null ? 'Add team member' : 'Edit member'),
      content: SizedBox(
        width: 540,
        child: Form(
          key: formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(
                    value: 'Available',
                    child: Text('Available'),
                  ),
                  DropdownMenuItem(
                    value: 'Responding',
                    child: Text('Responding'),
                  ),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'Unavailable',
                    child: Text('Unavailable'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => status = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: devicePlatformController,
                decoration: const InputDecoration(labelText: 'Device platform'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: deviceHealthController,
                decoration: const InputDecoration(labelText: 'Device health'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lastSeenController,
                decoration: const InputDecoration(labelText: 'Last seen'),
                validator: _required,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: isTeamAdmin,
                onChanged: (value) {
                  setState(() => isTeamAdmin = value ?? false);
                },
                title: const Text('Team Admin'),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: isDispatcher,
                onChanged: (value) {
                  setState(() => isDispatcher = value ?? false);
                },
                title: const Text('Dispatcher'),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: isResponder,
                onChanged: (value) {
                  setState(() => isResponder = value ?? false);
                },
                title: const Text('Responder'),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile.adaptive(
                value: isActive,
                title: const Text('Membership active'),
                onChanged: (value) {
                  setState(() => isActive = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.member == null ? 'Add member' : 'Save changes'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  void _submit() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final roles = <String>[
      if (isTeamAdmin) 'team_admin',
      if (isDispatcher) 'dispatcher',
      if (isResponder) 'responder',
    ];

    if (roles.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      TeamAdminMemberDraft(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        roles: roles,
        status: status,
        lastSeen: lastSeenController.text.trim(),
        devicePlatform: devicePlatformController.text.trim(),
        deviceHealth: deviceHealthController.text.trim(),
        isActive: isActive,
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'Available':
      return TeamAdminPalette.success;
    case 'Responding':
      return TeamAdminPalette.accent;
    case 'Pending':
      return TeamAdminPalette.secondaryAccent;
    default:
      return TeamAdminPalette.warning;
  }
}
