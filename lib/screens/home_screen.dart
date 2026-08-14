import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/mock_data.dart';
import '../models/models.dart';
import '../models/cart_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'product_detail_screen.dart';
import 'promo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bannerIndex = 0;

  static const List<Map<String, String>> _bannerPromos = [
    {'title': 'Promotions', 'emoji': '🔥', 'keyword': 'promo'},
    {'title': 'Nouveautés', 'emoji': '✨', 'keyword': 'nouveau'},
    {'title': 'Made In TN', 'emoji': '🇹🇳', 'keyword': 'tunisie'},
  ];

  void _openPromo({
    required String title,
    required String emoji,
    required String keyword,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PromoScreen(
          title: title,
          emoji: emoji,
          searchKeyword: keyword,
        ),
      ),
    );
  }

  void _showDeliveryInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Text('🚚', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Livraison', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Livraison standard sous 2 à 4 jours ouvrés, partout en '
          'Tunisie.\n\nFrais de livraison : 7.000 TND, calculés '
          'automatiquement au moment du paiement.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  // --- État lié aux appels API (remplace MockData.products/.categories) ---
  List<Product> _apiProducts = [];
  List<Category> _apiCategories = [];
  bool _isLoading = true;
  bool _isLoadingCategories = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await ApiService.getCategories();
      setState(() {
        _apiCategories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      // Si les catégories échouent, on n'affiche juste pas le bandeau ;
      // on ne bloque pas la page pour autant (les produits restent visibles).
      setState(() => _isLoadingCategories = false);
    }
  }

  /// Charge les produits pour la catégorie sélectionnée ET/OU la recherche
  /// en cours. `categoryId == null` correspond à "Tous" (index 0).
  Future<void> _loadProducts({int? categoryId}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // On charge 40 produits pour l'écran d'accueil.
      // (la boutique en a ~8500, donc pas question de tout charger d'un coup)
      final products = await ApiService.getProducts(
        offset: 0,
        count: 40,
        categoryId: categoryId,
        search: _searchQuery,
      );
      setState(() {
        _apiProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  int? get _currentCategoryId => _selectedCategoryIndex == 0
      ? null
      : _apiCategories[_selectedCategoryIndex - 1].id;

  /// Appelé à chaque frappe dans la barre de recherche. On attend 400ms
  /// sans nouvelle frappe avant de relancer l'appel API, pour éviter
  /// d'envoyer une requête à chaque lettre tapée.
  void _onSearchChanged(String value) {
    setState(() {}); // pour rafraîchir l'icône "effacer" tout de suite
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = value);
      _loadProducts(categoryId: _currentCategoryId);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onCategoryTap(int index) {
    setState(() => _selectedCategoryIndex = index);
    if (index == 0) {
      _loadProducts();
    } else {
      _loadProducts(categoryId: _apiCategories[index - 1].id);
    }
  }

  List<Product> get filteredProducts => _apiProducts;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: Colors.white,
            elevation: 1,
            shadowColor: Colors.black12,
            titleSpacing: 16,
            title: Row(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'twenty',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '.tn',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit...',
                    hintStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? const Icon(
                            Icons.tune,
                            color: AppTheme.textSecondary,
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                    filled: true,
                    fillColor: AppTheme.bgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Carousel
                const SizedBox(height: 12),
                CarouselSlider.builder(
                  itemCount: MockData.banners.length,
                  itemBuilder: (context, index, realIndex) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: MockData.banners[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: AppTheme.borderColor),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    AppTheme.primaryColor
                                        .withValues(alpha: 0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 20,
                              top: 0,
                              bottom: 0,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    index == 0
                                        ? 'Jusqu\'à -40%'
                                        : index == 1
                                            ? 'Nouveautés'
                                            : 'Made In TN',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    index == 0
                                        ? 'Sur tout le site!'
                                        : index == 1
                                            ? 'Découvrez-les'
                                            : 'Produits locaux',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () {
                                      final promo = _bannerPromos[
                                          index % _bannerPromos.length];
                                      _openPromo(
                                        title: promo['title']!,
                                        emoji: promo['emoji']!,
                                        keyword: promo['keyword']!,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Voir plus',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 170,
                    viewportFraction: 0.92,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    enlargeCenterPage: true,
                    onPageChanged: (index, _) =>
                        setState(() => _bannerIndex = index),
                  ),
                ),
                const SizedBox(height: 10),
                // Dots indicator
                Center(
                  child: AnimatedSmoothIndicator(
                    activeIndex: _bannerIndex,
                    count: MockData.banners.length,
                    effect: const ExpandingDotsEffect(
                      dotHeight: 6,
                      dotWidth: 6,
                      activeDotColor: AppTheme.primaryColor,
                      dotColor: AppTheme.borderColor,
                    ),
                  ),
                ),

                // Quick actions
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _QuickAction(
                        icon: '🔥',
                        label: 'Flash Sale',
                        color: AppTheme.primaryColor,
                        onTap: () => _openPromo(
                          title: 'Flash Sale',
                          emoji: '🔥',
                          keyword: 'promo',
                        ),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: '🇹🇳',
                        label: 'Made In TN',
                        color: AppTheme.secondaryColor,
                        onTap: () => _openPromo(
                          title: 'Made In TN',
                          emoji: '🇹🇳',
                          keyword: 'tunisie',
                        ),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: '🎁',
                        label: '20 Cadeaux',
                        color: AppTheme.accentColor,
                        onTap: () => _openPromo(
                          title: '20 Cadeaux',
                          emoji: '🎁',
                          keyword: 'cadeau',
                        ),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: '🚚',
                        label: 'Livraison',
                        color: AppTheme.successColor,
                        onTap: _showDeliveryInfo,
                      ),
                    ],
                  ),
                ),

                // Categories horizontal
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Catégories',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoriesScreen(),
                          ),
                        ),
                        child: const Text(
                          'Voir tout',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoadingCategories)
                  const SizedBox(
                    height: 90,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _apiCategories.length,
                      itemBuilder: (context, index) {
                        final cat = _apiCategories[index];
                        return GestureDetector(
                          onTap: () => _onCategoryTap(index + 1),
                          child: Container(
                            width: 72,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: cat.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: _selectedCategoryIndex == index + 1
                                        ? Border.all(color: cat.color, width: 2)
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      cat.icon,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  cat.name.split(' ').first,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        _selectedCategoryIndex == index + 1
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                    color: _selectedCategoryIndex == index + 1
                                        ? cat.color
                                        : AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Products section header
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Résultats pour "$_searchQuery"'
                            : (_selectedCategoryIndex == 0
                                ? 'Meilleurs produits'
                                : _apiCategories[_selectedCategoryIndex - 1]
                                    .name),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'Voir tout',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Products Grid
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Impossible de charger les produits.\n$_errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadProducts,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredProducts.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: Text('Aucun produit trouvé.')),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.56,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final products = filteredProducts;
                  if (index >= products.length) return null;
                  return ProductCard(
                    product: products[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailScreen(product: products[index]),
                      ),
                    ),
                  );
                }, childCount: filteredProducts.length),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
