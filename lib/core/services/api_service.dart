import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class ApiService {
  final Dio client = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return client.get(path, queryParameters: query);
  }

  Future<Response<dynamic>> post(String path, {Object? data}) {
    return client.post(path, data: data);
  }

  Future<Response<dynamic>> put(String path, {Object? data}) {
    return client.put(path, data: data);
  }

  Future<Response<dynamic>> delete(String path) {
    return client.delete(path);
  }
}
