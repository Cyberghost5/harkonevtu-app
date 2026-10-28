class OnboardingSlideModel {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final int sortOrder;

  OnboardingSlideModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.sortOrder,
  });

  factory OnboardingSlideModel.fromJson(Map<String, dynamic> json) {
    return OnboardingSlideModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}

class SupportInfoModel {
  final String phone;
  final String whatsapp;
  final String email;
  final String hours;
  final String whatsappGroup;
  final String telegramChannel;

  SupportInfoModel({
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.hours,
    required this.whatsappGroup,
    required this.telegramChannel,
  });

  factory SupportInfoModel.fromJson(Map<String, dynamic> json) {
    return SupportInfoModel(
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      email: json['email'] ?? '',
      hours: json['hours'] ?? '',
      whatsappGroup: json['whatsapp_group'] ?? '',
      telegramChannel: json['telegram_channel'] ?? '',
    );
  }
}

class PaymentGatewaysModel {
  final String activeGateway;
  final String paystackPublicKey;
  final String monnifyApiKey;
  final String monnifyContractNo;

  PaymentGatewaysModel({
    required this.activeGateway,
    required this.paystackPublicKey,
    required this.monnifyApiKey,
    required this.monnifyContractNo,
  });

  factory PaymentGatewaysModel.fromJson(Map<String, dynamic> json) {
    return PaymentGatewaysModel(
      activeGateway: json['active_gateway'] ?? 'paystack',
      paystackPublicKey: json['paystack_public_key'] ?? '',
      monnifyApiKey: json['monnify_api_key'] ?? '',
      monnifyContractNo: json['monnify_contract_no'] ?? '',
    );
  }
}

class AppServicesModel {
  final bool airtime;
  final bool data;
  final bool electricity;
  final bool cable;
  final bool epin;
  final bool betting;
  final bool airtimeToCash;
  final bool rechargeCardPrinting;
  final bool bulkSms;
  final bool cardPayment;
  final bool autoBankTransfer;
  final bool manualBankTransfer;
  final bool couponFunding;

  AppServicesModel({
    this.airtime = true,
    this.data = true,
    this.electricity = true,
    this.cable = true,
    this.epin = true,
    this.betting = true,
    this.airtimeToCash = true,
    this.rechargeCardPrinting = false,
    this.bulkSms = true,
    this.cardPayment = true,
    this.autoBankTransfer = true,
    this.manualBankTransfer = true,
    this.couponFunding = true,
  });

  factory AppServicesModel.fromJson(Map<String, dynamic> json) {
    return AppServicesModel(
      airtime: json['airtime'] ?? true,
      data: json['data'] ?? true,
      electricity: json['electricity'] ?? true,
      cable: json['cable'] ?? true,
      epin: json['epin'] ?? true,
      betting: json['betting'] ?? true,
      airtimeToCash: json['airtime_to_cash'] ?? true,
      rechargeCardPrinting: json['recharge_card_printing'] ?? false,
      bulkSms: json['bulk_sms'] ?? json['bulksms'] ?? true,
      cardPayment: json['card_payment'] ?? true,
      autoBankTransfer: json['auto_bank_transfer'] ?? true,
      manualBankTransfer: json['manual_bank_transfer'] ?? true,
      couponFunding: json['coupon_funding'] ?? true,
    );
  }
}

class AppConfigModel {
  final String appName;
  final String siteName;
  final String themeColor;
  final String? faviconUrl;
  final String? logo1Url;
  final String? logo2Url;
  final String currency;
  final String currencySymbol;
  final String appVersion;
  final String minVersion;
  final bool forceUpdate;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String? updateUrl;
  final String? playStoreUrl;
  final String? appStoreUrl;
  final AppServicesModel services;
  final PaymentGatewaysModel paymentGateways;
  final SupportInfoModel support;
  final List<OnboardingSlideModel> onboardingSlides;
  final bool googleAuthEnabled;
  final String googleClientId;
  final double agentUpgradeFee;
  final double kycFee;

  AppConfigModel({
    required this.appName,
    required this.siteName,
    required this.themeColor,
    this.faviconUrl,
    this.logo1Url,
    this.logo2Url,
    required this.currency,
    required this.currencySymbol,
    required this.appVersion,
    required this.minVersion,
    required this.forceUpdate,
    required this.maintenanceMode,
    required this.maintenanceMessage,
    this.updateUrl,
    this.playStoreUrl,
    this.appStoreUrl,
    required this.services,
    required this.paymentGateways,
    required this.support,
    required this.onboardingSlides,
    this.googleAuthEnabled = true,
    this.googleClientId = '',
    this.agentUpgradeFee = 2500.0,
    this.kycFee = 0.0,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    bool resolveGoogleEnabled() {
      if (json['google_auth'] != null && json['google_auth'] is Map) {
        final val = json['google_auth']['enabled'];
        return val == true || val == 1 || val == '1';
      }
      if (json['google_auth_status'] != null) {
        final val = json['google_auth_status'];
        return val == '1' || val == 1 || val == true;
      }
      return true;
    }

    String resolveGoogleClientId() {
      if (json['google_auth'] != null && json['google_auth'] is Map) {
        return (json['google_auth']['client_id'] ?? '').toString().trim();
      }
      return (json['google_client_id'] ?? '').toString().trim();
    }

    double resolveUpgradeFee() {
      if (json['charges'] != null && json['charges'] is Map) {
        final v = json['charges']['agent_upgrade_fee'];
        if (v != null) return double.tryParse(v.toString()) ?? 2500.0;
      }
      if (json['agent_upgrade_fee'] != null) {
        return double.tryParse(json['agent_upgrade_fee'].toString()) ?? 2500.0;
      }
      return 2500.0;
    }

    double resolveKycFee() {
      if (json['charges'] != null && json['charges'] is Map) {
        final v = json['charges']['kyc_fee'];
        if (v != null) return double.tryParse(v.toString()) ?? 0.0;
      }
      if (json['kyc_fee'] != null) {
        return double.tryParse(json['kyc_fee'].toString()) ?? 0.0;
      }
      return 0.0;
    }

    return AppConfigModel(
      appName: json['app_name'] ?? 'Harkone VTU',
      siteName: json['site_name'] ?? 'Harkone VTU',
      themeColor: json['theme_color'] ?? '#4f46e5',
      faviconUrl: json['favicon_url'],
      logo1Url: json['logo1_url'],
      logo2Url: json['logo2_url'],
      currency: json['currency'] ?? 'NGN',
      currencySymbol: json['currency_symbol'] ?? '₦',
      appVersion: json['app_version'] ?? '1.0.0',
      minVersion: json['min_version'] ?? '1.0.0',
      forceUpdate: json['force_update'] == true || json['force_update'] == 1 || json['force_update'] == '1',
      maintenanceMode: json['maintenance_mode'] == true || json['maintenance_mode'] == 1 || json['maintenance_mode'] == '1',
      maintenanceMessage: json['maintenance_message'] ?? 'Platform is under routine maintenance. Please check back shortly.',
      updateUrl: json['update_url'] ?? json['app_update_url'],
      playStoreUrl: json['play_store_url'] ?? json['playstore_url'],
      appStoreUrl: json['app_store_url'] ?? json['appstore_url'],
      services: AppServicesModel.fromJson(json['services'] ?? {}),
      paymentGateways: PaymentGatewaysModel.fromJson(json['payment_gateways'] ?? {}),
      support: SupportInfoModel.fromJson(json['support'] ?? {}),
      agentUpgradeFee: resolveUpgradeFee(),
      kycFee: resolveKycFee(),
      onboardingSlides: (json['onboarding_slides'] as List<dynamic>?)
              ?.map((e) => OnboardingSlideModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      googleAuthEnabled: resolveGoogleEnabled(),
      googleClientId: resolveGoogleClientId(),
    );
  }
}
