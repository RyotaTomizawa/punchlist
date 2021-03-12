class PunchlistElement {
  String punchlistId;
  String punchlistName;
  String createDate;
  String createUser;
  String explanationPunchlist;

  PunchlistElement(
      {this.punchlistId,
      this.punchlistName,
      this.createDate,
      this.createUser,
      this.explanationPunchlist});

  factory PunchlistElement.fromMap(Map<String, dynamic> json) {
    return PunchlistElement(
      punchlistId: json['punchlistId'] as String,
      punchlistName: json['punchlistName'] as String,
      createDate: json['createDate'] as String,
      createUser: json['createUser'] as String,
      explanationPunchlist: json['explanationPunchlist'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'punchlistId': punchlistId,
        'punchlistName': punchlistName,
        'createDate': createDate,
        'createUser': createUser,
        'explanationPunchlist': explanationPunchlist,
      };
}
