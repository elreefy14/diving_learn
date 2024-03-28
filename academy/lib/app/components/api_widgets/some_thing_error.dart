import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../config/translations/strings_enum.dart';

import '../custom_text.dart';

class SomeThingErrorWidget extends StatelessWidget {
  const SomeThingErrorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80.h,
      child: const Center(
        child: CustomText(
          txt: Strings.someThingErrorPleaseTryAgain,
          maxLine: 3,
        ),
      ),
    );
  }
}
