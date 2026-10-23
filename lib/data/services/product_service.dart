import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService;

  ProductService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  ApiService get apiService => _apiService;
  String? get lastError => _apiService.lastError;
  bool get isBackendConnected => _apiService.isBackendConnected;

  Future<List<Product>> fetchProducts({String? category, String? search}) async {
    return await _apiService.getProducts(category: category, search: search);
  }

  Future<Product?> fetchProductById(int id) async {
    return await _apiService.getProductById(id);
  }
}

