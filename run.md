# 🚀 RUN & BUILD GUIDE: Harkone VTU Whitelabel Platform

This master guide contains all commands and step-by-step instructions to create new branded apps, update logos and details, sync with GitHub, and build release APKs and App Bundles (.aab) on a VPS server.

---

## 💻 PART 1: LOCAL MACHINE (Creating & Updating Brands)

Your local machine handles code editing, brand configuration, icon generation, and GitHub branch management. **No heavy Android compilation happens locally.**

### Step 1: Create Brand Directory
Create a folder inside `brands/` using your brand ID (lowercase, underscores, no spaces):

```bash
# Example for a brand named "acme_vtu":
mkdir brands/acme_vtu
```

### Step 2: Add `brand.json` & Assets

Inside `brands/acme_vtu/`, create `brand.json`:

```json
{
  "brand_id": "acme_vtu",
  "app_name": "ACME Telecom",
  "package_name": "com.acme.vtu",
  "base_url": "https://vtu.acme.com/api/v1",
  "git_branch": "brand/acme_vtu",
  "key_alias": "acme_alias",
  "store_password": "supersecretstorepassword123",
  "key_password": "supersecretkeypassword123"
}
```

#### Asset Files (Optional):
* **Custom App Icon:** Place logo image at `brands/acme_vtu/logo.png` (min 512x512 PNG).
* **Firebase Push Notifications:** Place Firebase file at `brands/acme_vtu/google-services.json`.

---

### Step 3: Run the Whitelabel CLI Command Locally

Execute the CLI tool to generate the release keystore, update native app configs, commit, and push the branch to GitHub:

```bash
dart run tool/build_brand.dart tincitybill --gen-key --push
```

> **What this command does automatically:**
> 1. Creates unique JKS keystore (`brands/acme_vtu/upload-keystore.jks`) & `key.properties`.
> 2. Creates & checks out Git branch `brand/acme_vtu`.
> 3. Updates package name (`applicationId`), app display label, and API base URL.
> 4. Regenerates native Android & iOS launcher icons from `logo.png`.
> 5. Commits all changes and pushes `brand/acme_vtu` to GitHub.

---

## 🖥️ PART 2: VPS BUILD SERVER (Building APK & AAB)

Your high-spec VPS server compiles the release binaries for distribution and Google Play Console publishing.

### Step 1: Initial VPS Setup (First Time Only)

Clone the main repository on your VPS:

```bash
git clone https://github.com/Cyberghost5/harkonevtu-app.git
cd harkonevtu-app
```

---

### Step 2: Fetch & Switch to the Brand Branch on VPS

To build for a specific brand (e.g. `tincitybill`):

```bash
# 1. Fetch latest branches from GitHub
git fetch origin

# 2. Switch to the brand branch
git checkout brand/tincitybill

# 3. Pull latest branch code
git pull origin brand/tincitybill

# 4. Install Flutter packages
flutter pub get
```

---

### Step 3: Compile Signed Release Binaries on VPS

Run the build CLI command on your VPS:

```bash
dart run tool/build_brand.dart tincitybill --build
```

---

### 📦 Output Binaries Location on VPS

Upon successful compilation, both signed binaries will be placed in:

* **Release APK (Direct Install / Testing):**
  `dist/tincitybill/app-release.apk`

* **Android App Bundle (.aab for Google Play Store):**
  `dist/tincitybill/app-release.aab`

---

## 🔄 PART 3: FUTURE CODE UPDATES & MAINTENANCE

When you update core codebase features or fix bugs on `main` in the future:

### 1. On Local Machine (Push Updates & Sync Brand Branch):

```bash
# 1. Commit and push updates to main
git checkout main
git add .
git commit -m "Added new features to core app"
git push origin main

# 2. Merge main updates into the brand branch
git checkout brand/tincitybill
git merge main
git push origin brand/tincitybill
```

### 2. On VPS (Pull & Rebuild):

```bash
git checkout brand/tincitybill
git pull origin brand/tincitybill
flutter pub get
dart run tool/build_brand.dart tincitybill --build
```

---

## 📋 COMMAND CHEAT SHEET SUMMARY

| Task | Location | Command |
| :--- | :--- | :--- |
| **New Brand Setup (Keystore + Push)** | Local | `dart run tool/build_brand.dart <brand_id> --gen-key --push` |
| **Preview Changes (Dry Run)** | Local | `dart run tool/build_brand.dart <brand_id> --dry-run` |
| **Switch Brand Branch on VPS** | VPS | `git checkout brand/<brand_id> && git pull origin brand/<brand_id>` |
| **Compile Signed APK & AAB** | VPS | `dart run tool/build_brand.dart <brand_id> --build` |
| **Sync Brand with Main Updates** | Local | `git checkout brand/<brand_id> && git merge main && git push origin brand/<brand_id>` |
