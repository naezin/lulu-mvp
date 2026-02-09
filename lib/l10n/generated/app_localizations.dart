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

  /// 건강 타입 - 체온
  ///
  /// In ko, this message translates to:
  /// **'체온'**
  String get healthTypeTemperature;

  /// 건강 타입 - 증상
  ///
  /// In ko, this message translates to:
  /// **'증상'**
  String get healthTypeSymptom;

  /// 건강 타입 - 투약
  ///
  /// In ko, this message translates to:
  /// **'투약'**
  String get healthTypeMedication;

  /// 건강 타입 - 투약 (짧은 버전)
  ///
  /// In ko, this message translates to:
  /// **'투약'**
  String get healthTypeMedicationShort;

  /// 건강 타입 - 병원방문
  ///
  /// In ko, this message translates to:
  /// **'병원방문'**
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

  /// 출생일 라벨 (짧은 형태)
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

  /// Sweet Spot 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'다음 낮잠'**
  String get sweetSpotTitle;

  /// Sweet Spot 카드 제목 (아기 이름 + 수면타입)
  ///
  /// In ko, this message translates to:
  /// **'{babyName}의 다음 {sleepType}'**
  String sweetSpotTitleWithName(String babyName, String sleepType);

  /// Sweet Spot - 확인 중
  ///
  /// In ko, this message translates to:
  /// **'확인 중'**
  String get sweetSpotUnknown;

  /// Sweet Spot - 아직 여유 있음 (Huckleberry 스타일)
  ///
  /// In ko, this message translates to:
  /// **'아직 여유 있어요'**
  String get sweetSpotTooEarly;

  /// Sweet Spot - 곧 졸릴 수 있음 (확률적 표현)
  ///
  /// In ko, this message translates to:
  /// **'슬슬 졸려할 수 있어요'**
  String get sweetSpotApproaching;

  /// Sweet Spot - 지금 재우면 좋을 것 같음 (부드러운 권유)
  ///
  /// In ko, this message translates to:
  /// **'지금 재우면 좋을 것 같아요'**
  String get sweetSpotOptimal;

  /// Sweet Spot - 졸린 시간 지남 (확률적 표현)
  ///
  /// In ko, this message translates to:
  /// **'졸린 시간이 지났을 수 있어요'**
  String get sweetSpotOvertired;

  /// Sweet Spot Empty State 제목
  ///
  /// In ko, this message translates to:
  /// **'수면 기록이 필요해요'**
  String get sweetSpotEmptyTitle;

  /// Sweet Spot Empty State 제목 (이름 포함)
  ///
  /// In ko, this message translates to:
  /// **'{babyName}의 첫 기록을 시작해보세요'**
  String sweetSpotEmptyTitleWithName(String babyName);

  /// Sweet Spot Empty State 제목 (이름 없음)
  ///
  /// In ko, this message translates to:
  /// **'첫 기록을 시작해보세요'**
  String get sweetSpotEmptyTitleDefault;

  /// Sweet Spot Empty State 부제목
  ///
  /// In ko, this message translates to:
  /// **'첫 수면을 기록하면\n예상 시간을 알려드릴게요'**
  String get sweetSpotEmptySubtitle;

  /// Sweet Spot Empty State 액션 힌트
  ///
  /// In ko, this message translates to:
  /// **'아래 버튼을 눌러\n수유, 수면, 기저귀 기록을 시작하세요'**
  String get sweetSpotEmptyActionHint;

  /// Sweet Spot Empty State 힌트
  ///
  /// In ko, this message translates to:
  /// **'기록이 쌓이면 수면 예측을 알려드릴게요'**
  String get sweetSpotEmptyHint;

  /// Sweet Spot 면책 문구
  ///
  /// In ko, this message translates to:
  /// **'이 예측은 참고용이며, 아기마다 다를 수 있어요'**
  String get sweetSpotDisclaimer;

  /// Sweet Spot 오늘 수면 기록 없을 때 제목
  ///
  /// In ko, this message translates to:
  /// **'오늘 수면 기록이 없어요'**
  String get sweetSpotNoSleepTitle;

  /// Sweet Spot 오늘 수면 기록 없을 때 힌트
  ///
  /// In ko, this message translates to:
  /// **'수면을 기록하면 다음 수면 시간을 예측해 드릴게요'**
  String get sweetSpotNoSleepHint;

  /// Sweet Spot 수면 기록 버튼
  ///
  /// In ko, this message translates to:
  /// **'수면 기록하기'**
  String get sweetSpotRecordSleepButton;

  /// 기록 탭 오늘 빈 상태 제목
  ///
  /// In ko, this message translates to:
  /// **'{babyName}의 첫 기록을 시작해보세요'**
  String timelineEmptyTodayTitle(String babyName);

  /// 기록 탭 오늘 빈 상태 힌트
  ///
  /// In ko, this message translates to:
  /// **'아래 + 버튼을 눌러\n수유, 수면, 기저귀 기록을 시작하세요'**
  String get timelineEmptyTodayHint;

  /// 기록 탭 과거 날짜 빈 상태 제목
  ///
  /// In ko, this message translates to:
  /// **'{date} 기록이 없습니다'**
  String timelineEmptyPastTitle(String date);

  /// 기록 탭 과거 날짜 빈 상태 힌트
  ///
  /// In ko, this message translates to:
  /// **'다른 날짜를 선택해보세요'**
  String get timelineEmptyPastHint;

  /// 섹션 - 언어
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get sectionLanguage;

  /// 언어 변경 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'언어를 변경하시겠습니까?'**
  String get languageChangeConfirm;

  /// 언어 변경 안내 메시지
  ///
  /// In ko, this message translates to:
  /// **'앱이 선택한 언어로 표시됩니다.'**
  String get languageChangeMessage;

  /// 수유 컨텐츠 타입 - 모유
  ///
  /// In ko, this message translates to:
  /// **'모유'**
  String get feedingContentBreastMilk;

  /// 수유 컨텐츠 타입 - 분유
  ///
  /// In ko, this message translates to:
  /// **'분유'**
  String get feedingContentFormula;

  /// 수유 컨텐츠 타입 - 이유식
  ///
  /// In ko, this message translates to:
  /// **'이유식'**
  String get feedingContentSolid;

  /// 수유 방법 - 직접 수유
  ///
  /// In ko, this message translates to:
  /// **'직접 수유'**
  String get feedingMethodDirect;

  /// 수유 방법 - 유축 수유
  ///
  /// In ko, this message translates to:
  /// **'유축 수유'**
  String get feedingMethodExpressed;

  /// 모유 버튼 하위 라벨
  ///
  /// In ko, this message translates to:
  /// **'(직접/유축)'**
  String get feedingBreastMilkSubLabel;

  /// 수유 컨텐츠 유형 질문
  ///
  /// In ko, this message translates to:
  /// **'어떤 수유인가요?'**
  String get feedingQuestionContent;

  /// 모유 수유 방식 질문
  ///
  /// In ko, this message translates to:
  /// **'어떤 방식인가요?'**
  String get feedingQuestionMethod;

  /// 직접 수유 방향 질문
  ///
  /// In ko, this message translates to:
  /// **'어느 쪽으로 수유했나요?'**
  String get feedingQuestionSide;

  /// 수유 시간 질문
  ///
  /// In ko, this message translates to:
  /// **'얼마나 수유했나요?'**
  String get feedingQuestionDuration;

  /// 수유량 질문
  ///
  /// In ko, this message translates to:
  /// **'수유량을 입력해주세요'**
  String get feedingQuestionAmount;

  /// 수유 방향 - 왼쪽
  ///
  /// In ko, this message translates to:
  /// **'왼쪽'**
  String get feedingSideLeft;

  /// 수유 방향 - 오른쪽
  ///
  /// In ko, this message translates to:
  /// **'오른쪽'**
  String get feedingSideRight;

  /// 수유 방향 - 양쪽
  ///
  /// In ko, this message translates to:
  /// **'양쪽'**
  String get feedingSideBoth;

  /// 수유 방향 짧은 표기 - 왼쪽
  ///
  /// In ko, this message translates to:
  /// **'L'**
  String get feedingSideLeftShort;

  /// 수유 방향 짧은 표기 - 오른쪽
  ///
  /// In ko, this message translates to:
  /// **'R'**
  String get feedingSideRightShort;

  /// 수유 방향 짧은 표기 - 양쪽
  ///
  /// In ko, this message translates to:
  /// **'양'**
  String get feedingSideBothShort;

  /// 수유 시간 - N분
  ///
  /// In ko, this message translates to:
  /// **'{count}분'**
  String feedingDurationMinutes(int count);

  /// 수유량 - Nml
  ///
  /// In ko, this message translates to:
  /// **'{amount}ml'**
  String feedingAmountMl(int amount);

  /// 프리셋 수유 시간
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String feedingPresetDurationMinutes(int minutes);

  /// 직접 입력 필드 플레이스홀더
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get feedingDirectInputPlaceholder;

  /// 이유식 폼 제목
  ///
  /// In ko, this message translates to:
  /// **'이유식'**
  String get solidFoodTitle;

  /// 음식 이름 라벨
  ///
  /// In ko, this message translates to:
  /// **'음식 이름'**
  String get solidFoodNameLabel;

  /// 음식 이름 힌트
  ///
  /// In ko, this message translates to:
  /// **'예: 당근 퓨레, 쌀미음'**
  String get solidFoodNameHint;

  /// 처음 먹이는 음식 체크박스 라벨
  ///
  /// In ko, this message translates to:
  /// **'처음 먹이는 음식이에요'**
  String get solidFoodFirstTry;

  /// 양 라벨
  ///
  /// In ko, this message translates to:
  /// **'양'**
  String get solidFoodAmountLabel;

  /// 아기 반응 라벨
  ///
  /// In ko, this message translates to:
  /// **'아기 반응'**
  String get solidFoodReactionLabel;

  /// 이유식 단위 - 그램
  ///
  /// In ko, this message translates to:
  /// **'g'**
  String get solidUnitGram;

  /// 이유식 단위 - 숟가락
  ///
  /// In ko, this message translates to:
  /// **'숟가락'**
  String get solidUnitSpoon;

  /// 이유식 단위 - 그릇
  ///
  /// In ko, this message translates to:
  /// **'그릇'**
  String get solidUnitBowl;

  /// 아기 반응 - 잘 먹음
  ///
  /// In ko, this message translates to:
  /// **'잘 먹음'**
  String get babyReactionLiked;

  /// 아기 반응 - 보통
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get babyReactionNeutral;

  /// 아기 반응 - 거부
  ///
  /// In ko, this message translates to:
  /// **'거부'**
  String get babyReactionRejected;

  /// 통계 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get statisticsTitle;

  /// 주간 요약 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'이번 주 요약'**
  String get statisticsWeeklySummary;

  /// 통계 - 수면
  ///
  /// In ko, this message translates to:
  /// **'수면'**
  String get statisticsSleep;

  /// 통계 - 수유
  ///
  /// In ko, this message translates to:
  /// **'수유'**
  String get statisticsFeeding;

  /// 통계 - 기저귀
  ///
  /// In ko, this message translates to:
  /// **'기저귀'**
  String get statisticsDiaper;

  /// 통계 - 울음
  ///
  /// In ko, this message translates to:
  /// **'울음'**
  String get statisticsCrying;

  /// 통계 - 일 평균 단위
  ///
  /// In ko, this message translates to:
  /// **'/일 평균'**
  String get statisticsPerDayAverage;

  /// 통계 - 평균
  ///
  /// In ko, this message translates to:
  /// **'평균'**
  String get statisticsAverage;

  /// 함께 보기 탭 레이블
  ///
  /// In ko, this message translates to:
  /// **'함께 보기'**
  String get statisticsTogetherView;

  /// 함께 보기 뷰 제목
  ///
  /// In ko, this message translates to:
  /// **'이번 주 함께 보기'**
  String get statisticsTogetherViewTitle;

  /// 함께 보기 안내 메시지
  ///
  /// In ko, this message translates to:
  /// **'각 아기는 고유한 패턴을 가지고 있어요'**
  String get statisticsTogetherViewGuide;

  /// 교정연령 표시
  ///
  /// In ko, this message translates to:
  /// **'교정 {days}일'**
  String statisticsCorrectedAge(int days);

  /// 수면 리포트 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'수면 리포트'**
  String get statisticsSleepReport;

  /// 수유 리포트 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'수유 리포트'**
  String get statisticsFeedingReport;

  /// 기저귀 리포트 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'기저귀 리포트'**
  String get statisticsDiaperReport;

  /// 울음 리포트 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'울음 리포트'**
  String get statisticsCryingReport;

  /// 통계 면책 문구
  ///
  /// In ko, this message translates to:
  /// **'이 통계는 참고용이며 의료 판단이 아닙니다'**
  String get statisticsDisclaimer;

  /// 교정연령 기준 안내
  ///
  /// In ko, this message translates to:
  /// **'교정연령 기준으로 분석되었습니다'**
  String get statisticsCorrectedAgeNote;

  /// 기록 히스토리 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get recordHistoryTitle;

  /// 타임라인 탭 레이블
  ///
  /// In ko, this message translates to:
  /// **'타임라인'**
  String get tabTimeline;

  /// 통계 탭 레이블
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get tabStatistics;

  /// 통계 카드 - 일평균 접두어
  ///
  /// In ko, this message translates to:
  /// **'일평균'**
  String get statsDailyAvg;

  /// 통계 카드 - 수면
  ///
  /// In ko, this message translates to:
  /// **'수면'**
  String get statsSleep;

  /// 통계 카드 - 수유
  ///
  /// In ko, this message translates to:
  /// **'수유'**
  String get statsFeeding;

  /// 통계 카드 - 기저귀
  ///
  /// In ko, this message translates to:
  /// **'기저귀'**
  String get statsDiaper;

  /// 단위 - 시간
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get unitHours;

  /// 단위 - 회
  ///
  /// In ko, this message translates to:
  /// **'회'**
  String get unitTimes;

  /// 주간 트렌드 차트 제목
  ///
  /// In ko, this message translates to:
  /// **'주간 수면 추이'**
  String get weeklyTrendTitle;

  /// 통계 빈 상태 제목
  ///
  /// In ko, this message translates to:
  /// **'아직 통계가 없어요'**
  String get statisticsEmptyTitle;

  /// 통계 빈 상태 힌트
  ///
  /// In ko, this message translates to:
  /// **'기록을 쌓으면 통계가 나타나요'**
  String get statisticsEmptyHint;

  /// 날짜/시간 피커 제목
  ///
  /// In ko, this message translates to:
  /// **'시간 선택'**
  String get dateTimePickerTitle;

  /// 현재 시간 버튼
  ///
  /// In ko, this message translates to:
  /// **'지금'**
  String get dateTimeNow;

  /// 5분 전 버튼
  ///
  /// In ko, this message translates to:
  /// **'-5분'**
  String get dateTime5MinAgo;

  /// 15분 전 버튼
  ///
  /// In ko, this message translates to:
  /// **'-15분'**
  String get dateTime15MinAgo;

  /// 30분 전 버튼
  ///
  /// In ko, this message translates to:
  /// **'-30분'**
  String get dateTime30MinAgo;

  /// 날짜/시간 피커 취소
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get dateTimeCancel;

  /// 날짜/시간 피커 확인
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get dateTimeConfirm;

  /// 수면 시작 시간 라벨
  ///
  /// In ko, this message translates to:
  /// **'수면 시작'**
  String get sleepStartTime;

  /// 수면 종료 시간 라벨
  ///
  /// In ko, this message translates to:
  /// **'수면 종료'**
  String get sleepEndTime;

  /// 수면 지금 종료 버튼
  ///
  /// In ko, this message translates to:
  /// **'지금 종료'**
  String get sleepEndNow;

  /// 수면 종료 시간 선택 버튼
  ///
  /// In ko, this message translates to:
  /// **'시간 선택'**
  String get sleepSelectEndTime;

  /// 빠른 수유 기록 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'빠른 기록'**
  String get quickFeedingTitle;

  /// 빠른 수유 버튼 힌트
  ///
  /// In ko, this message translates to:
  /// **'탭: 저장 / 길게: 수정'**
  String get quickFeedingHint;

  /// 빠른 수유 빈 상태 제목
  ///
  /// In ko, this message translates to:
  /// **'아직 기록이 없어요'**
  String get quickFeedingEmpty;

  /// 빠른 수유 빈 상태 설명
  ///
  /// In ko, this message translates to:
  /// **'첫 수유를 기록하면 빠른 버튼이 나타나요!'**
  String get quickFeedingEmptyDesc;

  /// 빠른 수유 저장 완료
  ///
  /// In ko, this message translates to:
  /// **'{summary} 저장됨'**
  String quickFeedingSaved(String summary);

  /// 빠른 수유 저장 취소 버튼
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get quickFeedingUndo;

  /// 빠른 수유 저장 취소 완료
  ///
  /// In ko, this message translates to:
  /// **'취소됨'**
  String get quickFeedingUndone;

  /// 빠른 기록과 상세 입력 사이 구분선
  ///
  /// In ko, this message translates to:
  /// **'또는 새로 입력'**
  String get orNewEntry;

  /// Import 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'기존 기록 가져오기'**
  String get importTitle;

  /// 파일 선택 안내
  ///
  /// In ko, this message translates to:
  /// **'어떤 파일을 가져올까요?'**
  String get importSelectFile;

  /// TXT 파일 옵션
  ///
  /// In ko, this message translates to:
  /// **'텍스트 파일 (.txt)'**
  String get importTxtOption;

  /// TXT 파일 설명
  ///
  /// In ko, this message translates to:
  /// **'베이비타임 등'**
  String get importTxtDesc;

  /// CSV 파일 옵션
  ///
  /// In ko, this message translates to:
  /// **'CSV 파일 (.csv)'**
  String get importCsvOption;

  /// CSV 파일 설명
  ///
  /// In ko, this message translates to:
  /// **'Huckleberry 등'**
  String get importCsvDesc;

  /// Import 힌트
  ///
  /// In ko, this message translates to:
  /// **'대부분의 육아 앱 설정에서 데이터 내보내기를 지원해요'**
  String get importHint;

  /// 분석 중 메시지
  ///
  /// In ko, this message translates to:
  /// **'파일을 분석하고 있어요...'**
  String get importAnalyzing;

  /// 분석 완료 메시지
  ///
  /// In ko, this message translates to:
  /// **'파일 분석 완료'**
  String get importAnalyzed;

  /// 수유 기록 수
  ///
  /// In ko, this message translates to:
  /// **'수유'**
  String get importFeedingCount;

  /// 수면 기록 수
  ///
  /// In ko, this message translates to:
  /// **'수면'**
  String get importSleepCount;

  /// 기저귀 기록 수
  ///
  /// In ko, this message translates to:
  /// **'기저귀'**
  String get importDiaperCount;

  /// 놀이 기록 수
  ///
  /// In ko, this message translates to:
  /// **'놀이'**
  String get importPlayCount;

  /// 총 기록 수
  ///
  /// In ko, this message translates to:
  /// **'총'**
  String get importTotal;

  /// 아기 연결 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'아기 연결'**
  String get importBabyConnect;

  /// 아기 연결 설명
  ///
  /// In ko, this message translates to:
  /// **'이 기록을 어떤 아기에게 연결할까요?'**
  String get importBabyConnectDesc;

  /// 중복 경고 메시지
  ///
  /// In ko, this message translates to:
  /// **'기존 기록과 중복되면 건너뜁니다'**
  String get importDuplicateWarning;

  /// 가져오기 버튼
  ///
  /// In ko, this message translates to:
  /// **'{count}개 기록 가져오기'**
  String importButton(int count);

  /// 가져오기 진행 중 메시지
  ///
  /// In ko, this message translates to:
  /// **'기록을 가져오는 중...'**
  String get importProgress;

  /// 가져오기 완료 메시지
  ///
  /// In ko, this message translates to:
  /// **'기록을 가져왔어요!'**
  String get importComplete;

  /// 성공 라벨
  ///
  /// In ko, this message translates to:
  /// **'성공'**
  String get importSuccess;

  /// 건너뜀 라벨
  ///
  /// In ko, this message translates to:
  /// **'건너뜀 (중복)'**
  String get importSkipped;

  /// 홈으로 버튼
  ///
  /// In ko, this message translates to:
  /// **'홈으로 돌아가기'**
  String get importGoHome;

  /// 가족 관리 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'가족 관리'**
  String get familyManagement;

  /// 가족 멤버 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'가족 멤버'**
  String get familyMembers;

  /// 대기 중인 초대 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'대기 중인 초대'**
  String get pendingInvites;

  /// 가족 설정 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'가족 설정'**
  String get familySettings;

  /// 가족 초대 버튼
  ///
  /// In ko, this message translates to:
  /// **'가족 초대하기'**
  String get inviteFamily;

  /// 관리자 넘기기 메뉴
  ///
  /// In ko, this message translates to:
  /// **'관리자 넘기기'**
  String get transferOwnership;

  /// 다른 가족 참여 메뉴
  ///
  /// In ko, this message translates to:
  /// **'다른 가족 참여'**
  String get joinOtherFamily;

  /// 다른 가족 참여 설명
  ///
  /// In ko, this message translates to:
  /// **'현재 가족을 나가고 다른 가족에 참여해요.'**
  String get joinOtherFamilyDesc;

  /// 가족 나가기 메뉴
  ///
  /// In ko, this message translates to:
  /// **'가족 나가기'**
  String get leaveFamily;

  /// 가족 삭제 제목
  ///
  /// In ko, this message translates to:
  /// **'가족 삭제'**
  String get deleteFamily;

  /// 가족 삭제 설명
  ///
  /// In ko, this message translates to:
  /// **'가족을 삭제하면 모든 기록이 사라져요.'**
  String get deleteFamilyDesc;

  /// 가족 나가기 설명
  ///
  /// In ko, this message translates to:
  /// **'더 이상 기록을 볼 수 없어요.'**
  String get leaveFamilyDesc;

  /// 관리자 나갈 수 없음 제목
  ///
  /// In ko, this message translates to:
  /// **'관리자는 나갈 수 없어요'**
  String get cannotLeave;

  /// 관리자 넘기기 안내
  ///
  /// In ko, this message translates to:
  /// **'먼저 다른 멤버에게 관리자를 넘겨주세요.'**
  String get transferOwnershipFirst;

  /// 나가기 버튼
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get leave;

  /// 취소 버튼
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// 계속 버튼
  ///
  /// In ko, this message translates to:
  /// **'계속'**
  String get continueButton;

  /// 가족 참여 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'가족 참여'**
  String get joinFamily;

  /// 초대 코드 입력 안내
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 입력하세요'**
  String get enterInviteCode;

  /// 초대 코드 입력 설명
  ///
  /// In ko, this message translates to:
  /// **'가족 관리자에게 받은 6자리 코드를 입력해주세요.'**
  String get enterInviteCodeDesc;

  /// 가족 참여 버튼
  ///
  /// In ko, this message translates to:
  /// **'가족 참여하기'**
  String get joinFamilyButton;

  /// 유효한 초대 라벨
  ///
  /// In ko, this message translates to:
  /// **'유효한 초대'**
  String get validInvite;

  /// 가족 멤버 수
  ///
  /// In ko, this message translates to:
  /// **'{count}명의 가족'**
  String memberCount(String count);

  /// 아기 이름 목록
  ///
  /// In ko, this message translates to:
  /// **'아기: {names}'**
  String babyNames(String names);

  /// 만료 일수
  ///
  /// In ko, this message translates to:
  /// **'{days}일 후 만료'**
  String expiresIn(String days);

  /// 가족 참여 완료 메시지
  ///
  /// In ko, this message translates to:
  /// **'가족에 참여했어요!'**
  String get joinedFamily;

  /// 관리자 넘기기 제목
  ///
  /// In ko, this message translates to:
  /// **'누구에게 관리자를 넘길까요?'**
  String get transferOwnershipTitle;

  /// 관리자 넘기기 설명
  ///
  /// In ko, this message translates to:
  /// **'관리자는 가족 멤버를 초대하고 관리할 수 있어요.'**
  String get transferOwnershipDesc;

  /// 관리자 넘기기 버튼
  ///
  /// In ko, this message translates to:
  /// **'관리자 넘기기'**
  String get transferOwnershipButton;

  /// 관리자 넘기기 확인 제목
  ///
  /// In ko, this message translates to:
  /// **'관리자를 넘기시겠어요?'**
  String get confirmTransfer;

  /// 관리자 넘기기 확인 설명
  ///
  /// In ko, this message translates to:
  /// **'이 작업은 되돌릴 수 없어요.'**
  String get confirmTransferDesc;

  /// 관리자 넘기기 완료 메시지
  ///
  /// In ko, this message translates to:
  /// **'관리자를 넘겼어요'**
  String get ownershipTransferred;

  /// 기록 가져오기 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'기록 가져오기'**
  String get importRecords;

  /// 아기 매핑 제목
  ///
  /// In ko, this message translates to:
  /// **'기존 기록을 가져올까요?'**
  String get mapBabiesTitle;

  /// 아기 매핑 설명
  ///
  /// In ko, this message translates to:
  /// **'내 아기와 새 가족 아기를 연결하면 기록을 가져올 수 있어요.'**
  String get mapBabiesDesc;

  /// 아기 선택 힌트
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get selectBaby;

  /// 연결 안 함 옵션
  ///
  /// In ko, this message translates to:
  /// **'연결 안 함'**
  String get doNotLink;

  /// 가져오지 않기 버튼
  ///
  /// In ko, this message translates to:
  /// **'가져오지 않기'**
  String get skipImport;

  /// 기록 가져오기 버튼
  ///
  /// In ko, this message translates to:
  /// **'기록 가져오기'**
  String get importRecordsButton;

  /// 기록 가져오기 완료 메시지
  ///
  /// In ko, this message translates to:
  /// **'{count}개 기록을 가져왔어요!'**
  String recordsImported(int count);

  /// 이메일 초대 입력 라벨
  ///
  /// In ko, this message translates to:
  /// **'이메일로 초대'**
  String get inviteByEmail;

  /// 초대 유효 기간
  ///
  /// In ko, this message translates to:
  /// **'{days}일간 유효'**
  String inviteValidDays(String days);

  /// 카카오톡 공유 버튼
  ///
  /// In ko, this message translates to:
  /// **'카카오톡'**
  String get shareKakao;

  /// 코드 복사 버튼
  ///
  /// In ko, this message translates to:
  /// **'코드 복사'**
  String get copyCode;

  /// 이메일 발송 완료 메시지
  ///
  /// In ko, this message translates to:
  /// **'초대 이메일을 보냈어요!'**
  String get inviteEmailSent;

  /// 잘못된 이메일 에러
  ///
  /// In ko, this message translates to:
  /// **'올바른 이메일을 입력해주세요'**
  String get invalidEmail;

  /// 코드 복사 완료 메시지
  ///
  /// In ko, this message translates to:
  /// **'초대 코드가 복사되었어요!'**
  String get codeCopied;

  /// 아기 정보 없음 제목
  ///
  /// In ko, this message translates to:
  /// **'아기 정보가 없습니다'**
  String get emptyBabiesTitle;

  /// 아기 정보 없음 힌트
  ///
  /// In ko, this message translates to:
  /// **'온보딩을 완료해주세요'**
  String get emptyBabiesHint;

  /// 일간 스코프
  ///
  /// In ko, this message translates to:
  /// **'일간'**
  String get scopeDaily;

  /// 주간 스코프
  ///
  /// In ko, this message translates to:
  /// **'주간'**
  String get scopeWeekly;

  /// 주간 뷰 안내
  ///
  /// In ko, this message translates to:
  /// **'주간 패턴은 통계 탭에서 확인하세요'**
  String get weeklyPatternHint;

  /// 필터 - 전체
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get filterAll;

  /// 활동 - 수유
  ///
  /// In ko, this message translates to:
  /// **'수유'**
  String get activityFeeding;

  /// 활동 - 수면
  ///
  /// In ko, this message translates to:
  /// **'수면'**
  String get activitySleep;

  /// 활동 - 기저귀
  ///
  /// In ko, this message translates to:
  /// **'기저귀'**
  String get activityDiaper;

  /// 활동 - 놀이
  ///
  /// In ko, this message translates to:
  /// **'놀이'**
  String get activityPlay;

  /// 액션 - 수정
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get actionEdit;

  /// 스와이프 힌트
  ///
  /// In ko, this message translates to:
  /// **'밀어서 수정/삭제'**
  String get swipeHint;

  /// 경과 시간 - 방금
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get elapsedJustNow;

  /// 경과 시간 - N분 전
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 전'**
  String elapsedMinutesAgo(int minutes);

  /// 경과 시간 - N시간 전
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 전'**
  String elapsedHoursAgo(int hours);

  /// 경과 시간 - N시간 N분 전
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분 전'**
  String elapsedHoursMinutesAgo(int hours, int minutes);

  /// 경과 시간 - N일 전
  ///
  /// In ko, this message translates to:
  /// **'{days}일 전'**
  String elapsedDaysAgo(int days);

  /// 기록 수정 완료 메시지
  ///
  /// In ko, this message translates to:
  /// **'기록이 수정되었어요'**
  String get recordUpdated;

  /// 다시 시도 버튼
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// 기본 아기 이름
  ///
  /// In ko, this message translates to:
  /// **'아기'**
  String get babyDefault;

  /// 가족 정보 없음 메시지
  ///
  /// In ko, this message translates to:
  /// **'가족 정보가 없어요'**
  String get familyInfoMissing;

  /// 데이터 로딩 타임아웃 메시지
  ///
  /// In ko, this message translates to:
  /// **'데이터 로딩이 너무 오래 걸려요...'**
  String get dataLoadTimeout;

  /// 데이터 로드 실패 메시지
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러올 수 없어요'**
  String get dataLoadFailed;

  /// 통계 로딩 메시지
  ///
  /// In ko, this message translates to:
  /// **'통계를 불러오는 중...'**
  String get statisticsLoading;

  /// 일반 오류 메시지
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했어요'**
  String get errorOccurred;

  /// 권장 범위 내
  ///
  /// In ko, this message translates to:
  /// **'적정'**
  String get recommendationInRange;

  /// 권장 범위 미달
  ///
  /// In ko, this message translates to:
  /// **'적음'**
  String get recommendationBelow;

  /// 권장 범위 초과
  ///
  /// In ko, this message translates to:
  /// **'많음'**
  String get recommendationAbove;

  /// 오늘
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get today;

  /// 횟수 단위 - N회
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String countTimes(int count);

  /// 전주 대비
  ///
  /// In ko, this message translates to:
  /// **'vs 전주'**
  String get vsPrev;

  /// DailyGrid 수면 레이블
  ///
  /// In ko, this message translates to:
  /// **'수면'**
  String get dailyGridSleep;

  /// DailyGrid 수유 레이블
  ///
  /// In ko, this message translates to:
  /// **'수유'**
  String get dailyGridFeeding;

  /// DailyGrid 기저귀 레이블
  ///
  /// In ko, this message translates to:
  /// **'기저귀'**
  String get dailyGridDiaper;

  /// DailyGrid 놀이 레이블
  ///
  /// In ko, this message translates to:
  /// **'놀이'**
  String get dailyGridPlay;

  /// WeeklyGrid 평균 수면 레이블
  ///
  /// In ko, this message translates to:
  /// **'평균 수면'**
  String get weeklyGridAvgSleep;

  /// WeeklyGrid 평균 수유 레이블
  ///
  /// In ko, this message translates to:
  /// **'평균 수유'**
  String get weeklyGridAvgFeeding;

  /// WeeklyGrid 평균 기저귀 레이블
  ///
  /// In ko, this message translates to:
  /// **'평균 기저귀'**
  String get weeklyGridAvgDiaper;

  /// WeeklyGrid 평균 놀이 레이블
  ///
  /// In ko, this message translates to:
  /// **'평균 놀이'**
  String get weeklyGridAvgPlay;

  /// 수유 횟수
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String dailyGridFeedingCount(int count);

  /// 일반 횟수
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String dailyGridCount(int count);

  /// 경과 시간 (시간+분)
  ///
  /// In ko, this message translates to:
  /// **'{hours}h {minutes}m 전'**
  String dailyGridElapsedHours(int hours, int minutes);

  /// 경과 시간 (분)
  ///
  /// In ko, this message translates to:
  /// **'{minutes}m 전'**
  String dailyGridElapsedMinutes(int minutes);

  /// 기록 없음 표시
  ///
  /// In ko, this message translates to:
  /// **'-'**
  String get dailyGridNoRecord;

  /// 횟수 단위
  ///
  /// In ko, this message translates to:
  /// **'회'**
  String get dailyGridCountUnit;

  /// 시간 단위
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get dailyGridUnitHours;

  /// 분 단위
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get dailyGridUnitMinutes;

  /// 기존 유저 - 오늘 기록 없음 안내
  ///
  /// In ko, this message translates to:
  /// **'오늘은 아직 기록이 없어요'**
  String get dailyViewNoRecordsToday;

  /// 기존 유저 - 특정 날짜 기록 없음 안내
  ///
  /// In ko, this message translates to:
  /// **'{date}에는 기록이 없어요'**
  String dailyViewNoRecordsDate(String date);

  /// WeeklyChartFull 제목
  ///
  /// In ko, this message translates to:
  /// **'주간 패턴'**
  String get weeklyChartTitle;

  /// WeeklyChartFull 빈 상태 제목
  ///
  /// In ko, this message translates to:
  /// **'아직 패턴을 분석하기엔\n데이터가 부족해요'**
  String get weeklyChartEmptyTitle;

  /// WeeklyChartFull 빈 상태 힌트
  ///
  /// In ko, this message translates to:
  /// **'3일 이상 기록하면 패턴이 나타나요'**
  String get weeklyChartEmptyHint;

  /// 요일 - 월요일
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get weekdayMon;

  /// 요일 - 화요일
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get weekdayTue;

  /// 요일 - 수요일
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get weekdayWed;

  /// 요일 - 목요일
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get weekdayThu;

  /// 요일 - 금요일
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get weekdayFri;

  /// 요일 - 토요일
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get weekdaySat;

  /// 요일 - 일요일
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get weekdaySun;

  /// 차트 필터 - 전체
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get chartFilterAll;

  /// 차트 필터 - 수면
  ///
  /// In ko, this message translates to:
  /// **'수면'**
  String get chartFilterSleep;

  /// 차트 필터 - 수유
  ///
  /// In ko, this message translates to:
  /// **'수유'**
  String get chartFilterFeeding;

  /// 차트 필터 - 기저귀
  ///
  /// In ko, this message translates to:
  /// **'기저귀'**
  String get chartFilterDiaper;

  /// 차트 필터 - 놀이
  ///
  /// In ko, this message translates to:
  /// **'놀이'**
  String get chartFilterPlay;

  /// 차트 필터 - 건강
  ///
  /// In ko, this message translates to:
  /// **'건강'**
  String get chartFilterHealth;

  /// 차트 범례 - 밤잠
  ///
  /// In ko, this message translates to:
  /// **'밤잠'**
  String get chartLegendNightSleep;

  /// 차트 범례 - 낮잠
  ///
  /// In ko, this message translates to:
  /// **'낮잠'**
  String get chartLegendDaySleep;

  /// 차트 범례 - 수유
  ///
  /// In ko, this message translates to:
  /// **'수유'**
  String get chartLegendFeeding;

  /// 차트 범례 - 기저귀
  ///
  /// In ko, this message translates to:
  /// **'기저귀'**
  String get chartLegendDiaper;

  /// 차트 범례 - 놀이
  ///
  /// In ko, this message translates to:
  /// **'놀이'**
  String get chartLegendPlay;

  /// 차트 범례 - 건강
  ///
  /// In ko, this message translates to:
  /// **'건강'**
  String get chartLegendHealth;

  /// 인사이트 제목 - 좋음
  ///
  /// In ko, this message translates to:
  /// **'좋은 소식!'**
  String get insightTitleGood;

  /// 인사이트 제목 - 주의
  ///
  /// In ko, this message translates to:
  /// **'참고하세요'**
  String get insightTitleCaution;

  /// 인사이트 제목 - 기본
  ///
  /// In ko, this message translates to:
  /// **'이번 주 인사이트'**
  String get insightTitleDefault;

  /// 인사이트 제목 - 함께보기
  ///
  /// In ko, this message translates to:
  /// **'함께보기 인사이트'**
  String get insightTitleTogether;

  /// 주간 캘린더 피커 제목
  ///
  /// In ko, this message translates to:
  /// **'주 선택'**
  String get weekPickerTitle;

  /// 이번 주 버튼
  ///
  /// In ko, this message translates to:
  /// **'이번 주'**
  String get weekPickerThisWeek;

  /// 일간 캘린더 피커 제목
  ///
  /// In ko, this message translates to:
  /// **'날짜 선택'**
  String get dayPickerTitle;

  /// 오늘 버튼
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get dayPickerToday;

  /// DateNavigator 일간 날짜 포맷: 2/8 (일)
  ///
  /// In ko, this message translates to:
  /// **'{month}/{day} ({weekday})'**
  String dateFormatDaily(String month, String day, String weekday);

  /// DateNavigator 주간 날짜 범위 포맷: 2/2 ~ 2/8
  ///
  /// In ko, this message translates to:
  /// **'{startMonth}/{startDay} ~ {endMonth}/{endDay}'**
  String dateFormatWeeklyRange(
    String startMonth,
    String startDay,
    String endMonth,
    String endDay,
  );

  /// 수면 기록 - 지금 재우기 모드 버튼
  ///
  /// In ko, this message translates to:
  /// **'지금 재우기'**
  String get sleepModeNow;

  /// 수면 기록 취소 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'수면 기록을 취소하시겠습니까?'**
  String get sleepCancelConfirmTitle;

  /// 수면 기록 취소 확인 다이얼로그 메시지
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 수면 기록이 삭제됩니다.'**
  String get sleepCancelConfirmMessage;

  /// 수면 기록 취소 완료 스낵바 메시지
  ///
  /// In ko, this message translates to:
  /// **'수면 기록이 취소되었습니다'**
  String get sleepSessionCanceled;

  /// 빠른 기록 버튼 - 이전과 같이 레이블
  ///
  /// In ko, this message translates to:
  /// **'이전과 같이'**
  String get quickRecordSameAsLast;

  /// 빠른 기록 - 분유 수량 표시
  ///
  /// In ko, this message translates to:
  /// **'분유 {amount}ml'**
  String quickRecordFormulaWithAmount(int amount);

  /// 빠른 기록 - 모유 시간 표시
  ///
  /// In ko, this message translates to:
  /// **'모유 {duration}분'**
  String quickRecordBreastWithDuration(int duration);

  /// 빠른 기록 - 모유 좌/우 표시
  ///
  /// In ko, this message translates to:
  /// **'모유 {side}'**
  String quickRecordBreastWithSide(String side);

  /// 빠른 기록 - 이유식 레이블
  ///
  /// In ko, this message translates to:
  /// **'이유식'**
  String get quickRecordSolidFood;

  /// 수면 기록 화면 - 수면 종류 레이블
  ///
  /// In ko, this message translates to:
  /// **'수면 종류'**
  String get sleepTypeLabel;

  /// 수면 기록 화면 - 수면 시간 레이블
  ///
  /// In ko, this message translates to:
  /// **'수면 시간'**
  String get sleepTimeLabel;

  /// 수면 기록 화면 - 메모 힌트 텍스트
  ///
  /// In ko, this message translates to:
  /// **'특이사항이 있으면 입력해 주세요'**
  String get sleepNotesHint;

  /// 수면 기록 화면 - 시작 시간 레이블
  ///
  /// In ko, this message translates to:
  /// **'시작 시간'**
  String get sleepStartTimeLabel;

  /// 수면 기록 화면 - 종료 시간 레이블
  ///
  /// In ko, this message translates to:
  /// **'종료 시간'**
  String get sleepEndTimeLabel;

  /// 수면 기록 화면 - 낮잠 제안 메시지
  ///
  /// In ko, this message translates to:
  /// **'현재 시간 기준 낮잠이 적절해 보여요'**
  String get sleepSuggestNap;

  /// 수면 기록 화면 - 밤잠 제안 메시지
  ///
  /// In ko, this message translates to:
  /// **'현재 시간 기준 밤잠이 적절해 보여요'**
  String get sleepSuggestNight;

  /// 수면 기록 화면 - 진행 중 상태 표시
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get sleepOngoing;

  /// CSV 내보내기 - 날짜 컬럼명
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get exportColumnDate;

  /// CSV 내보내기 - 시간 컬럼명
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get exportColumnTime;

  /// CSV 내보내기 - 유형 컬럼명
  ///
  /// In ko, this message translates to:
  /// **'유형'**
  String get exportColumnType;

  /// CSV 내보내기 - 상세 컬럼명
  ///
  /// In ko, this message translates to:
  /// **'상세'**
  String get exportColumnDetail;

  /// CSV 내보내기 - 소요시간 컬럼명
  ///
  /// In ko, this message translates to:
  /// **'소요시간'**
  String get exportColumnDuration;

  /// CSV 내보내기 - 메모 컬럼명
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get exportColumnNotes;

  /// CSV 내보내기 - 날짜 포맷
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월 {day}일'**
  String exportDateFormat(String year, String month, String day);

  /// CSV 내보내기 - 분 단위 수면 시간
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 수면'**
  String exportSleptMinutes(int minutes);

  /// CSV 내보내기 - 시간+분 단위 수면 시간
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분 수면'**
  String exportSleptHoursMinutes(int hours, int minutes);

  /// CSV 내보내기 - 모유 좌/우 시간
  ///
  /// In ko, this message translates to:
  /// **'{side} {duration}분'**
  String exportBreastSide(String side, int duration);

  /// CSV 내보내기 - 분유량
  ///
  /// In ko, this message translates to:
  /// **'분유 {amount}ml'**
  String exportFormulaAmount(String amount);

  /// CSV 내보내기 - 이유식 상세
  ///
  /// In ko, this message translates to:
  /// **'이유식: {name}'**
  String exportSolidFoodDetail(String name);

  /// CSV 내보내기 - 체온
  ///
  /// In ko, this message translates to:
  /// **'체온 {temp}°C'**
  String exportTemperature(String temp);

  /// CSV 내보내기 - 투약
  ///
  /// In ko, this message translates to:
  /// **'투약: {name}'**
  String exportMedication(String name);

  /// CSV 내보내기 - 병원 방문
  ///
  /// In ko, this message translates to:
  /// **'병원: {name}'**
  String exportHospitalVisit(String name);

  /// CSV 내보내기 - 증상
  ///
  /// In ko, this message translates to:
  /// **'증상: {name}'**
  String exportSymptom(String name);

  /// 기록 수정 바텀시트 제목
  ///
  /// In ko, this message translates to:
  /// **'기록 수정'**
  String get editActivityTitle;

  /// 기록 수정 - 유형 레이블
  ///
  /// In ko, this message translates to:
  /// **'기록 유형'**
  String get editActivityTypeLabel;

  /// 기록 수정 - 시작 시간 레이블
  ///
  /// In ko, this message translates to:
  /// **'시작 시간'**
  String get editStartTimeLabel;

  /// 기록 수정 - 종료 시간 레이블
  ///
  /// In ko, this message translates to:
  /// **'종료 시간'**
  String get editEndTimeLabel;

  /// 기록 수정 - 수유량 레이블
  ///
  /// In ko, this message translates to:
  /// **'수유량 (ml)'**
  String get editAmountLabel;

  /// 기록 수정 - 메모 레이블
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get editMemoLabel;

  /// 기록 수정 - 메모 힌트 텍스트
  ///
  /// In ko, this message translates to:
  /// **'메모를 입력하세요'**
  String get editMemoHint;

  /// 기록 수정 성공 스낵바 메시지
  ///
  /// In ko, this message translates to:
  /// **'기록이 수정되었어요'**
  String get editSaveSuccess;

  /// 기록 수정 실패 스낵바 메시지
  ///
  /// In ko, this message translates to:
  /// **'수정 실패: {error}'**
  String editSaveFailed(String error);

  /// 기록 삭제 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'기록을 삭제할까요?'**
  String get editDeleteConfirmTitle;

  /// 기록 삭제 확인 다이얼로그 메시지
  ///
  /// In ko, this message translates to:
  /// **'이 기록을 삭제하시겠습니까?'**
  String get editDeleteConfirmMessage;

  /// 기록 삭제 성공 스낵바 메시지
  ///
  /// In ko, this message translates to:
  /// **'기록이 삭제되었어요'**
  String get editDeleteSuccess;

  /// 기록 삭제 취소 버튼 레이블
  ///
  /// In ko, this message translates to:
  /// **'삭제 취소'**
  String get editUndoDelete;

  /// 설정 화면 - 위험 구역 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'위험 구역'**
  String get settingsDangerZone;

  /// 설정 화면 - 계정 삭제 버튼
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get settingsDeleteAccount;

  /// 설정 화면 - 계정 삭제 설명
  ///
  /// In ko, this message translates to:
  /// **'모든 데이터가 영구적으로 삭제됩니다'**
  String get settingsDeleteAccountDesc;

  /// 설정 화면 - 계정 삭제 확인 메시지
  ///
  /// In ko, this message translates to:
  /// **'정말로 계정을 삭제하시겠습니까?'**
  String get settingsDeleteAccountConfirm;

  /// 설정 화면 - 로그아웃 버튼
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get settingsLogout;

  /// 설정 화면 - 로그아웃 확인 메시지
  ///
  /// In ko, this message translates to:
  /// **'로그아웃 하시겠습니까?'**
  String get settingsLogoutConfirm;

  /// 설정 화면 - 비로그인 상태 텍스트
  ///
  /// In ko, this message translates to:
  /// **'로그인되지 않았습니다'**
  String get settingsNotLoggedIn;

  /// 울음 분석 화면 - 대기 상태 제목
  ///
  /// In ko, this message translates to:
  /// **'아기가 울고 있나요?'**
  String get cryIdleTitle;

  /// 울음 분석 화면 - 대기 상태 부제
  ///
  /// In ko, this message translates to:
  /// **'아래 버튼을 눌러 울음을 분석해보세요'**
  String get cryIdleSubtitle;

  /// 울음 분석 화면 - 녹음 중 제목
  ///
  /// In ko, this message translates to:
  /// **'울음 소리를 듣고 있어요'**
  String get cryRecordingTitle;

  /// 울음 분석 화면 - 녹음 중 부제
  ///
  /// In ko, this message translates to:
  /// **'아기 가까이에서 분석하면 더 정확해요'**
  String get cryRecordingSubtitle;

  /// 울음 분석 화면 - 분석 중 제목
  ///
  /// In ko, this message translates to:
  /// **'울음 패턴을 분석 중이에요'**
  String get cryAnalyzingTitle;

  /// 울음 분석 화면 - 분석 중 부제
  ///
  /// In ko, this message translates to:
  /// **'잠시만 기다려 주세요'**
  String get cryAnalyzingSubtitle;

  /// 울음 분석 화면 - 결과 제목
  ///
  /// In ko, this message translates to:
  /// **'분석 결과'**
  String get cryResultTitle;

  /// 울음 분석 화면 - 시작 버튼
  ///
  /// In ko, this message translates to:
  /// **'울음 분석 시작'**
  String get cryStartButton;

  /// 울음 분석 화면 - 중지 버튼
  ///
  /// In ko, this message translates to:
  /// **'분석 중지'**
  String get cryStopButton;

  /// 울음 분석 화면 - 재분석 버튼
  ///
  /// In ko, this message translates to:
  /// **'다시 분석하기'**
  String get cryReanalyzeButton;

  /// 울음 분석 화면 - 신뢰도 표시
  ///
  /// In ko, this message translates to:
  /// **'신뢰도 {percent}%'**
  String cryConfidence(int percent);

  /// 울음 분석 기록 저장 완료 스낵바
  ///
  /// In ko, this message translates to:
  /// **'울음 분석 기록이 저장되었어요'**
  String get cryRecordSaved;

  /// 울음 분석 화면 - 프라이버시 안내문
  ///
  /// In ko, this message translates to:
  /// **'모든 음성 데이터는 기기에서만 처리되며 저장되지 않습니다'**
  String get cryPrivacyNote;

  /// 울음 분석 화면 - 분석 시작 버튼 레이블
  ///
  /// In ko, this message translates to:
  /// **'분석 시작'**
  String get cryAnalysisStart;

  /// 울음 분석 모델 로드 실패 메시지
  ///
  /// In ko, this message translates to:
  /// **'울음 분석 모델을 불러올 수 없습니다'**
  String get cryModelLoadFailed;

  /// 울음 분석 모델 로딩 중 메시지
  ///
  /// In ko, this message translates to:
  /// **'울음 분석 모델 로딩 중...'**
  String get cryModelLoading;

  /// 울음 분석 결과 저장 확인 메시지
  ///
  /// In ko, this message translates to:
  /// **'결과를 저장할까요?'**
  String get cryResultSavePrompt;

  /// 울음 분석 화면 - 기록 버튼
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get cryRecordButton;

  /// 울음 분석 화면 - 대응 제안 제목
  ///
  /// In ko, this message translates to:
  /// **'이렇게 해보세요'**
  String get cryActionSuggestion;

  /// 울음 분석 화면 - Dunstan 분류 레이블
  ///
  /// In ko, this message translates to:
  /// **'Dunstan Baby Language'**
  String get cryDunstanLabel;

  /// 건강 기록 화면 - 기록 시간 레이블
  ///
  /// In ko, this message translates to:
  /// **'기록 시간'**
  String get healthRecordTimeLabel;

  /// 건강 기록 화면 - 유형 선택 안내
  ///
  /// In ko, this message translates to:
  /// **'기록 유형을 선택하세요'**
  String get healthSelectType;

  /// 건강 기록 화면 - 메모 힌트 텍스트
  ///
  /// In ko, this message translates to:
  /// **'추가 메모를 입력하세요'**
  String get healthNotesHint;

  /// 건강 기록 화면 - 체온 입력 힌트
  ///
  /// In ko, this message translates to:
  /// **'체온을 입력하세요'**
  String get healthTempInput;

  /// 건강 기록 화면 - 증상 선택 안내
  ///
  /// In ko, this message translates to:
  /// **'증상을 선택하세요'**
  String get healthSymptomSelect;

  /// 건강 기록 화면 - 약 이름 힌트
  ///
  /// In ko, this message translates to:
  /// **'약 이름'**
  String get healthMedNameHint;

  /// 건강 기록 화면 - 용량 힌트
  ///
  /// In ko, this message translates to:
  /// **'용량'**
  String get healthMedDoseHint;

  /// 건강 기록 화면 - 병원명 힌트
  ///
  /// In ko, this message translates to:
  /// **'병원명'**
  String get healthHospitalNameHint;

  /// 건강 기록 화면 - 의료 면책 조항
  ///
  /// In ko, this message translates to:
  /// **'이 정보는 참고용이며 의료 조언이 아닙니다'**
  String get healthMedicalDisclaimer;

  /// 건강 기록 화면 - 저체온 경고
  ///
  /// In ko, this message translates to:
  /// **'체온이 낮아요. 보온에 신경써주세요.'**
  String get healthTempWarningLow;

  /// 건강 기록 화면 - 미열 경고
  ///
  /// In ko, this message translates to:
  /// **'미열이 있어요. 지켜봐주세요.'**
  String get healthTempWarningMild;

  /// 건강 기록 화면 - 발열 경고
  ///
  /// In ko, this message translates to:
  /// **'열이 있어요. 병원 방문을 권장해요.'**
  String get healthTempWarningHigh;

  /// 건강 기록 화면 - 정상 체온 안내
  ///
  /// In ko, this message translates to:
  /// **'정상 체온이에요.'**
  String get healthTempNormal;

  /// 선택적 메모 필드 레이블
  ///
  /// In ko, this message translates to:
  /// **'메모 (선택)'**
  String get notesOptionalLabel;

  /// 어제 날짜 표시
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get yesterday;

  /// 성장 요약 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'성장 현황'**
  String get growthOverview;

  /// 성장 측정일 표시
  ///
  /// In ko, this message translates to:
  /// **'{date} 측정 ({relative})'**
  String growthMeasuredAt(String date, String relative);

  /// 성장 카드 - 체중 레이블
  ///
  /// In ko, this message translates to:
  /// **'체중'**
  String get growthWeight;

  /// 성장 카드 - 신장 레이블
  ///
  /// In ko, this message translates to:
  /// **'신장'**
  String get growthLength;

  /// 성장 카드 - 두위 레이블
  ///
  /// In ko, this message translates to:
  /// **'두위'**
  String get growthHeadCircumference;

  /// 성장 카드 - 미측정 표시
  ///
  /// In ko, this message translates to:
  /// **'미측정'**
  String get notMeasured;

  /// 성장 카드 - 적용된 차트 유형 표시
  ///
  /// In ko, this message translates to:
  /// **'{chartType} 적용'**
  String growthChartApplied(String chartType);

  /// 성장 카드 - 교정연령 표시
  ///
  /// In ko, this message translates to:
  /// **'교정연령 {age}'**
  String growthCorrectedAge(String age);

  /// 성장 카드 - 차트 보기 안내
  ///
  /// In ko, this message translates to:
  /// **'탭하여 성장 차트 보기'**
  String get tapToViewGrowthChart;

  /// N일 전 표시
  ///
  /// In ko, this message translates to:
  /// **'{count}일 전'**
  String daysAgoCount(int count);

  /// 온보딩 아기 정보 입력 타이틀
  ///
  /// In ko, this message translates to:
  /// **'{label} 정보를\n입력해 주세요'**
  String onboardingBabyInfoTitle(String label);

  /// 출생일 선택 힌트
  ///
  /// In ko, this message translates to:
  /// **'출생일을 선택해주세요'**
  String get hintSelectBirthDate;

  /// 출생체중 라벨 (필수)
  ///
  /// In ko, this message translates to:
  /// **'출생체중 (필수)'**
  String get labelBirthWeightRequired;

  /// 출생체중 입력 힌트
  ///
  /// In ko, this message translates to:
  /// **'예: 3200'**
  String get hintBirthWeight;

  /// 출생체중 도움말
  ///
  /// In ko, this message translates to:
  /// **'성장 추적 기능에 활용돼요'**
  String get birthWeightHelperText;

  /// 조산아 여부 질문 (전체)
  ///
  /// In ko, this message translates to:
  /// **'조산아인가요?'**
  String get questionIsPretermFull;

  /// 조산아 교정연령 안내
  ///
  /// In ko, this message translates to:
  /// **'37주 미만 출생 시, 교정연령으로 발달을 추적해요'**
  String get prematureAgeInfo;

  /// 아기 정보 없음 제목
  ///
  /// In ko, this message translates to:
  /// **'아기 정보가 없습니다'**
  String get emptyBabyInfoTitle;

  /// 아기 정보 없음 안내
  ///
  /// In ko, this message translates to:
  /// **'온보딩을 완료해주세요'**
  String get emptyBabyInfoHint;

  /// 기본 아기 이름
  ///
  /// In ko, this message translates to:
  /// **'아기'**
  String get defaultBabyName;

  /// 단위 - N분
  ///
  /// In ko, this message translates to:
  /// **'{count}분'**
  String unitMinutes(int count);

  /// 활동 제목 - 기저귀 교체
  ///
  /// In ko, this message translates to:
  /// **'기저귀 교체'**
  String get diaperChange;

  /// 수유 제목 - 모유 수유
  ///
  /// In ko, this message translates to:
  /// **'모유 수유'**
  String get feedingBreastfeeding;

  /// 수유 제목 - 젖병 수유
  ///
  /// In ko, this message translates to:
  /// **'젖병 수유'**
  String get feedingBottleFeeding;

  /// 빠른 기록 버튼 툴팁 (줄바꿈 포함)
  ///
  /// In ko, this message translates to:
  /// **'탭하면 이전과 같은 내용으로\n바로 저장돼요!'**
  String get quickRecordTooltip;

  /// 빠른 기록 - 아기 이름 포함 마지막 기록 반복
  ///
  /// In ko, this message translates to:
  /// **'{name}의 마지막 기록 반복'**
  String quickRecordRepeatWithName(String name);

  /// 시간 표시 - 방금
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get timeAgoJustNow;

  /// 시간 표시 - N분 전
  ///
  /// In ko, this message translates to:
  /// **'{count}분 전'**
  String timeAgoMinutes(int count);

  /// 시간 표시 - N시간 전
  ///
  /// In ko, this message translates to:
  /// **'{count}시간 전'**
  String timeAgoHours(int count);

  /// 라벨 - 기록
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get labelRecord;

  /// 건강 - 체온 값 표시
  ///
  /// In ko, this message translates to:
  /// **'체온 {temp}°C'**
  String healthTempValue(String temp);

  /// 설정 화면 - 위험 영역 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'위험 영역'**
  String get sectionDangerZone;

  /// 아기 상태 - 조산아
  ///
  /// In ko, this message translates to:
  /// **'조산아'**
  String get statusPreterm;

  /// 아기 상태 - 만삭
  ///
  /// In ko, this message translates to:
  /// **'만삭'**
  String get statusFullTerm;

  /// 아기 추가 최대 인원 안내
  ///
  /// In ko, this message translates to:
  /// **'최대 4명까지 등록 가능'**
  String get addBabyMaxHint;

  /// 가족 관리 - 초대 안내
  ///
  /// In ko, this message translates to:
  /// **'가족 멤버 초대하기'**
  String get familyInviteHint;

  /// 설정 - 가져오기 제목
  ///
  /// In ko, this message translates to:
  /// **'기존 기록 가져오기'**
  String get importRecordsTitle;

  /// 설정 - 가져오기 부제
  ///
  /// In ko, this message translates to:
  /// **'다른 앱에서 기록 이전'**
  String get importRecordsHint;

  /// 설정 - CSV 내보내기 제목
  ///
  /// In ko, this message translates to:
  /// **'CSV로 내보내기'**
  String get exportCSVTitle;

  /// 설정 - 데이터 초기화 제목
  ///
  /// In ko, this message translates to:
  /// **'데이터 초기화'**
  String get resetDataTitle;

  /// 설정 - 데이터 초기화 안내
  ///
  /// In ko, this message translates to:
  /// **'모든 데이터를 삭제하고 처음부터 시작'**
  String get resetDataHint;

  /// 데이터 초기화 확인 메시지
  ///
  /// In ko, this message translates to:
  /// **'정말 모든 데이터를 삭제하시겠어요?'**
  String get resetDataConfirm;

  /// 초기화 경고 - 기록 삭제
  ///
  /// In ko, this message translates to:
  /// **'모든 기록이 삭제됩니다'**
  String get resetWarningRecords;

  /// 초기화 경고 - 아기 정보 삭제
  ///
  /// In ko, this message translates to:
  /// **'아기 정보가 삭제됩니다'**
  String get resetWarningBabies;

  /// 초기화 경고 - 되돌릴 수 없음
  ///
  /// In ko, this message translates to:
  /// **'이 작업은 되돌릴 수 없습니다'**
  String get resetWarningIrreversible;

  /// 데이터 초기화 완료 메시지
  ///
  /// In ko, this message translates to:
  /// **'초기화 완료! 앱을 다시 시작해주세요.'**
  String get resetCompleteMessage;

  /// 에러 - 초기화 실패
  ///
  /// In ko, this message translates to:
  /// **'초기화 실패: {error}'**
  String errorResetFailed(String error);

  /// 울음 분석 - 히스토리 준비중 안내
  ///
  /// In ko, this message translates to:
  /// **'히스토리 기능은 곧 추가됩니다.'**
  String get cryHistoryComingSoon;

  /// 울음 분석 - 대기 상태 안내
  ///
  /// In ko, this message translates to:
  /// **'버튼을 누르고 울음 소리를 들려주세요'**
  String get cryIdleHint;

  /// 울음 분석 - 교정연령 기준 안내
  ///
  /// In ko, this message translates to:
  /// **'교정연령 {weeks}주 기준으로 분석해요'**
  String cryCorrectedAgeInfo(int weeks);

  /// 울음 분석 - 녹음 중 제목
  ///
  /// In ko, this message translates to:
  /// **'듣고 있어요...'**
  String get cryListeningTitle;

  /// 울음 분석 - 녹음 중 안내
  ///
  /// In ko, this message translates to:
  /// **'2-10초 동안 울음 소리를 들려주세요'**
  String get cryListeningHint;

  /// 울음 분석 - 분석 중 제목
  ///
  /// In ko, this message translates to:
  /// **'분석 중...'**
  String get cryAnalyzingText;

  /// 울음 분석 - 분석 중 안내
  ///
  /// In ko, this message translates to:
  /// **'AI가 울음 패턴을 분석하고 있어요'**
  String get cryAnalyzingHint;

  /// 울음 분석 - 분석 상세 제목
  ///
  /// In ko, this message translates to:
  /// **'분석 상세'**
  String get cryDetailTitle;

  /// 울음 분석 - 조산아 신뢰도 보정 안내
  ///
  /// In ko, this message translates to:
  /// **'교정연령 {weeks}주 기준으로 신뢰도를 보정했어요.'**
  String cryPretermAdjustInfo(int weeks);

  /// 울음 분석 - 피드백 감사 메시지
  ///
  /// In ko, this message translates to:
  /// **'피드백을 보내주셨어요. 감사합니다!'**
  String get cryFeedbackThanks;

  /// 울음 분석 - 피드백 질문
  ///
  /// In ko, this message translates to:
  /// **'분석 결과가 맞나요?'**
  String get cryFeedbackQuestion;

  /// 울음 분석 - 피드백 정확함
  ///
  /// In ko, this message translates to:
  /// **'맞아요'**
  String get cryFeedbackCorrect;

  /// 울음 분석 - 피드백 부정확함
  ///
  /// In ko, this message translates to:
  /// **'아니에요'**
  String get cryFeedbackIncorrect;

  /// 울음 분석 - 알 수 없는 오류
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 오류가 발생했어요.'**
  String get cryErrorUnknown;

  /// 버튼 - 다시 시도
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get buttonRetry;

  /// 울음 분석 - 남은 분석 횟수
  ///
  /// In ko, this message translates to:
  /// **'오늘 남은 분석: {count}회'**
  String cryRemainingCount(int count);

  /// 버튼 - 업그레이드
  ///
  /// In ko, this message translates to:
  /// **'업그레이드'**
  String get buttonUpgrade;

  /// 울음 분석 - 면책 조항 (일반)
  ///
  /// In ko, this message translates to:
  /// **'이 분석 결과는 참고용이며, 의료적 조언을 대체하지 않습니다. 걱정되시면 담당 의료진과 상담하세요.'**
  String get cryDisclaimer;

  /// 울음 분석 - 면책 조항 (조산아)
  ///
  /// In ko, this message translates to:
  /// **'이 분석 결과는 참고용이며, 의료적 조언을 대체하지 않습니다. 조산아의 울음 패턴은 개인차가 크므로, 걱정되시면 담당 의료진과 상담하세요.'**
  String get cryDisclaimerWithPreterm;

  /// 울음 분석 - 아기 정보 없음
  ///
  /// In ko, this message translates to:
  /// **'아기 정보를 먼저 등록해주세요'**
  String get cryEmptyBabyInfo;

  /// CSV 헤더 - 날짜
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get csvHeaderDate;

  /// CSV 헤더 - 시간
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get csvHeaderTime;

  /// CSV 헤더 - 종료시간
  ///
  /// In ko, this message translates to:
  /// **'종료시간'**
  String get csvHeaderEndTime;

  /// CSV 헤더 - 아기
  ///
  /// In ko, this message translates to:
  /// **'아기'**
  String get csvHeaderBaby;

  /// CSV 헤더 - 유형
  ///
  /// In ko, this message translates to:
  /// **'유형'**
  String get csvHeaderType;

  /// CSV 헤더 - 상세
  ///
  /// In ko, this message translates to:
  /// **'상세'**
  String get csvHeaderDetail;

  /// CSV 헤더 - 양/시간
  ///
  /// In ko, this message translates to:
  /// **'양/시간'**
  String get csvHeaderAmountDuration;

  /// CSV 헤더 - 메모
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get csvHeaderNotes;

  /// 알 수 없는 아기 이름
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get unknownBaby;

  /// 수면 기록 - 진행 중 수면 아래 새 기록 추가 안내
  ///
  /// In ko, this message translates to:
  /// **'또는 새 기록 추가'**
  String get sleepOrAddNewRecord;

  /// 수면 기록 - 진행 중 수면 상태 표시
  ///
  /// In ko, this message translates to:
  /// **'{babyName} {sleepType} 중'**
  String sleepOngoingStatus(String babyName, String sleepType);

  /// 수면 취소 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 수면 기록이 삭제됩니다.'**
  String get sleepCancelConfirmBody;

  /// 수면 기록 - 기록 추가 모드 버튼
  ///
  /// In ko, this message translates to:
  /// **'기록 추가'**
  String get sleepModeAddRecord;

  /// 수면 기록 - 지금 수면 시작 제목
  ///
  /// In ko, this message translates to:
  /// **'지금 수면 시작'**
  String get sleepStartNow;

  /// 수면 기록 - 지금 수면 시작 안내
  ///
  /// In ko, this message translates to:
  /// **'저장하면 수면이 시작됩니다.\n아기가 깨면 홈 화면에서 종료 버튼을 눌러주세요.'**
  String get sleepStartNowHint;

  /// 수면 기록 - 총 수면 시간 라벨
  ///
  /// In ko, this message translates to:
  /// **'총 수면 시간: '**
  String get sleepTotalDuration;

  /// 수면 기록 - 메모 힌트
  ///
  /// In ko, this message translates to:
  /// **'수면 상태, 특이사항 등'**
  String get hintSleepNotes;

  /// 수면 시작 완료 스낵바 메시지
  ///
  /// In ko, this message translates to:
  /// **'{name} 수면 시작! 홈에서 종료할 수 있어요'**
  String sleepStartedMessage(String name);

  /// 시간 선택 시맨틱 라벨
  ///
  /// In ko, this message translates to:
  /// **'시간 선택'**
  String get labelTimeSelect;

  /// 기록 수정 바텀시트 - 유형별 제목
  ///
  /// In ko, this message translates to:
  /// **'{title} 수정'**
  String editActivityTitleWithType(String title);

  /// 라벨 - 시간
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get labelTime;

  /// 라벨 - 시작
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get labelStart;

  /// 라벨 - 종료
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get labelEnd;

  /// 라벨 - 설정 안 함
  ///
  /// In ko, this message translates to:
  /// **'설정 안 함'**
  String get labelNotSet;

  /// 라벨 - 종류
  ///
  /// In ko, this message translates to:
  /// **'종류'**
  String get labelType;

  /// 수유 정보 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'수유 정보'**
  String get feedingInfo;

  /// 수유량 라벨
  ///
  /// In ko, this message translates to:
  /// **'수유량'**
  String get feedingAmount;

  /// 기저귀 정보 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'기저귀 정보'**
  String get diaperInfo;

  /// 놀이 정보 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'놀이 정보'**
  String get playInfo;

  /// 건강 정보 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'건강 정보'**
  String get healthInfo;

  /// 라벨 - 메모
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get labelNotes;

  /// 힌트 - 메모 입력
  ///
  /// In ko, this message translates to:
  /// **'메모를 입력하세요'**
  String get hintNotes;

  /// 라벨 - 시작 시간
  ///
  /// In ko, this message translates to:
  /// **'시작 시간'**
  String get labelStartTime;

  /// 라벨 - 종료 시간
  ///
  /// In ko, this message translates to:
  /// **'종료 시간'**
  String get labelEndTime;

  /// 저장 실패 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'저장 실패: {error}'**
  String errorSaveFailed(String error);

  /// 활동 - 건강
  ///
  /// In ko, this message translates to:
  /// **'건강'**
  String get activityHealth;

  /// 라벨 - 기타
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get labelOther;

  /// 건강 기록 - 유형 선택 라벨
  ///
  /// In ko, this message translates to:
  /// **'기록 유형 선택'**
  String get healthTypeSelectLabel;

  /// 건강 기록 - 증상 선택 라벨
  ///
  /// In ko, this message translates to:
  /// **'증상 선택 (복수 선택 가능)'**
  String get healthSymptomSelectLabel;

  /// 증상 - 기타
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get symptomOther;

  /// 건강 기록 - 투약 정보 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'투약 정보'**
  String get healthMedicationInfo;

  /// 건강 기록 - 투약 정보 힌트
  ///
  /// In ko, this message translates to:
  /// **'약 이름, 용량, 복용 방법 등'**
  String get hintMedication;

  /// 건강 기록 - 병원 방문 정보 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'병원 방문 정보'**
  String get healthHospitalInfo;

  /// 건강 기록 - 병원 방문 힌트
  ///
  /// In ko, this message translates to:
  /// **'병원명, 진료 내용, 처방 등'**
  String get hintHospital;

  /// 추가 메모 힌트
  ///
  /// In ko, this message translates to:
  /// **'추가 메모'**
  String get hintAdditionalNotes;

  /// 의료 면책 조항 (2줄)
  ///
  /// In ko, this message translates to:
  /// **'이 기록은 참고용이며 의료 진단을 대체하지 않습니다.\n이상 증상이 있으면 소아과 전문의와 상담하세요.'**
  String get medicalDisclaimer;

  /// 라벨 - 기록 시간
  ///
  /// In ko, this message translates to:
  /// **'기록 시간'**
  String get labelRecordTime;

  /// 리포트 카드 - 이번 주 횟수
  ///
  /// In ko, this message translates to:
  /// **'이번 주 {count}회'**
  String reportThisWeekCount(int count);

  /// 리포트 카드 - 야간 기상 레이블
  ///
  /// In ko, this message translates to:
  /// **'야간 기상'**
  String get reportNightWakeups;

  /// 울음 타입 - 배고픔 라벨
  ///
  /// In ko, this message translates to:
  /// **'배고픔'**
  String get cryTypeHungryLabel;

  /// 울음 타입 - 졸림 라벨
  ///
  /// In ko, this message translates to:
  /// **'졸림'**
  String get cryTypeTiredLabel;

  /// 울음 타입 - 가스 라벨
  ///
  /// In ko, this message translates to:
  /// **'가스'**
  String get cryTypeGasLabel;

  /// 울음 타입 - 불편 라벨
  ///
  /// In ko, this message translates to:
  /// **'불편'**
  String get cryTypeDiscomfortLabel;

  /// 기저귀 기록 - 상태 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'기저귀 상태'**
  String get diaperStatus;

  /// 기저귀 기록 - 교체 시간 라벨
  ///
  /// In ko, this message translates to:
  /// **'기저귀 교체 시간'**
  String get diaperChangeTime;

  /// 기저귀 기록 - 대변 색상 선택적 라벨
  ///
  /// In ko, this message translates to:
  /// **'대변 색상 (선택)'**
  String get stoolColorOptional;

  /// 기저귀 기록 - 대변 색상 도움말
  ///
  /// In ko, this message translates to:
  /// **'색상을 선택하면 건강 추적에 도움이 됩니다'**
  String get stoolColorHelpText;

  /// 기저귀 기록 - 위험 대변 색상 경고
  ///
  /// In ko, this message translates to:
  /// **'이 색상은 의료 상담이 필요할 수 있습니다.\n지속되면 소아과 방문을 권장합니다.'**
  String get stoolColorWarning;

  /// 기저귀 기록 - 메모 힌트
  ///
  /// In ko, this message translates to:
  /// **'색상, 양, 특이사항 등'**
  String get diaperNotesHint;

  /// 빠른 기록과 상세 입력 사이 구분 텍스트
  ///
  /// In ko, this message translates to:
  /// **'또는 상세 입력'**
  String get orDetailedEntry;

  /// 놀이 기록 - 활동 유형 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'활동 유형'**
  String get playActivityType;

  /// 놀이 기록 - 터미타임 권장 안내
  ///
  /// In ko, this message translates to:
  /// **'교정연령 기준 권장: 하루 3-5분씩 여러 번'**
  String get playTummyTimeRecommendation;

  /// 놀이 기록 - 활동 시간 선택적 라벨
  ///
  /// In ko, this message translates to:
  /// **'활동 시간 (선택)'**
  String get playDurationOptional;

  /// 놀이 기록 - 직접 입력 힌트
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get playDirectInput;

  /// 놀이 기록 - 메모 힌트
  ///
  /// In ko, this message translates to:
  /// **'아기의 반응, 특이사항 등'**
  String get playNotesHint;

  /// 놀이 기록 - 시간 선택 라벨
  ///
  /// In ko, this message translates to:
  /// **'놀이 시간'**
  String get playTimeLabel;

  /// 단위 - 분 (단일)
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get unitMinute;

  /// 울음 타입 - 배고픔 (상세)
  ///
  /// In ko, this message translates to:
  /// **'배고파요'**
  String get cryTypeHungry;

  /// 울음 타입 - 졸림 (상세)
  ///
  /// In ko, this message translates to:
  /// **'졸려요'**
  String get cryTypeTired;

  /// 울음 타입 - 불편함 (상세)
  ///
  /// In ko, this message translates to:
  /// **'불편해요'**
  String get cryTypeDiscomfort;

  /// 울음 타입 - 가스/복통 (상세)
  ///
  /// In ko, this message translates to:
  /// **'배가 아파요'**
  String get cryTypeGas;

  /// 울음 타입 - 트림 (상세)
  ///
  /// In ko, this message translates to:
  /// **'트림이 필요해요'**
  String get cryTypeBurp;

  /// 울음 타입 - 분류 불가
  ///
  /// In ko, this message translates to:
  /// **'분석 중...'**
  String get cryTypeUnknown;

  /// 울음 설명 - 배고픔
  ///
  /// In ko, this message translates to:
  /// **'아기가 배고플 때 내는 울음이에요.\n입을 벌리거나 손을 빠는 행동과 함께 나타나요.'**
  String get cryDescHungry;

  /// 울음 설명 - 졸림
  ///
  /// In ko, this message translates to:
  /// **'아기가 졸리고 피곤할 때 내는 울음이에요.\n하품을 하거나 눈을 비비는 신호와 함께 나타나요.'**
  String get cryDescTired;

  /// 울음 설명 - 불편함
  ///
  /// In ko, this message translates to:
  /// **'아기가 신체적으로 불편할 때 내는 울음이에요.\n기저귀가 젖었거나, 덥거나 추울 수 있어요.'**
  String get cryDescDiscomfort;

  /// 울음 설명 - 가스
  ///
  /// In ko, this message translates to:
  /// **'아기 배에 가스가 찼을 때 내는 울음이에요.\n다리를 배 쪽으로 끌어당기는 동작을 해요.'**
  String get cryDescGas;

  /// 울음 설명 - 트림
  ///
  /// In ko, this message translates to:
  /// **'아기가 트림을 하고 싶을 때 내는 울음이에요.\n수유 후에 자주 나타나요.'**
  String get cryDescBurp;

  /// 울음 설명 - 분류 불가
  ///
  /// In ko, this message translates to:
  /// **'울음 패턴을 분석 중이에요.\n좀 더 명확한 울음 소리가 필요해요.'**
  String get cryDescUnknown;

  /// 울음 권장 행동 - 배고픔
  ///
  /// In ko, this message translates to:
  /// **'수유를 시작해보세요'**
  String get cryActionHungry;

  /// 울음 권장 행동 - 졸림
  ///
  /// In ko, this message translates to:
  /// **'재우기를 시도해보세요'**
  String get cryActionTired;

  /// 울음 권장 행동 - 불편함
  ///
  /// In ko, this message translates to:
  /// **'기저귀와 옷을 확인해보세요'**
  String get cryActionDiscomfort;

  /// 울음 권장 행동 - 가스
  ///
  /// In ko, this message translates to:
  /// **'배를 부드럽게 마사지해보세요'**
  String get cryActionGas;

  /// 울음 권장 행동 - 트림
  ///
  /// In ko, this message translates to:
  /// **'등을 토닥이며 트림시켜주세요'**
  String get cryActionBurp;

  /// 울음 권장 행동 - 분류 불가
  ///
  /// In ko, this message translates to:
  /// **'다시 분석해보세요'**
  String get cryActionUnknown;

  /// 울음 분석 - Dunstan 사운드 코드 라벨
  ///
  /// In ko, this message translates to:
  /// **'{code} 사운드'**
  String crySoundLabel(String code);

  /// 에러 - 아기 선택 필요
  ///
  /// In ko, this message translates to:
  /// **'아기를 선택해주세요'**
  String get errorSelectBaby;

  /// 성장 기록 - 측정일 라벨
  ///
  /// In ko, this message translates to:
  /// **'측정일'**
  String get growthMeasuredDateLabel;

  /// 버튼 - 변경
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get buttonChange;

  /// 라벨 - 선택 (필수가 아닌 항목)
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get labelOptional;

  /// 성장 기록 - 메모 힌트
  ///
  /// In ko, this message translates to:
  /// **'소아과 정기검진, 예방접종 등'**
  String get growthNoteHint;

  /// 성공 - 성장 기록 저장됨
  ///
  /// In ko, this message translates to:
  /// **'성장 기록이 저장되었어요'**
  String get successGrowthRecordSaved;

  /// 성장 기록 - 팁
  ///
  /// In ko, this message translates to:
  /// **'소아과 정기검진 후 기록하면 정확해요'**
  String get growthTipCheckup;

  /// Sweet Spot 예상 시간 - 분 단위
  ///
  /// In ko, this message translates to:
  /// **'약 {count}분 후'**
  String sweetSpotEstimateMinutes(int count);

  /// Sweet Spot 예상 시간 - 시간 단위
  ///
  /// In ko, this message translates to:
  /// **'약 {count}시간 후'**
  String sweetSpotEstimateHours(int count);

  /// Sweet Spot 예상 시간 - 시간+분 단위
  ///
  /// In ko, this message translates to:
  /// **'약 {hours}시간 {minutes}분 후'**
  String sweetSpotEstimateHoursMinutes(int hours, int minutes);

  /// 수면 종료 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'수면을 종료할까요?'**
  String get sleepEndConfirmTitle;

  /// 버튼 - 종료
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get buttonEnd;

  /// 성장 차트 화면 제목 (아기 이름 포함)
  ///
  /// In ko, this message translates to:
  /// **'{name} 성장 차트'**
  String growthChartTitleWithName(String name);

  /// 성장 차트 - WHO 전환 예정 안내
  ///
  /// In ko, this message translates to:
  /// **'WHO 차트 전환 예정'**
  String get growthChartWhoTransition;

  /// 성장 차트 - 현재 측정 항목
  ///
  /// In ko, this message translates to:
  /// **'현재 {metric}'**
  String growthCurrentMetric(String metric);

  /// 성장 차트 - 백분위 라벨
  ///
  /// In ko, this message translates to:
  /// **'백분위'**
  String get growthPercentile;

  /// 성장 차트 - 측정 필요 표시
  ///
  /// In ko, this message translates to:
  /// **'측정 필요'**
  String get growthNeedMeasurement;

  /// 에러 - 체중 입력 필수
  ///
  /// In ko, this message translates to:
  /// **'체중을 입력해주세요'**
  String get errorEnterWeight;

  /// 에러 - 체중 최소값 미달
  ///
  /// In ko, this message translates to:
  /// **'체중이 너무 작습니다 (최소 0.3kg)'**
  String get errorWeightTooLow;

  /// 에러 - 체중 최대값 초과
  ///
  /// In ko, this message translates to:
  /// **'체중이 너무 큽니다 (최대 30kg)'**
  String get errorWeightTooHigh;

  /// 에러 - 신장 최소값 미달
  ///
  /// In ko, this message translates to:
  /// **'신장이 너무 작습니다 (최소 20cm)'**
  String get errorLengthTooLow;

  /// 에러 - 신장 최대값 초과
  ///
  /// In ko, this message translates to:
  /// **'신장이 너무 큽니다 (최대 120cm)'**
  String get errorLengthTooHigh;

  /// 에러 - 두위 최소값 미달
  ///
  /// In ko, this message translates to:
  /// **'두위가 너무 작습니다 (최소 15cm)'**
  String get errorHeadCircTooLow;

  /// 에러 - 두위 최대값 초과
  ///
  /// In ko, this message translates to:
  /// **'두위가 너무 큽니다 (최대 60cm)'**
  String get errorHeadCircTooHigh;

  /// 에러 - 측정일 선택 필수
  ///
  /// In ko, this message translates to:
  /// **'측정일을 선택해주세요'**
  String get errorSelectMeasuredDate;

  /// 에러 - 측정일이 출생일 이전
  ///
  /// In ko, this message translates to:
  /// **'측정일은 출생일 이후여야 합니다'**
  String get errorMeasuredDateAfterBirth;

  /// 에러 - 미래 날짜 선택 불가
  ///
  /// In ko, this message translates to:
  /// **'미래 날짜는 선택할 수 없습니다'**
  String get errorFutureDate;

  /// 경고 - 급격한 체중 변화
  ///
  /// In ko, this message translates to:
  /// **'급격한 변화가 감지되었어요. 입력값을 확인해주세요.'**
  String get warningRapidWeightChange;

  /// 경고 - 급격한 신장 변화
  ///
  /// In ko, this message translates to:
  /// **'급격한 신장 변화가 감지되었어요. 입력값을 확인해주세요.'**
  String get warningRapidLengthChange;

  /// 함께 보기 - 다태아 필요 안내
  ///
  /// In ko, this message translates to:
  /// **'아기 2명 이상일 때 함께 보기가 가능해요'**
  String get togetherViewNeedMultipleBabies;

  /// 수면 패턴 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'수면 패턴'**
  String get sleepPattern;

  /// 낮잠 비율 퍼센트
  ///
  /// In ko, this message translates to:
  /// **'낮잠 {percent}%'**
  String napRatioPercent(int percent);

  /// 밤잠 비율 퍼센트
  ///
  /// In ko, this message translates to:
  /// **'밤잠 {percent}%'**
  String nightRatioPercent(int percent);

  /// 인사이트 - 낮잠 비율 높음
  ///
  /// In ko, this message translates to:
  /// **'낮잠 비율이 높아요'**
  String get insightNapRatioHigh;

  /// 인사이트 - 밤잠 비율 높음
  ///
  /// In ko, this message translates to:
  /// **'밤잠 비율이 높아요'**
  String get insightNightRatioHigh;

  /// 인사이트 - 패턴 차이 안내 (비교 금지, 차이만 표현)
  ///
  /// In ko, this message translates to:
  /// **'{baby1}은 {insight1},\n{baby2}이는 {insight2}\n(패턴이 달라요)'**
  String insightPatternDifference(
    String baby1,
    String insight1,
    String baby2,
    String insight2,
  );

  /// 인사이트 - 수면 시간 증가
  ///
  /// In ko, this message translates to:
  /// **'지난주보다 수면 시간이 늘었어요'**
  String get insightSleepIncreased;

  /// 인사이트 - 수면 시간 감소
  ///
  /// In ko, this message translates to:
  /// **'지난주보다 수면 시간이 줄었어요'**
  String get insightSleepDecreased;

  /// 인사이트 - 가장 수면이 많은 요일
  ///
  /// In ko, this message translates to:
  /// **'{dayName}에 가장 많이 잤어요'**
  String insightMostSleepDay(String dayName);

  /// 인사이트 - 기록 없을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'기록을 시작해보세요'**
  String get insightStartRecording;

  /// 수면 중복 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'{babyName} 수면이 진행 중이에요'**
  String sleepInProgressTitle(String babyName);

  /// 수면 중복 다이얼로그 경과 시간
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분째 수면 중'**
  String sleepInProgressDuration(int hours, int minutes);

  /// 수면 중복 다이얼로그 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'종료 후 새로 시작'**
  String get sleepEndAndStart;

  /// 과거 수면 추가 시 겹침 경고
  ///
  /// In ko, this message translates to:
  /// **'수면 시간이 겹칩니다. 확인해주세요'**
  String get sleepOverlapWarning;

  /// 저장 확인 토스트 액션 - 기록 탭으로 이동
  ///
  /// In ko, this message translates to:
  /// **'기록 보기'**
  String get viewRecord;

  /// 에러 - 재시도 한도 초과
  ///
  /// In ko, this message translates to:
  /// **'잠시 후 다시 시도해주세요'**
  String get errorRetryLater;

  /// 에러 - 네트워크 연결 확인
  ///
  /// In ko, this message translates to:
  /// **'인터넷 연결을 확인해주세요'**
  String get errorNetworkCheck;

  /// 에러 - 연결 타임아웃
  ///
  /// In ko, this message translates to:
  /// **'연결이 느려요. 다시 시도할까요?'**
  String get errorConnectionSlow;

  /// 에러 - 데이터 로드 실패 (일반)
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러오지 못했어요'**
  String get errorDataLoadFailed;

  /// 백분위 - 측정 필요 (짧은)
  ///
  /// In ko, this message translates to:
  /// **'측정 필요'**
  String get percentileMeasureNeeded;

  /// 백분위 - 3% 미만
  ///
  /// In ko, this message translates to:
  /// **'3% 미만'**
  String get percentileBelow3;

  /// 백분위 - 97% 초과
  ///
  /// In ko, this message translates to:
  /// **'97% 초과'**
  String get percentileAbove97;

  /// 백분위 상태 - 정상 (Huckleberry 스타일)
  ///
  /// In ko, this message translates to:
  /// **'잘 자라고 있어요'**
  String get percentileGrowingWell;

  /// 백분위 상태 - 관찰 (Huckleberry 스타일)
  ///
  /// In ko, this message translates to:
  /// **'지켜봐 주세요'**
  String get percentileWatchNeeded;

  /// 백분위 상태 - 주의 (Huckleberry 스타일)
  ///
  /// In ko, this message translates to:
  /// **'소아과 상담을 고려해주세요'**
  String get percentileDoctorConsult;

  /// 백분위 상태 - 측정 필요
  ///
  /// In ko, this message translates to:
  /// **'측정이 필요해요'**
  String get percentileMeasurementNeeded;

  /// 온보딩 - 다둥이 팁 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'다둥이 기록 팁'**
  String get multipleBirthTipTitle;

  /// 온보딩 - 다둥이 팁 부제목
  ///
  /// In ko, this message translates to:
  /// **'더 쉽게 기록할 수 있어요'**
  String get multipleBirthTipSubtitle;

  /// 다둥이 팁 - 빠른 전환 제목
  ///
  /// In ko, this message translates to:
  /// **'탭으로 빠른 전환'**
  String get multipleBirthTipQuickSwitchTitle;

  /// 다둥이 팁 - 빠른 전환 설명
  ///
  /// In ko, this message translates to:
  /// **'상단 탭을 눌러 아기별 기록을\n빠르게 확인하고 전환해요 (1초 이내!)'**
  String get multipleBirthTipQuickSwitchDesc;

  /// 다둥이 팁 - 개별 통계 제목
  ///
  /// In ko, this message translates to:
  /// **'개별 통계'**
  String get multipleBirthTipIndividualStatsTitle;

  /// 다둥이 팁 - 개별 통계 설명
  ///
  /// In ko, this message translates to:
  /// **'각 아기의 수유, 수면, 기저귀 패턴을\n개별로 분석해드려요'**
  String get multipleBirthTipIndividualStatsDesc;

  /// 다둥이 팁 - 개별 알림 제목
  ///
  /// In ko, this message translates to:
  /// **'개별 알림'**
  String get multipleBirthTipIndividualAlertTitle;

  /// 다둥이 팁 - 개별 알림 설명
  ///
  /// In ko, this message translates to:
  /// **'각 아기 맞춤 수유/수면 시간을\n따로 알려드려요'**
  String get multipleBirthTipIndividualAlertDesc;

  /// 다둥이 팁 - 색상 구분 제목
  ///
  /// In ko, this message translates to:
  /// **'색상으로 구분'**
  String get multipleBirthTipColorCodeTitle;

  /// 다둥이 팁 - 색상 구분 설명
  ///
  /// In ko, this message translates to:
  /// **'각 아기만의 색상으로\n한눈에 구분할 수 있어요'**
  String get multipleBirthTipColorCodeDesc;

  /// 파이 차트 접근성 - 접두어
  ///
  /// In ko, this message translates to:
  /// **'비율 차트.'**
  String get pieChartAccessibilityPrefix;

  /// 파이 차트 접근성 - 섹션 읽기
  ///
  /// In ko, this message translates to:
  /// **'{label} {percent}퍼센트'**
  String pieChartAccessibilitySection(String label, int percent);

  /// 오프라인 배너 - 마지막 동기화 시간
  ///
  /// In ko, this message translates to:
  /// **'오프라인 모드 - 마지막 동기화: {time}'**
  String offlineModeLastSync(String time);

  /// 시간 - 알 수 없음
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get timeUnknown;

  /// 통계 빈 상태 - 첫 기록 시작 안내
  ///
  /// In ko, this message translates to:
  /// **'첫 기록을 시작해보세요!'**
  String get statisticsEmptyStartHint;

  /// 통계 빈 상태 - 기록 시작 버튼
  ///
  /// In ko, this message translates to:
  /// **'기록 시작하기'**
  String get statisticsStartRecording;

  /// 온보딩 완료 화면 타이틀
  ///
  /// In ko, this message translates to:
  /// **'준비 완료!'**
  String get onboardingCompletionTitle;

  /// 온보딩 완료 - 조산아 메시지
  ///
  /// In ko, this message translates to:
  /// **'{names}의 교정연령에 맞춰\n발달을 꼼꼼히 기록해드릴게요'**
  String onboardingCompletionPreterm(String names);

  /// 온보딩 완료 - SGA 메시지
  ///
  /// In ko, this message translates to:
  /// **'{names}의 성장을 세심하게\n추적해드릴게요'**
  String onboardingCompletionSGA(String names);

  /// 온보딩 완료 - 일반 메시지
  ///
  /// In ko, this message translates to:
  /// **'{names}의 육아 기록을\n시작할 준비가 되었어요'**
  String onboardingCompletionReady(String names);

  /// 온보딩 완료 - 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다: {error}'**
  String onboardingCompletionError(String error);

  /// 재태주수 짧은 표기
  ///
  /// In ko, this message translates to:
  /// **'{weeks}주'**
  String gestationalWeeksShort(int weeks);

  /// SGA 성장 추적 배지
  ///
  /// In ko, this message translates to:
  /// **'성장 추적'**
  String get growthTracking;

  /// 나이 표시 - N일
  ///
  /// In ko, this message translates to:
  /// **'{count}일'**
  String ageInfoDays(int count);

  /// 나이 표시 - N개월
  ///
  /// In ko, this message translates to:
  /// **'{count}개월'**
  String ageInfoMonths(int count);

  /// 나이 표시 - N살
  ///
  /// In ko, this message translates to:
  /// **'{count}살'**
  String ageInfoYears(int count);

  /// 나이 표시 - N살 N개월
  ///
  /// In ko, this message translates to:
  /// **'{years}살 {months}개월'**
  String ageInfoYearsMonths(int years, int months);

  /// 수유 컨텐츠 - 모유 서브 라벨
  ///
  /// In ko, this message translates to:
  /// **'(직접/유축)'**
  String get feedingContentBreastMilkSub;

  /// 수유 방법 - 유축 젖병
  ///
  /// In ko, this message translates to:
  /// **'유축 젖병'**
  String get feedingMethodExpressedBottle;

  /// 이유식 단위 - 그램
  ///
  /// In ko, this message translates to:
  /// **'g'**
  String get solidFoodUnitGram;

  /// 이유식 단위 - 숟가락
  ///
  /// In ko, this message translates to:
  /// **'숟가락'**
  String get solidFoodUnitSpoon;

  /// 이유식 단위 - 그릇
  ///
  /// In ko, this message translates to:
  /// **'그릇'**
  String get solidFoodUnitBowl;

  /// 동일란 구분 - 일란성
  ///
  /// In ko, this message translates to:
  /// **'일란성'**
  String get zygosityIdentical;

  /// 동일란 구분 - 이란성
  ///
  /// In ko, this message translates to:
  /// **'이란성'**
  String get zygosityFraternal;

  /// 동일란 구분 - 모름
  ///
  /// In ko, this message translates to:
  /// **'모름'**
  String get zygosityUnknown;

  /// 이메일 로그인 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'이메일 로그인'**
  String get authEmailLoginTitle;

  /// 회원가입 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get authSignupTitle;

  /// 이메일 입력 라벨
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get authEmailLabel;

  /// 비밀번호 입력 라벨
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get authPasswordLabel;

  /// 이메일 필수 입력 검증
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력해주세요'**
  String get authEmailRequired;

  /// 이메일 형식 검증
  ///
  /// In ko, this message translates to:
  /// **'유효한 이메일 주소를 입력해주세요'**
  String get authEmailInvalid;

  /// 비밀번호 필수 입력 검증
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력해주세요'**
  String get authPasswordRequired;

  /// 비밀번호 최소 길이 검증
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 최소 6자 이상이어야 합니다'**
  String get authPasswordMinLength;

  /// 닉네임 입력 라벨
  ///
  /// In ko, this message translates to:
  /// **'닉네임 (선택)'**
  String get authNicknameLabel;

  /// 회원가입 버튼
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get authSignupButton;

  /// 로그인 버튼
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get authLoginButton;

  /// 로그인으로 전환 텍스트
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있으신가요? 로그인'**
  String get authToggleToLogin;

  /// 회원가입으로 전환 텍스트
  ///
  /// In ko, this message translates to:
  /// **'계정이 없으신가요? 회원가입'**
  String get authToggleToSignup;

  /// 비밀번호 찾기 텍스트
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 잊으셨나요?'**
  String get authForgotPassword;

  /// 비밀번호 재설정 이메일 발송 성공
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정 이메일을 발송했습니다'**
  String get authPasswordResetSent;

  /// 비밀번호 재설정 이메일 발송 실패
  ///
  /// In ko, this message translates to:
  /// **'이메일 발송에 실패했습니다'**
  String get authPasswordResetFailed;

  /// Sweet Spot 수면 카드 - 시작 시간 라벨
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get sweetSpotSleepStart;

  /// Sweet Spot 수면 카드 - 종료 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'탭하여 수면 종료'**
  String get sweetSpotTapToEndSleep;

  /// Sweet Spot 카드 헤더 - 다음 수면 타입 (이름 없음)
  ///
  /// In ko, this message translates to:
  /// **'다음 {sleepType}'**
  String sweetSpotNextSleepType(String sleepType);

  /// Sweet Spot 카드 시간 예측 표시
  ///
  /// In ko, this message translates to:
  /// **'약 {time} ({minutes}분 후)'**
  String sweetSpotTimeEstimate(String time, int minutes);

  /// 조산아 정보 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'{label}의 출생 정보를\n입력해 주세요'**
  String pretermInfoTitle(String label);

  /// 조산아 정보 화면 부제목
  ///
  /// In ko, this message translates to:
  /// **'교정연령 계산에 사용돼요'**
  String get pretermInfoSubtitle;

  /// 조산아 정보 - 출생 주수 라벨
  ///
  /// In ko, this message translates to:
  /// **'출생 주수'**
  String get pretermGestationalWeeksLabel;

  /// 조산아 정보 - 주 단위
  ///
  /// In ko, this message translates to:
  /// **'주'**
  String get pretermWeeksUnit;

  /// 조산아 정보 - 교정연령 설명 제목
  ///
  /// In ko, this message translates to:
  /// **'교정연령이란?'**
  String get pretermCorrectedAgeTitle;

  /// 조산아 정보 - 교정연령 설명 본문
  ///
  /// In ko, this message translates to:
  /// **'만삭 예정일을 기준으로 계산한 나이예요. 조산아의 발달을 더 정확하게 평가할 수 있어요.'**
  String get pretermCorrectedAgeDesc;

  /// 조산아 정보 - 최소 주수 라벨
  ///
  /// In ko, this message translates to:
  /// **'22주'**
  String get pretermWeeksMin;

  /// 조산아 정보 - 조산 기준 안내
  ///
  /// In ko, this message translates to:
  /// **'37주 미만 = 조산'**
  String get pretermWeeksPreterm;

  /// 조산아 정보 - 최대 주수 라벨
  ///
  /// In ko, this message translates to:
  /// **'42주'**
  String get pretermWeeksMax;

  /// 에러 - 활동 데이터 로드 실패
  ///
  /// In ko, this message translates to:
  /// **'활동 데이터를 불러오는데 실패했습니다'**
  String get errorLoadActivities;

  /// 에러 - 가족 데이터 로드 실패
  ///
  /// In ko, this message translates to:
  /// **'가족 데이터를 불러오는데 실패했습니다'**
  String get errorLoadFamilyData;

  /// Sweet Spot 상태 라벨 - 확인 중
  ///
  /// In ko, this message translates to:
  /// **'확인 중'**
  String get sweetSpotStateLabelUnknown;

  /// Sweet Spot 상태 라벨 - 아직 일찍
  ///
  /// In ko, this message translates to:
  /// **'아직 일찍'**
  String get sweetSpotStateLabelTooEarly;

  /// Sweet Spot 상태 라벨 - 곧 수면 시간
  ///
  /// In ko, this message translates to:
  /// **'곧 수면 시간'**
  String get sweetSpotStateLabelApproaching;

  /// Sweet Spot 상태 라벨 - 지금이 최적
  ///
  /// In ko, this message translates to:
  /// **'지금이 최적!'**
  String get sweetSpotStateLabelOptimal;

  /// Sweet Spot 상태 라벨 - 과로 상태
  ///
  /// In ko, this message translates to:
  /// **'과로 상태'**
  String get sweetSpotStateLabelOvertired;

  /// 성장 화면 - 측정 기록 추가 버튼
  ///
  /// In ko, this message translates to:
  /// **'측정 기록 추가'**
  String get growthAddMeasurement;

  /// 성장 화면 - 알 수 없는 오류
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 오류'**
  String get growthErrorUnknown;

  /// 성장 화면 - 오늘 날짜 표시
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get growthRecordToday;

  /// 성장 화면 - 어제 날짜 표시
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get growthRecordYesterday;

  /// 성장 화면 - N일 전 표시
  ///
  /// In ko, this message translates to:
  /// **'{count}일 전'**
  String growthRecordDaysAgo(int count);

  /// Import - 아기 선택 드롭다운 힌트
  ///
  /// In ko, this message translates to:
  /// **'아기 선택'**
  String get importBabySelectHint;

  /// 개수 단위 - N개
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String countItems(int count);

  /// Import - 에러 접두사
  ///
  /// In ko, this message translates to:
  /// **'에러: {error}'**
  String importErrorPrefix(String error);

  /// 알 수 없는 오류 메시지
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 오류가 발생했습니다.'**
  String get errorUnknown;

  /// 수유 시간 라벨
  ///
  /// In ko, this message translates to:
  /// **'수유 시간'**
  String get feedingTimeLabel;

  /// 메모 입력 힌트 텍스트
  ///
  /// In ko, this message translates to:
  /// **'특이사항을 기록하세요'**
  String get notesPlaceholder;

  /// 오늘 요약 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'오늘 요약'**
  String get todaySummaryTitle;

  /// 온보딩 - 아기 수 선택 제목
  ///
  /// In ko, this message translates to:
  /// **'아기가 몇 명인가요?'**
  String get babyCountTitle;

  /// 온보딩 - 아기 수 선택 부제
  ///
  /// In ko, this message translates to:
  /// **'다둥이 가정도 함께 할 수 있어요'**
  String get babyCountSubtitle;

  /// 온보딩 - 아기 수 1명
  ///
  /// In ko, this message translates to:
  /// **'1명'**
  String get babyCountOne;

  /// 기본 아기 라벨 (단태아)
  ///
  /// In ko, this message translates to:
  /// **'아기'**
  String get babyLabelDefault;

  /// 로그인 화면 - 구분선 텍스트
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get authOrDivider;

  /// 로그인 화면 - 이메일 로그인 버튼
  ///
  /// In ko, this message translates to:
  /// **'이메일로 로그인'**
  String get authEmailLogin;

  /// 로그인 화면 - 약관 동의 접두사
  ///
  /// In ko, this message translates to:
  /// **'로그인 시 '**
  String get authTermsPrefix;

  /// 로그인 화면 - 서비스 이용약관
  ///
  /// In ko, this message translates to:
  /// **'서비스 이용약관'**
  String get authTermsOfService;

  /// 로그인 화면 - 약관 연결 텍스트
  ///
  /// In ko, this message translates to:
  /// **' 및 '**
  String get authTermsAnd;

  /// 로그인 화면 - 개인정보처리방침
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get authPrivacyPolicy;

  /// 로그인 화면 - 약관 동의 접미사
  ///
  /// In ko, this message translates to:
  /// **'에 동의하게 됩니다.'**
  String get authTermsSuffix;

  /// 교정연령 포맷 - 접두사
  ///
  /// In ko, this message translates to:
  /// **'교정 '**
  String get correctedAgeFormatPrefix;

  /// 교정연령 포맷 - 주만 표시
  ///
  /// In ko, this message translates to:
  /// **'{prefix}{weeks}주'**
  String correctedAgeFormatWeeksOnly(String prefix, int weeks);

  /// 교정연령 포맷 - 개월만 표시
  ///
  /// In ko, this message translates to:
  /// **'{prefix}{months}개월'**
  String correctedAgeFormatMonthsOnly(String prefix, int months);

  /// 교정연령 포맷 - 개월+주 표시
  ///
  /// In ko, this message translates to:
  /// **'{prefix}{months}개월 {weeks}주'**
  String correctedAgeFormatMonthsWeeks(String prefix, int months, int weeks);

  /// 실제연령 포맷 - 주만 표시
  ///
  /// In ko, this message translates to:
  /// **'{weeks}주'**
  String actualAgeFormatWeeksOnly(int weeks);

  /// 실제연령 포맷 - 개월만 표시
  ///
  /// In ko, this message translates to:
  /// **'{months}개월'**
  String actualAgeFormatMonthsOnly(int months);

  /// 실제연령 포맷 - 개월+주 표시
  ///
  /// In ko, this message translates to:
  /// **'{months}개월 {weeks}주'**
  String actualAgeFormatMonthsWeeks(int months, int weeks);

  /// 라벨 - 필수 항목
  ///
  /// In ko, this message translates to:
  /// **'필수'**
  String get labelRequired;

  /// 에러 - 유효하지 않은 숫자
  ///
  /// In ko, this message translates to:
  /// **'올바른 숫자를 입력해주세요'**
  String get errorInvalidNumber;

  /// 에러 - 값이 최소값 미달
  ///
  /// In ko, this message translates to:
  /// **'{label}이(가) 너무 작습니다 (최소 {min}{unit})'**
  String errorValueTooLow(String label, String min, String unit);

  /// 에러 - 값이 최대값 초과
  ///
  /// In ko, this message translates to:
  /// **'{label}이(가) 너무 큽니다 (최대 {max}{unit})'**
  String errorValueTooHigh(String label, String max, String unit);

  /// 성장 입력 - 이전 측정값 표시
  ///
  /// In ko, this message translates to:
  /// **'이전: {value}{unit}'**
  String growthPreviousValue(String value, String unit);

  /// 성장 입력 - 이전 측정일 (N일 전)
  ///
  /// In ko, this message translates to:
  /// **'({days}일 전)'**
  String growthPreviousDaysAgo(int days);

  /// 울음 분석 상세 설명 다이얼로그
  ///
  /// In ko, this message translates to:
  /// **'AI 기반 울음 분석 기능이\nPhase 2에서 출시됩니다.\n\n아기의 울음 패턴을 분석하여\n배고픔, 졸림, 불편함 등을\n구분해드릴게요.'**
  String get cryAnalysisDetailedDescription;

  /// 출시 예정 배지
  ///
  /// In ko, this message translates to:
  /// **'Coming Soon'**
  String get comingSoonBadge;

  /// 요일 약자 - 월
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get dayNameMon;

  /// 요일 약자 - 화
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get dayNameTue;

  /// 요일 약자 - 수
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get dayNameWed;

  /// 요일 약자 - 목
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get dayNameThu;

  /// 요일 약자 - 금
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get dayNameFri;

  /// 요일 약자 - 토
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get dayNameSat;

  /// 요일 약자 - 일
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get dayNameSun;

  /// 요일 전체 - 월요일
  ///
  /// In ko, this message translates to:
  /// **'월요일'**
  String get dayNameMonFull;

  /// 요일 전체 - 화요일
  ///
  /// In ko, this message translates to:
  /// **'화요일'**
  String get dayNameTueFull;

  /// 요일 전체 - 수요일
  ///
  /// In ko, this message translates to:
  /// **'수요일'**
  String get dayNameWedFull;

  /// 요일 전체 - 목요일
  ///
  /// In ko, this message translates to:
  /// **'목요일'**
  String get dayNameThuFull;

  /// 요일 전체 - 금요일
  ///
  /// In ko, this message translates to:
  /// **'금요일'**
  String get dayNameFriFull;

  /// 요일 전체 - 토요일
  ///
  /// In ko, this message translates to:
  /// **'토요일'**
  String get dayNameSatFull;

  /// 요일 전체 - 일요일
  ///
  /// In ko, this message translates to:
  /// **'일요일'**
  String get dayNameSunFull;

  /// 차트 툴팁 - 요일: 값
  ///
  /// In ko, this message translates to:
  /// **'{day}: {value}'**
  String chartTooltipDayValue(String day, String value);

  /// 차트 접근성 - 지난 7일
  ///
  /// In ko, this message translates to:
  /// **'지난 7일 차트.'**
  String get chartAccessibilityLast7Days;

  /// 차트 접근성 - 평균값
  ///
  /// In ko, this message translates to:
  /// **'평균 {value}'**
  String chartAccessibilityAverage(String value);

  /// 오늘 놀이 요약 - 아기 이름 포함
  ///
  /// In ko, this message translates to:
  /// **'{name} 오늘의 놀이'**
  String todayPlayWithName(String name);

  /// 오늘 놀이 요약 제목
  ///
  /// In ko, this message translates to:
  /// **'오늘의 놀이'**
  String get todayPlay;

  /// 오늘 놀이 - 총 시간
  ///
  /// In ko, this message translates to:
  /// **'총 {minutes}분'**
  String totalMinutesLabel(int minutes);

  /// 오늘 놀이 - 터미타임 횟수 및 시간
  ///
  /// In ko, this message translates to:
  /// **'터미타임 {count}회 ({minutes}분)'**
  String tummyTimeCountMinutes(int count, int minutes);

  /// 오늘 놀이 - 목욕 완료 배지
  ///
  /// In ko, this message translates to:
  /// **'목욕 완료'**
  String get bathComplete;

  /// 오늘 놀이 - 외출 배지
  ///
  /// In ko, this message translates to:
  /// **'외출'**
  String get outdoorLabel;

  /// 체온 슬라이더 - 저체온 라벨
  ///
  /// In ko, this message translates to:
  /// **'체온이 낮아요'**
  String get tempSliderLowLabel;

  /// 체온 슬라이더 - 저체온 메시지
  ///
  /// In ko, this message translates to:
  /// **'보온에 신경써주세요.'**
  String get tempSliderLowMessage;

  /// 체온 슬라이더 - 정상 라벨
  ///
  /// In ko, this message translates to:
  /// **'정상 체온이에요'**
  String get tempSliderNormalLabel;

  /// 체온 슬라이더 - 정상 메시지
  ///
  /// In ko, this message translates to:
  /// **'체온이 정상 범위입니다.'**
  String get tempSliderNormalMessage;

  /// 체온 슬라이더 - 미열 라벨
  ///
  /// In ko, this message translates to:
  /// **'체온이 조금 높아요'**
  String get tempSliderMildLabel;

  /// 체온 슬라이더 - 미열 메시지
  ///
  /// In ko, this message translates to:
  /// **'지켜봐주세요.'**
  String get tempSliderMildMessage;

  /// 체온 슬라이더 - 발열 라벨
  ///
  /// In ko, this message translates to:
  /// **'열이 있어요'**
  String get tempSliderHighLabel;

  /// 체온 슬라이더 - 발열 메시지
  ///
  /// In ko, this message translates to:
  /// **'병원 방문을 고려해주세요.'**
  String get tempSliderHighMessage;

  /// 조산아 보정 - 만삭아 기준 분석
  ///
  /// In ko, this message translates to:
  /// **'만삭아 기준으로 분석했어요.'**
  String get pretermAnalysisFullTerm;

  /// 조산아 보정 - 만삭아 유사 신뢰도
  ///
  /// In ko, this message translates to:
  /// **'교정연령 {weeks}주로, 만삭아와 유사한 신뢰도예요.'**
  String pretermAnalysisSimilar(int weeks);

  /// 조산아 보정 - 신뢰도 보정 안내
  ///
  /// In ko, this message translates to:
  /// **'교정연령 {weeks}주 기준, 신뢰도를 {percentage}%로 보정했어요.\n조산아의 울음 패턴은 만삭아와 다를 수 있어요.'**
  String pretermAnalysisAdjusted(int weeks, int percentage);

  /// 터미타임 타이머 - 목표 달성
  ///
  /// In ko, this message translates to:
  /// **'권장 시간 달성!'**
  String get tummyTimerGoalReached;

  /// 터미타임 타이머 - 목표 시간
  ///
  /// In ko, this message translates to:
  /// **'목표: {minutes}분'**
  String tummyTimerGoalMinutes(int minutes);

  /// 터미타임 타이머 - 일시정지 버튼
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get tummyTimerPause;

  /// 터미타임 타이머 - 완료 버튼
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get tummyTimerComplete;

  /// 터미타임 타이머 - 초기화 버튼
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get tummyTimerReset;

  /// 수유 버튼 - 모유 좌측
  ///
  /// In ko, this message translates to:
  /// **'모유 좌측'**
  String get feedingBreastLeft;

  /// 수유 버튼 - 모유 우측
  ///
  /// In ko, this message translates to:
  /// **'모유 우측'**
  String get feedingBreastRight;

  /// 수유 버튼 - 모유 양쪽
  ///
  /// In ko, this message translates to:
  /// **'모유 양쪽'**
  String get feedingBreastBoth;

  /// 빠른 수유 버튼 접근성 라벨
  ///
  /// In ko, this message translates to:
  /// **'{type} {amount} 빠른 저장 버튼. 길게 누르면 수정 모드'**
  String recentFeedingAccessibility(String type, String amount);

  /// 인증 에러 - 잘못된 자격증명
  ///
  /// In ko, this message translates to:
  /// **'이메일 또는 비밀번호가 올바르지 않습니다.'**
  String get authErrorInvalidCredentials;

  /// 인증 에러 - 이메일 미인증
  ///
  /// In ko, this message translates to:
  /// **'이메일 인증이 필요합니다. 메일함을 확인해주세요.'**
  String get authErrorEmailNotConfirmed;

  /// 인증 에러 - 이미 가입된 사용자
  ///
  /// In ko, this message translates to:
  /// **'이미 가입된 이메일입니다.'**
  String get authErrorUserAlreadyRegistered;

  /// 인증 에러 - 비밀번호 너무 짧음
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 최소 6자 이상이어야 합니다.'**
  String get authErrorPasswordTooShort;

  /// 인증 에러 - 유효하지 않은 이메일
  ///
  /// In ko, this message translates to:
  /// **'유효한 이메일 주소를 입력해주세요.'**
  String get authErrorInvalidEmail;

  /// 인증 에러 - 일반 오류
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다. 다시 시도해주세요.'**
  String get authErrorGeneric;

  /// Fenton 성장 차트 설명
  ///
  /// In ko, this message translates to:
  /// **'조산아 성장 차트 (22-50주)'**
  String get growthChartFentonDesc;

  /// WHO 성장 차트 설명
  ///
  /// In ko, this message translates to:
  /// **'세계보건기구 성장 차트 (0-24개월)'**
  String get growthChartWhoDesc;

  /// 요약 카드 접근성 라벨
  ///
  /// In ko, this message translates to:
  /// **'{label} {value} {subLabel}, 지난주 대비 {change}'**
  String summaryCardAccessibility(
    String label,
    String value,
    String subLabel,
    String change,
  );

  /// 수량 입력 - 직접 입력 축약 힌트
  ///
  /// In ko, this message translates to:
  /// **'직접'**
  String get amountInputDirectShort;

  /// 수량 입력 - 직접 입력 힌트
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get amountInputDirect;

  /// 초대 코드 검증 실패 에러
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 확인할 수 없어요'**
  String get inviteCodeVerifyError;

  /// Apple 로그인 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'Apple로 계속하기'**
  String get continueWithApple;

  /// 성장 빈 상태 - 이름 포함 제목
  ///
  /// In ko, this message translates to:
  /// **'{babyName}의 첨 성장 기록을\n남겨보세요!'**
  String growthEmptyTitleWithName(String babyName);

  /// 성장 빈 상태 - 제목
  ///
  /// In ko, this message translates to:
  /// **'첨 성장 기록을\n남겨보세요!'**
  String get growthEmptyTitle;

  /// 성장 빈 상태 - 설명
  ///
  /// In ko, this message translates to:
  /// **'소아과 정기검진 후 기록하면\n성장 추이를 확인할 수 있어요'**
  String get growthEmptyDescription;

  /// 성장 빈 상태 - CTA 버튼
  ///
  /// In ko, this message translates to:
  /// **'첨 기록 남기기'**
  String get growthEmptyButton;

  /// 통계 필터 - 함께 보기
  ///
  /// In ko, this message translates to:
  /// **'함께 보기'**
  String get filterViewTogether;

  /// 통계 필터 - 교정연령 일수
  ///
  /// In ko, this message translates to:
  /// **'교정{days}일'**
  String filterCorrectedAgeDays(int days);

  /// 울음 분석 카드 - 부제목
  ///
  /// In ko, this message translates to:
  /// **'아기가 왜 우는지 알아보세요'**
  String get cryAnalysisCardSubtitle;

  /// 울음 분석 카드 - CTA 버튼
  ///
  /// In ko, this message translates to:
  /// **'분석 시작하기'**
  String get cryAnalysisStartButton;

  /// 성장 차트 - 지표 포함 제목
  ///
  /// In ko, this message translates to:
  /// **'{metric} 성장 차트'**
  String growthChartTitleWithMetric(String metric);

  /// 성장 차트 범례 - 중앙값
  ///
  /// In ko, this message translates to:
  /// **'50% (중앙값)'**
  String get growthChartLegendMedian;

  /// 성장 차트 범례 - 측정값
  ///
  /// In ko, this message translates to:
  /// **'측정값'**
  String get growthChartLegendMeasured;

  /// 성장 지표 - 체중
  ///
  /// In ko, this message translates to:
  /// **'체중'**
  String get growthMetricWeight;

  /// 성장 지표 - 신장
  ///
  /// In ko, this message translates to:
  /// **'신장'**
  String get growthMetricLength;

  /// 성장 지표 - 두위
  ///
  /// In ko, this message translates to:
  /// **'두위'**
  String get growthMetricHeadCircumference;

  /// 가족 멤버 - 본인 배지
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get memberBadgeMe;

  /// 가족 멤버 - 관리자 역할
  ///
  /// In ko, this message translates to:
  /// **'관리자'**
  String get memberRoleOwner;

  /// 가족 멤버 - 참여 날짜
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일 참여'**
  String memberJoinedDate(int month, int day);

  /// 성장 백분위 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'성장 백분위'**
  String get growthPercentileTitle;

  /// 하단 네비게이션 - 기록
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get navRecords;

  /// 아기 정보 미등록 안내
  ///
  /// In ko, this message translates to:
  /// **'아기 정보를 먼저 등록해주세요'**
  String get registerBabyFirst;

  /// 기록 삭제 완료 메시지
  ///
  /// In ko, this message translates to:
  /// **'기록이 삭제되었어요'**
  String get recordDeleted;

  /// 실행취소 버튼 레이블
  ///
  /// In ko, this message translates to:
  /// **'실행취소'**
  String get undoAction;

  /// 통계 - 회수 단위
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String statisticsCountUnit(String count);

  /// 통계 - 분 변화량
  ///
  /// In ko, this message translates to:
  /// **'{sign}{minutes}분'**
  String statisticsMinuteChange(String sign, String minutes);

  /// 통계 - 회수 변화량
  ///
  /// In ko, this message translates to:
  /// **'{sign}{count}회'**
  String statisticsCountChange(String sign, String count);

  /// x
  ///
  /// In ko, this message translates to:
  /// **'우리 가족'**
  String get defaultFamilyName;

  /// x
  ///
  /// In ko, this message translates to:
  /// **'{days}일 남음'**
  String inviteDaysRemaining(int days);

  /// x
  ///
  /// In ko, this message translates to:
  /// **'서로 다른 패턴도 모두 정상이에요'**
  String get togetherDifferentPatternsNormal;

  /// x
  ///
  /// In ko, this message translates to:
  /// **'다시 분석'**
  String get cryReanalyzeShort;

  /// x
  ///
  /// In ko, this message translates to:
  /// **'높음'**
  String get confidenceLevelHigh;

  /// x
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get confidenceLevelMedium;

  /// x
  ///
  /// In ko, this message translates to:
  /// **'낮음'**
  String get confidenceLevelLow;

  /// x
  ///
  /// In ko, this message translates to:
  /// **'정확해요'**
  String get cryFeedbackAccurate;

  /// x
  ///
  /// In ko, this message translates to:
  /// **'다른 것 같아요'**
  String get cryFeedbackInaccurate;

  /// x
  ///
  /// In ko, this message translates to:
  /// **'잘 모르겠어요'**
  String get cryFeedbackUnsure;

  /// x
  ///
  /// In ko, this message translates to:
  /// **'증가'**
  String get directionIncreasing;

  /// x
  ///
  /// In ko, this message translates to:
  /// **'유지'**
  String get directionStable;

  /// x
  ///
  /// In ko, this message translates to:
  /// **'감소'**
  String get directionDecreasing;

  /// x
  ///
  /// In ko, this message translates to:
  /// **'교정연령 D{days}'**
  String sgaCorrectedAgeDMinus(int days);

  /// x
  ///
  /// In ko, this message translates to:
  /// **'교정연령 D+{days}'**
  String sgaCorrectedAgeDPlus(int days);

  /// x
  ///
  /// In ko, this message translates to:
  /// **'성장 추적 모드'**
  String get sgaGrowthTrackingMode;

  /// x
  ///
  /// In ko, this message translates to:
  /// **'시간 선택: {time}'**
  String semanticsTimeSelect(String time);

  /// x
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분'**
  String ongoingSleepElapsedHoursMinutes(int hours, int minutes);

  /// x
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String ongoingSleepElapsedMinutes(int minutes);

  /// 함께보기 가이드 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'알겠어요'**
  String get togetherOkButton;

  /// 홈 울음분석 카드 제목
  ///
  /// In ko, this message translates to:
  /// **'울음 분석'**
  String get cryAnalysisCardTitle;

  /// 홈 울음분석 카드 시작 버튼
  ///
  /// In ko, this message translates to:
  /// **'분석 시작하기'**
  String get cryAnalysisStartButtonHome;

  /// 울음 분석 진행 중 텍스트
  ///
  /// In ko, this message translates to:
  /// **'분석 중...'**
  String get cryAnalyzing;

  /// 울음 분석 취소 버튼
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cryCancelButton;

  /// 가족 기본 이름
  ///
  /// In ko, this message translates to:
  /// **'우리 가족'**
  String get familyDefaultName;

  /// 가족 구성원 수
  ///
  /// In ko, this message translates to:
  /// **'{count}명의 가족'**
  String familyMemberCount(int count);

  /// 초대 만료 남은 일수
  ///
  /// In ko, this message translates to:
  /// **'{days}일 남음'**
  String familyInviteDaysLeft(int days);

  /// 성장 데이터 로딩 에러 제목
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러오지 못했어요'**
  String get growthErrorTitle;

  /// 성장 데이터 에러 재시도 버튼
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get growthErrorRetry;

  /// 성장 차트 50% 범례
  ///
  /// In ko, this message translates to:
  /// **'50% (중앙값)'**
  String get growthChartLegend50;

  /// 온보딩 시작 버튼
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get welcomeStartButton;

  /// 파일 선택 실패 에러
  ///
  /// In ko, this message translates to:
  /// **'파일을 선택할 수 없습니다: {error}'**
  String importCannotSelectFile(String error);

  /// 가족 정보 없음 에러
  ///
  /// In ko, this message translates to:
  /// **'가족 정보가 없습니다. 온보딩을 완료해주세요.'**
  String get importNoFamilyInfo;

  /// 가져오기 실패 에러
  ///
  /// In ko, this message translates to:
  /// **'가져오기 실패: {error}'**
  String importFailed(String error);

  /// 월일 날짜 포맷
  ///
  /// In ko, this message translates to:
  /// **'M월 d일 (E)'**
  String get dateFormatMonthDay;

  /// 성장 차트 제목
  ///
  /// In ko, this message translates to:
  /// **'{metric} 성장 차트'**
  String growthMetricChartTitle(String metric);
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
