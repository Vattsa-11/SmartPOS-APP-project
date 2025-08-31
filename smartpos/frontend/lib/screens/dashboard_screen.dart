import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _apiService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Widget _buildDashboardItem({
    required IconData icon,
    required String title,
    required Function() onTap,
    Color? color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color ?? Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _barcodeController = TextEditingController();
    final _priceController = TextEditingController();
    final _categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Product name is required';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode',
                    hintText: 'Enter product barcode',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Barcode is required';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Price is required';
                    }
                    try {
                      double.parse(value);
                    } catch (_) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Category is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  final product = Product(
                    name: _nameController.text,
                    barcode: _barcodeController.text,
                    price: double.parse(_priceController.text),
                    category: _categoryController.text,
                  );
                  
                  await _apiService.addProduct(product);
                  Navigator.of(ctx).pop();
                  _loadProducts();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(user != null ? user.shopName : 'Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome message
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                'Welcome, ${user?.username ?? 'User'}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            
            // Dashboard grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDashboardItem(
                      icon: Icons.add_shopping_cart,
                      title: 'Add Product',
                      onTap: _showAddProductDialog,
                      color: Colors.blue,
                    ),
                    _buildDashboardItem(
                      icon: Icons.inventory,
                      title: 'View Inventory',
                      onTap: () {},
                      color: Colors.green,
                    ),
                    _buildDashboardItem(
                      icon: Icons.receipt,
                      title: 'Billing',
                      onTap: () {},
                      color: Colors.orange,
                    ),
                    _buildDashboardItem(
                      icon: Icons.people,
                      title: 'Customers',
                      onTap: () {},
                      color: Colors.purple,
                    ),
                    _buildDashboardItem(
                      icon: Icons.bar_chart,
                      title: 'Reports',
                      onTap: () {},
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            
            // Recent products
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Recent Products',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _products.isEmpty
                          ? const Center(child: Text('No products found'))
                          : ListView.builder(
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                final product = _products[index];
                                return ListTile(
                                  title: Text(product.name),
                                  subtitle: Text(product.category),
                                  trailing: Text(
                                    '\$${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
