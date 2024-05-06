class MentionsData {
  final String mentionId;
  final String mentionWho;
  final String membersId;

  MentionsData({
    required this.mentionId,
    required this.mentionWho,
    required this.membersId,
  });

  factory MentionsData.fromJson(Map<dynamic, dynamic> json) {
    return MentionsData(
      mentionId: json['mentionId'],
      mentionWho: json['mentionWho'],
      membersId: json['membersId'],
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      'mentionId': mentionId,
      'mentionWho': mentionWho,
      'membersId': membersId,
    };
  }

  MentionsData copyWith({
    String? mentionId,
    String? mentionWho,
    String? membersId,
  }) {
    return MentionsData(
      mentionId: mentionId ?? this.mentionId,
      mentionWho: mentionWho ?? this.mentionWho,
      membersId: membersId ?? this.membersId,
    );
  }
}
