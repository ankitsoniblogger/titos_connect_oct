import 'package:booking_system_flutter/component/app_common_dialog.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/custom_stepper.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/screens/booking/component/confirm_booking_dialog.dart';
import 'package:booking_system_flutter/screens/booking/component/coupon_widget.dart';
import 'package:booking_system_flutter/screens/service/package/package_info_bottom_sheet.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/wallet_balance_component.dart';
import '../../../model/booking_amount_model.dart';
import '../../../utils/booking_calculations_logic.dart';
import 'applied_tax_list_bottom_sheet.dart';

class BookingServiceStep3 extends StatefulWidget {
  final ServiceDetailResponse data;
  final BookingPackage? selectedPackage;

  BookingServiceStep3({required this.data, this.selectedPackage});

  @override
  _BookingServiceStep3State createState() => _BookingServiceStep3State();
}

class _BookingServiceStep3State extends State<BookingServiceStep3> {
  CouponData? appliedCouponData;

  BookingAmountModel bookingAmountModel = BookingAmountModel();
  num advancePaymentAmount = 0;

  int itemCount = 1;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    setPrice();
  }

  void setPrice() {
    bookingAmountModel = finalCalculations(
      servicePrice: widget.data.serviceDetail!.price.validate(),
      appliedCouponData: appliedCouponData,
      discount: widget.data.serviceDetail!.discount.validate(),
      taxes: widget.data.taxes,
      quantity: itemCount,
      selectedPackage: widget.selectedPackage,
    );

    if (bookingAmountModel.finalGrandTotalAmount.isNegative) {
      appliedCouponData = null;
      setPrice();

      toast(language.youCannotApplyThisCoupon);
    } else {
      advancePaymentAmount = (bookingAmountModel.finalGrandTotalAmount * (widget.data.serviceDetail!.advancePaymentPercentage.validate() / 100).toStringAsFixed(DECIMAL_POINT).toDouble());
    }
    setState(() {});
  }

  void applyCoupon() async {
    var value = await showInDialog(
      context,
      backgroundColor: context.cardColor,
      contentPadding: EdgeInsets.zero,
      builder: (p0) {
        return AppCommonDialog(
          title: language.lblAvailableCoupons,
          child: CouponWidget(
            couponData: widget.data.couponData.validate(),
            appliedCouponData: appliedCouponData ?? null,
          ),
        );
      },
    );

    if (value != null) {
      if (value is bool && !value) {
        appliedCouponData = null;
      } else if (value is CouponData) {
        appliedCouponData = value;
      } else {
        appliedCouponData = null;
      }
      setPrice();
    }
  }

  Widget priceWidget() {
    if (!widget.data.serviceDetail!.isFreeService)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.priceDetail, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
          16.height,
          Container(
            padding: EdgeInsets.all(16),
            width: context.width(),
            decoration: boxDecorationDefault(color: context.cardColor),
            child: Column(
              children: [
                /// Service or Package Price
                Row(
                  children: [
                    Text(language.lblPrice, style: secondaryTextStyle(size: 14)).expand(),
                    16.width,
                    if (widget.selectedPackage != null)
                      PriceWidget(price: bookingAmountModel.finalTotalServicePrice, color: textPrimaryColorGlobal, isBoldText: true)
                    else if (!widget.data.serviceDetail!.isHourlyService)
                      Marquee(
                        child: Row(
                          children: [
                            PriceWidget(price: widget.data.serviceDetail!.price.validate(), size: 12, isBoldText: false, color: textSecondaryColorGlobal),
                            Text(' * $itemCount  = ', style: secondaryTextStyle()),
                            PriceWidget(price: bookingAmountModel.finalTotalServicePrice, color: textPrimaryColorGlobal),
                          ],
                        ),
                      )
                    else
                      PriceWidget(price: bookingAmountModel.finalTotalServicePrice, color: textPrimaryColorGlobal, isBoldText: true)
                  ],
                ),

                /// Fix Discount on Base Price
                if (widget.data.serviceDetail!.discount.validate() != 0 && widget.selectedPackage == null)
                  Column(
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        children: [
                          Text(language.lblDiscount, style: secondaryTextStyle(size: 14)),
                          Text(
                            " (${widget.data.serviceDetail!.discount.validate()}% ${language.lblOff.toLowerCase()})",
                            style: boldTextStyle(color: Colors.green),
                          ).expand(),
                          16.width,
                          PriceWidget(
                            price: bookingAmountModel.finalDiscountAmount,
                            color: Colors.green,
                            isBoldText: true,
                          ),
                        ],
                      ),
                    ],
                  ),

                /// Coupon Discount on Base Price
                if (widget.selectedPackage == null)
                  Column(
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      if (appliedCouponData != null)
                        Row(
                          children: [
                            Row(
                              children: [
                                Text(language.lblCoupon, style: secondaryTextStyle(size: 14)),
                                Text(
                                  " (${appliedCouponData!.code})",
                                  style: boldTextStyle(color: primaryColor, size: 14),
                                ).onTap(() {
                                  applyCoupon();
                                }).expand(),
                              ],
                            ).expand(),
                            PriceWidget(
                              price: bookingAmountModel.finalCouponDiscountAmount,
                              color: Colors.green,
                              isBoldText: true,
                            ),
                          ],
                        ),
                      if (appliedCouponData == null)
                        Row(
                          children: [
                            Text(language.lblCoupon, style: secondaryTextStyle(size: 14)).expand(),
                            Text(
                              language.applyCoupon,
                              style: boldTextStyle(color: primaryColor, size: 14),
                            ).onTap(() {
                              applyCoupon();
                            }),
                          ],
                        ),
                      /*Row(
                      children: [
                        if (appliedCouponData != null) Text(language.lblCoupon, style: secondaryTextStyle(size: 14)) else Text(language.lblCoupon, style: secondaryTextStyle(size: 14)).expand(),
                        if (appliedCouponData != null)
                          Text(
                            " (${appliedCouponData!.code})",
                            style: boldTextStyle(color: primaryColor),
                          ).onTap(() {
                            applyCoupon();
                          }).expand(),
                        Text(
                          appliedCouponData != null ? "" : language.applyCoupon,
                          style: boldTextStyle(color: primaryColor),
                        ).onTap(() {
                          applyCoupon();
                        }),
                        if (appliedCouponData != null)
                          PriceWidget(
                            price: bookingAmountModel.finalCouponDiscountAmount,
                            color: Colors.green,
                            isBoldText: true,
                          ),
                      ],
                    ),*/
                    ],
                  ),

                /// Show Subtotal, Total Amount and Apply Discount, Coupon if service is Fixed or Hourly
                if (widget.selectedPackage == null)
                  if (!widget.data.serviceDetail!.isHourlyService)
                    Column(
                      children: [
                        Divider(height: 26, color: context.dividerColor),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(language.lblSubTotal, style: secondaryTextStyle(size: 14)).flexible(fit: FlexFit.loose),
                            16.width,
                            PriceWidget(price: bookingAmountModel.finalSubTotal, color: textPrimaryColorGlobal)
                          ],
                        ),
                      ],
                    ),

                /// Tax Amount Applied on Price
                Column(
                  children: [
                    Divider(height: 26, color: context.dividerColor),
                    Row(
                      children: [
                        Row(
                          children: [
                            Text(language.lblTax, style: secondaryTextStyle(size: 14)).expand(),
                            Icon(Icons.info_outline_rounded, size: 20, color: context.primaryColor).onTap(
                              () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) {
                                    return AppliedTaxListBottomSheet(taxes: widget.data.taxes.validate(), subTotal: bookingAmountModel.finalSubTotal);
                                  },
                                );
                              },
                            ),
                          ],
                        ).expand(),
                        16.width,
                        PriceWidget(price: bookingAmountModel.finalTotalTax, color: Colors.red, isBoldText: true),
                      ],
                    ),
                  ],
                ),

                /// Final Amount
                Column(
                  children: [
                    Divider(height: 26, color: context.dividerColor),
                    Row(
                      children: [
                        Text(language.totalAmount, style: secondaryTextStyle(size: 14)).expand(),
                        PriceWidget(
                          price: bookingAmountModel.finalGrandTotalAmount,
                          color: primaryColor,
                        )
                      ],
                    ),
                  ],
                ),

                /// Advance Payable Amount if it is required by Service Provider
                if (widget.data.serviceDetail!.isAdvancePayment)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        children: [
                          Row(
                            children: [
                              Text(language.advancePayAmount, style: secondaryTextStyle(size: 14)),
                              Text(" (${widget.data.serviceDetail!.advancePaymentPercentage.validate().toString()}%)  ", style: boldTextStyle(color: Colors.green)),
                            ],
                          ).expand(),
                          PriceWidget(price: advancePaymentAmount, color: primaryColor),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          )
        ],
      );

    return Offstage();
  }

  Widget buildDateWidget() {
    if (widget.data.serviceDetail!.isSlotAvailable) {
      return Text(widget.data.serviceDetail!.dateTimeVal.validate(), style: boldTextStyle(size: 12));
    }
    return Text(formatDate(widget.data.serviceDetail!.dateTimeVal.validate(), format: DATE_FORMAT_3), style: boldTextStyle(size: 12));
  }

  Widget buildTimeWidget() {
    if (widget.data.serviceDetail!.bookingSlot == null) {
      return Text(formatDate(widget.data.serviceDetail!.dateTimeVal.validate(), format: HOUR_12_FORMAT), style: boldTextStyle(size: 12));
    }
    return Text(
        TimeOfDay(
          hour: widget.data.serviceDetail!.bookingSlot.validate().splitBefore(':').split(":").first.toInt(),
          minute: widget.data.serviceDetail!.bookingSlot.validate().splitBefore(':').split(":").last.toInt(),
        ).format(context),
        style: boldTextStyle(size: 12));
  }

  Widget buildBookingSummaryWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(language.bookingDateAndSlot, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        16.height,
        Container(
          padding: EdgeInsets.all(16),
          decoration: boxDecorationDefault(color: context.cardColor),
          width: context.width(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("${language.lblDate}: ", style: secondaryTextStyle()),
                  buildDateWidget(),
                ],
              ),
              8.height,
              Row(
                children: [
                  Text("${language.lblTime}: ", style: secondaryTextStyle()),
                  buildTimeWidget(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget packageWidget() {
    if (widget.selectedPackage != null)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.package, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
          16.height,
          Container(
            padding: EdgeInsets.all(16),
            decoration: boxDecorationDefault(color: context.cardColor),
            width: context.width(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Marquee(child: Text(widget.selectedPackage!.name.validate(), style: boldTextStyle())),
                        4.height,
                        Row(
                          children: [
                            Text(language.includedServices, style: secondaryTextStyle()),
                            8.width,
                            ic_info.iconImage(size: 20),
                          ],
                        ),
                      ],
                    ).expand(),
                    16.width,
                    CachedImageWidget(
                      url: widget.selectedPackage!.imageAttachments.validate().isNotEmpty ? widget.selectedPackage!.imageAttachments!.first.validate() : '',
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ).cornerRadiusWithClipRRect(defaultRadius),
                  ],
                ).onTap(
                  () {
                    showModalBottomSheet(
                      backgroundColor: Colors.transparent,
                      context: context,
                      isScrollControlled: true,
                      isDismissible: true,
                      shape: RoundedRectangleBorder(borderRadius: radiusOnly(topLeft: defaultRadius, topRight: defaultRadius)),
                      builder: (_) {
                        return DraggableScrollableSheet(
                          initialChildSize: 0.50,
                          minChildSize: 0.2,
                          maxChildSize: 1,
                          builder: (context, scrollController) => PackageInfoComponent(packageData: widget.selectedPackage!, scrollController: scrollController),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );

    return Offstage();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.selectedPackage == null)
              Container(
                padding: EdgeInsets.all(16),
                decoration: boxDecorationDefault(color: context.cardColor),
                width: context.width(),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.data.serviceDetail!.name.validate(), style: boldTextStyle()),
                        16.height,
                        if (widget.data.serviceDetail!.isFixedService)
                          Container(
                            height: 40,
                            padding: EdgeInsets.all(8),
                            decoration: boxDecorationWithRoundedCorners(
                              backgroundColor: context.scaffoldBackgroundColor,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_drop_down_sharp, size: 24).onTap(
                                  () {
                                    if (itemCount != 1) itemCount--;
                                    setPrice();
                                  },
                                ),
                                16.width,
                                Text(itemCount.toString(), style: primaryTextStyle()),
                                16.width,
                                Icon(Icons.arrow_drop_up_sharp, size: 24).onTap(
                                  () {
                                    itemCount++;
                                    setPrice();
                                  },
                                ),
                              ],
                            ),
                          )
                      ],
                    ).expand(),
                    CachedImageWidget(
                      url: widget.data.serviceDetail!.attachments.validate().isNotEmpty ? widget.data.serviceDetail!.attachments!.first.validate() : '',
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ).cornerRadiusWithClipRRect(defaultRadius)
                  ],
                ),
              ),
            packageWidget(),
            16.height,
            buildBookingSummaryWidget(),
            16.height,
            priceWidget(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Observer(builder: (context) {
                  return WalletBalanceComponent().visible(appStore.isEnableUserWallet && widget.data.serviceDetail!.isFixedService);
                }),
                16.height,
                Text(language.disclaimer, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                Text(language.disclaimerContent, style: secondaryTextStyle()),
              ],
            ).paddingSymmetric(vertical: 16),
            36.height,
            Row(
              children: [
                AppButton(
                  onTap: () {
                    customStepperController.previousPage(duration: 200.milliseconds, curve: Curves.easeInOut);
                  },
                  shapeBorder: RoundedRectangleBorder(borderRadius: radius(), side: BorderSide(color: context.primaryColor)),
                  text: language.lblPrevious,
                  textColor: textPrimaryColorGlobal,
                ).expand(flex: 1),
                16.width,
                AppButton(
                  color: context.primaryColor,
                  text: widget.data.serviceDetail!.isAdvancePayment ? language.advancePayment : language.confirm,
                  textColor: Colors.white,
                  onTap: () {
                    showInDialog(
                      context,
                      builder: (p0) {
                        return ConfirmBookingDialog(
                          data: widget.data,
                          bookingPrice: bookingAmountModel.finalGrandTotalAmount,
                          selectedPackage: widget.selectedPackage,
                          qty: itemCount,
                          couponCode: appliedCouponData?.code,
                          bookingAmountModel: BookingAmountModel(
                            finalCouponDiscountAmount: bookingAmountModel.finalCouponDiscountAmount,
                            finalDiscountAmount: bookingAmountModel.finalDiscountAmount,
                            finalSubTotal: bookingAmountModel.finalSubTotal,
                            finalTotalServicePrice: bookingAmountModel.finalTotalServicePrice,
                            finalTotalTax: bookingAmountModel.finalTotalTax,
                          ),
                        );
                      },
                    );
                  },
                ).expand(flex: 2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
