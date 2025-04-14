class UserModel {
  final String uid;
  final String email;
  final String name;
  final int points;
  final int totalEarnings;
  final int spinsToday;
  final String referredBy;
  final String myReferralCode;
  final String upiId;
  final DateTime lastLoginDate;
  final bool referralCodeApplied;
  final List<String> appliedReferralCodes;

  UserModel({
    required this.uid,
    required this.email,
    this.name = '',
    this.points = 0,
    this.totalEarnings = 0,
    this.spinsToday = 0,
    this.referredBy = '',
    required this.myReferralCode,
    this.upiId = '',
    required this.lastLoginDate,
    this.referralCodeApplied = false,
    this.appliedReferralCodes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'points': points,
      'totalEarnings': totalEarnings,
      'spinsToday': spinsToday,
      'referredBy': referredBy,
      'myReferralCode': myReferralCode,
      'upiId': upiId,
      'lastLoginDate': lastLoginDate,
      'referralCodeApplied': referralCodeApplied,
      'appliedReferralCodes': appliedReferralCodes,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      points: map['points'] ?? 0,
      totalEarnings: map['totalEarnings'] ?? 0,
      spinsToday: map['spinsToday'] ?? 0,
      referredBy: map['referredBy'] ?? '',
      myReferralCode: map['myReferralCode'] ?? '',
      upiId: map['upiId'] ?? '',
      lastLoginDate: map['lastLoginDate']?.toDate() ?? DateTime.now(),
      referralCodeApplied: map['referralCodeApplied'] ?? false,
      appliedReferralCodes:
          map['appliedReferralCodes'] != null
              ? List<String>.from(map['appliedReferralCodes'])
              : [],
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    int? points,
    int? totalEarnings,
    int? spinsToday,
    String? referredBy,
    String? myReferralCode,
    String? upiId,
    DateTime? lastLoginDate,
    bool? referralCodeApplied,
    List<String>? appliedReferralCodes,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      points: points ?? this.points,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      spinsToday: spinsToday ?? this.spinsToday,
      referredBy: referredBy ?? this.referredBy,
      myReferralCode: myReferralCode ?? this.myReferralCode,
      upiId: upiId ?? this.upiId,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      referralCodeApplied: referralCodeApplied ?? this.referralCodeApplied,
      appliedReferralCodes: appliedReferralCodes ?? this.appliedReferralCodes,
    );
  }
}
