##Check updates##

A simple script to check for changes in ToT of git dependencies. This is used to
track changes when tracking tip of tree of dependencies. For example, to track
benchmarks on the latest version of every package.

Simply run the binary on a pubspec.yaml file like this:

```bash
  git clone https://github.com/sigmundch/check_updates_on_git_deps
  cd check_updates_on_git_deps
  pub get
  pub run check_updates csslib/pubspec.yaml
```

and this package will run pub-upgrade on a temporary folder, and compare the
pubspec.lock file for changes.
