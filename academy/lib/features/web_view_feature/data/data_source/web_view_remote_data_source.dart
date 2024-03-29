// import 'dart:developer';
// import '../models/app_updater_model.dart';
//
// abstract class WebViewRemoteDataSource {
//   /// Calls the [GET] {/CustomerHybridApp/GetCustomerHybridAppVersionAndConfiguration?platformID=} endpoint.
//   ///
//   /// Throws a [ServerException] for all error codes.
//   Future<AppUpdaterModel> checkForUpdate(Map<String, dynamic> map);
//
// }
//
// class WebViewRemoteDataSourceImpl implements WebViewRemoteDataSource {
//
//   WebViewRemoteDataSourceImpl({required this.networkManager});
//   final NetworkManager networkManager;
//
//   @override
//   Future<AppUpdaterModel> checkForUpdate(Map<String, dynamic> map) async {
//     final res = await networkManager.request(
//       method: RequestMethod.get,
//       queryParameters: map,
//       endPoint: fetchConfigurationUrl,
//       baseVersion: ''
//     );
//     return  _handleResponse(
//       res,
//     );
//   }
//
//   Future<AppUpdaterModel> _handleResponse(
//       Response res,
//       ) async {
//     log(res.data.toString(), name: "response");
//     log(res.statusCode.toString(), name: "statusCode");
//     //todo: ensure the backend has 201 success code
//     if (res.statusCode == 200) {
//       return AppUpdaterModel.fromJson(res.data);
//     } else {
//       //todo: ensure the backend send error message with [message] key
//       throw ServerException(res);
//     }
//   }
// }
