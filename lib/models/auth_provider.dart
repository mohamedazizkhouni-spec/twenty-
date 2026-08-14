import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Session utilisateur : suit le même principe que CartProvider (état en
/// mémoire + persistance shared_preferences pour survivre à la fermeture
/// de l'app). Alimenté soit par ApiService.login() (une fois
/// authenticate.php déployé par Ramzi), soit directement après une
/// inscription réussie (ApiService.createCustomerAccount).
class AuthProvider extends ChangeNotifier {
  static const String _prefsKey = 'auth_customer_v1';

  Customer? _customer;
  bool _isLoaded = false;

  Customer? get customer => _customer;
  bool get isLoggedIn => _customer != null;

  /// Utile côté UI pour éviter d'afficher "Connexion" une frame avant que
  /// la lecture du disque (asynchrone) soit terminée, comme pour le panier.
  bool get isLoaded => _isLoaded;

  AuthProvider() {
    _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _customer = Customer.fromCacheJson(decoded);
      }
    } catch (e) {
      // Session corrompue ou format changé entre deux versions de l'app :
      // on repart déconnecté plutôt que de planter l'app au démarrage.
      debugPrint('AuthProvider: échec lecture session locale ($e)');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customer == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, jsonEncode(_customer!.toCacheJson()));
      }
    } catch (e) {
      debugPrint('AuthProvider: échec sauvegarde session locale ($e)');
    }
  }

  /// Appelé après un login OU une inscription réussie.
  void setSession(Customer customer) {
    _customer = customer;
    notifyListeners();
    _saveToDisk();
  }

  void logout() {
    _customer = null;
    notifyListeners();
    _saveToDisk();
  }
}
