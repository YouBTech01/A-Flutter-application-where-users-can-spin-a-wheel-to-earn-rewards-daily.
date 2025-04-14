class WithdrawalRequestModel {
  final String id;
  final String uid;
  final String upiId;
  final int amount;
  final String status;
  final DateTime timestamp;

  WithdrawalRequestModel({
    required this.id,
    required this.uid,
    required this.upiId,
    required this.amount,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'upiId': upiId,
      'amount': amount,
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory WithdrawalRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return WithdrawalRequestModel(
      id: id,
      uid: map['uid'] ?? '',
      upiId: map['upiId'] ?? '',
      amount: map['amount'] ?? 0,
      status: map['status'] ?? 'pending',
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
    );
  }
}
