import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// 앱 이름
  ///
  /// In ko, this message translates to:
  /// **'LULU'**
  String get appTitle;

  /// 하단 네비게이션 - 홈
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// 하단 네비게이션 - 기록
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get navRecord;

  /// 하단 네비게이션 - 성장
  ///
  /// In ko, this message translates to:
  /// **'성장'**
  String get navGrowth;

  /// 하단 네비게이션 - 설정
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get navSettings;

  /// 설정 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get screenTitleSettings;

  /// 타임라인 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'기록 히스토리'**
  String get screenTitleTimeline;

  /// 성장 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'성장'**
  String get screenTitleGrowth;

  /// 성장 차트 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'성장 차트'**
  String get screenTitleGrowthChart;

  /// 성장 입력 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'성장 기록'**
  String get screenTitleGrowthInput;

  /// 수유 기록 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'수유 기록'**
  String get recordTitleFeeding;

  /// 수면 기록 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'수면 기록'**
  String get recordTitleSleep;

  /// 기저귀 기록 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'기저귀 기록'**
  String get recordTitleDiaper;

  /// 놀이 기록 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'놀이 기록'**
  String get recordTitlePlay;

  /// 건강 기록 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'건강 기록'**
  String get recordTitleHealth;

  /// 활동 유형 - 수유
  ///
  /// In ko, this message translates to:
  /// **'수유'**
  String get activityTypeFeeding;

  /// 활동 유형 - 수면
  ///
  /// In ko, this message translates to:
  /// **'수면'**
  String get activityTypeSleep;

  /// 활동 유형 - 기저귀
  ///
  /// In ko, this message translates to:
  /// **'기저귀'**
  String get activityTypeDiaper;

  /// 활동 유형 - 놀이
  ///
  /// In ko, this message translates to:
  /// **'놀이'**
  String get activityTypePlay;

  /// 활동 유형 - 건강
  ///
  /// In ko, this message translates to:
  /// **'건강'**
  String get activityTypeHealth;

  /// 수유 타입 - 모유
  ///
  /// In ko, this message translates to:
  /// **'모유'**
  String get feedingTypeBreast;

  /// 수유 타입 - 젖병
  ///
  /// In ko, this message translates to:
  /// **'젖병'**
  String get feedingTypeBottle;

  /// 수유 타입 - 분유
  ///
  /// In ko, this message translates to:
  /// **'분유'**
  String get feedingTypeFormula;

  /// 수유 타입 - 이유식
  ///
  /// In ko, this message translates to:
  /// **'이유식'**
  String get feedingTypeSolid;

  /// 모유 수유 - 왼쪽
  ///
  /// In ko, this message translates to:
  /// **'왼쪽'**
  String get breastSideLeft;

  /// 모유 수유 - 오른쪽
  ///
  /// In ko, this message translates to:
  /// **'오른쪽'**
  String get breastSideRight;

  /// 모유 수유 - 양쪽
  ///
  /// In ko, this message translates to:
  /// **'양쪽'**
  String get breastSideBoth;

  /// 수면 타입 - 낮잠
  ///
  /// In ko, this message translates to:
  /// **'낮잠'**
  String get sleepTypeNap;

  /// 수면 타입 - 밤잠
  ///
  /// In ko, this message translates to:
  /// **'밤잠'**
  String get sleepTypeNight;

  /// 수면 시작 표시
  ///
  /// In ko, this message translates to:
  /// **'수면 시작'**
  String get sleepStart;

  /// 수면 종료 표시
  ///
  /// In ko, this message translates to:
  /// **'수면 종료'**
  String get sleepEnd;

  /// 기저귀 타입 - 소변
  ///
  /// In ko, this message translates to:
  /// **'소변'**
  String get diaperTypeWet;

  /// 기저귀 타입 - 대변
  ///
  /// In ko, this message translates to:
  /// **'대변'**
  String get diaperTypeDirty;

  /// 기저귀 타입 - 혼합
  ///
  /// In ko, this message translates to:
  /// **'혼합'**
  String get diaperTypeBoth;

  /// 기저귀 타입 - 건조
  ///
  /// In ko, this message translates to:
  /// **'건조'**
  String get diaperTypeDry;

  /// 기저귀 타입 상세 - 소변+대변
  ///
  /// In ko, this message translates to:
  /// **'소변+대변'**
  String get diaperTypeBothDetail;

  /// 기저귀 타입 - 깨끗함
  ///
  /// In ko, this message translates to:
  /// **'깨끗함'**
  String get diaperTypeClean;

  /// 대변 색상 - 노랑
  ///
  /// In ko, this message translates to:
  /// **'노랑'**
  String get stoolColorYellow;

  /// 대변 색상 - 갈색
  ///
  /// In ko, this message translates to:
  /// **'갈색'**
  String get stoolColorBrown;

  /// 대변 색상 - 녹색
  ///
  /// In ko, this message translates to:
  /// **'녹색'**
  String get stoolColorGreen;

  /// 대변 색상 - 검정
  ///
  /// In ko, this message translates to:
  /// **'검정'**
  String get stoolColorBlack;

  /// 대변 색상 - 빨강
  ///
  /// In ko, this message translates to:
  /// **'빨강'**
  String get stoolColorRed;

  /// 대변 색상 - 흰색
  ///
  /// In ko, this message translates to:
  /// **'흰색'**
  String get stoolColorWhite;

  /// 놀이 타입 - 터미타임
  ///
  /// In ko, this message translates to:
  /// **'터미타임'**
  String get playTypeTummyTime;

  /// 놀이 타입 - 목욕
  ///
  /// In ko, this message translates to:
  /// **'목욕'**
  String get playTypeBath;

  /// 놀이 타입 - 외출
  ///
  /// In ko, this message translates to:
  /// **'외출'**
  String get playTypeOutdoor;

  /// 놀이 타입 - 실내놀이
  ///
  /// In ko, this message translates to:
  /// **'실내놀이'**
  String get playTypeIndoor;

  /// 놀이 타입 - 독서
  ///
  /// In ko, this message translates to:
  /// **'독서'**
  String get playTypeReading;

  /// 놀이 타입 - 기타
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get playTypeOther;

  /// 건강 타입 - 체온 측정
  ///
  /// In ko, this message translates to:
  /// **'체온 측정'**
  String get healthTypeTemperature;

  /// 건강 타입 - 증상 기록
  ///
  /// In ko, this message translates to:
  /// **'증상 기록'**
  String get healthTypeSymptom;

  /// 건강 타입 - 투약 기록
  ///
  /// In ko, this message translates to:
  /// **'투약 기록'**
  String get healthTypeMedication;

  /// 건강 타입 - 투약 (짧은 버전)
  ///
  /// In ko, this message translates to:
  /// **'투약'**
  String get healthTypeMedicationShort;

  /// 건강 타입 - 병원 방문
  ///
  /// In ko, this message translates to:
  /// **'병원 방문'**
  String get healthTypeHospital;

  /// 증상 - 기침
  ///
  /// In ko, this message translates to:
  /// **'기침'**
  String get symptomCough;

  /// 증상 - 콧물
  ///
  /// In ko, this message translates to:
  /// **'콧물'**
  String get symptomRunnyNose;

  /// 증상 - 발열
  ///
  /// In ko, this message translates to:
  /// **'발열'**
  String get symptomFever;

  /// 증상 - 구토
  ///
  /// In ko, this message translates to:
  /// **'구토'**
  String get symptomVomiting;

  /// 증상 - 설사
  ///
  /// In ko, this message translates to:
  /// **'설사'**
  String get symptomDiarrhea;

  /// 증상 - 발진
  ///
  /// In ko, this message translates to:
  /// **'발진'**
  String get symptomRash;

  /// 체온 상태 - 저체온
  ///
  /// In ko, this message translates to:
  /// **'저체온'**
  String get tempStatusLow;

  /// 체온 상태 - 정상
  ///
  /// In ko, this message translates to:
  /// **'정상'**
  String get tempStatusNormal;

  /// 체온 상태 - 미열
  ///
  /// In ko, this message translates to:
  /// **'미열'**
  String get tempStatusMild;

  /// 체온 상태 - 발열
  ///
  /// In ko, this message translates to:
  /// **'발열'**
  String get tempStatusHigh;

  /// 체온 라벨
  ///
  /// In ko, this message translates to:
  /// **'체온'**
  String get temperature;

  /// 성별 - 남아
  ///
  /// In ko, this message translates to:
  /// **'남아'**
  String get genderMale;

  /// 성별 - 여아
  ///
  /// In ko, this message translates to:
  /// **'여아'**
  String get genderFemale;

  /// 성별 - 미정
  ///
  /// In ko, this message translates to:
  /// **'미정'**
  String get genderUnknown;

  /// 출산 유형 - 단태아
  ///
  /// In ko, this message translates to:
  /// **'단태아'**
  String get babyTypeSingleton;

  /// 출산 유형 - 쌍둥이
  ///
  /// In ko, this message translates to:
  /// **'쌍둥이'**
  String get babyTypeTwin;

  /// 출산 유형 - 세쌍둥이
  ///
  /// In ko, this message translates to:
  /// **'세쌍둥이'**
  String get babyTypeTriplet;

  /// 출산 유형 - 네쌍둥이
  ///
  /// In ko, this message translates to:
  /// **'네쌍둥이'**
  String get babyTypeQuadruplet;

  /// 출생 순서 - 첫째
  ///
  /// In ko, this message translates to:
  /// **'첫째'**
  String get birthOrderFirst;

  /// 출생 순서 - 둘째
  ///
  /// In ko, this message translates to:
  /// **'둘째'**
  String get birthOrderSecond;

  /// 출생 순서 - 셋째
  ///
  /// In ko, this message translates to:
  /// **'셋째'**
  String get birthOrderThird;

  /// 출생 순서 - 넷째
  ///
  /// In ko, this message translates to:
  /// **'넷째'**
  String get birthOrderFourth;

  /// 조산아
  ///
  /// In ko, this message translates to:
  /// **'조산아'**
  String get preterm;

  /// 만삭아
  ///
  /// In ko, this message translates to:
  /// **'만삭'**
  String get fullTerm;

  /// 교정연령 접두어
  ///
  /// In ko, this message translates to:
  /// **'교정'**
  String get correctedAge;

  /// 실제 연령
  ///
  /// In ko, this message translates to:
  /// **'실제'**
  String get actualAge;

  /// 버튼 - 시작하기
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get buttonStart;

  /// 버튼 - 다음
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get buttonNext;

  /// 버튼 - 저장하기
  ///
  /// In ko, this message translates to:
  /// **'저장하기'**
  String get buttonSave;

  /// 버튼 - 취소
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get buttonCancel;

  /// 버튼 - 삭제
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get buttonDelete;

  /// 버튼 - 확인
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get buttonConfirm;

  /// 버튼 - 알겠어요
  ///
  /// In ko, this message translates to:
  /// **'알겠어요'**
  String get buttonOk;

  /// 버튼 - 아니오
  ///
  /// In ko, this message translates to:
  /// **'아니오'**
  String get buttonNo;

  /// 버튼 - 추가
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get buttonAdd;

  /// 버튼 - 전체 보기
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get buttonViewAll;

  /// 버튼 - 수면 시작
  ///
  /// In ko, this message translates to:
  /// **'수면 시작'**
  String get buttonStartSleep;

  /// 버튼 - CSV로 내보내기
  ///
  /// In ko, this message translates to:
  /// **'CSV로 내보내기'**
  String get buttonExportCsv;

  /// 라벨 - 이름
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get labelName;

  /// 라벨 - 생년월일
  ///
  /// In ko, this message translates to:
  /// **'생년월일'**
  String get labelBirthDate;

  /// 라벨 - 출생일
  ///
  /// In ko, this message translates to:
  /// **'출생일'**
  String get labelBirthDateShort;

  /// 라벨 - 성별
  ///
  /// In ko, this message translates to:
  /// **'성별'**
  String get labelGender;

  /// 라벨 - 조산아 여부
  ///
  /// In ko, this message translates to:
  /// **'조산아 여부'**
  String get labelIsPreterm;

  /// 라벨 - 재태주수
  ///
  /// In ko, this message translates to:
  /// **'재태주수'**
  String get labelGestationalWeeks;

  /// 라벨 - 출생 체중
  ///
  /// In ko, this message translates to:
  /// **'출생 체중'**
  String get labelBirthWeight;

  /// 라벨 - 출생 체중 (선택)
  ///
  /// In ko, this message translates to:
  /// **'출생 체중 (선택)'**
  String get labelBirthWeightOptional;

  /// 라벨 - 수유량
  ///
  /// In ko, this message translates to:
  /// **'수유량'**
  String get labelFeedingAmount;

  /// 라벨 - 내보내기 기간
  ///
  /// In ko, this message translates to:
  /// **'내보내기 기간'**
  String get labelExportPeriod;

  /// 힌트 - 아기 이름 입력
  ///
  /// In ko, this message translates to:
  /// **'아기 이름을 입력하세요'**
  String get hintEnterBabyName;

  /// 힌트 - 주수 선택
  ///
  /// In ko, this message translates to:
  /// **'주수를 선택하세요'**
  String get hintSelectWeeks;

  /// 힌트 - 그램 단위
  ///
  /// In ko, this message translates to:
  /// **'그램 단위 (예: 2500)'**
  String get hintGrams;

  /// 질문 - 조산 여부
  ///
  /// In ko, this message translates to:
  /// **'37주 이전에 태어났나요?'**
  String get questionIsPreterm;

  /// 섹션 - 아기 관리
  ///
  /// In ko, this message translates to:
  /// **'아기 관리'**
  String get sectionBabyManagement;

  /// 섹션 - 데이터
  ///
  /// In ko, this message translates to:
  /// **'데이터'**
  String get sectionData;

  /// 섹션 - 앱 정보
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get sectionAppInfo;

  /// 섹션 - 최근 기록
  ///
  /// In ko, this message translates to:
  /// **'최근 기록'**
  String get sectionRecentRecords;

  /// 정보 - 버전
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get infoVersion;

  /// 정보 - 개발
  ///
  /// In ko, this message translates to:
  /// **'개발'**
  String get infoDeveloper;

  /// 정보 - 팀 이름
  ///
  /// In ko, this message translates to:
  /// **'LULU Team'**
  String get infoTeamName;

  /// 다이얼로그 제목 - 아기 추가
  ///
  /// In ko, this message translates to:
  /// **'아기 추가'**
  String get addBabyTitle;

  /// 아기 추가 안내
  ///
  /// In ko, this message translates to:
  /// **'최대 4명까지 등록 가능'**
  String get addBabySubtitle;

  /// 다이얼로그 제목 - 아기 삭제
  ///
  /// In ko, this message translates to:
  /// **'아기 삭제'**
  String get deleteBabyTitle;

  /// 삭제 경고 메시지
  ///
  /// In ko, this message translates to:
  /// **'이 작업은 되돌릴 수 없습니다.'**
  String get deleteBabyWarning;

  /// 삭제 확인 메시지
  ///
  /// In ko, this message translates to:
  /// **'{name}의 모든 기록이 삭제됩니다.'**
  String deleteBabyConfirmMessage(String name);

  /// 내보내기 기간 - 오늘
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get exportPeriodToday;

  /// 내보내기 기간 - 최근 7일
  ///
  /// In ko, this message translates to:
  /// **'최근 7일'**
  String get exportPeriodWeek;

  /// 내보내기 기간 - 최근 30일
  ///
  /// In ko, this message translates to:
  /// **'최근 30일'**
  String get exportPeriodMonth;

  /// 내보내기 기간 - 전체
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get exportPeriodAll;

  /// 내보내기 안내
  ///
  /// In ko, this message translates to:
  /// **'{period} 기록을 파일로 저장'**
  String exportToFile(String period);

  /// 내보내기 이메일 제목
  ///
  /// In ko, this message translates to:
  /// **'LULU 육아 기록'**
  String get exportEmailSubject;

  /// 내보내기 이메일 본문
  ///
  /// In ko, this message translates to:
  /// **'육아 기록 데이터입니다.'**
  String get exportEmailBody;

  /// 성공 - 아기 추가됨
  ///
  /// In ko, this message translates to:
  /// **'{name}이(가) 추가되었습니다'**
  String successBabyAdded(String name);

  /// 성공 - 아기 삭제됨
  ///
  /// In ko, this message translates to:
  /// **'{name}이(가) 삭제되었습니다'**
  String successBabyDeleted(String name);

  /// 성공 - 기록 저장됨
  ///
  /// In ko, this message translates to:
  /// **'기록이 저장되었습니다'**
  String get successRecordSaved;

  /// 에러 - 가족 정보 없음
  ///
  /// In ko, this message translates to:
  /// **'가족 정보가 없습니다'**
  String get errorNoFamily;

  /// 에러 - 기록 없음
  ///
  /// In ko, this message translates to:
  /// **'내보낼 기록이 없습니다'**
  String get errorNoRecords;

  /// 에러 - 내보내기 실패
  ///
  /// In ko, this message translates to:
  /// **'내보내기 실패: {error}'**
  String errorExportFailed(String error);

  /// 에러 - 삭제 실패
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패: {error}'**
  String errorDeleteFailed(String error);

  /// 에러 - 추가 실패
  ///
  /// In ko, this message translates to:
  /// **'추가 실패: {error}'**
  String errorAddFailed(String error);

  /// 에러 - 이름 필수
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해주세요'**
  String get errorEnterName;

  /// 에러 - 주수 선택 필수
  ///
  /// In ko, this message translates to:
  /// **'재태주수를 선택해주세요'**
  String get errorSelectWeeks;

  /// 에러 - 아기 등록 필요
  ///
  /// In ko, this message translates to:
  /// **'아기 정보를 먼저 등록해주세요'**
  String get errorRegisterBaby;

  /// 에러 - 아기 정보 없음
  ///
  /// In ko, this message translates to:
  /// **'아기 정보가 없습니다'**
  String get errorNoBabyInfo;

  /// 에러 - 온보딩 필요
  ///
  /// In ko, this message translates to:
  /// **'온보딩을 완료해주세요'**
  String get errorCompleteOnboarding;

  /// 에러 - 데이터 로드 실패
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러오는데 실패했습니다: {error}'**
  String errorLoadData(String error);

  /// 빈 상태 - 오늘 기록 없음
  ///
  /// In ko, this message translates to:
  /// **'오늘 기록이 없어요'**
  String get emptyNoRecordsToday;

  /// 빈 상태 - 특정 날짜 기록 없음
  ///
  /// In ko, this message translates to:
  /// **'{date} 기록이 없습니다'**
  String emptyNoRecordsDate(String date);

  /// 빈 상태 - 오늘 기록 없음 (상세)
  ///
  /// In ko, this message translates to:
  /// **'오늘의 기록이 없습니다'**
  String get emptyNoTodayRecords;

  /// 빈 상태 안내
  ///
  /// In ko, this message translates to:
  /// **'+ 버튼을 눌러 첫 기록을 시작하세요'**
  String get emptyStartRecording;

  /// 빈 상태 안내 - 날짜 선택
  ///
  /// In ko, this message translates to:
  /// **'다른 날짜를 선택해보세요'**
  String get emptySelectOtherDate;

  /// 상태 - 진행 중
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get statusOngoing;

  /// 상태 - 진행중 (공백 없음)
  ///
  /// In ko, this message translates to:
  /// **'진행중'**
  String get statusInProgress;

  /// 시간 단위 - 분
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get timeMinute;

  /// 시간 단위 - 시간
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get timeHour;

  /// 시간 단위 - 일
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get timeDay;

  /// 시간 단위 - 주
  ///
  /// In ko, this message translates to:
  /// **'주'**
  String get timeWeek;

  /// 시간 단위 - 개월
  ///
  /// In ko, this message translates to:
  /// **'개월'**
  String get timeMonth;

  /// 시간 - 방금
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get timeJustNow;

  /// 시간 - N분 전
  ///
  /// In ko, this message translates to:
  /// **'{count}분 전'**
  String timeMinutesAgo(int count);

  /// 시간 - N시간 전
  ///
  /// In ko, this message translates to:
  /// **'{count}시간 전'**
  String timeHoursAgo(int count);

  /// 시간 - N일 전
  ///
  /// In ko, this message translates to:
  /// **'{count}일 전'**
  String timeDaysAgo(int count);

  /// 시간 - 지금
  ///
  /// In ko, this message translates to:
  /// **'지금'**
  String get timeNow;

  /// 시간 - 출생
  ///
  /// In ko, this message translates to:
  /// **'출생'**
  String get timeBirth;

  /// 기간 - N분
  ///
  /// In ko, this message translates to:
  /// **'{count}분'**
  String durationMinutes(int count);

  /// 기간 - N시간
  ///
  /// In ko, this message translates to:
  /// **'{count}시간'**
  String durationHours(int count);

  /// 기간 - N시간 N분
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분'**
  String durationHoursMinutes(int hours, int minutes);

  /// 기록 수
  ///
  /// In ko, this message translates to:
  /// **'{count}개 기록'**
  String recordCount(int count);

  /// 연령 - 출생 N일
  ///
  /// In ko, this message translates to:
  /// **'출생 {count}일'**
  String ageDays(int count);

  /// 연령 - 출생 N주
  ///
  /// In ko, this message translates to:
  /// **'출생 {count}주'**
  String ageWeeks(int count);

  /// 연령 - N개월
  ///
  /// In ko, this message translates to:
  /// **'{count}개월'**
  String ageMonths(int count);

  /// 교정연령 표시
  ///
  /// In ko, this message translates to:
  /// **'교정 {corrected}개월 (실제 {actual}개월)'**
  String ageCorrectedMonths(int corrected, int actual);

  /// 주 단위
  ///
  /// In ko, this message translates to:
  /// **'{count}주'**
  String weekUnit(int count);

  /// 환영 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'Lulu에 오신 것을 환영해요!'**
  String get welcomeTitle;

  /// 환영 화면 부제목
  ///
  /// In ko, this message translates to:
  /// **'아기의 수면, 수유, 기저귀를 쉽고 빠르게 기록해 보세요'**
  String get welcomeSubtitle;

  /// 빠른 기록 버튼 안내
  ///
  /// In ko, this message translates to:
  /// **'탭하면 이전과 같은 내용으로 바로 저장돼요!'**
  String get quickRecordHint;

  /// 빠른 기록 - 탭하여 저장
  ///
  /// In ko, this message translates to:
  /// **'탭하여 저장'**
  String get quickRecordTapToSave;

  /// 빠른 기록 - 마지막 기록 반복
  ///
  /// In ko, this message translates to:
  /// **'마지막 기록 반복'**
  String get quickRecordRepeat;

  /// 울음 분석 기능 제목
  ///
  /// In ko, this message translates to:
  /// **'울음 분석'**
  String get cryAnalysisTitle;

  /// 울음 분석 준비 중
  ///
  /// In ko, this message translates to:
  /// **'울음 분석 기능 준비 중'**
  String get cryAnalysisPreparing;

  /// 울음 분석 - 출시 예정
  ///
  /// In ko, this message translates to:
  /// **'Phase 2에서 만나요!'**
  String get cryAnalysisComingSoon;

  /// 울음 분석 설명
  ///
  /// In ko, this message translates to:
  /// **'AI 기반 울음 분석 기능이 Phase 2에서 출시됩니다.'**
  String get cryAnalysisDescription;

  /// Sweet Spot - 확인 중
  ///
  /// In ko, this message translates to:
  /// **'확인 중'**
  String get sweetSpotUnknown;

  /// Sweet Spot - 아직 일찍
  ///
  /// In ko, this message translates to:
  /// **'아직 일찍'**
  String get sweetSpotTooEarly;

  /// Sweet Spot - 곧 수면 시간
  ///
  /// In ko, this message translates to:
  /// **'곧 수면 시간'**
  String get sweetSpotApproaching;

  /// Sweet Spot - 최적
  ///
  /// In ko, this message translates to:
  /// **'지금이 최적!'**
  String get sweetSpotOptimal;

  /// Sweet Spot - 과로
  ///
  /// In ko, this message translates to:
  /// **'과로 상태'**
  String get sweetSpotOvertired;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'ko':
      return SKo();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
