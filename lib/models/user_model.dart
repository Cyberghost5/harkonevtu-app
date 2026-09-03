class WalletModel {
  final int id;
  final int userId;
  final double balance;
  final double totalFunded;
  final double totalSpent;
  final double referralBalance;

  WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    required this.totalFunded,
    required this.totalSpent,
    required this.referralBalance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return WalletModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      balance: parseDouble(json['balance']),
      totalFunded: parseDouble(json['total_funded']),
      totalSpent: parseDouble(json['total_spent']),
      referralBalance: parseDouble(json['referral_balance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balance': balance.toStringAsFixed(2),
      'total_funded': totalFunded.toStringAsFixed(2),
      'total_spent': totalSpent.toStringAsFixed(2),
      'referral_balance': referralBalance.toStringAsFixed(2),
    };
  }
}

class UserModel {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String userType;
  final bool isActive;
  final String? referralCode;
  final String? kycStatus;
  final String? avatar;
  final WalletModel? wallet;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.userType,
    required this.isActive,
    this.referralCode,
    this.kycStatus,
    this.avatar,
    this.wallet,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['full_name'] ?? json['username'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      userType: json['user_type'] ?? 'user',
      isActive: json['is_active'] ?? true,
      referralCode: json['referral_code'],
      kycStatus: json['kyc_status'],
      avatar: json['avatar'] ?? json['profile_photo_url'] ?? json['avatar_url'] ?? json['profile_picture'],
      wallet: json['wallet'] != null ? WalletModel.fromJson(json['wallet']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'user_type': userType,
      'is_active': isActive,
      'referral_code': referralCode,
      'kyc_status': kycStatus,
      'avatar': avatar,
      'wallet': wallet?.toJson(),
    };
  }
}
