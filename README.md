# LogMyDailyTask

개인 업무를 체크인으로 기록하고 주간 단위로 확인하는 로컬 우선 앱입니다.
체크인에서 업무를 입력하고 **체크인 저장**을 누르면 현재 날짜와 시각으로 기록됩니다.
저장한 업무는 주간 화면에 바로 표시되며 앱을 다시 열어도 남습니다.
평일을 기본으로 표시하고 주말 기록이 있는 주에는 주말도 표시합니다.
앱은 기기의 언어와 시간대를 따릅니다.
데스크톱과 모바일에서는 SQLCipher로 로컬 DB를 암호화하고 키는 OS 보안 저장소에 보관합니다.
웹에서는 브라우저의 해당 사이트 저장소를 사용합니다.

## 자동 체크인

주간 화면 오른쪽 위의 시계 아이콘에서 근무 요일과 시작·종료 시각, 체크인 간격을 설정합니다.
간격은 5~120분 범위에서 5분 단위로 선택할 수 있습니다. 설정은 앱을 다시 열어도 유지됩니다.
기본값은 월~금 09:00~18:00, 30분 간격입니다.

알림은 앱이 열려 있고 활성 상태일 때 근무 시간 안의 완전한 구간이 끝나면 앱 안에 표시됩니다.
예를 들어 09:00 시작에 30분 간격이면 첫 알림은 09:30에 표시됩니다.
알림의 **체크인**을 누르면 입력 화면이 열립니다.
근무 시작 시각에 맞춰 구간을 계산하거나, 기기별로 알림을 끌 수 있습니다.

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
