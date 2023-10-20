import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../main.dart';
import '../model/configuration_response.dart';
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/configs.dart';

class RazorPayServiceNew {
  late PaymentSetting paymentSetting;
  late Razorpay razorPay;
  num totalAmount = 0;
  late Function(Map<String, dynamic>) onComplete;

  RazorPayServiceNew({
    required PaymentSetting paymentSetting,
    required num totalAmount,
    required Function(Map<String, dynamic>) onComplete,
  }) {
    razorPay = Razorpay();
    razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);
    this.paymentSetting = paymentSetting;
    this.totalAmount = totalAmount;
    this.onComplete = onComplete;
  }

  Future handlePaymentSuccess(PaymentSuccessResponse response) async {
    appStore.setLoading(false);
    onComplete.call({
      'orderId': response.orderId,
      'paymentId': response.paymentId,
      'signature': response.signature,
    });
  }

  void handlePaymentError(PaymentFailureResponse response) {
    appStore.setLoading(false);
    toast(response.message.validate(), print: true);
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    appStore.setLoading(false);
    toast("${language.externalWallet} " + response.walletName!);
  }

  void razorPayCheckout() async {
    appStore.setLoading(true);
    String razorKey = '';
    if (paymentSetting.isTest == 1) {
      razorKey = paymentSetting.testValue!.razorKey!;
    } else {
      razorKey = paymentSetting.liveValue!.razorKey!;
    }

    var options = {
      'key': razorKey,
      'amount': (totalAmount * 100).toInt(),
      'name': APP_NAME,
      'theme.color': primaryColor.toHex(),
      'description': APP_NAME,
      'image': 'https://razorpay.com/assets/razorpay-glyph.svg',
      'currency': await isIqonicProduct ? RAZORPAY_CURRENCY_CODE : '${appStore.currencyCode}',
      'prefill': {'contact': appStore.userContactNumber, 'email': appStore.userEmail},
      /* 'external': {
        'wallets': ['paytm']
      }*/
    };
    try {
      razorPay.open(options);
    } catch (e) {
      appStore.setLoading(false);
      debugPrint(e.toString());
    }
  }
}
