class Item {
  String punchlistId;
  String itemId;
  String imgName;
  String itemName;
  String itemExplanation;
  String itemStatus;

  Item(
      {this.punchlistId,
      this.itemId,
      this.imgName,
      this.itemName,
      this.itemExplanation,
      this.itemStatus});

  factory Item.fromMap(Map<String, dynamic> json) {
    return Item(
      punchlistId: json['punchlistId'] as String,
      itemId: json['itemId'] as String,
      imgName: json['imgName'] as String,
      itemName: json['itemName'] as String,
      itemExplanation: json['itemExplanation'] as String,
      itemStatus: json['itemStatus'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'punchlistId': punchlistId,
        'itemId': itemId,
        'imgName': imgName,
        'itemName': itemName,
        'itemExplanation': itemExplanation,
        'itemStatus': itemStatus,
      };
}
