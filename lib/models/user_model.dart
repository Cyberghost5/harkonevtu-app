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

  factory UserModel.fromJson(Map<String, dynamic> rawJson) {
    Map<String, dynamic> json = rawJson;
    if (rawJson.containsKey('user') && rawJson['user'] is Map<String, dynamic>) {
      json = rawJson['user'] as Map<String, dynamic>;
    } else if (rawJson.containsKey('data') && rawJson['data'] is Map<String, dynamic>) {
      json = rawJson['data'] as Map<String, dynamic>;
    }

    String resolveName(Map<String, dynamic> data) {
      if (data['name'] != null && data['name'].toString().trim().isNotEmpty) {
        return data['name'].toString().trim();
      }
      if (data['full_name'] != null && data['full_name'].toString().trim().isNotEmpty) {
        return data['full_name'].toString().trim();
      }
      if (data['fullname'] != null && data['fullname'].toString().trim().isNotEmpty) {
        return data['fullname'].toString().trim();
      }
      final firstName = data['first_name']?.toString().trim() ?? '';
      final lastName = data['last_name']?.toString().trim() ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
      if (data['username'] != null && data['username'].toString().trim().isNotEmpty) {
        return data['username'].toString().trim();
      }
      return '';
    }

    return UserModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: resolveName(json),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['phone_number']?.toString() ?? json['mobile']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? json['role']?.toString() ?? 'user',
      isActive: json['is_active'] == true || json['status'] == 'active' || json['status'] == 1 || json['is_active'] == 1,
      referralCode: json['referral_code']?.toString() ?? json['ref_code']?.toString(),
      kycStatus: json['kyc_status']?.toString(),
      avatar: json['avatar']?.toString() ?? json['profile_photo_url']?.toString() ?? json['avatar_url']?.toString() ?? json['profile_picture']?.toString(),
      wallet: json['wallet'] != null && json['wallet'] is Map<String, dynamic>
          ? WalletModel.fromJson(json['wallet'] as Map<String, dynamic>)
          : null,
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
