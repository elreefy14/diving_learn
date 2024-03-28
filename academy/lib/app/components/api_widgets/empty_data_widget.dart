import 'package:flutter/material.dart';

import '../../../config/translations/strings_enum.dart';
import '../custom_text.dart';

class EmptyDataWidget extends StatelessWidget {
  const EmptyDataWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CustomText(
        txt: Strings.emptyData,
        maxLine: 3,
      ),
    );
  }
}
