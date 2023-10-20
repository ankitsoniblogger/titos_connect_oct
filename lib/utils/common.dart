import 'dart:convert';
import 'dart:io';

import 'package:booking_system_flutter/component/app_common_dialog.dart';
import 'package:booking_system_flutter/component/html_widget.dart';
import 'package:booking_system_flutter/component/location_service_dialog.dart';
import 'package:booking_system_flutter/component/new_update_dialog.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/remote_config_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/auth/auth_user_services.dart';
import 'package:booking_system_flutter/screens/auth/sign_in_screen.dart';
import 'package:booking_system_flutter/services/location_service.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/permissions.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tabs;
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:html/parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'constant.dart';

Future<bool> get isIqonicProduct async => await getPackageName() == appPackageName;

bool get isUserTypeHandyman => appStore.userType == USER_TYPE_HANDYMAN;

bool get isUserTypeProvider => appStore.userType == USER_TYPE_PROVIDER;

bool get isUserTypeUser => appStore.userType == USER_TYPE_USER;

bool get isLoginTypeUser => appStore.loginType == LOGIN_TYPE_USER;

bool get isLoginTypeGoogle => appStore.loginType == LOGIN_TYPE_GOOGLE;

bool get isLoginTypeApple => appStore.loginType == LOGIN_TYPE_APPLE;

bool get isLoginTypeOTP => appStore.loginType == LOGIN_TYPE_OTP;

ThemeMode get appThemeMode => appStore.isDarkMode ? ThemeMode.dark : ThemeMode.light;

bool get isCurrencyPositionLeft => getStringAsync(CURRENCY_POSITION, defaultValue: CURRENCY_POSITION_LEFT) == CURRENCY_POSITION_LEFT;

bool get isCurrencyPositionRight => getStringAsync(CURRENCY_POSITION, defaultValue: CURRENCY_POSITION_LEFT) == CURRENCY_POSITION_RIGHT;

bool get isRTL => RTL_LanguageS.contains(appStore.selectedLanguageCode);

void initializeOneSignal() async {
  OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

  await OneSignal.shared.setAppId(getStringAsync(ONESIGNAL_API_KEY)).then((value) async {
    OneSignal.shared.sendTag(ONESIGNAL_TAG_KEY, ONESIGNAL_TAG_VALUE);
    OneSignal.shared.setNotificationWillShowInForegroundHandler((OSNotificationReceivedEvent? event) {
      return event?.complete(event.notification);
    });
    OneSignal.shared.disablePush(false);
    OneSignal.shared.consentGranted(true);

    OSDeviceState? osDeviceState = await OneSignal.shared.getDeviceState();
    if (osDeviceState!.hasNotificationPermission) {
      updatePlayerId(playerId: osDeviceState.userId.validate());
    } else {
      await OneSignal.shared.promptUserForPushNotificationPermission(fallbackToSettings: true).then((value) async {
        if (value) {
          updatePlayerId(playerId: osDeviceState.userId.validate());
        }
      });
    }

    OneSignal.shared.setSubscriptionObserver((changes) async {
      updatePlayerId(playerId: changes.to.userId.validate());
    });
  }).catchError(onError);
}

Future<void> commonLaunchUrl(String address, {LaunchMode launchMode = LaunchMode.inAppWebView}) async {
  await launchUrl(Uri.parse(address), mode: launchMode).catchError((e) {
    toast('${language.invalidURL}: $address');
  });
}

void launchCall(String? url) {
  if (url.validate().isNotEmpty) {
    if (isIOS)
      commonLaunchUrl('tel://' + url!, launchMode: LaunchMode.externalApplication);
    else
      commonLaunchUrl('tel:' + url!, launchMode: LaunchMode.externalApplication);
  }
}

void launchMap(String? url) {
  if (url.validate().isNotEmpty) {
    commonLaunchUrl(GOOGLE_MAP_PREFIX + url!, launchMode: LaunchMode.externalApplication);
  }
}

void launchMail(String url) {
  if (url.validate().isNotEmpty) {
    commonLaunchUrl('$MAIL_TO$url', launchMode: LaunchMode.externalApplication);
  }
}

void checkIfLink(BuildContext context, String value, {String? title}) {
  if (value.validate().isEmpty) return;

  String temp = parseHtmlString(value.validate());
  if (temp.startsWith("https") || temp.startsWith("http")) {
    launchUrlCustomTab(temp.validate());
  } else if (temp.validateEmail()) {
    launchMail(temp);
  } else if (temp.validatePhone() || temp.startsWith('+')) {
    launchCall(temp);
  } else {
    HtmlWidget(postContent: value, title: title).launch(context);
  }
}

void launchUrlCustomTab(String? url) {
  if (url.validate().isNotEmpty) {
    custom_tabs.launch(
      url!,
      customTabsOption: custom_tabs.CustomTabsOption(
        enableDefaultShare: true,
        enableInstantApps: true,
        enableUrlBarHiding: true,
        showPageTitle: true,
        toolbarColor: primaryColor,
      ),
      safariVCOption: custom_tabs.SafariViewControllerOption(
        preferredBarTintColor: primaryColor,
        preferredControlTintColor: Colors.white,
        barCollapsingEnabled: true,
        entersReaderIfAvailable: true,
        dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
      ),
    );
  }
}

List<LanguageDataModel> languageList() {
  return [
    LanguageDataModel(id: 1, name: 'English', languageCode: 'en', fullLanguageCode: 'en-US', flag: 'assets/flag/ic_us.png'),
    LanguageDataModel(id: 2, name: 'Hindi', languageCode: 'hi', fullLanguageCode: 'hi-IN', flag: 'assets/flag/ic_india.png'),
    LanguageDataModel(id: 3, name: 'Arabic', languageCode: 'ar', fullLanguageCode: 'ar-AR', flag: 'assets/flag/ic_ar.png'),
    LanguageDataModel(id: 4, name: 'French', languageCode: 'fr', fullLanguageCode: 'fr-FR', flag: 'assets/flag/ic_fr.png'),
    LanguageDataModel(id: 5, name: 'German', languageCode: 'de', fullLanguageCode: 'de-DE', flag: 'assets/flag/ic_de.png'),
  ];
}

InputDecoration inputDecoration(BuildContext context, {Widget? prefixIcon, String? labelText, double? borderRadius}) {
  return InputDecoration(
    contentPadding: EdgeInsets.only(left: 12, bottom: 10, top: 10, right: 10),
    labelText: labelText,
    labelStyle: secondaryTextStyle(),
    alignLabelWithHint: true,
    prefixIcon: prefixIcon,
    enabledBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(color: Colors.red, width: 0.0),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(color: Colors.red, width: 1.0),
    ),
    errorMaxLines: 2,
    border: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    ),
    errorStyle: primaryTextStyle(color: Colors.red, size: 12),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(color: primaryColor, width: 0.0),
    ),
    filled: true,
    fillColor: context.cardColor,
  );
}

String parseHtmlString(String? htmlString) {
  return parse(parse(htmlString).body!.text).documentElement!.text;
}

String formatDate(String? dateTime, {String format = DATE_FORMAT_1, bool isFromMicrosecondsSinceEpoch = false, bool isLanguageNeeded = true}) {
  final languageCode = isLanguageNeeded ? appStore.selectedLanguageCode : null;
  final parsedDateTime = isFromMicrosecondsSinceEpoch ? DateTime.fromMicrosecondsSinceEpoch(dateTime.validate().toInt() * 1000) : DateTime.parse(dateTime.validate());

  return DateFormat(format, languageCode).format(parsedDateTime);
}

Future<bool> addToWishList({required int serviceId}) async {
  Map req = {"id": "", "service_id": serviceId, "user_id": appStore.userId};
  return await addWishList(req).then((res) {
    toast(language.serviceAddedToFavourite);
    return true;
  }).catchError((error) {
    toast(error.toString());
    return false;
  });
}

Future<bool> removeToWishList({required int serviceId}) async {
  Map req = {"user_id": appStore.userId, 'service_id': serviceId};

  return await removeWishList(req).then((res) {
    toast(language.serviceRemovedFromFavourite);
    return true;
  }).catchError((error) {
    toast(error.toString());
    return false;
  });
}

void locationWiseService(BuildContext context, VoidCallback onTap) async {
  Permissions.cameraFilesAndLocationPermissionsGranted().then((value) async {
    await setValue(PERMISSION_STATUS, value);

    if (value) {
      bool? res = await showInDialog(
        context,
        contentPadding: EdgeInsets.zero,
        builder: (p0) {
          return AppCommonDialog(
            title: language.lblAlert,
            child: LocationServiceDialog(),
          );
        },
      );

      if (res ?? false) {
        appStore.setLoading(true);

        await setValue(PERMISSION_STATUS, value);
        await getUserLocation().then((value) async {
          await appStore.setCurrentLocation(!appStore.isCurrentLocation);
        }).catchError((e) {
          appStore.setLoading(false);
          toast(e.toString(), print: true);
        });

        onTap.call();
      }
    }
  }).catchError((e) {
    toast(e.toString(), print: true);
  });
}

// Logic For Calculate Time
String calculateTimer(int secTime) {
  int hour = 0, minute = 0, seconds = 0;

  hour = secTime ~/ 3600;

  minute = ((secTime - hour * 3600)) ~/ 60;

  seconds = secTime - (hour * 3600) - (minute * 60);

  String hourLeft = hour.toString().length < 2 ? "0" + hour.toString() : hour.toString();

  String minuteLeft = minute.toString().length < 2 ? "0" + minute.toString() : minute.toString();

  String minutes = minuteLeft == '00' ? '01' : minuteLeft;

  String result = "$hourLeft:$minutes";

  log(seconds);

  return result;
}

String getPaymentStatusText(String? status, String? method) {
  if (status!.isEmpty) {
    return language.lblPending;
  } else if (status == SERVICE_PAYMENT_STATUS_PAID || status == PENDING_BY_ADMIN) {
    return language.paid;
  } else if (status == SERVICE_PAYMENT_STATUS_ADVANCE_PAID) {
    return language.advancePaid;
  } else if (status == SERVICE_PAYMENT_STATUS_PENDING && method == PAYMENT_METHOD_COD) {
    return language.pendingApproval;
  } else if (status == SERVICE_PAYMENT_STATUS_PENDING) {
    return language.lblPending;
  } else {
    return "";
  }
}

String buildPaymentStatusWithMethod(String status, String method) {
  return '${getPaymentStatusText(status, method)}${(status == SERVICE_PAYMENT_STATUS_PAID || status == PENDING_BY_ADMIN) ? ' ${language.by} ${method.capitalizeFirstLetter()}' : ''}';
}

Color getRatingBarColor(int rating, {bool showRedForZeroRating = false}) {
  if (rating == 1 || rating == 2) {
    return showRedForZeroRating ? showRedForZeroRatingColor : ratingBarColor;
  } else if (rating == 3) {
    return Color(0xFFff6200);
  } else if (rating == 4 || rating == 5) {
    return Color(0xFF73CB92);
  } else {
    return showRedForZeroRating ? showRedForZeroRatingColor : ratingBarColor;
  }
}

Future<FirebaseRemoteConfig> setupFirebaseRemoteConfig() async {
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  try {
    remoteConfig.setConfigSettings(RemoteConfigSettings(fetchTimeout: Duration.zero, minimumFetchInterval: Duration.zero));
    await remoteConfig.fetch();
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    throw language.firebaseRemoteCannotBe;
  }
  if (remoteConfig.getString(USER_CHANGE_LOG).isNotEmpty) await compareValuesInSharedPreference(USER_CHANGE_LOG, remoteConfig.getString(USER_CHANGE_LOG));
  if (remoteConfig.getString(USER_CHANGE_LOG).validate().isNotEmpty) {
    remoteConfigDataModel = RemoteConfigDataModel.fromJson(jsonDecode(remoteConfig.getString(USER_CHANGE_LOG)));

    await compareValuesInSharedPreference(IN_MAINTENANCE_MODE, remoteConfigDataModel.inMaintenanceMode);

    if (isIOS) {
      await compareValuesInSharedPreference(HAS_IN_REVIEW, remoteConfig.getBool(HAS_IN_APP_STORE_REVIEW));
    } else if (isAndroid) {
      await compareValuesInSharedPreference(HAS_IN_REVIEW, remoteConfig.getBool(HAS_IN_PLAY_STORE_REVIEW));
    }
  }

  return remoteConfig;
}

void ifNotTester(VoidCallback callback) {
  if (appStore.userEmail != DEFAULT_EMAIL) {
    callback.call();
  } else {
    toast(language.lblUnAuthorized);
  }
}

void doIfLoggedIn(BuildContext context, VoidCallback callback) {
  if (appStore.isLoggedIn) {
    callback.call();
  } else {
    SignInScreen(returnExpected: true).launch(context).then((value) {
      if (value ?? false) {
        callback.call();
      }
    });
  }
}

Widget get trailing {
  return ic_arrow_right.iconImage(size: 16);
}

void showNewUpdateDialog(BuildContext context) async {
  showInDialog(
    context,
    contentPadding: EdgeInsets.zero,
    barrierDismissible: !remoteConfigDataModel.isForceUpdate.validate(),
    builder: (_) {
      return NewUpdateDialog();
    },
  );
}

Future<void> showForceUpdateDialog(BuildContext context) async {
  if (getBoolAsync(UPDATE_NOTIFY, defaultValue: true)) {
    getPackageInfo().then((value) {
      if (isAndroid && remoteConfigDataModel.android != null && remoteConfigDataModel.android!.versionCode.validate().toInt() > value.versionCode.validate().toInt()) {
        showNewUpdateDialog(context);
      } else if (isIOS && remoteConfigDataModel.iOS != null && remoteConfigDataModel.iOS!.versionCode.validate() != value.versionCode.validate()) {
        showNewUpdateDialog(context);
      }
    });
  }
}

bool isTodayAfterDate(DateTime val) => val.isAfter(todayDate);

Widget mobileNumberInfoWidget() {
  return RichTextWidget(
    list: [
      TextSpan(text: language.addYourCountryCode, style: secondaryTextStyle()),
      TextSpan(text: ' "91-", "236-" ', style: boldTextStyle(size: 12)),
      TextSpan(
        text: ' (${language.help})',
        style: boldTextStyle(size: 12, color: primaryColor),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            launchUrlCustomTab("https://countrycode.org/");
          },
      ),
    ],
  );
}

Future<bool> compareValuesInSharedPreference(String key, dynamic value) async {
  bool status = false;
  if (value is String) {
    status = getStringAsync(key) == value;
  } else if (value is bool) {
    status = getBoolAsync(key) == value;
  } else if (value is int) {
    status = getIntAsync(key) == value;
  } else if (value is double) {
    status = getDoubleAsync(key) == value;
  }

  if (!status) {
    await setValue(key, value);
  }
  return status;
}
Future<File> getCameraImage({bool isCamera = true}) async {
  final pickedImage = await ImagePicker().pickImage(source: isCamera ? ImageSource.camera : ImageSource.gallery);
  return File(pickedImage!.path);
}

Future<List<File>> getMultipleImageSource({bool isCamera = true}) async {
  final pickedImage = await ImagePicker().pickMultiImage();
  return pickedImage.map((e) => File(e.path)).toList();
}