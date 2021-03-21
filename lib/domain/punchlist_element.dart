class PunchlistElement {
  int punchlistId;
  String punchlistName;
  String createDate;
  String explanationPunchlist;

  PunchlistElement(
      {this.punchlistId,
      this.punchlistName,
      this.createDate,
      this.explanationPunchlist});

  factory PunchlistElement.fromMap(Map<String, dynamic> json) {
    return PunchlistElement(
      punchlistId: json['punchlistId'] as int,
      punchlistName: json['punchlistName'] as String,
      createDate: json['createDate'] as String,
      explanationPunchlist: json['explanationPunchlist'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'punchlistId': punchlistId,
        'punchlistName': punchlistName,
        'createDate': createDate,
        'explanationPunchlist': explanationPunchlist,
      };
}
