import 'dart:io';

import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

main(args) {
  if (args.length == 0) {
    print('usage: dart check_updates.dart <path-to-pubspec.yaml>');
    exit(1);
  }

  var pubspec = args[0];
  var lockfile = '${path.withoutExtension(pubspec)}.lock';

  var oldLockFile = new File(lockfile);
  var oldLockContents = '';
  if (oldLockFile.existsSync()) {
    oldLockContents = oldLockFile.readAsStringSync();
  }

  var tmpDir = Directory.systemTemp.createTempSync('check_updates_');
  new File(pubspec).copySync('${tmpDir.path}/pubspec.yaml');
  var pubExec = path.join(getSdkDir().path, 'bin', 'pub');
  var res = Process.runSync(pubExec, ['upgrade'],
      workingDirectory: tmpDir.path,
      runInShell: true);
  print(res.stdout);
  print(res.stderr);
  if (res.exitCode != 0) exit(res.exitCode);
  print('-- comparing lock files --');
  var newLockContents = new File('${tmpDir.path}/pubspec.lock').readAsStringSync();
  if (oldLockContents != newLockContents) {
    print('lock file contents are different:\n');
    var oldPackages = loadYaml(oldLockContents)['packages'];
    var newPackages = loadYaml(newLockContents)['packages'];
    for (var name in oldPackages.keys) {
      var oldPackage = oldPackages[name];
      var newPackage = newPackages[name];

      // only track tip-of-tree dependencies
      if (oldPackage['source'] != 'git') continue;

      if (newPackage == null) {
        print('package $name was removed');
        continue;
      }

      var oldUrl = oldPackage['description']['url'];
      var newUrl = newPackage['description']['url'];
      var oldRef = oldPackage['description']['resolved-ref'];
      var newRef = newPackage['description']['resolved-ref'];
      if (oldUrl != newUrl) {
        print("$name's url changed:\n  from: $oldUrl\n  to:   $newUrl");
      } else if (oldRef != newRef) {
        print("$name's ref changed:\n  from: $oldRef\n  to:   $newRef");
      }
    }

    for (var name in newPackages.keys) {
      var newPackage = newPackages[name];
      if (newPackage['source'] != 'git') continue;

      if (oldPackages[name] == null || oldPackages[name]['source'] != 'git') {
        var url = newPackage['description']['url'];
        var ref = newPackage['description']['resolved-ref'];
        print('package $name was added:\n  repo: $url\n  commit: $ref');
      }
    }
    print('\nTo update the lock file, run:\n'
        '  cp ${tmpDir.path}/pubspec.lock $lockfile.');
  } else {
    print('lock file contents are the same as before.');
    tmpDir.deleteSync(recursive: true);
  }
}
