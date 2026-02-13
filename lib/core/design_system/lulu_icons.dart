import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Lulu Design System - Icons
///
/// Material Icons Rounded를 사용한 일관된 아이콘 시스템

class LuluIcons {
  // ========================================
  // 활동 타입 (Activity Types)
  // ========================================

  static const IconData sleep = Icons.bedtime_rounded;
  static const IconData feeding = Icons.local_drink_rounded;
  static const IconData diaper = Icons.baby_changing_station_rounded;
  static const IconData play = Icons.toys_rounded;
  static const IconData health = Icons.favorite_rounded;
  static const IconData wakeWindow = Icons.wb_sunny_rounded;

  // ========================================
  // 네비게이션 (Navigation)
  // ========================================

  static const IconData home = Icons.home_rounded;
  static const IconData records = Icons.list_alt_rounded;
  static const IconData insights = Icons.insights_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData chat = Icons.chat_bubble_rounded;

  // ========================================
  // 액션 (Actions)
  // ========================================

  static const IconData add = Icons.add_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData save = Icons.check_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData forward = Icons.arrow_forward_rounded;
  static const IconData time = Icons.access_time_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData sort = Icons.sort_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData download = Icons.download_rounded;
  static const IconData upload = Icons.upload_rounded;

  // ========================================
  // MVP-F: 다태아 관련 아이콘
  // ========================================

  static const IconData baby = Icons.child_care_rounded;
  static const IconData babies = Icons.group_rounded;
  static const IconData family = Icons.family_restroom_rounded;
  static const IconData switchBaby = Icons.swap_horiz_rounded;

  // ========================================
  // 수면 상세 (Sleep Details)
  // ========================================

  static const IconData sleepCrib = Icons.crib_rounded;
  static const IconData sleepBed = Icons.bed_rounded;
  static const IconData sleepStroller = Icons.stroller_rounded;
  static const IconData sleepCar = Icons.drive_eta_rounded;
  static const IconData sleepArms = Icons.child_care_rounded;

  // ========================================
  // 수유 상세 (Feeding Details)
  // ========================================

  static const IconData feedingBottle = Icons.local_drink_rounded;
  static const IconData feedingBreast = Icons.child_friendly_rounded;
  static const IconData feedingSolid = Icons.restaurant_rounded;

  // ========================================
  // 기저귀 상세 (Diaper Details)
  // ========================================

  static const IconData diaperWet = Icons.water_drop_rounded;
  static const IconData diaperDirty = Icons.sanitizer_rounded;
  static const IconData diaperBoth = Icons.baby_changing_station_rounded;

  // ========================================
  // 상태 (Status)
  // ========================================

  static const IconData success = Icons.check_circle_rounded;
  static const IconData warning = Icons.warning_rounded;
  static const IconData error = Icons.error_rounded;
  static const IconData info = Icons.info_rounded;

  // ========================================
  // UI 요소 (UI Elements)
  // ========================================

  static const IconData notification = Icons.notifications_rounded;
  static const IconData notificationOff = Icons.notifications_off_rounded;
  static const IconData moon = Icons.nightlight_rounded;
  static const IconData sun = Icons.wb_sunny_rounded;
  static const IconData star = Icons.star_rounded;
  static const IconData heart = Icons.favorite_rounded;
  static const IconData note = Icons.note_alt_rounded;
  static const IconData tips = Icons.tips_and_updates_rounded;
  static const IconData celebration = Icons.celebration_rounded;

  // ========================================
  // Badge / Achievement
  // ========================================

  static const IconData trophy = Icons.emoji_events_rounded;
  static const IconData badge = Icons.workspace_premium_rounded;

  // ========================================
  // 성장 관련 (Growth)
  // ========================================

  static const IconData growth = Icons.trending_up_rounded;
  static const IconData chart = Icons.show_chart_rounded;
  static const IconData ruler = Icons.straighten_rounded;
  static const IconData weight = Icons.monitor_weight_rounded;
  static const IconData head = Icons.face_rounded;
  static const IconData memo = Icons.edit_note_rounded;
  static const IconData checkCircle = Icons.check_circle_rounded;

  // ========================================
  // 놀이 상세 (Play Details)
  // ========================================

  static const IconData tummyTime = Icons.child_care_rounded;
  static const IconData bath = Icons.bathtub_rounded;
  static const IconData outdoor = Icons.directions_walk_rounded;
  static const IconData indoorPlay = Icons.palette_rounded;
  static const IconData reading = Icons.menu_book_rounded;
  static const IconData other = Icons.more_horiz_rounded;

  // ========================================
  // 건강 상세 (Health Details)
  // ========================================

  static const IconData temperature = Icons.thermostat_rounded;
  static const IconData symptom = Icons.sick_rounded;
  static const IconData medication = Icons.medication_rounded;
  static const IconData hospital = Icons.local_hospital_rounded;

  // ========================================
  // 증상 (Symptoms)
  // ========================================

  static const IconData cough = Icons.air_rounded;
  static const IconData runnyNose = Icons.water_drop_rounded;
  static const IconData fever = Icons.whatshot_rounded;
  static const IconData vomiting = Icons.sick_rounded;
  static const IconData diarrhea = Icons.warning_amber_rounded;
  static const IconData rash = Icons.radio_button_checked_rounded;

  // ========================================
  // 기저귀 상세 확장 (Diaper Details Extended)
  // ========================================

  static const IconData diaperDry = Icons.auto_awesome_rounded;

  // ========================================
  // 수유 상세 확장 (Feeding Details Extended)
  // ========================================

  static const IconData breastfeeding = Icons.pregnant_woman_rounded;

  // ========================================
  // 상태 표시 (Status Indicators)
  // ========================================

  static const IconData statusOk = Icons.check_circle_rounded;
  static const IconData statusWarn = Icons.warning_amber_rounded;
  static const IconData statusSync = Icons.sync_rounded;
  static const IconData statusStat = Icons.analytics_rounded;
  static const IconData statusDelete = Icons.delete_outline_rounded;
  static const IconData statusError = Icons.error_outline_rounded;
  static const IconData statusInfo = Icons.info_outline_rounded;

  // ========================================
  // 울음 분석 (Cry Analysis)
  // ========================================

  static const IconData microphone = Icons.mic_rounded;
  static const IconData microphoneOff = Icons.mic_off_rounded;
  static const IconData soundWave = Icons.graphic_eq_rounded;
  static const IconData cryAnalysis = Icons.record_voice_over_rounded;
  static const IconData audioAnalyzing = Icons.hearing_rounded;
  static const IconData cryResult = Icons.psychology_rounded;

  // ========================================
  // 방향 화살표 (Directional Arrows)
  // ========================================

  static const IconData arrowUp = Icons.arrow_upward_rounded;
  static const IconData arrowDown = Icons.arrow_downward_rounded;
  static const IconData chevronLeft = Icons.chevron_left_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData chevronDown = Icons.keyboard_arrow_down_rounded;
  static const IconData chevronUp = Icons.keyboard_arrow_up_rounded;

  // ========================================
  // 조작 (Manipulation)
  // ========================================

  static const IconData remove = Icons.remove_rounded;

  // ========================================
  // 추가 UI 요소 (Additional UI Elements)
  // ========================================

  static const IconData errorOutline = Icons.error_outline_rounded;
  static const IconData editCalendar = Icons.edit_calendar_rounded;
  static const IconData tip = Icons.lightbulb_outline_rounded;
  static const IconData barChart = Icons.bar_chart_rounded;

  // ========================================
  // 네비게이션 확장 (Navigation Extended)
  // ========================================

  static const IconData backIos = Icons.arrow_back_ios_new_rounded;
  static const IconData forwardIos = Icons.arrow_forward_ios_rounded;
  static const IconData expandMore = Icons.expand_more_rounded;
  static const IconData expandLess = Icons.expand_less_rounded;
  static const IconData menuIcon = Icons.menu_rounded;
  static const IconData history = Icons.history_rounded;
  static const IconData settingsOutlined = Icons.settings_rounded;

  // ========================================
  // 액션 확장 (Actions Extended)
  // ========================================

  static const IconData addCircleOutline = Icons.add_circle_outline_rounded;
  static const IconData removeCircleOutline = Icons.remove_circle_outline_rounded;
  static const IconData deleteForever = Icons.delete_forever_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData send = Icons.send_rounded;
  static const IconData copy = Icons.copy_rounded;
  static const IconData skipNext = Icons.skip_next_rounded;
  static const IconData playArrow = Icons.play_arrow_rounded;
  static const IconData pause = Icons.pause_rounded;
  static const IconData stop = Icons.stop_rounded;
  static const IconData helpOutline = Icons.help_outline_rounded;
  static const IconData exitToApp = Icons.exit_to_app_rounded;
  static const IconData logout = Icons.logout_rounded;
  static const IconData compareArrows = Icons.compare_arrows_rounded;
  static const IconData swapHoriz = Icons.swap_horiz_rounded;

  // ========================================
  // 상태 확장 (Status Extended)
  // ========================================

  static const IconData checkCircleOutline = Icons.check_circle_outline_rounded;
  static const IconData infoOutline = Icons.info_outline_rounded;
  static const IconData notificationActive = Icons.notifications_active_rounded;
  static const IconData newRelease = Icons.new_releases_rounded;
  static const IconData cloudOff = Icons.cloud_off_rounded;

  // ========================================
  // 사용자/가족 (User/Family)
  // ========================================

  static const IconData personOutlined = Icons.person_outline_rounded;
  static const IconData personAdd = Icons.person_add_rounded;
  static const IconData people = Icons.people_rounded;
  static const IconData groupAdd = Icons.group_add_rounded;
  static const IconData male = Icons.male_rounded;
  static const IconData female = Icons.female_rounded;

  // ========================================
  // 인증/보안 (Auth/Security)
  // ========================================

  static const IconData apple = Icons.apple;
  static const IconData emailOutlined = Icons.email_rounded;
  static const IconData lockOutlined = Icons.lock_outline_rounded;
  static const IconData mailOutline = Icons.mail_outline_rounded;
  static const IconData visibility = Icons.visibility_rounded;
  static const IconData visibilityOff = Icons.visibility_off_rounded;

  // ========================================
  // 데이터/파일 (Data/File)
  // ========================================

  static const IconData fileDownload = Icons.file_download_rounded;
  static const IconData fileUpload = Icons.file_upload_rounded;
  static const IconData folderOpen = Icons.folder_open_rounded;
  static const IconData description = Icons.description_rounded;
  static const IconData summarize = Icons.summarize_rounded;
  static const IconData tableChart = Icons.table_chart_rounded;
  static const IconData insertChart = Icons.insert_chart_outlined_rounded;

  // ========================================
  // 수유 확장 (Feeding Extended)
  // ========================================

  static const IconData feedingOutlined = Icons.local_drink_rounded;
  static const IconData restaurantOutlined = Icons.restaurant_rounded;
  static const IconData cafe = Icons.local_cafe_rounded;

  // ========================================
  // 기저귀 확장 (Diaper Extended)
  // ========================================

  static const IconData diaperOutlined = Icons.baby_changing_station_rounded;

  // ========================================
  // 수면 확장 (Sleep Extended)
  // ========================================

  static const IconData sleepOutlined = Icons.bedtime_rounded;

  // ========================================
  // 감정 표현 (Sentiment)
  // ========================================

  static const IconData sentimentHappy = Icons.sentiment_very_satisfied_rounded;
  static const IconData sentimentNeutral = Icons.sentiment_neutral_rounded;
  static const IconData sentimentSad = Icons.sentiment_dissatisfied_rounded;
  static const IconData sentimentSadOutlined = Icons.sentiment_dissatisfied_rounded;
  static const IconData thumbUp = Icons.thumb_up_rounded;
  static const IconData thumbDown = Icons.thumb_down_rounded;

  // ========================================
  // 차트/분석 (Charts/Analytics)
  // ========================================

  static const IconData analyticsOutlined = Icons.analytics_rounded;
  static const IconData bubbleChart = Icons.bubble_chart_rounded;
  static const IconData trendingFlat = Icons.trending_flat_rounded;

  // ========================================
  // 기타 (Miscellaneous)
  // ========================================

  static const IconData language = Icons.language_rounded;
  static const IconData timer = Icons.timer_rounded;
  static const IconData timerOutlined = Icons.timer_rounded;
  static const IconData sportsEsports = Icons.sports_esports_rounded;
  static const IconData snowflake = Icons.ac_unit_rounded;
  static const IconData bolt = Icons.bolt_rounded;
  static const IconData micOutlined = Icons.mic_rounded;

  // ========================================
  // 아이콘 크기 (Icon Sizes)
  // ========================================

  static const double sizeXS = 16;
  static const double sizeSM = 20;
  static const double sizeMD = 24;
  static const double sizeLG = 32;
  static const double sizeXL = 48;

  // ========================================
  // SVG Icons (Widget-based)
  // ========================================

  /// SVG poop icon for dirty diaper
  /// Optical size correction: solid SVG appears visually heavier than
  /// outlined Material Icons at the same px size. 3px padding compensates.
  static Widget poopIcon({double size = 24, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: SvgPicture.asset(
        'assets/icons/poop.svg',
        width: size - 6,
        height: size - 6,
        colorFilter: color != null
            ? ColorFilter.mode(color, BlendMode.srcIn)
            : null,
      ),
    );
  }

  // ========================================
  // 헬퍼 메서드 (Helper Methods)
  // ========================================

  /// 활동 타입으로 아이콘 가져오기
  static IconData forType(String type) {
    switch (type.toLowerCase()) {
      case 'sleep':
        return sleep;
      case 'feeding':
        return feeding;
      case 'diaper':
        return diaper;
      case 'play':
        return play;
      case 'health':
      case 'temperature':
      case 'medication':
        return health;
      default:
        return Icons.circle_rounded;
    }
  }

  /// 수면 장소로 아이콘 가져오기
  static IconData forSleepLocation(String? location) {
    if (location == null) return sleepBed;
    switch (location.toLowerCase()) {
      case 'crib':
        return sleepCrib;
      case 'bed':
        return sleepBed;
      case 'stroller':
        return sleepStroller;
      case 'car':
        return sleepCar;
      case 'arms':
        return sleepArms;
      default:
        return sleepBed;
    }
  }

  /// 수유 타입으로 아이콘 가져오기
  static IconData forFeedingType(String? type) {
    if (type == null) return feedingBottle;
    switch (type.toLowerCase()) {
      case 'bottle':
        return feedingBottle;
      case 'breast':
        return feedingBreast;
      case 'solid':
        return feedingSolid;
      default:
        return feedingBottle;
    }
  }

  /// 기저귀 타입으로 아이콘 가져오기
  static IconData forDiaperType(String? type) {
    if (type == null) return diaperBoth;
    switch (type.toLowerCase()) {
      case 'wet':
        return diaperWet;
      case 'dirty':
        return diaperDirty;
      case 'both':
        return diaperBoth;
      default:
        return diaperBoth;
    }
  }
}
