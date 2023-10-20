import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/configuration_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:uuid/uuid.dart';

class FlutterWaveServiceNew {
  final Customer customer = Customer(
    name: appStore.userName,
    phoneNumber: appStore.userContactNumber,
    email: appStore.userEmail,
  );

  void checkout({
    required PaymentSetting paymentSetting,
    required num totalAmount,
    required Function(Map) onComplete,
  }) async {
    String transactionId = Uuid().v1();
    String flutterWavePublicKey = '';
    String flutterWaveSecretKey = '';

    if (paymentSetting.isTest == 1) {
      flutterWavePublicKey = paymentSetting.testValue!.flutterwavePublic!;
      flutterWaveSecretKey = paymentSetting.testValue!.flutterwaveSecret!;
    } else {
      flutterWavePublicKey = paymentSetting.liveValue!.flutterwavePublic!;
      flutterWaveSecretKey = paymentSetting.liveValue!.flutterwaveSecret!;
    }

    Flutterwave flutterWave = Flutterwave(
      context: getContext,
      publicKey: flutterWavePublicKey,
      currency: appStore.currencyCode,
      redirectUrl: BASE_URL,
      txRef: transactionId,
      amount: totalAmount.validate().toStringAsFixed(DECIMAL_POINT),
      customer: customer,
      paymentOptions: "card, payattitude, barter",
      customization: Customization(title: language.payWithFlutterWave, logo: appLogo),
      isTestMode: paymentSetting.isTest == 1,
    );

    await flutterWave.charge().then((value) {
      if (value.status == "successful") {
        appStore.setLoading(true);

        verifyPayment(transactionId: value.transactionId.validate(), flutterWaveSecretKey: flutterWaveSecretKey).then((v) {
          if (v.status == "success") {
            onComplete.call({
              'transaction_id': value.transactionId.validate(),
            });
          } else {
            appStore.setLoading(false);
            toast(language.transactionFailed);
          }
        }).catchError((e) {
          appStore.setLoading(false);

          toast(e.toString());
        });
      } else {
        toast(language.lblTransactionCancelled);
        appStore.setLoading(false);
      }
    });
  }
}
