import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../main.dart';

class AppliedTaxListBottomSheet extends StatelessWidget {
  final List<TaxData> taxes;
  final num subTotal;

  const AppliedTaxListBottomSheet({super.key, required this.taxes, required this.subTotal});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.appliedTaxes, style: boldTextStyle(size: LABEL_TEXT_SIZE)).paddingSymmetric(horizontal: 16),
          8.height,
          AnimatedListView(
            itemCount: taxes.length,
            padding: EdgeInsets.all(8),
            shrinkWrap: true,
            listAnimationType: ListAnimationType.FadeIn,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (_, index) {
              TaxData data = taxes[index];

              if (data.type == TAX_TYPE_PERCENT) {
                data.totalCalculatedValue = subTotal * data.value.validate() / 100;
              } else {
                data.totalCalculatedValue = data.value.validate();
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data.title.validate(), style: primaryTextStyle()).expand(),
                    PriceWidget(price: data.totalCalculatedValue.validate()),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
