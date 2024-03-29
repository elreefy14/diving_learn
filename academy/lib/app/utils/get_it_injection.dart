
import '../../features/web_view_feature/data/data_source/web_view_navigation_rule_evaluation_data_source.dart';
import '../../features/web_view_feature/data/repository_impl/web_view_repo_impl.dart';
import '../../features/web_view_feature/domain/repository/web_view_repo.dart';
import '../../features/web_view_feature/domain/usecase/on_route_change_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  //* Data sources
  getIt.registerLazySingleton<INavigationEvaluatorDataSource>(() => INavigationEvaluatorDataSourceImpl(),);

  //* Repository
  getIt.registerLazySingleton<WebViewRepo>(() => WebViewRepoImpl(iNavigationEvaluatorDataSource: getIt()),);

  //*cache service
  // getIt.registerLazySingleton<CacheService>(() => CacheService(),);
  //*Navigation service
  // getIt.registerLazySingleton<NavService>(() => NavService(),);

  //! ----------- Core -----------
  // getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(getIt()));
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  // getIt.registerLazySingleton<NetworkManager>(() => NetworkManager());

  //* Use cases
  getIt.registerLazySingleton<OnRouteChangeUseCase>(() => OnRouteChangeUseCase(repository: getIt(),),);

}
