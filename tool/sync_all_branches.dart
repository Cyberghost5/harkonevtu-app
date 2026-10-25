import 'dart:io';

const List<String> brandBranches = [
  'brand/dakeventures',
  'brand/idypay',
  'brand/nmilleniumresource',
  'brand/tincitybill',
];

void main(List<String> args) async {
  final commitMessage = args.isNotEmpty ? args.join(' ') : 'Update codebase';

  print('🚀 Starting Sync & Push to all branches...\n');

  // 1. Get current branch
  final currentBranchRes = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  final initialBranch = (currentBranchRes.stdout as String).trim();
  print('📌 Starting on branch: [$initialBranch]');

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

    print('\n🌿 Switching to [$branch] and merging latest [main]...');
    await Process.run('git', ['checkout', branch]);
    final mergeRes = await Process.run('git', ['merge', 'main', '-m', 'Merge latest updates from main into $branch']);
    print(mergeRes.stdout);

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
