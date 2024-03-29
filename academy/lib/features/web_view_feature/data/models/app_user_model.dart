class AppUser {
  AppUser({required this.transactionType, required this.userId, required this.publicKey, required this.enrolledBioType});

  factory AppUser.fromJson(Map<dynamic, dynamic> parsedJson) {
    return AppUser(
        transactionType: parsedJson['transactionType'] as String,
        userId:parsedJson['userId'] as String,
        publicKey: parsedJson['publicKey'] as String,
        enrolledBioType:parsedJson['enrolledBioType'] as int);
  }
  String transactionType;
  String publicKey;
  String userId;
  int enrolledBioType;

  Map toJson() => {
        'transactionType': transactionType,
        'userId': userId,
        'publicKey': publicKey,
        'enrolledBioType': enrolledBioType,
      };
}
