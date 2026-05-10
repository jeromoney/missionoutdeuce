class TeamAdminTeam {
  const TeamAdminTeam({
    required this.publicId,
    required this.name,
    required this.organization,
    required this.region,
    required this.dispatchChannel,
    required this.notes,
    required this.members,
  });

  final String publicId;
  final String name;
  final String organization;
  final String region;
  final String dispatchChannel;
  final String notes;
  final List<TeamAdminMember> members;

  TeamAdminTeam copyWith({
    String? publicId,
    String? name,
    String? organization,
    String? region,
    String? dispatchChannel,
    String? notes,
    List<TeamAdminMember>? members,
  }) {
    return TeamAdminTeam(
      publicId: publicId ?? this.publicId,
      name: name ?? this.name,
      organization: organization ?? this.organization,
      region: region ?? this.region,
      dispatchChannel: dispatchChannel ?? this.dispatchChannel,
      notes: notes ?? this.notes,
      members: members ?? this.members,
    );
  }
}

class TeamAdminWorkspace {
  const TeamAdminWorkspace({
    required this.team,
    required this.memberCrudSupported,
    required this.usingLiveData,
    this.statusMessage,
  });

  final TeamAdminTeam team;
  final bool memberCrudSupported;
  final bool usingLiveData;
  final String? statusMessage;
}

class TeamAdminMember {
  const TeamAdminMember({
    required this.publicId,
    required this.userPublicId,
    required this.teamPublicId,
    required this.name,
    required this.email,
    required this.phone,
    required this.roles,
    required this.status,
    required this.lastSeenAt,
    required this.devicePlatform,
    required this.deviceHealth,
    required this.isActive,
    this.revokedAt,
  });

  final String publicId;
  final String userPublicId;
  final String teamPublicId;
  final String name;
  final String email;
  final String phone;
  final List<String> roles;
  final String status;
  final DateTime? lastSeenAt;
  final String devicePlatform;
  final String deviceHealth;
  final bool isActive;
  final String? revokedAt;

  TeamAdminMember copyWith({
    String? publicId,
    String? userPublicId,
    String? teamPublicId,
    String? name,
    String? email,
    String? phone,
    List<String>? roles,
    String? status,
    DateTime? lastSeenAt,
    String? devicePlatform,
    String? deviceHealth,
    bool? isActive,
    String? revokedAt,
  }) {
    return TeamAdminMember(
      publicId: publicId ?? this.publicId,
      userPublicId: userPublicId ?? this.userPublicId,
      teamPublicId: teamPublicId ?? this.teamPublicId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roles: roles ?? this.roles,
      status: status ?? this.status,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      devicePlatform: devicePlatform ?? this.devicePlatform,
      deviceHealth: deviceHealth ?? this.deviceHealth,
      isActive: isActive ?? this.isActive,
      revokedAt: revokedAt ?? this.revokedAt,
    );
  }
}

class TeamAdminMemberDraft {
  const TeamAdminMemberDraft({
    required this.name,
    required this.email,
    required this.phone,
    required this.roles,
  });

  final String name;
  final String email;
  final String phone;
  final List<String> roles;
}
