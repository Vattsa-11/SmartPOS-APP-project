import 'package:flutter/material.dart';
import '../models/inventory.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class InventoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Inventory> _inventoryItems = [];
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  
  // Filter properties
  String _searchQuery = '';
  bool _showLowStockOnly = false;
  
  // Getters
  List<Inventory> get inventoryItems => _inventoryItems;
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Filter getters
  String get searchQuery => _searchQuery;
  bool get showLowStockOnly => _showLowStockOnly;
  
  // Filtered inventory based on current filters
  List<Inventory> get filteredInventory {
    if (_inventoryItems.isEmpty) {
      return [];
    }
    
    return _inventoryItems.where((item) {
      // Create a product from the product data
      final product = item.product is Product 
          ? item.product as Product
          : Product.fromJson(item.product);
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!product.name.toLowerCase().contains(query) && 
            !product.barcode.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Apply low stock filter
      if (_showLowStockOnly && !item.isLowStock) {
        return false;
      }
      
      return true;
    }).toList();
  }
  

  
  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  // Toggle low stock filter
  void toggleLowStockFilter() {
    _showLowStockOnly = !_showLowStockOnly;
    notifyListeners();
  }
  
  // Reset all filters
  void resetFilters() {
    _searchQuery = '';
    _showLowStockOnly = false;
    notifyListeners();
  }
  
  // Load inventory data
  Future<void> fetchInventory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Try to load from API
      try {
        await _apiService.getInventory();
        // TODO: Parse inventory data properly when backend is ready
        _inventoryItems = [];
      } catch (apiError) {
        print('API call failed, using local data: $apiError');
        // Keep existing local data if API fails
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load inventory: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load products
  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Try to load products from API
      try {
        _products = await _apiService.getProducts();
      } catch (apiError) {
        print('API call failed, using local data: $apiError');
        // Keep existing local data if API fails
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load products: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add a product with initial inventory
  Future<void> addProduct(Product product, int quantity, int reorderLevel) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Add product to database via API
      final newProduct = await _apiService.addProduct(product);
      
      // Add to local products list
      _products.add(newProduct);
      
      // Create inventory item for the product
      final inventoryItem = Inventory(
        id: DateTime.now().millisecondsSinceEpoch,
        productId: newProduct.id!,
        product: newProduct,
        quantity: quantity,
        reorderLevel: reorderLevel,
        expiryDate: null,
      );
      
      // Add to local inventory
      _inventoryItems.add(inventoryItem);
      
      print('Added product to database: ${product.name} with quantity: $quantity');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error adding product: $e');
      // Fallback to local storage if API fails
      try {
        final newProduct = Product(
          id: DateTime.now().millisecondsSinceEpoch,
          name: product.name,
          barcode: product.barcode,
          price: product.price,
          category: product.category,
          userId: null,
          createdAt: DateTime.now().toIso8601String(),
        );
        
        _products.add(newProduct);
        
        final inventoryItem = Inventory(
          id: DateTime.now().millisecondsSinceEpoch + 1,
          productId: newProduct.id!,
          product: newProduct,
          quantity: quantity,
          reorderLevel: reorderLevel,
          expiryDate: null,
        );
        
        _inventoryItems.add(inventoryItem);
        
        print('Added product locally (fallback): ${product.name} with quantity: $quantity');
        
        _isLoading = false;
        notifyListeners();
      } catch (fallbackError) {
        _error = 'Failed to add product: $fallbackError';
        _isLoading = false;
        notifyListeners();
        rethrow;
      }
    }
  }
  
  // Update a product and its inventory
  Future<void> updateProduct(int id, Product product, int quantity, int reorderLevel) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // TODO: Replace with API calls
      // await _apiService.updateProduct(id, product);
      // await _apiService.updateInventory(id, quantity, reorderLevel: reorderLevel);
      
      // Temporary implementation
      print('TODO: Update product via API: ${product.name}');
      
      // Refresh data
      await fetchProducts();
      await fetchInventory();
    } catch (e) {
      _error = 'Failed to update product: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Delete a product
  Future<void> deleteProduct(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // TODO: Replace with API call
      // await _apiService.deleteProduct(id);
      
      // Temporary implementation
      print('TODO: Delete product via API: $id');
      
      // Update local state temporarily
      _products.removeWhere((p) => p.id == id);
      _inventoryItems.removeWhere((item) => item.productId == id);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete product: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update inventory item quantity
  Future<void> updateStock(int productId, int newQuantity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // TODO: Replace with API call
      // await _apiService.updateInventory(productId, newQuantity);
      
      // Temporary implementation
      print('TODO: Update stock via API: Product $productId, Quantity $newQuantity');
      
      // Update local state temporarily
      final index = _inventoryItems.indexWhere((item) => item.productId == productId);
      if (index >= 0) {
        // TODO: Fix this when we have proper copyWith method
        // _inventoryItems[index] = _inventoryItems[index].copyWith(quantity: newQuantity);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update stock: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}