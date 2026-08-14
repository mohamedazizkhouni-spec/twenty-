import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../models/cart_provider.dart';
import '../models/favorites_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Écran de détail d'un produit : image, prix, description complète,
/// mode de livraison (un seul mode standard pour l'instant), et bouton
/// d'ajout au panier.
///
/// On reçoit le `Product` déjà chargé depuis la grille (pour afficher tout
/// de suite l'essentiel : nom, prix, image), puis on recharge le produit
/// en entier via ApiService.getProduct() pour récupérer la description
/// complète, absente de la liste (display=full n'est demandé qu'ici, pas
/// dans getProducts, pour ne pas ralentir le chargement de la grille).
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadFullDetails();
  }

  Future<void> _loadFullDetails() async {
    try {
      final full = await ApiService.getProduct(_product.id);
      if (!mounted) return;
      setState(() {
        _product = full;
        _isLoadingDetails = false;
      });
    } catch (_) {
      // Si le rechargement complet échoue, on garde les infos qu'on avait
      // déjà (nom/prix/image) et on masque juste la section description.
      if (!mounted) return;
      setState(() => _isLoadingDetails = false);
    }
  }

  /// Le champ description contient parfois du HTML basique (<p>...</p>)
  /// venant de PrestaShop. On le nettoie pour un affichage texte simple.
  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final description = _stripHtml(_product.description);
    final favorites = context.watch<FavoritesProvider>();
    final isFavorite = favorites.isFavorite(_product);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppTheme.primaryColor : AppTheme.textPrimary,
                ),
                onPressed: () => context
                    .read<FavoritesProvider>()
                    .toggleFavorite(_product),
              ),
            ],
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: _product.imageUrl.isEmpty
                  ? Container(
                      color: AppTheme.borderColor,
                      child: const Icon(Icons.image_not_supported_outlined,
                          size: 48, color: Colors.grey),
                    )
                  : CachedNetworkImage(
                      imageUrl: _product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: AppTheme.borderColor),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.borderColor,
                        child: const Icon(Icons.image_not_supported_outlined,
                            size: 48, color: Colors.grey),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_product.brand.isNotEmpty)
                    Text(
                      _product.brand.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${_product.price.toStringAsFixed(2)} DT',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (_product.hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${_product.oldPrice!.toStringAsFixed(2)} DT',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- Mode de livraison ---
                  const Text(
                    'Mode de livraison',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            color: AppTheme.primaryColor),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Livraison standard',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Seul mode disponible actuellement',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle,
                            color: AppTheme.primaryColor, size: 22),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- Description ---
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingDetails)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Text(
                      description.isEmpty
                          ? 'Aucune description disponible pour ce produit.'
                          : description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                  // Espace pour ne pas être caché par le bouton fixe en bas
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              label: const Text(
                'Ajouter au panier',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              onPressed: () {
                context.read<CartProvider>().addToCart(_product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${_product.name} ajouté au panier'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
