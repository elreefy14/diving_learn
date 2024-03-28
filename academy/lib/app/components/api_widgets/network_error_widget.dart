import 'package:flutter/material.dart';

import '../../../config/translations/strings_enum.dart';
import '../custom_text.dart';

class NetworkErrorWidget extends StatelessWidget {
  const NetworkErrorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CustomText(
        txt: Strings.networkError,
        maxLine: 5,
        textAlign: TextAlign.center,
        height: 1.8,
      ),
    );
  }
}
