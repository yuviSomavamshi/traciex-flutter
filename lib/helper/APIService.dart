import 'dart:convert';
import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:http/io_client.dart';
import 'package:traciex/helper/SharedPreferencesHelper.dart';
import 'package:traciex/models/API.dart';
import 'package:traciex/models/Location.dart';
import 'package:traciex/models/QRCode.dart';
import 'package:traciex/models/Result.dart';
import 'package:traciex/models/user.dart';
import 'package:meta/meta.dart';
import '../constants.dart';
import 'Convertor.dart';
import 'navigate.dart';

class APIService {
  final String _endpoint = kWebsite + "/api/v1";
  Dio _dio;

  APIService() {
    BaseOptions options = BaseOptions(
        receiveTimeout: 10000, sendTimeout: 3000, connectTimeout: 10000);
    _dio = Dio(options);
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
    _dio.options.baseUrl = _endpoint;
    _dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      String token = await SharedPreferencesHelper.getUserToken();
      if (token != null) {
        options.headers["Authorization"] = "Bearer " + token;
      }
      String cookie = await SharedPreferencesHelper.getRefreshToken();
      if (cookie != null) {
        options.headers["Cookie"] = cookie;
      }
      String csrf = await SharedPreferencesHelper.getCSRFToken();
      if (csrf != null) {
        options.headers["X-CSRF-Token"] = csrf;
      }
      options.headers["User-Agent"] = "HealthX-Mobile";
      options.headers["Accept"] = "application/json";

      // Do something before request is sent
      return handler.next(options); //continue
      // If you want to resolve the request with some custom data，
      // you can resolve a `Response` object eg: return `dio.resolve(response)`.
      // If you want to reject the request with a error message,
      // you can reject a `DioError` object eg: return `dio.reject(dioError)`
    }, onResponse: (response, handler) {
      // Do something with response data
      try {
        response.data.putIfAbsent("statusCode", () => response.statusCode);
      } catch (e) {
        print(e);
      }
      return handler.next(response); // continue
      // If you want to reject the request with a error message,
      // you can reject a `DioError` object eg: return `dio.reject(dioError)`
    }, onError: (DioError error, handler) async {
      if (error.type == DioErrorType.other ||
          error.type == DioErrorType.connectTimeout ||
          error.type == DioErrorType.receiveTimeout) {
        error.response = Response(data: {
          "message":
              "External service is not responding. Please try again after sometime."
        }, statusCode: 500, statusMessage: "No Internet", requestOptions: null);
      }
      // Do something with response error
      if (error.response?.statusCode == 401 &&
          error.requestOptions?.path != "/accounts/refresh-token") {
        try {
          String token = await SharedPreferencesHelper.getUserToken();
          if (token != null) {
            options.headers["Authorization"] = "Bearer " + token;
          }
          String cookie = await SharedPreferencesHelper.getRefreshToken();
          if (cookie != null) {
            options.headers["Cookie"] = cookie;
          }
          options.headers["User-Agent"] = "HealthX-Mobile";
          options.headers["Accept"] = "application/json";

          final ioc = new HttpClient();
          ioc.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          final http = new IOClient(ioc);
          var response = await http.post(
              Uri.parse(_endpoint + "/accounts/refresh-token"),
              body: {},
              headers: {
                "Authorization": "Bearer " + token,
                "Cookie": "refreshToken=" + cookie,
                "User-Agent": "HealthX-Mobile",
                "Accept": "application/json"
              });

          if (response.statusCode == 200) {
            User res = User.fromJson(jsonDecode(response.body));
            SharedPreferencesHelper.saveSession(res);
            return _dio.request(
                error.requestOptions.baseUrl + error.requestOptions.path,
                data: error.requestOptions.data,
                options: Options(method: error.requestOptions.method, headers: {
                  "Authorization": "Bearer " + res.jwtToken,
                  "Cookie": res.refreshToken,
                  "User-Agent": "HealthX-Mobile",
                  "Accept": "application/json"
                }));
          } else {
            SharedPreferencesHelper.clearSession();
            NavigationService.instance.navigateTo("/sign_in");
          }
        } catch (e) {
          print(e);
        }
        return _dio.request("", options: null);
      } else {
        return handler.next(error);
      }
    }));
  }

  Future<User> authenticate({
    @required String email,
    @required String password,
  }) async {
    try {
      final response = await _dio.post('/accounts/authenticate', data: {
        'email': email,
        'password': password,
      });
      if (response.headers['set-cookie'] != null) {
        response.data
            .putIfAbsent("refreshToken", () => response.headers['set-cookie']);
      }
      return User.fromJson(response.data);
    } catch (error) {
      Map map = Map<String, dynamic>.from(error.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return User.fromJson(map);
    }
  }

  Future<API> signup({
    @required String name,
    @required String email,
    @required String password,
  }) async {
    try {
      final response = await _dio.post('/accounts/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': password,
        'role': 'Patient'
      });
      return API.fromJson(response.data);
    } catch (error) {
      Map map = Map<String, dynamic>.from(error.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<API> verifyOTP(
      {@required String email, @required String token}) async {
    try {
      final response = await _dio.post('/accounts/verify-email',
          data: {'email': email, 'token': token});
      return API.fromJson(response.data);
    } catch (error) {
      Map map = Map<String, dynamic>.from(error.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<API> validateResetToken(
      {@required String email, @required String token}) async {
    try {
      final response = await _dio.post('/accounts/validate-reset-token',
          data: {'email': email, 'token': token});
      return API.fromJson(response.data);
    } catch (error) {
      Map map = Map<String, dynamic>.from(error.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<API> forgotPassword({@required String email}) async {
    try {
      final response =
          await _dio.post('/accounts/forgot-password', data: {'email': email});
      return API.fromJson(response.data);
    } catch (error) {
      Map map = Map<String, dynamic>.from(error.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<API> resetPassword(
      {@required String token,
      @required String email,
      @required String password,
      @required String confirmPassword}) async {
    try {
      final response = await _dio.post('/accounts/reset-password', data: {
        'email': email,
        'token': token,
        'password': password,
        'confirmPassword': confirmPassword
      });
      return API.fromJson(response.data);
    } catch (error) {
      Map map = Map<String, dynamic>.from(error.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<API> changePassword(
      {@required String oldPassword,
      @required String password,
      @required String confirmPassword}) async {
    try {
      final response = await _dio.post('/accounts/change-password', data: {
        'oldPassword': oldPassword,
        'password': password,
        'confirmPassword': confirmPassword
      });
      return API.fromJson(response.data);
    } catch (error) {
      Map map = Map<String, dynamic>.from(error.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<List<User>> getMyStaffs() async {
    try {
      final response = await _dio.get('/customer/staff');
      List<User> _users = [];
      if (response.statusCode == 200) {
        for (var user in response.data) {
          _users.add(User.fromJson(user));
        }
      }
      return _users;
    } on Exception catch (e) {
      print(e);
      return [];
    }
  }

  Future<Map<String, dynamic>> getUsageReport(
      String startDate, String endDate) async {
    try {
      final response = await _dio.get('/customer/usage-report?startDate=' +
          startDate +
          "&endDate=" +
          endDate);

      return response.data;
    } on Exception catch (e) {
      print(e);
      return null;
    }
  }

  Future<Map<String, dynamic>> getStaffUsageReport(
      String startDate, String endDate) async {
    try {
      final response = await _dio.get(
          '/customer/staff-usage-report?startDate=' +
              startDate +
              "&endDate=" +
              endDate);
      return response.data;
    } on Exception catch (e) {
      print(e);
      return null;
    }
  }

  Future<API> createStaff(
      {@required String name,
      @required String email,
      @required String password}) async {
    try {
      final response = await _dio.post('/customer/staff', data: {
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': password,
        'role': 'Staff'
      });
      return API.fromJson(response.data);
    } catch (error) {
      Map map = Map<String, dynamic>.from(error.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<API> deleteStaff(String id) async {
    try {
      final response = await _dio.delete('/customer/staff/' + id);
      return API.fromJson(response.data);
    } catch (error) {
      Map map = Map<String, dynamic>.from(error.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<List<Location>> getMyLocations() async {
    try {
      final response = await _dio.get('/customer/locations');
      List<Location> _locations = [];
      if (response.statusCode == 200) {
        for (var loc in response.data) {
          _locations.add(Location.fromJson(loc));
        }
      }
      return _locations;
    } on Exception catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<Location>> getAllLocations() async {
    try {
      final response = await _dio.get('/customer/locations/all');
      List<Location> _locations = [
        Location.fromJson({"id": "-1", "location": "Select"})
      ];
      if (response.statusCode == 200) {
        for (var loc in response.data) {
          _locations.add(Location.fromJson(loc));
        }
      }
      return _locations;
    } on Exception catch (e) {
      print(e);
      return [];
    }
  }

  Future<API> createLocation(String location) async {
    try {
      String customerId = await SharedPreferencesHelper.getUserId();
      final response = await _dio.post('/customer/location',
          data: {'customerId': customerId, 'location': location});
      return API.fromJson(response.data);
    } catch (error) {
      Map map = Map<String, dynamic>.from(error.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<API> deleteLocation(String id) async {
    try {
      final response = await _dio.delete('/customer/location/' + id);
      return API.fromJson(response.data);
    } catch (error) {
      Map map = Map<String, dynamic>.from(error.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<API> registerPatient(QRCode code) async {
    try {
      String locationId =
          await SharedPreferencesHelper.getString("DefaultTestLocationId");
      String location =
          await SharedPreferencesHelper.getString("DefaultTestLocationName");
      String staffId = await SharedPreferencesHelper.getUserId();
      final response = await _dio.post('/bc/register-device', data: {
        "patientId": code.getHash(),
        "barcode": code.relationship,
        "timestamp": DateTime.now().toString(),
        "location": location != null ? location : "-",
        "locationId": locationId,
        "staffId": staffId
      });
      return API.fromJson(response.data);
    } catch (e) {
      print(e);
      Map map = Map<String, dynamic>.from(e.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<API> scrapDevice(String barcode) async {
    try {
      String staffId = await SharedPreferencesHelper.getUserId();
      final response = await _dio.post('/bc/scrap-device',
          data: {'staffId': staffId, 'barcode': barcode});
      return API.fromJson(response.data);
    } catch (e) {
      print(e);
      Map map = Map<String, dynamic>.from(e.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<List<Result>> patientReport(String hash) async {
    try {
      final response =
          await _dio.post('/bc/diagnosis-report', data: {"patientId": hash});
      List<Result> _results = [];
      if (response.data['_status'] == 200) {
        for (var _result in response.data['results']) {
          var obj = Result.fromJson(_result);
          _results.add(obj);
        }
      }
      return _results;
    } on Exception catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<Result>> patients() async {
    try {
      String locationId =
          await SharedPreferencesHelper.getString("DefaultTestLocationId");
      final response = await _dio.get('/bc/location?locationId=' + locationId);
      List<Result> _results = [];
      if (response.statusCode == 200) {
        for (var _result in response.data) {
          Convertor c = new Convertor();
          dynamic json = jsonDecode(c.decrypt(_result["patientId"]));

          var obj = Result.fromJson({
            "id": json["id"],
            "name": json["name"],
            "nationality": json["nationality"],
            "dob": json["dob"],
            "diagnosis": _result["diagnosis"],
            "subject_id": _result["code"]
          });
          _results.add(obj);
        }
      }
      return _results;
    } on Exception catch (e) {
      print(e);
      return [];
    }
  }

  Future<bool> checkOutPatient(String patientId, String barcode) async {
    try {
      await _dio.post('/bc/checkout',
          data: {"patientId": patientId, "barcode": barcode});
      return true;
    } on Exception catch (e) {
      print(e);
      return false;
    }
  }

  Future<API> checkWebtimer() async {
    try {
      final response = await _dio.post('/ws/check', data: {});
      return API.fromJson(response.data);
    } catch (e) {
      Map map = Map<String, dynamic>.from(e.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<API> disconnectWebtimer() async {
    try {
      final response = await _dio.post('/ws/disconnect', data: {});
      return API.fromJson(response.data);
    } catch (e) {
      Map map = Map<String, dynamic>.from(e.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<API> registerWebtimer(String receiverName) async {
    try {
      final response =
          await _dio.post('/ws/register', data: {'receiverName': receiverName});
      return API.fromJson(response.data);
    } catch (e) {
      Map map = Map<String, dynamic>.from(e.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }

  Future<API> invokeWebtimer(String type, String user) async {
    try {
      final response =
          await _dio.post('/ws/timer/' + type, data: {'patientName': user});
      return API.fromJson(response.data);
    } catch (e) {
      Map map = Map<String, dynamic>.from(e.response?.data);
      map.putIfAbsent("statusCode", () => 500);
      return API.fromJson(map);
    }
  }
}
