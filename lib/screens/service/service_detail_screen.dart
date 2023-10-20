import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/model/slot_data.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/book_service_screen.dart';
import 'package:booking_system_flutter/screens/booking/component/booking_detail_provider_widget.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/screens/review/components/review_widget.dart';
import 'package:booking_system_flutter/screens/review/rating_view_all_screen.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/screens/service/component/service_detail_header_component.dart';
import 'package:booking_system_flutter/screens/service/component/service_faq_widget.dart';
import 'package:booking_system_flutter/screens/service/package/package_component.dart';
import 'package:booking_system_flutter/screens/service/shimmer/service_detail_shimmer.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

class ServiceDetailScreen extends StatefulWidget {
  final int serviceId;
  final ServiceData? service;

  ServiceDetailScreen({required this.serviceId, this.service});

  @override
  _ServiceDetailScreenState createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> with TickerProviderStateMixin {
  PageController pageController = PageController();

  Future<ServiceDetailResponse>? future;

  int selectedAddressId = 0;
  int selectedBookingAddressId = -1;
  BookingPackage? selectedPackage;

  @override
  void initState() {
    super.initState();
    setStatusBarColor(transparentColor);
    init();
  }

  void init() async {
    future = getServiceDetails(serviceId: widget.serviceId.validate(), customerId: appStore.userId);
  }

  //region Widgets
  Widget availableWidget({required ServiceData data}) {
    if (data.serviceAddressMapping.validate().isEmpty) return Offstage();

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.lblAvailableAt, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
          16.height,
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(
              data.serviceAddressMapping!.length,
              (index) {
                ServiceAddressMapping value = data.serviceAddressMapping![index];
                if (value.providerAddressMapping == null) return Offstage();

                bool isSelected = selectedAddressId == index;
                if (selectedBookingAddressId == -1) {
                  selectedBookingAddressId = data.serviceAddressMapping!.first.providerAddressId.validate();
                }
                return GestureDetector(
                  onTap: () {
                    selectedAddressId = index;
                    selectedBookingAddressId = value.providerAddressId.validate();
                    setState(() {});
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: boxDecorationDefault(color: isSelected ? primaryColor : context.cardColor),
                    child: Text(
                      '${value.providerAddressMapping!.address.validate()}',
                      style: boldTextStyle(color: isSelected ? Colors.white : textPrimaryColorGlobal),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget providerWidget({required UserData data}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(language.lblAboutProvider, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        16.height,
        BookingDetailProviderWidget(providerData: data).onTap(() async {
          await ProviderInfoScreen(providerId: data.id).launch(context);
          setStatusBarColor(Colors.transparent);
        }),
      ],
    ).paddingAll(16);
  }

  Widget serviceFaqWidget({required List<ServiceFaq> data}) {
    if (data.isEmpty) return Offstage();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ViewAllLabel(label: language.lblFaq, list: data),
          8.height,
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: data.length,
            padding: EdgeInsets.all(0),
            itemBuilder: (_, index) => ServiceFaqWidget(serviceFaq: data[index]),
          ),
          8.height,
        ],
      ),
    );
  }

  Widget slotsAvailable({required List<SlotData> data, required bool isSlotAvailable}) {
    if (!isSlotAvailable || data.where((element) => element.slot.validate().isNotEmpty).isEmpty) return Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ViewAllLabel(label: language.lblAvailableOnTheseDays, list: []),
        6.height,
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(data.where((element) => element.slot.validate().isNotEmpty).length, (index) {
            SlotData value = data.where((element) => element.slot.validate().isNotEmpty).toList()[index];
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: boxDecorationDefault(color: context.cardColor),
              child: Text('${value.day.capitalizeFirstLetter()}', style: secondaryTextStyle(size: LABEL_TEXT_SIZE, color: primaryColor)),
            );
          }),
        ),
      ],
    ).paddingAll(16);
  }

  Widget reviewWidget({required List<RatingData> data, required ServiceDetailResponse serviceDetailResponse}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ViewAllLabel(
          //label: language.review,
          label: '${language.review} (${serviceDetailResponse.serviceDetail!.totalReview})',
          list: data,
          onTap: () {
            RatingViewAllScreen(serviceId: widget.serviceId).launch(context);
          },
        ),
        data.isNotEmpty
            ? Wrap(
                children: List.generate(
                  data.length,
                  (index) => ReviewWidget(data: data[index]),
                ),
              ).paddingTop(8)
            : Text(language.lblNoReviews, style: secondaryTextStyle()),
      ],
    ).paddingSymmetric(horizontal: 16);
  }

  Widget relatedServiceWidget({required List<ServiceData> serviceList, required int serviceId}) {
    if (serviceList.isEmpty) return Offstage();

    serviceList.removeWhere((element) => element.id == serviceId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        8.height,
        if (serviceList.isNotEmpty) Text(language.lblRelatedServices, style: boldTextStyle(size: LABEL_TEXT_SIZE)).paddingSymmetric(horizontal: 16),
        if (serviceList.isNotEmpty)
          HorizontalList(
            itemCount: serviceList.length,
            padding: EdgeInsets.all(16),
            spacing: 8,
            runSpacing: 16,
            itemBuilder: (_, index) => ServiceComponent(serviceData: serviceList[index], width: context.width() / 2 - 26).paddingOnly(right: 8),
          ),
        16.height,
      ],
    );
  }

  //endregion

  void bookNow(ServiceDetailResponse serviceDetailResponse) {
    doIfLoggedIn(context, () {
      serviceDetailResponse.serviceDetail!.bookingAddressId = selectedBookingAddressId;
      BookServiceScreen(data: serviceDetailResponse, selectedPackage: selectedPackage).launch(context).then((value) {
        setStatusBarColor(transparentColor);
      });
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    setStatusBarColor(transparentColor);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget buildBodyWidget(AsyncSnapshot<ServiceDetailResponse> snap) {
      if (snap.hasError) {
        return Text(snap.error.toString()).center();
      } else if (snap.hasData) {
        return Stack(
          children: [
            AnimatedScrollView(
              padding: EdgeInsets.only(bottom: 120),
              listAnimationType: ListAnimationType.FadeIn,
              fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
              onSwipeRefresh: () async {
                appStore.setLoading(true);
                init();
                setState(() {});

                return await 2.seconds.delay;
              },
              children: [
                ServiceDetailHeaderComponent(serviceDetail: snap.data!.serviceDetail!),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    8.height,
                    Text(language.hintDescription, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                    8.height,
                    snap.data!.serviceDetail!.description.validate().isNotEmpty
                        ? ReadMoreText(
                            snap.data!.serviceDetail!.description.validate(),
                            style: secondaryTextStyle(),
                            colorClickableText: context.primaryColor,
                            textAlign: TextAlign.justify,
                          )
                        : Text(language.lblNotDescription, style: secondaryTextStyle()),
                  ],
                ).paddingAll(16),
                slotsAvailable(data: snap.data!.serviceDetail!.bookingSlots.validate(), isSlotAvailable: snap.data!.serviceDetail!.isSlotAvailable),
                availableWidget(data: snap.data!.serviceDetail!),
                providerWidget(data: snap.data!.provider!),

                /// Only active status package display
                if (snap.data!.serviceDetail!.servicePackage.validate().isNotEmpty)
                  PackageComponent(
                    servicePackage: snap.data!.serviceDetail!.servicePackage.validate(),
                    callBack: (v) {
                      if (v != null) {
                        selectedPackage = v;
                      } else {
                        selectedPackage = null;
                      }
                      bookNow(snap.data!);
                    },
                  ),
                serviceFaqWidget(data: snap.data!.serviceFaq.validate()),
                reviewWidget(data: snap.data!.ratingData!, serviceDetailResponse: snap.data!),
                24.height,
                if (snap.data!.relatedService.validate().isNotEmpty) relatedServiceWidget(serviceList: snap.data!.relatedService.validate(), serviceId: snap.data!.serviceDetail!.id.validate()),
              ],
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: AppButton(
                onTap: () {
                  bookNow(snap.data!);
                },
                color: context.primaryColor,
                child: Text(language.lblBookNow, style: boldTextStyle(color: white)),
                width: context.width(),
                textColor: Colors.white,
              ),
            )
          ],
        );
      }
      return ServiceDetailShimmer();
    }

    return FutureBuilder<ServiceDetailResponse>(
      initialData: listOfCachedData.firstWhere((element) => element?.$1 == widget.serviceId.validate(), orElse: () => null)?.$2,
      future: future,
      builder: (context, snap) {
        return Scaffold(
          body: Stack(
            children: [
              buildBodyWidget(snap),
              Observer(builder: (context) => LoaderWidget().visible(appStore.isLoading)),
            ],
          ),
        );
      },
    );
  }
}
