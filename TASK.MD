# MASTER PROMPT: Dynamic Flutter Mobile Application for Harkone VTU Platform

## 🎯 Role & Objective
You are an elite Senior Mobile Engineer specializing in Flutter (Dart) and Android Studio development. Your objective is to build a state-of-the-art, production-ready mobile application for iOS & Android.

The backend is fully built, tested, and live using Laravel Sanctum REST APIs. All API endpoints strictly enforce a standardized JSON response contract:
- Success: `{ "status": true, "message": "...", "data": { ... } }`
- Error: `{ "status": false, "message": "...", "errors": { ... } }`
- Authorization: `Authorization: Bearer <sanctum_token>`
- Base URL: `https://nmilleniumresource.com.ng/api/v1`
- API Reference Source:** Refer to the attached `hoppscotch-team-collections-openapi.json.json` as the single source of truth for all exact endpoint URIs, HTTP methods, required headers, request payloads, and JSON response schemas.

---

## 🎨 Design System & Aesthetics Guidelines (MUST OBEY)



## 🎨 100% DYNAMIC BRANDING & THEME ENGINE (CRITICAL RULE)
Do NOT hardcode default theme colors, app names, static logos, or service toggles in the mobile app codebase! 

On app startup (`SplashScreen`), the mobile app MUST call **`GET /api/v1/app-config`** and dynamically initialize the entire application state:
1. **Dynamic Theme Color:** Parse `data.theme_color` (hex string e.g. `#4caf50` or `#4f46e5`) and apply it dynamically to `ThemeData` primary accent, buttons, active tabs, and highlights. Build a stunning, modern dark-mode aesthetic with sleek glassmorphism panels, subtle border glows, and curated color palettes from the config endpoint.
2. **Dynamic Branding & Logos:** Set app title from `data.app_name` / `data.site_name`, and fetch logo/favicon images dynamically from `data.logo1_url`, `data.logo2_url`, and `data.favicon_url`.
3. **Currency & Formatting:** Use `data.currency_symbol` (`₦`) and `data.currency` (`NGN`) across all price tags and inputs.
4. **Service Feature Toggles:** Dynamically enable or hide service cards based on `data.services` (`airtime`, `data`, `electricity`, `cable`, `epin`, `betting`, `airtime_to_cash`, `recharge_card_printing`, `card_payment`, `auto_bank_transfer`, `manual_bank_transfer`, `coupon_funding`).
5. **App Versioning & Maintenance Control:** 
   - If `data.maintenance_mode` is `true`, redirect immediately to a Maintenance Screen displaying `data.maintenance_message`.
   - If `data.force_update` is `true` and current app version is lower than `data.min_version`, lock screen with a Play Store / App Store update prompt.
6. **Support & Community Links:** Use `data.support` details (`phone`, `whatsapp`, `email`, `hours`, `whatsapp_group`, `telegram_channel`).
7. **Visual Excellence:** Build a stunning, modern dark-mode aesthetic with sleek glassmorphism panels, subtle border glows, and curated color palettes based on the color from the config endpoint.
   - Typography: Clean Google Fonts (`Outfit` or `Inter`)
8. **Dynamic UI & Micro-Animations:**
   - Smooth page transitions, shimmer loading skeletons, 60fps/120fps animations.
   - Interactive balance toggle (Hide/Show wallet balance with smooth blur effect).
   - Instant 1-tap copy buttons with haptic feedback toasts for virtual bank account numbers and electricity tokens.
9. **Zero Placeholder Policy:** Never use raw generic text or broken image placeholders. Handle non-image fallback vectors cleanly.

---

## ⚙️ Core Architecture & Requirements
- **State Management:** Provider / Riverpod / Bloc
- **Networking:** Dio HTTP client with interceptors:
  - Header: `Accept: application/json`, `Content-Type: application/json`
  - Auth Interceptor: Automatically attach `Authorization: Bearer <sanctum_token>` for authenticated routes.
  - 401 Expiry Interceptor: Clear token and navigate to Login upon token expiration.
- **Secure Storage:** `flutter_secure_storage` for Sanctum tokens, user credentials, and biometric settings.
- **Security:** `local_auth` for Fingerprint / FaceID authentication and 4-digit Transaction PIN bottom-sheet confirmation.
- **Receipt Exporter:** `widgets_to_image` or `pdf` / `printing` for shareable receipt cards.

---

## 🔄 Milestone-Driven Execution Strategy
We will build this mobile application strictly step-by-step in **6 Sequential Milestones**. 
- Complete one milestone at a time.
- Present progress, code files, and verification steps before proceeding to the next milestone.

---

### 🚀 MILESTONE 1: Project Setup, Dynamic Theme Engine, Config & Onboarding
**Goal:** Initialize project structure, set up network layer, secure storage, dynamic theme configuration from API, and dynamic onboarding screens.
1. Create clean folder structure:
   - `lib/core/` (api, constants, storage, routes, theme)
   - `lib/models/` (JSON models)
   - `lib/providers/` (State Management)
   - `lib/views/` (UI Screens)
2. Configure `Dio` API client with interceptors for `Bearer` tokens and JSON headers.
3. Build `SplashScreen` & `ThemeProvider`:
   - Call `GET /api/v1/app-config` on launch.
   - Parse `theme_color`, `app_name`, `logo1_url`, `logo2_url`, `services`, `payment_gateways`, and `support`.
   - Check `maintenance_mode` and `force_update`.
4. Build `OnboardingScreen`:
   - Parse `data.onboarding_slides` returned by `GET /api/v1/app-config` (or `GET /api/v1/onboarding`).
   - Swipeable page carousel with slide titles, descriptions, vector illustrations, and "Skip" / "Get Started" buttons.

---

### 🔑 MILESTONE 2: Authentication & Session Management
**Goal:** Build user registration, login, OTP verification, password recovery, and secure session state.
1. Build `LoginScreen`:
   - Input validation (Email/Phone + Password).
   - Call `POST /api/v1/auth/login`. Store Sanctum token securely in `flutter_secure_storage`.
   - Option for Fingerprint / FaceID biometric quick login if enabled.
2. Build `RegisterScreen`:
   - Full Name, Username, Email, Phone Number, Password, and optional Referral Code (`POST /api/v1/auth/register`).
3. Build `OtpVerificationScreen`:
   - 6-digit OTP input, countdown timer, resend button (`POST /api/v1/auth/verify-otp` and `POST /api/v1/auth/resend-otp`).
4. Build `ForgotPasswordScreen` & `ResetPasswordScreen`:
   - Account recovery via OTP (`POST /api/v1/auth/forgot-password` and `POST /api/v1/auth/reset-password`).

---

### 🏠 MILESTONE 3: Main Shell, Bottom Navigation & Home Dashboard
**Goal:** Build bottom navigation shell and dynamic Home Dashboard.
1. Build `MainNavigationShell`: Bottom navigation bar using the dynamic `theme_color` for active items (Home, Services, Wallet, Profile).
2. Build `HomeDashboardView`:
   - **Header Bar:** Dynamic `logo1_url` / `app_name`, user greeting, and notification icon.
   - **Wallet Glass Card:** Display wallet balance with Eye Toggle (Show/Hide ₦ Balance) using dynamic `currency_symbol` and "Fund Wallet" button.
   - **Virtual Account Card (DVA):** Display Monnify/Wema bank account number with 1-tap Copy button.
   - **Dynamic Quick Actions Grid:** Render service shortcut icons based on API feature toggles (`data.services`).
   - **Recent Transactions Feed:** Show latest 5 transactions with status badges and tap-to-view receipt modal.

---

### 📶 MILESTONE 4: VTU Core Services (Airtime & Data)
**Goal:** Build Airtime purchase flow with automatic network lookup and Data bundle selection.
1. Build `AirtimeTopupScreen`:
   - Network Selector Cards (MTN, Airtel, Glo, 9mobile).
   - Auto-Network Lookup: As user types phone number, call `POST /api/v1/airtime/network-lookup` to auto-select network.
   - Amount selection chips and custom input.
   - Transaction PIN bottom-sheet modal before calling `POST /api/v1/airtime/purchase`.
2. Build `DataBundlesScreen`:
   - Network selector & Data Type Tabs (SME, Gifting, Corporate Gifting).
   - Query `GET /api/v1/data/plans?network={network_key}`. Display plan cards (Data Volume, Validity, Price).
   - Transaction PIN confirmation modal before calling `POST /api/v1/data/purchase`.

---

### 💡 MILESTONE 5: Bills & Utilities (Electricity, Cable TV & Exam Pins)
**Goal:** Build bill payment services with account/meter validation.
1. Build `ElectricityBillsScreen`:
   - Disco provider dropdown fetched from `GET /api/v1/bills/electricity/discos`.
   - Meter type toggle (Prepaid vs Postpaid).
   - Meter validation: Call `POST /api/v1/bills/electricity/validate-meter` and display verified customer name.
   - Purchase execution (`POST /api/v1/bills/electricity/purchase`) with PIN verification. Display generated Token string with 1-tap Copy button.
2. Build `CableTvScreen`:
   - Provider tabs (DSTV, GOtv, StarTimes, Showmax).
   - Smartcard validation (`POST /api/v1/bills/cable/validate-smartcard`).
   - Package plan selector (`GET /api/v1/bills/cable/plans?provider={provider}`) and purchase flow (`POST /api/v1/bills/cable/purchase`).
3. Build `ExamPinsScreen`:
   - WAEC, NECO, NABTEB pin purchase (`POST /api/v1/bills/exam-pins/purchase`). Display PIN & serial numbers.

---

### 🚀 MILESTONE 6: Specialized Services, Wallet Funding, Profile & Shareable Receipts
**Goal:** Complete betting, voucher printing, airtime-to-cash, wallet funding, profile settings, and receipt exporter.
1. Build `BettingTopupScreen`: Platform list (`GET /api/v1/betting/platforms`), account validation (`POST /api/v1/betting/validate-account`), and funding (`POST /api/v1/betting/fund`).
2. Build `VoucherPrintingScreen`: Generate physical recharge/data card pins and batch serial numbers (`POST /api/v1/vouchers/generate`).
3. Build `AirtimeToCashScreen`: View conversion settings (`GET /api/v1/airtime-to-cash/settings`), submit transfer request (`POST /api/v1/airtime-to-cash/submit`).
4. Build `WalletFundingScreen`:
   - Tab 1: Virtual Bank Accounts (Monnify DVA list with 1-tap copy buttons from `GET /api/v1/payments/dva-accounts`).
   - Tab 2: Online Card Payment (Paystack popup using `paystack_public_key` from config & `POST /api/v1/payments/initialize`).
   - Tab 3: Coupon Code Redemption (`POST /api/v1/payments/redeem-coupon`).
5. Build `Profile & Security Settings`:
   - Profile view, update info, change password, update 4-digit transaction PIN, submit KYC documents (`POST /api/v1/kyc/submit`), view Referral link/earnings (`GET /api/v1/referrals/summary`), and contact support (`GET /api/v1/support/contact`).
6. Build `Shareable Receipt Modal / Exporter`:
   - Render receipt cards with dynamic logo, transaction reference, date, status, recipient, and amount, downloadable as PNG image or PDF.

---

### 🔔 MILESTONE 7: Push Notifications & Background System Alerts (FCM / Local Notifications)
**Goal:** Integrate system-level push notifications and background tray alerts for real-time transaction updates, wallet funding alerts, and admin announcements.
1. Integrate `firebase_messaging` / `flutter_local_notifications` packages.
2. Register FCM device token on login (`POST /api/v1/user/device-token`).
3. Handle foreground notifications, background message handlers, and interactive system notification clicks.

---

## 📁 ATTACHMENTS & REFERENCE DOCUMENTS
- **Postman Collection File:** Attach `hoppscotch-team-collections-openapi.json`.
- **Interactive Documentation URL:** `https://nmilleniumresource.com.ng/api/docs`

---

## 🚦 Begin Task Execution
Start right now by acknowledging this master prompt and reading the attached `hoppscotch-team-collections-openapi.json`. Begin with **MILESTONE 1**: set up the Flutter project architecture, Dio API client, secure storage, `ThemeProvider` parsing dynamic `theme_color` & `app_name` from `GET /api/v1/app-config`, and dynamic `OnboardingScreen`.

Let's begin!
