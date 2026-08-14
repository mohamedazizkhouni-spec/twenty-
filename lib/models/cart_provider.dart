import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Panier "local" : tout vit en mémoire dans cette classe, rien n'est
/// envoyé à l'API PrestaShop tant que l'utilisateur n'a pas validé sa
/// commande à l'écran de checkout. La seule chose ajoutée ici est la
/// persistance sur le téléphone (shared_preferences), pour que le panier
/// survive à la fermeture de l'app.
class CartProvider extends ChangeNotifier {
  static const String _prefsKey = 'cart_items_v1';

  final List<CartItem> _items = [];
  bool _isLoaded = false;

  List<CartItem> get items => _items;

  /// Utile côté UI pour éviter d'afficher le panier avant que la lecture
  /// du disque (asynchrone) soit terminée.
  bool get isLoaded => _isLoaded;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.total);

  double get deliveryFee {
    if (subtotal >= 100) return 0;
    return 7.000;
  }

  double get total => subtotal + deliveryFee;

  bool isInCart(Product product) => _items.any((item) => item.product.id == product.id);

  CartProvider() {
    _loadFromDisk();
  }

  /// Lit le panier sauvegardé au démarrage de l'app. Appelé une seule
  /// fois depuis le constructeur.
  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        _items
          ..clear()
          ..addAll(
            decoded.map(
              (e) => CartItem.fromCacheJson(Map<String, dynamic>.from(e as Map)),
            ),
          );
      }
    } catch (e) {
      // Panier corrompu ou format changé entre deux versions de l'app :
      // on repart d'un panier vide plutôt que de planter l'app au démarrage.
      debugPrint('CartProvider: échec lecture panier local ($e)');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Réécrit tout le panier sur le disque. Appelé après chaque
  /// modification (add/remove/decrease/clear) — un panier reste petit
  /// (quelques dizaines d'articles max), donc réécrire l'ensemble à
  /// chaque fois est largement assez rapide pour ne pas justifier un
  /// diff incrémental.
  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_items.map((e) => e.toCacheJson()).toList());
      await prefs.setString(_prefsKey, raw);
    } catch (e) {
      debugPrint('CartProvider: échec sauvegarde panier local ($e)');
    }
  }

  void addToCart(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
    _saveToDisk();
  }

  void removeFromCart(Product product) {
    _items.removeWhere((item) => item.product.id == product.id);
    notifyListeners();
    _saveToDisk();
  }

  void decreaseQuantity(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
      _saveToDisk();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    _saveToDisk();
  }
}
