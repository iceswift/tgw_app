import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gold_app/models/gold_price_model.dart';
import 'package:gold_app/models/gold_price_latest_model.dart';
import 'package:gold_app/models/jewelry_price_model.dart';
import 'package:gold_app/models/gold_weight_price_model.dart';
import 'package:gold_app/models/shop_price_model.dart';
import 'package:gold_app/models/gold_board_model.dart';

class GoldApiService {
  static const String baseUrl = 'https://api.thaigoldview.com';
  static const Duration _timeout = Duration(seconds: 15);

  Future<GoldBoard> getBoard() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/board'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        // Handle waiting_for_data status
        if (jsonResponse['status'] == 'waiting_for_data') {
          throw Exception('กำลังรอข้อมูลจากแหล่งที่มา...');
        }
        
        return GoldBoard.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load board data. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<List<GoldPrice>> getLatestPrices() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/history'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];

        return data.map((item) {
          return GoldPrice.fromJson(item);
        }).toList();
      } else {
        throw Exception('Failed to load gold prices');
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<GoldPrice> getCurrentPrice() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/gold'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // Map new API structure to GoldPrice model
        return GoldPrice(
          dateTime: jsonResponse['updated_at'] ?? '',
          goldBarBuy: jsonResponse['bullion_buy'] ?? '',
          goldOrnamentBuy: jsonResponse['ornament_buy'] ?? '',
          goldBarSell: '',
          goldOrnamentSell: '',
          spot: '',
          thb: '',
          change: '',
        );
      } else {
        throw Exception('Failed to load current gold price');
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<GoldPriceLatest> getLatestPrice() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/latest'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return GoldPriceLatest.fromJson(jsonResponse);
      } else {
        print(
          'API Error (getLatestPrice): ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to load latest gold price. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Connection Error (getLatestPrice): $e');
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<List<JewelryPrice>> getJewelryPrices() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/percent_jewelry'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];

        return data.map((item) {
          return JewelryPrice(
            type: item['type'] ?? '',
            perGramBuy: 'n/a',
            perBahtBuy: item['buy'] ?? 'n/a',
            perBahtSell: item['sell'] ?? 'n/a',
          );
        }).toList();
      } else {
        throw Exception('Failed to load jewelry prices');
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<List<GoldWeightPrice>> getWeightPrices() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/weight_jewelry'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((item) => GoldWeightPrice.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load weight prices');
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<List<ShopPrice>> getShopPrices() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/shops'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((item) => ShopPrice.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load shop prices');
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }
}
