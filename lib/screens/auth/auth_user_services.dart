import 'dart:convert';

import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/login_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:nb_utils/nb_utils.dart';

Future<LoginResponse> loginCurrentUsers(BuildContext context, {required Map<String, dynamic> req, bool isSocialLogin = false, bool isOtpLogin = false}) async {
  appStore.setLoading(true);

  String? uid = req['uid'];

  final userValue = await loginUser(req, isSocialLogin: isSocialLogin);
  if (userValue.userData != null && userValue.userData!.status == 0) throw language.accessDeniedContactYourAdmin;
  userValue.userData?.uid = uid;

  log("***************** Normal Login Succeeds *****************");

  return userValue;
}

void saveDataToPreference(BuildContext context, {required UserData userData, bool isSocialLogin = false, required Function onRedirectionClick}) async {
  onRedirectionClick.call();
  saveUserData(userData);
  registerInFirebase(context, userData: userData, isSocialLogin: isSocialLogin);
}

void registerInFirebase(BuildContext context, {required UserData userData, bool isSocialLogin = false}) async {
  await firebaseLogin(context, userData: userData, isSocialLogin: isSocialLogin).then((value) async {
    if (await userService.isUserExistWithUid(value.validate())) {
      appStore.setUId(value.validate());
    } else {}
  }).catchError((e) async {
    log("================== Error In Firebase =========================");
    log(e);
  });
}

Future<String> firebaseLogin(BuildContext context, {required UserData userData, bool isSocialLogin = false}) async {
  try {
    final firebaseEmail = userData.email.validate();

    final firebaseUid = await authService.signInWithEmailPassword(email: firebaseEmail, uid: userData.uid.validate(), isSocialLogin: isSocialLogin);

    userData.uid = firebaseUid;

    log("***************** User Already Registered in Firebase $firebaseUid;*****************");

    log(!isSocialLogin && await userService.isUserExistWithUid(firebaseUid));
    log(await userService.isUserExistWithUid(firebaseUid));
    log(!isSocialLogin);
    if (!isSocialLogin && await userService.isUserExistWithUid(firebaseUid)) {
      return firebaseUid;
    } else {
      return await authService.setRegisterData(userData: userData);
    }
  } catch (e) {
    if (e.toString() == USER_NOT_FOUND) {
      log("***************** ($e) , Again registering the current user *****************");

      return await registerUserInFirebase(context, user: userData);
    } else {
      throw e.toString();
    }
  }
}

Future<String> registerUserInFirebase(BuildContext context, {required UserData user}) async {
  try {
    log("*************************************************** Login user is registering again.  ***************************************************");
    return authService.signUpWithEmailPassword(context, userData: user);
  } catch (e) {
    throw e.toString();
  }
}

Future<void> updatePlayerId({required String playerId}) async {
  if (playerId.isEmpty || !appStore.isLoggedIn) return;

  userService.updatePlayerIdInFirebase(email: appStore.userEmail.validate(), playerId: playerId);

  MultipartRequest multiPartRequest = await getMultiPartRequest('update-profile');
  Map<String, dynamic> req = {
    UserKeys.id: appStore.userId,
    UserKeys.playerId: playerId,
  };

  multiPartRequest.fields.addAll(await getMultipartFields(val: req));

  multiPartRequest.headers.addAll(buildHeaderTokens());

  log("MultiPart Request : ${jsonEncode(multiPartRequest.fields)} ${multiPartRequest.files.map((e) => e.field + ": " + e.filename.validate())}");

  await sendMultiPartRequest(multiPartRequest, onSuccess: (temp) async {
    appStore.setLoading(false);

    if ((temp as String).isJson()) {
      appStore.setPlayerId(playerId);
    }
  }, onError: (error) {
    log(error);
    appStore.setLoading(false);
  }).catchError((e) {
    appStore.setLoading(false);
    log(e);
  });
}

Future<void> setUserInFirebaseIfNotRegistered(BuildContext context) async {
  appStore.setLoading(true);

  UserData tempUserData = UserData()
    ..contactNumber = appStore.userContactNumber.validate()
    ..email = appStore.userEmail.validate()
    ..firstName = appStore.userFirstName.validate()
    ..lastName = appStore.userLastName.validate()
    ..profileImage = appStore.userProfileImage.validate()
    ..userType = appStore.userType.validate()
    ..loginType = appStore.loginType
    ..playerId = getStringAsync(PLAYERID)
    ..username = appStore.userName;

  await registerUserInFirebase(context, user: tempUserData).then((value) {
    appStore.setUId(value);
  }).catchError((e) {
    log(e.toString());
  });

  appStore.setLoading(false);
}
