import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    printUsage();
    exit(0);
  }

  final brandId = args.firstWhere((a) => !a.startsWith('-'), orElse: () => '');
  if (brandId.isEmpty) {
    print('❌ Error: Brand ID is required.');
    printUsage();
    exit(1);
  }

  final shouldPush = args.contains('--push') || args.contains('-p');
  final shouldBuild = args.contains('--build') || args.contains('-b');
  final shouldGenKey = args.contains('--gen-key') || args.contains('-g');
  final isDryRun = args.contains('--dry-run');

  print('🚀 Starting Whitelabel Builder for Brand: [$brandId]');
  if (isDryRun) print('🔍 Running in DRY-RUN mode (no disk/git changes will be saved)');

  // 1. Locate brand configuration
  final brandDir = Directory('brands/$brandId');
  final configFile = File('${brandDir.path}/brand.json');

  if (!configFile.existsSync()) {
    print('❌ Config file not found: ${configFile.path}');
    print('   Make sure you have created the directory brands/$brandId/ with brand.json');
    exit(1);
  }

  final configJson = jsonDecode(configFile.readAsStringSync());
  final appName = configJson['app_name'] as String?;
  final packageName = configJson['package_name'] as String?;
  final baseUrl = configJson['base_url'] as String?;
  final gitBranch = (configJson['git_branch'] as String?) ?? 'brand/$brandId';

  if (appName == null || packageName == null || baseUrl == null) {
    print('❌ Invalid brand.json schema. Fields app_name, package_name, and base_url are required.');
    exit(1);
  }

  print('   App Name: $appName');
  print('   Package Name: $packageName');
  print('   Base URL: $baseUrl');
  print('   Git Branch: $gitBranch');

  // 2. Git Branch Checkout
  if (!isDryRun) {
    print('\n🌿 Switching Git Branch to: $gitBranch');
    final gitCheck = await Process.run('git', ['rev-parse', '--verify', gitBranch]);
    if (gitCheck.exitCode == 0) {
      final res = await Process.run('git', ['checkout', gitBranch]);
      print(res.stdout);
    } else {
      print('   Creating new branch: $gitBranch');
      final res = await Process.run('git', ['checkout', '-b', gitBranch]);
      print(res.stdout);
    }
  }

  // 3. Update ApiConstants.baseUrl
  final apiConstantsFile = File('lib/core/api/api_constants.dart');
  if (apiConstantsFile.existsSync()) {
    print('\n🌐 Updating API Base URL in lib/core/api/api_constants.dart');
    final newContent = '''class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: '$baseUrl',
  );
}
''';
    if (!isDryRun) apiConstantsFile.writeAsStringSync(newContent);
  }

  // 4. Update Android Package Name (build.gradle.kts)
  final gradleFile = File('android/app/build.gradle.kts');
  if (gradleFile.existsSync()) {
    print('📱 Updating Android applicationId in android/app/build.gradle.kts');
    var content = gradleFile.readAsStringSync();
    content = content.replaceAll(
      RegExp(r'applicationId\s*=\s*".*?"'),
      'applicationId = "$packageName"',
    );
    if (!isDryRun) gradleFile.writeAsStringSync(content);
  }

  // 5. Update Android App Label (AndroidManifest.xml)
  final manifestFile = File('android/app/src/main/AndroidManifest.xml');
  if (manifestFile.existsSync()) {
    print('🏷️  Updating Android app label in AndroidManifest.xml');
    var content = manifestFile.readAsStringSync();
    content = content.replaceAll(
      RegExp(r'android:label=".*?"'),
      'android:label="$appName"',
    );
    if (!isDryRun) manifestFile.writeAsStringSync(content);
  }

  // 6. Update Logo Asset if custom logo exists
  final customLogo = File('${brandDir.path}/logo.png');
  final targetLogo = File('assets/logo.png');
  if (customLogo.existsSync()) {
    print('🎨 Copying custom logo from ${customLogo.path} -> ${targetLogo.path}');
    if (!isDryRun) {
      targetLogo.parent.createSync(recursive: true);
      customLogo.copySync(targetLogo.path);
    }
  }

  // 7. Regenerate Launcher Icons
  if (!isDryRun) {
    print('🖼️  Regenerating Launcher Icons via flutter_launcher_icons...');
    final iconResult = await Process.run('dart', ['run', 'flutter_launcher_icons']);
    print(iconResult.stdout);
    if (iconResult.exitCode != 0) {
      print('⚠️ Warning: Launcher icon generation exited with code ${iconResult.exitCode}: ${iconResult.stderr}');
    }
  }

  // 8. Copy google-services.json if present
  final customFirebase = File('${brandDir.path}/google-services.json');
  final targetFirebase = File('android/app/google-services.json');
  if (customFirebase.existsSync()) {
    print('🔥 Copying Firebase google-services.json -> ${targetFirebase.path}');
    if (!isDryRun) customFirebase.copySync(targetFirebase.path);
  }

  // 8.4. Auto-generate JKS Keystore & key.properties if requested or specified in brand.json
  final keyAlias = (configJson['key_alias'] as String?) ?? '${brandId}_alias';
  final storePassword = (configJson['store_password'] as String?) ?? '${brandId}_SecretPass123!';
  final keyPassword = (configJson['key_password'] as String?) ?? storePassword;
  final brandKeystoreFile = File('${brandDir.path}/upload-keystore.jks');
  final brandKeyPropFile = File('${brandDir.path}/key.properties');

  if (shouldGenKey && !brandKeystoreFile.existsSync()) {
    print('🔑 Generating unique JKS keystore for brand [$brandId] via keytool...');
    if (!isDryRun) {
      try {
        final keytoolCmd = _findKeytoolExecutable();
        final keytoolRes = await Process.run(keytoolCmd, [
          '-genkeypair',
          '-v',
          '-keystore',
          brandKeystoreFile.path,
          '-keyalg',
          'RSA',
          '-keysize',
          '2048',
          '-validity',
          '10000',
          '-alias',
          keyAlias,
          '-storepass',
          storePassword,
          '-keypass',
          keyPassword,
          '-dname',
          'CN=$appName, OU=Mobile, O=$appName, L=Lagos, ST=Lagos, C=NG',
        ]);
        print(keytoolRes.stdout);
        if (keytoolRes.exitCode == 0) {
          print('✅ Generated JKS keystore: ${brandKeystoreFile.path}');
          brandKeyPropFile.writeAsStringSync('''storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=$keyAlias
storeFile=upload-keystore.jks
''');
          print('✅ Generated key.properties: ${brandKeyPropFile.path}');
        } else {
          print('⚠️ Keytool notice/error: ${keytoolRes.stderr}');
        }
      } catch (e) {
        print('⚠️ Notice: keytool command not in PATH ($e)');
        print('ℹ️ Generating key.properties for brand [$brandId]...');
        brandKeyPropFile.writeAsStringSync('''storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=$keyAlias
storeFile=upload-keystore.jks
''');
        print('✅ Generated key.properties: ${brandKeyPropFile.path}');
      }
    }
  }

  // 8.5. Copy unique brand Android Keystore & key.properties if present
  final customKeyProp = File('${brandDir.path}/key.properties');
  final targetKeyProp = File('android/key.properties');
  if (customKeyProp.existsSync()) {
    print('🔑 Copying unique brand key.properties -> ${targetKeyProp.path}');
    if (!isDryRun) customKeyProp.copySync(targetKeyProp.path);
  }

  // Search for any .jks files in brandDir
  final jksFiles = brandDir.listSync().whereType<File>().where((f) => f.path.endsWith('.jks') || f.path.endsWith('.keystore'));
  for (final jks in jksFiles) {
    final fileName = jks.path.split(Platform.pathSeparator).last;
    final targetJks = File('android/app/$fileName');
    print('🔐 Copying unique brand keystore [${jks.path}] -> [${targetJks.path}]');
    if (!isDryRun) jks.copySync(targetJks.path);
  }

  // 9. Git Commit & Push
  if (!isDryRun) {
    print('\n📦 Staging and Committing Brand Configuration...');
    await Process.run('git', ['add', '.']);
    final commitRes = await Process.run('git', ['commit', '-m', 'Configure white-label brand: $appName ($packageName)']);
    print(commitRes.stdout);

    if (shouldPush) {
      print('⬆️  Pushing branch [$gitBranch] to GitHub...');
      final pushRes = await Process.run('git', ['push', '-u', 'origin', gitBranch]);
      print(pushRes.stdout);
      if (pushRes.exitCode != 0) {
        print('⚠️  Git push error: ${pushRes.stderr}');
      }
    }
  }

  // 10. Optional Release Build (APK + AAB)
  if (shouldBuild && !isDryRun) {
    final distDir = Directory('dist/$brandId');
    distDir.createSync(recursive: true);

    print('\n🛠️  Building Flutter Release APK...');
    final buildApkRes = await Process.run('flutter', ['build', 'apk', '--release']);
    print(buildApkRes.stdout);

    if (buildApkRes.exitCode == 0) {
      final apkSource = File('build/app/outputs/flutter-apk/app-release.apk');
      if (apkSource.existsSync()) {
        final distApk = File('${distDir.path}/app-release.apk');
        apkSource.copySync(distApk.path);
        print('✅ Compiled APK saved to: ${distApk.path}');
      }
    } else {
      print('❌ APK Build failed: ${buildApkRes.stderr}');
    }

    print('\n📦 Building Flutter Android App Bundle (.aab) for Play Store...');
    final buildAabRes = await Process.run('flutter', ['build', 'appbundle', '--release']);
    print(buildAabRes.stdout);

    if (buildAabRes.exitCode == 0) {
      final aabSource = File('build/app/outputs/bundle/release/app-release.aab');
      if (aabSource.existsSync()) {
        final distAab = File('${distDir.path}/app-release.aab');
        aabSource.copySync(distAab.path);
        print('✅ Compiled AAB saved to: ${distAab.path}');
      }
    } else {
      print('❌ AAB Build failed: ${buildAabRes.stderr}');
    }
  }

  print('\n✨ Whitelabel configuration completed successfully for [$appName]!');
}

void printUsage() {
  print('''
🏷️  Whitelabel Brand Builder CLI

Usage:
  dart run tool/build_brand.dart <brand_id> [options]

Options:
  -g, --gen-key  Generate unique JKS keystore & key.properties for the brand automatically
  -p, --push     Commit and push brand branch to GitHub
  -b, --build    Build signed release APK & Android App Bundle (.aab) for Google Play Store
  --dry-run      Preview changes without modifying files or Git
  -h, --help     Show this help message

Examples:
  dart run tool/build_brand.dart company_a --gen-key
  dart run tool/build_brand.dart company_a --gen-key --push --build
''');
}

String _findKeytoolExecutable() {
  if (Platform.isWindows) {
    final javaHome = Platform.environment['JAVA_HOME'];
    if (javaHome != null && javaHome.isNotEmpty) {
      final keytoolInJavaHome = File('$javaHome\\bin\\keytool.exe');
      if (keytoolInJavaHome.existsSync()) return keytoolInJavaHome.path;
    }

    final commonPaths = [
      r'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe',
      r'C:\Program Files\Android\Android Studio\jre\bin\keytool.exe',
      r'C:\Program Files\Java\jdk-17\bin\keytool.exe',
      r'C:\Program Files\Java\jdk-21\bin\keytool.exe',
      r'C:\Program Files\Java\jdk1.8.0_301\bin\keytool.exe',
    ];

    for (final p in commonPaths) {
      if (File(p).existsSync()) return p;
    }
  }
  return 'keytool';
}
