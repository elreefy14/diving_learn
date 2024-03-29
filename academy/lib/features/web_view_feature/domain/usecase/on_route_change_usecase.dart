import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../../app/usecase/usecase.dart';
import '../repository/web_view_repo.dart';

class OnRouteChangeUseCase implements UseCaseWithoutEither<NavigationActionPolicy?, OnRouteChangeUseCaseParams> {

  OnRouteChangeUseCase({required this.repository});
  final WebViewRepo repository;

  @override
  Future<NavigationActionPolicy?> call(OnRouteChangeUseCaseParams params) {
    return repository.onRouteChange(params.controller,params.navigationAction);
  }
}

class OnRouteChangeUseCaseParams {

  const OnRouteChangeUseCaseParams({
    required this.controller,
    required this.navigationAction,
  });

  final InAppWebViewController controller;
  final  NavigationAction navigationAction;
}
