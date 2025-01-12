class Group {
  final String id;
  final String name;
  final String leaderId;
  final List<String> memberEmails;
  
  Group({
    required this.id,
    required this.name,
    required this.leaderId,
    required this.memberEmails,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'leaderId': leaderId,
      'memberEmails': memberEmails,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      leaderId: map['leaderId'],
      memberEmails: List<String>.from(map['memberEmails']),
    );
  }
}