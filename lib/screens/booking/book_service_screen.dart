import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/custom_stepper.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/screens/booking/component/booking_service_step1.dart';
import 'package:booking_system_flutter/screens/booking/component/booking_service_step2.dart';
import 'package:booking_system_flutter/screens/booking/component/booking_service_step3.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class CustomStep {
  final String title;
  final Widget page;

  CustomStep({required this.title, required this.page});
}

class BookServiceScreen extends StatefulWidget {
  final ServiceDetailResponse data;
  final int bookingAddressId;
  final BookingPackage? selectedPackage;

  BookServiceScreen({required this.data, this.bookingAddressId = 0, this.selectedPackage});

  @override
  _BookServiceScreenState createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  List<CustomStep>? stepsList;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    stepsList = [
      CustomStep(
        title: widget.data.serviceDetail!.isSlotAvailable ? language.lblStep2 : language.lblStep1,
        page: BookingServiceStep2(
          data: widget.data,
          isSlotAvailable: !widget.data.serviceDetail!.isSlotAvailable,
        ),
      ),
      CustomStep(
        title: widget.data.serviceDetail!.isSlotAvailable ? language.lblStep3 : language.lblStep2,
        page: BookingServiceStep3(data: widget.data, selectedPackage: widget.selectedPackage != null ? widget.selectedPackage : null),
      ),
    ];

    if (widget.data.serviceDetail!.isSlotAvailable) {
      stepsList!.insert(0, CustomStep(title: language.lblStep1, page: BookingServiceStep1(data: widget.data)));
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        language.bookTheService,
        textColor: Colors.white,
        color: context.primaryColor,
        backWidget: BackWidget(),
      ),
      body: Container(
        child: Column(
          children: [
            CustomStepper(stepsList: stepsList.validate()).expand(),
          ],
        ),
      ),
    );
  }
}
