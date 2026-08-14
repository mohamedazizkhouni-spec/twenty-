import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Favoris : même principe que CartProvider — tout vit en mémoire, avec
/// une sauvegarde locale (shared_preferences) pour survivre à la
/// fermeture de l'app. Rien n'est envoyé à l'API PrestaShop (les favoris
/// n'ont pas d'équivalent direct côté Webservice).
class FavoritesProvider extends ChangeNotifier {
  static const String _prefsKey = 'favorites_v1';

  final List<Product> _items = [];
  bool _isLoaded = false;

  List<Product> get items => _items;
  bool get isLoaded => _isLoaded;
  int get count => _items.length;

  bool isFavorite(Product product) =>
      _items.any((p) => p.id == product.id);

  FavoritesProvider() {
    _loadFromDisk();
  }

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
              (e) => Product.fromCacheJson(Map<String, dynamic>.from(e as Map)),
            ),
          );
      }
    } catch (e) {
      debugPrint('FavoritesProvider: échec lecture favoris ($e)');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_items.map((e) => e.toCacheJson()).toList());
      await prefs.setString(_prefsKey, raw);
    } catch (e) {
      debugPrint('FavoritesProvider: échec sauvegarde favoris ($e)');
    }
  }

  /// Ajoute ou retire le produit des favoris selon son état actuel.
  /// C'est cette fonction que le bouton cœur appelle à chaque tap.
  void toggleFavorite(Product product) {
    if (isFavorite(product)) {
      _items.removeWhere((p) => p.id == product.id);
    } else {
      _items.add(product);
    }
    notifyListeners();
    _saveToDisk();
  }
}
