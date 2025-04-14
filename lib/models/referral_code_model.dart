class ReferralCodeModel {
  final String code;
  final String uid;

  ReferralCodeModel({required this.code, required this.uid});

  Map<String, dynamic> toMap() {
    return {'uid': uid};
  }

  factory ReferralCodeModel.fromMap(Map<String, dynamic> map, String code) {
    return ReferralCodeModel(code: code, uid: map['uid'] ?? '');
  }
}
