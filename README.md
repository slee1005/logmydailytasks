# LogMyDailyTask

개인 업무를 체크인으로 기록하고 주간 단위로 확인하는 로컬 우선 앱입니다.
체크인에서 업무를 입력하고 **체크인 저장**을 누르면 현재 날짜와 시각으로 기록됩니다.
Daily Worklog에는 오늘 기록이 최신순으로 표시됩니다. **Add entry / 기록 추가**로 입력하고, 목록에서는 시간·디바이스·동기화 상태·업무 제목을 확인합니다. 노트와 카테고리는 **+**로 펼칩니다. 완료된 업무는 iOS와 macOS 모두 시작·종료 시간만 표시합니다. 날짜 카드에서 좌우로 스와이프하거나 화살표를 눌러 하루씩 이동할 수 있습니다. 월간 달력에서 날짜를 누르면 그날의 기록을 볼 수 있습니다. **카테고리 관리**에서 이 기기의 카테고리 이름을 바꾸거나 삭제할 수 있으며, 기존 체크인에는 저장 당시의 카테고리 이름이 표시됩니다.
앱은 기기의 언어와 시간대를 따릅니다.
데스크톱과 모바일에서는 SQLCipher로 로컬 DB를 암호화하고 키는 OS 보안 저장소에 보관합니다.
웹에서는 브라우저의 해당 사이트 저장소를 사용합니다.

## 작업 시간과 내보내기

- 체크인에서 **작업 시작·종료 시간 지정**을 펼치면 날짜, 시각, IANA 시간대를 선택할 수 있습니다. 시간은 UTC로 저장되며, 주간 기록의 시간 구간은 선택한 시간대로 표시됩니다.
- 체크인에서 최근 48시간의 업무를 버튼으로 선택할 수 있습니다. 업무 제목이나 한글 초성을 입력하면 해당 기간의 추천을 검색합니다.
- 새 기록을 저장하면 같은 기기의 바로 이전 미종료 업무를 새 기록의 시작 시각으로 종료합니다. 다른 기기에서 가져온 기록은 변경하지 않습니다.
- 리포트에서 날짜 범위를 선택해 CSV를 내보낼 수 있습니다. Mac에서는 저장을 누르면 다운로드 폴더에 바로 저장되며, 같은 이름의 파일이 있으면 번호를 붙입니다. 새 기록에는 저장 플랫폼이 표시됩니다.

## Mac에 설치

[GitHub Releases](https://github.com/slee1005/logmydailytasks/releases/latest)에서 Apple silicon용 `LogMyDailyTask-macOS.dmg`를 열고 앱을 Applications 폴더로 드래그하세요. 공개 빌드는 Apple 공증을 받지 않았으며 Google Sheets 로그인 설정이 포함되어 있지 않습니다.

Google Sheets 연동이 필요하면 App Store/TestFlight 빌드를 사용하세요. Store 빌드는 앱 전용 Data Protection Keychain을 사용하고 기존 DB 키를 보존해 이관합니다. 공개 DMG는 프로비저닝 프로필 없이 동작하도록 기존 파일 기반 macOS Keychain을 사용합니다. 기존 DB의 키가 없거나 접근이 거부되면 새 키로 덮어쓰지 않습니다.

앱은 시작할 때와 실행 중 6시간마다 새 버전을 확인합니다. 알림의 **다운로드**를 눌러 새 DMG를 받은 뒤 Applications의 앱을 교체할 수 있습니다.

## 자동 체크인

주간 화면 오른쪽 위의 시계 아이콘에서 근무 요일과 시작·종료 시각, 체크인 간격을 설정합니다.
간격은 5~120분 범위에서 5분 단위로 선택할 수 있습니다. 설정은 앱을 다시 열어도 유지됩니다.
기본값은 월~금 09:00~18:00, 30분 간격입니다. 체크인 알림을 끄면 즉시 적용되고 예약 알림이 취소됩니다.

근무 시간 안의 완전한 구간이 끝나면 알림이 표시됩니다. 예를 들어 09:00 시작에
30분 간격이면 첫 알림은 09:30입니다. 짧은 근무 시간에 정각 기준 구간이 없으면 종료 시각에 한 번 알립니다.

- **Android·iOS·macOS**에서는 일정을 켠 상태로 저장하고 OS 알림 권한을 허용하면
  앱이 백그라운드에 있거나 종료된 뒤에도 예약된 알림이 표시됩니다. 알림을 누르면 체크인 화면이 열립니다.
- macOS에서 알림을 테스트할 때는 빌드한 `.app`을 `~/Applications` 또는 `/Applications`에 복사해 열고,
  **시스템 설정 → 알림 → LogMyDailyTask**에서 허용 여부를 확인하세요.
  임시 빌드 경로에서 실행하면 macOS가 앱의 알림 권한 요청을 거부할 수 있습니다.
- 한 번에 가까운 알림을 최대 60개 예약합니다. 앱이 다시 활성화되면 예약을 보충합니다.
  60개를 모두 소진한 상태에서는 앱을 다시 열어야 이후 알림이 예약됩니다.
- Android에서는 알림 권한과 함께 정확한 알람 권한을 허용하면 더 정확하게 전달됩니다.
  권한을 허용하지 않으면 전달이 늦어질 수 있습니다. 시스템 설정에서 앱을 강제 종료하면 앱을 다시 열어야 합니다.
- 웹과 Windows에서는 앱이 활성 상태일 때 앱 안에서 알림이 표시됩니다.

## 개발 환경

iPhone 앱은 iOS 26.0 이상에서 설치할 수 있습니다.

Flutter stable 3.50.0을 사용합니다. macOS 또는 Chrome에서 실행하려면 다음 명령을 사용하세요.

```sh
flutter pub get
flutter run -d macos
bash tool/setup_web_storage.sh
flutter run -d chrome --web-port=7357
```

웹에서 다시 실행할 때는 같은 브라우저 프로필과 주소·포트를 사용하세요.
DB 스키마 변경 후 `dart run build_runner build`로 Drift 코드를 갱신합니다.

`flutter analyze`와 `flutter test`로 정적 분석과 위젯 테스트를 실행합니다.

요구사항과 개발 순서는 [한국어 PRD](docs/LogMyDailyTask_PRD_ko.md),
[English PRD](docs/LogMyDailyTask_PRD_en.md),
[개발 가이드](docs/LogMyDailyTask_DEV_GUIDE.md)를 참고하세요.

## Google Sheets 동기화

Google Cloud 프로젝트에서 Sheets API와 Drive API를 활성화하고 OAuth 동의 화면과 테스트 사용자를 설정합니다. 여러 기기에서 같은 Cloud 프로젝트의 OAuth 클라이언트와 같은 Google 계정을 사용하세요.

- **macOS 공개판용 Google 로그인**: macOS용 Google Sign-In SDK가 앱 번들에 등록된 공개 클라이언트 ID와 콜백 URL을 사용합니다. Xcode에서 Runner Release의 Keychain Sharing을 설정하고 `Runner/GoogleSignInRelease.entitlements`를 사용해 서명한 뒤, Flutter 빌드에 `--dart-define=WORKLOG_MAC_GOOGLE_SIGN_IN=true`를 전달합니다. 배포 전 실제 Google 계정으로 로그인하고 시트 쓰기와 앱 재실행 후 세션 복원을 확인해야 합니다. 배포용 앱은 외부 네트워크 연결 권한만 사용합니다. App Store에 올리기 전에 서명된 앱에 `com.apple.security.network.server`가 없는지 확인하세요.
- **macOS / Windows 로컬 개발**: Desktop OAuth 클라이언트를 만든 뒤 `--dart-define=GOOGLE_SHEETS_CLIENT_ID=… --dart-define=GOOGLE_SHEETS_CLIENT_SECRET=…`를 로컬 Flutter 디버그 실행 명령에 전달할 수 있습니다. 이 설정이 적용된 빌드를 공개 배포하지 마세요.
- **Android**: 앱 패키지와 서명 인증서 SHA-1을 등록한 Android 클라이언트를 만들고 같은 프로젝트의 Web OAuth 클라이언트 ID를 `--dart-define=GOOGLE_SHEETS_SERVER_CLIENT_ID=…`로 전달합니다.
- **iOS**: 앱 번들 ID로 iOS OAuth 클라이언트를 등록하고 `GOOGLE_SHEETS_IOS_CLIENT_ID`를 dart-define으로 전달합니다. App Store ID는 비워 둘 수 있습니다. 사용자는 앱에서 본인의 Google 계정으로 로그인하고 Sheets 접근을 허용합니다. 로컬 파일 `ios/Flutter/GoogleSheets.local.xcconfig`에 `GOOGLE_SHEETS_IOS_REVERSED_CLIENT_ID = com.googleusercontent.apps.…`를 설정합니다.
- **웹**: Google Sheets 로그인이 아직 지원되지 않습니다.

주간 화면의 구름 아이콘에서 기기 이름을 설정하고 로그인합니다. 표시된 계정을 확인하고 시트를 만듭니다. 다른 기기에서도 같은 시트를 선택하면 각 기기의 기록이 모입니다. 앱은 기록을 저장할 때와 실행 중 5분마다 동기화를 시도합니다. 주간 화면과 CSV에서 동기화 상태를 확인할 수 있습니다.

연결 화면에서 현재 시트의 링크를 열 수 있습니다. 시트의 날짜·시작·종료·수정 시각은 실제 날짜/시간 값으로, Minutes는 실제 시간 차이에서 계산한 숫자로 저장합니다. 새 시트를 만들 때 `LogMyDailyTask`가 이미 있으면 `_v001`, `_v002`처럼 사용 가능한 이름을 선택해 기존 파일을 보존합니다.

연동은 `drive.file`과 계정 확인용 범위를 사용하며, 새 파일 이름을 확인할 때 `drive.metadata.readonly` 동의를 요청합니다. 다른 기기에서 가져온 기록은 읽기 전용입니다. OAuth 클라이언트 비밀키, 서명 키, 로컬 인증 설정 파일은 저장소에 커밋하지 않습니다. 네이티브 앱의 공개 OAuth 클라이언트 ID는 빌드에 포함될 수 있습니다.

## 릴리스

`pubspec.yaml`의 버전과 일치하는 `v*` 태그를 사용합니다. 현재 소스 버전은 `0.2.3+10`이며, 플랫폼별 Store 빌드 번호는 별도로 관리할 수 있습니다. 변경 사항은 [CHANGELOG](CHANGELOG.md)에 정리합니다.

공개 macOS DMG는 `bash tool/package_macos.sh v0.2.3`으로 만듭니다. 태그를 푸시하면 GitHub Actions가 같은 명령으로 DMG를 만들고 릴리스에 추가합니다. 이미 만든 릴리스의 설명과 Android APK 등 다른 첨부 파일은 유지합니다. Android APK와 Apple Store 빌드는 로컬 서명 설정으로 생성하고, 인증 정보는 커밋하지 않습니다.
