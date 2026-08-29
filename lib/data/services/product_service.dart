import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService;

  ProductService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<List<Product>> fetchProducts({String? category, String? search}) async {
    return await _apiService.getProducts(category: category, search: search);
  }
}
