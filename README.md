# LogMyDailyTask

개인 업무를 체크인으로 기록하고 주간 단위로 확인하는 로컬 우선 앱입니다.
체크인에서 업무를 입력하고 **체크인 저장**을 누르면 현재 날짜와 시각으로 기록됩니다.
저장한 업무는 주간 화면에 바로 표시되며 앱을 다시 열어도 남습니다.
평일을 기본으로 표시하고 주말 기록이 있는 주에는 주말도 표시합니다.
앱은 기기의 언어와 시간대를 따릅니다.
데스크톱과 모바일에서는 SQLCipher로 로컬 DB를 암호화하고 키는 OS 보안 저장소에 보관합니다.
웹에서는 브라우저의 해당 사이트 저장소를 사용합니다.

## 작업 시간과 내보내기

- 체크인에서 **작업 시작·종료 시간 지정**을 펼치면 날짜, 시각, IANA 시간대를 선택할 수 있습니다. 시간은 UTC로 저장되며, 주간 기록의 시간 구간은 선택한 시간대로 표시됩니다.
- 업무 제목을 입력하면 최근 7일 기록에서 추천합니다. 한글 초성과 이전 기록 검색도 지원합니다.
- 주간 화면에서 날짜 범위를 선택해 CSV를 내보낼 수 있습니다. 새 기록에는 저장 플랫폼이 표시됩니다.

## 자동 체크인

주간 화면 오른쪽 위의 시계 아이콘에서 근무 요일과 시작·종료 시각, 체크인 간격을 설정합니다.
간격은 5~120분 범위에서 5분 단위로 선택할 수 있습니다. 설정은 앱을 다시 열어도 유지됩니다.
기본값은 월~금 09:00~18:00, 30분 간격입니다.

근무 시간 안의 완전한 구간이 끝나면 알림이 표시됩니다. 예를 들어 09:00 시작에
30분 간격이면 첫 알림은 09:30입니다. 근무 시작 시각 기준 정렬과 기기별 알림 끄기도 지원합니다.

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

- **macOS / Windows**: Desktop OAuth 클라이언트를 만든 뒤 `--dart-define=GOOGLE_SHEETS_CLIENT_ID=… --dart-define=GOOGLE_SHEETS_CLIENT_SECRET=…`를 Flutter 실행 또는 빌드 명령에 전달합니다. Desktop OAuth 클라이언트에는 서버용 비밀 키를 사용하지 마세요.
- **Android**: 앱 패키지와 서명 인증서 SHA-1을 등록한 Android 클라이언트를 만들고 같은 프로젝트의 Web OAuth 클라이언트 ID를 `--dart-define=GOOGLE_SHEETS_SERVER_CLIENT_ID=…`로 전달합니다.
- **iOS**: 앱 번들 ID로 iOS OAuth 클라이언트를 등록하고 `GOOGLE_SHEETS_IOS_CLIENT_ID`와 `GOOGLE_SHEETS_SERVER_CLIENT_ID`를 dart-define으로 전달합니다. 로컬 파일 `ios/Flutter/GoogleSheets.local.xcconfig`에 `GOOGLE_SHEETS_IOS_REVERSED_CLIENT_ID = com.googleusercontent.apps.…`를 설정합니다.
- **웹**: Google Sheets 로그인이 아직 지원되지 않습니다.

주간 화면의 구름 아이콘에서 기기 이름을 설정하고 로그인합니다. 표시된 계정을 확인하고 시트를 만듭니다. 다른 기기에서도 같은 시트를 선택하면 각 기기의 기록이 모입니다. 앱은 기록을 저장할 때와 실행 중 5분마다 동기화를 시도합니다. 주간 화면과 CSV에서 동기화 상태를 확인할 수 있습니다.

연동은 `drive.file`과 계정 확인용 범위를 사용합니다. 다른 기기에서 가져온 기록은 읽기 전용입니다. Google Cloud OAuth 값이나 로컬 설정 파일은 저장소에 커밋하지 않습니다.
