import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Comunicação HTTP com a API PHP de tarefas.
class ApiService {
  static const String endpoint =
      'http://10.140.170.19/pdm_api/tarefas.php';
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(String path) async =>
      _decode(await _client.get(_uri(path), headers: _headers));

  Future<Map<String, dynamic>> post(
          String path, Map<String, dynamic> body) async =>
      _decode(await _client.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<Map<String, dynamic>> put(
          String path, Map<String, dynamic> body) async =>
      _decode(await _client.put(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<Map<String, dynamic>> delete(String path) async =>
      _decode(await _client.delete(_uri(path), headers: _headers));

  Uri _uri(String path) {
    final value = path.startsWith('http') ? path : '$endpoint$path';
    return Uri.parse(value);
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
      };

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('O servidor respondeu com erro HTTP ${response.statusCode}.');
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Formato JSON inesperado.');
      }
      if (decoded['sucesso'] == false) {
        throw ApiException('${decoded['mensagem'] ?? 'A operação não foi concluída.'}');
      }
      return decoded;
    } on FormatException {
      throw ApiException('A resposta da API não está em um formato JSON válido.');
    }
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}
