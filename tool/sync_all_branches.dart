import 'dart:convert';
import 'dart:io';

const List<String> brandBranches = [
  'brand/dakeventures',
  'brand/idypay',
  'brand/nmilleniumresource',
  'brand/tincitybill',
];

void applyBrandConfig(String brandId) {
  final brandDir = Directory('brands/$brandId');
  final configFile = File('${brandDir.path}/brand.json');
  if (!configFile.existsSync()) return;

  final config = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
  final baseUrl = config['base_url'] as String? ?? '';
  final packageName = config['package_name'] as String? ?? '';
  var googleClientId = config['google_server_client_id'] as String? ?? '';

  // Extract from google-services.json if not present in brand.json
  if (googleClientId.trim().isEmpty) {
    final gsFile = File('${brandDir.path}/google-services.json');
    if (gsFile.existsSync()) {
      try {
        final gs = jsonDecode(gsFile.readAsStringSync());
        final clients = gs['client'] as List<dynamic>?;
        if (clients != null && clients.isNotEmpty) {
          final oauthList = clients.first['oauth_client'] as List<dynamic>?;
          if (oauthList != null) {
            for (final oc in oauthList) {
              if (oc['client_type'] == 3 && oc['client_id'] != null) {
                googleClientId = oc['client_id'].toString().trim();
                break;
              }
            }
          }
        }
      } catch (_) {}
    }
  }

  // 1. Update ApiConstants
  final apiConstantsFile = File('lib/core/api/api_constants.dart');
  if (apiConstantsFile.existsSync()) {
    apiConstantsFile.writeAsStringSync('''class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: '$baseUrl',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '$googleClientId',
  );
}
''');
  }

  // 2. Update build.gradle.kts applicationId
  final gradleFile = File('android/app/build.gradle.kts');
  if (gradleFile.existsSync() && packageName.isNotEmpty) {
    var content = gradleFile.readAsStringSync();
    content = content.replaceAll(
      RegExp(r'applicationId\s*=\s*".*?"'),
      'applicationId = "$packageName"',
    );
    gradleFile.writeAsStringSync(content);
  }

  // 3. Copy brand google-services.json to android/app/google-services.json
  final brandGoogleServices = File('${brandDir.path}/google-services.json');
  final targetGoogleServices = File('android/app/google-services.json');
  if (brandGoogleServices.existsSync()) {
    brandGoogleServices.copySync(targetGoogleServices.path);
  }
}

void main(List<String> args) async {
  final commitMessage = args.isNotEmpty ? args.join(' ') : 'Update codebase';

  print('🚀 Starting Sync & Push to all branches...\n');

  // 1. Get current branch
  final currentBranchRes = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  final initialBranch = (currentBranchRes.stdout as String).trim();
  print('📌 Starting on branch: [$initialBranch]');

  // Ensure current branch configuration is aligned if it's a brand branch
  if (initialBranch.startsWith('brand/')) {
    final brandId = initialBranch.replaceFirst('brand/', '');
    applyBrandConfig(brandId);
  }

  // 2. Check if working tree has changes
  final statusRes = await Process.run('git', ['status', '--porcelain']);
  final hasChanges = (statusRes.stdout as String).trim().isNotEmpty;

  if (hasChanges) {
    print('📦 Staging and committing changes on [$initialBranch] with message: "$commitMessage"...');
    await Process.run('git', ['add', '.']);
    final commitRes = await Process.run('git', ['commit', '-m', commitMessage]);
    print(commitRes.stdout);
  }

  // 3. Push current branch if ahead
  print('⬆️  Pushing [$initialBranch] to origin...');
  await Process.run('git', ['push', 'origin', initialBranch]);

  // 4. Update main
  if (initialBranch != 'main') {
    print('\n🌿 Switching to main and merging updates from [$initialBranch]...');
    await Process.run('git', ['checkout', 'main']);
    await Process.run('git', ['merge', initialBranch, '-m', 'Merge updates from $initialBranch into main']);
    print('⬆️  Pushing main to origin...');
    await Process.run('git', ['push', 'origin', 'main']);
  }

  // 5. Merge main into every brand branch and push
  for (final branch in brandBranches) {
    if (branch == initialBranch) continue;

    final brandId = branch.replaceFirst('brand/', '');
    print('\n🌿 Switching to [$branch] and merging latest [main]...');
    await Process.run('git', ['checkout', branch]);
    final mergeRes = await Process.run('git', ['merge', 'main', '-m', 'Merge latest updates from main into $branch']);
    print(mergeRes.stdout);

    // Enforce brand config integrity after merge
    applyBrandConfig(brandId);

    // Commit any brand adjustments
    final branchStatus = await Process.run('git', ['status', '--porcelain']);
    if ((branchStatus.stdout as String).trim().isNotEmpty) {
      await Process.run('git', ['add', '.']);
      await Process.run('git', ['commit', '-m', 'Apply brand-specific config for $brandId']);
    }

    print('⬆️  Pushing [$branch] to origin...');
    final pushRes = await Process.run('git', ['push', 'origin', branch]);
    if (pushRes.exitCode != 0) {
      print('⚠️ Push warning: ${pushRes.stderr}');
    } else {
      print('✅ [$branch] updated and pushed.');
    }
  }

  // 6. Return to initial branch
  print('\n🔄 Returning to initial branch [$initialBranch]...');
  await Process.run('git', ['checkout', initialBranch]);

  print('\n✨ All branches successfully synchronized and pushed to GitHub!');
}
