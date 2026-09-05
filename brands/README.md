# 🏷️ Multi-Brand / Whitelabel Configuration Store

This directory stores configuration files and brand assets for each company/brand.

## Folder Structure

```
brands/
  ├── brand_config_template.txt     # Reference cheat-sheet template
  ├── company_a/
  │     ├── brand.json               # Mandatory configuration
  │     ├── logo.png                 # (Optional) Custom launcher logo
  │     ├── google-services.json     # (Optional) Custom Android Firebase config
  │     ├── key.properties          # (Optional) Company A secret keystore passwords
  │     └── upload-keystore.jks     # (Optional) Company A unique release signing key
  └── default/
        ├── brand.json
        └── logo.png
```

## `brand.json` Fields

```json
{
  "brand_id": "company_a",
  "app_name": "Company A VTU",
  "package_name": "com.companya.vtu",
  "base_url": "https://companya.com/api/v1",
  "git_branch": "brand/company_a",
  "key_alias": "companya_alias",
  "store_password": "supersecretpassword123",
  "key_password": "supersecretpassword123"
}
```

## CLI Commands

To switch configuration, generate icons, commit to Git branch, and build:

```bash
# 1. Generate unique JKS keystore & key.properties for a new brand automatically:
dart run tool/build_brand.dart company_a --gen-key

# 2. Apply config, commit, push branch to GitHub, and build release signed APK + AAB (.aab):
dart run tool/build_brand.dart company_a --push --build
```
