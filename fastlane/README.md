fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios create_app

```sh
[bundle exec] fastlane ios create_app
```

App Store Connect에 앱 등록

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

App Store 메타데이터 + 스크린샷 업로드 (심사 제출 X)

### ios finalize_app_store

```sh
[bundle exec] fastlane ios finalize_app_store
```

1.0.0 버전에 최신 빌드 attach + 카테고리 GAMES/TRIVIA 설정

### ios beta

```sh
[bundle exec] fastlane ios beta
```

TestFlight 배포

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
