import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedIndex = 0;

  List<Category> _categories = [];
  List<Product> _products = [];
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _errorMessage = null;
    });
    try {
      final categories = await ApiService.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
      if (categories.isNotEmpty) {
        _loadProductsForSelected();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadProductsForSelected() async {
    if (_categories.isEmpty) return;
    setState(() => _isLoadingProducts = true);
    try {
      final products = await ApiService.getProducts(
        offset: 0,
        count: 40,
        categoryId: _categories[_selectedIndex].id,
      );
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingProducts = false;
      });
    }
  }

  void _onSelectCategory(int index) {
    setState(() => _selectedIndex = index);
    _loadProductsForSelected();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text(
          'Catégories',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _categories.isEmpty
              ? _ErrorState(message: _errorMessage!, onRetry: _loadCategories)
              : _categories.isEmpty
                  ? const Center(child: Text('Aucune catégorie trouvée.'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final selectedCategory = _categories[_selectedIndex];

    return Row(
      children: [
        // Sidebar categories
        Container(
          width: 90,
          color: Colors.white,
          child: ListView.builder(
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                onTap: () => _onSelectCategory(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color.withValues(alpha: 0.08)
                        : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: isSelected ? cat.color : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.color.withValues(alpha: 0.15)
                              : AppTheme.bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cat.icon,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cat.name.split(' ').first,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                          color:
                              isSelected ? cat.color : AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Container(width: 1, color: AppTheme.borderColor),

        // Products area
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            selectedCategory.icon,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedCategory.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  _isLoadingProducts
                                      ? 'Chargement...'
                                      : '${_products.length} produits',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Filter chips
                      const SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip('Tout', true),
                            SizedBox(width: 8),
                            _FilterChip('Nouveautés', false),
                            SizedBox(width: 8),
                            _FilterChip('Promotions', false),
                            SizedBox(width: 8),
                            _FilterChip('Livraison gratuite', false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoadingProducts)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_products.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          selectedCategory.icon,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucun produit dans cette catégorie.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.56,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = _products[index];
                      return ProductCard(
                        product: product,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: product),
                          ),
                        ),
                      );
                    }, childCount: _products.length),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              'Impossible de charger les catégories.\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _FilterChip(this.label, this.isSelected);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
