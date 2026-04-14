class TeamAdminTeam {
  const TeamAdminTeam({
    required this.publicId,
    required this.name,
    required this.organization,
    required this.region,
    required this.dispatchChannel,
    required this.notes,
    required this.members,
    required this.incidents,
    required this.responses,
  });

  final String publicId;
  final String name;
  final String organization;
  final String region;
  final String dispatchChannel;
  final String notes;
  final List<TeamAdminMember> members;
  final List<TeamIncidentSummary> incidents;
  final List<TeamResponseSummary> responses;

  TeamAdminTeam copyWith({
    String? publicId,
    String? name,
    String? organization,
    String? region,
    String? dispatchChannel,
    String? notes,
    List<TeamAdminMember>? members,
    List<TeamIncidentSummary>? incidents,
    List<TeamResponseSummary>? responses,
  }) {
    return TeamAdminTeam(
      publicId: publicId ?? this.publicId,
      name: name ?? this.name,
      organization: organization ?? this.organization,
      region: region ?? this.region,
      dispatchChannel: dispatchChannel ?? this.dispatchChannel,
      notes: notes ?? this.notes,
      members: members ?? this.members,
      incidents: incidents ?? this.incidents,
      responses: responses ?? this.responses,
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
    required this.lastSeen,
    required this.devicePlatform,
    required this.deviceHealth,
    required this.isActive,
  });

  final String publicId;
  final String userPublicId;
  final String teamPublicId;
  final String name;
  final String email;
  final String phone;
  final List<String> roles;
  final String status;
  final String lastSeen;
  final String devicePlatform;
  final String deviceHealth;
  final bool isActive;

  TeamAdminMember copyWith({
    String? publicId,
    String? userPublicId,
    String? teamPublicId,
    String? name,
    String? email,
    String? phone,
    List<String>? roles,
    String? status,
    String? lastSeen,
    String? devicePlatform,
    String? deviceHealth,
    bool? isActive,
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
      lastSeen: lastSeen ?? this.lastSeen,
      devicePlatform: devicePlatform ?? this.devicePlatform,
      deviceHealth: deviceHealth ?? this.deviceHealth,
      isActive: isActive ?? this.isActive,
    );
  }
}

class TeamIncidentSummary {
  const TeamIncidentSummary({
    required this.publicId,
    required this.teamPublicId,
    required this.title,
    required this.location,
    required this.state,
    required this.time,
  });

  final String publicId;
  final String? teamPublicId;
  final String title;
  final String location;
  final String state;
  final String time;
}

class TeamResponseSummary {
  const TeamResponseSummary({
    required this.userPublicId,
    required this.memberName,
    required this.incidentTitle,
    required this.status,
    required this.time,
  });

  final String userPublicId;
  final String memberName;
  final String incidentTitle;
  final String status;
  final String time;
}

class TeamAdminMemberDraft {
  const TeamAdminMemberDraft({
    required this.name,
    required this.email,
    required this.phone,
    required this.roles,
    required this.status,
    required this.lastSeen,
    required this.devicePlatform,
    required this.deviceHealth,
    required this.isActive,
  });

  final String name;
  final String email;
  final String phone;
  final List<String> roles;
  final String status;
  final String lastSeen;
  final String devicePlatform;
  final String deviceHealth;
  final bool isActive;
}
