import 'package:flutter/material.dart';

/// Domaine de ta boutique Twenty.tn. Utilisé pour reconstruire les URLs
/// d'images produits (PrestaShop ne renvoie que l'ID de l'image, pas
/// l'URL complète).
const String kShopBaseUrl = 'https://www.demos.twenty.tn';

/// PrestaShop stocke les champs traduisibles (name, description, ...)
/// sous forme de liste `[{"id": "1", "value": "..."}, {"id": "2", ...}]`
/// où chaque "id" correspond à une langue de la boutique (souvent
/// 1 = anglais, 2 = français, 3 = arabe, mais ça peut varier selon la
/// config du Back Office). On essaie la langue préférée en premier,
/// puis on retombe sur la première valeur non vide trouvée.
String _localized(dynamic field, {String preferredLangId = '2'}) {
  if (field == null) return '';
  if (field is String) return field;

  if (field is List) {
    Map<String, dynamic>? preferred;
    Map<String, dynamic>? firstNonEmpty;
    for (final entry in field) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final value = (map['value'] ?? '').toString();
      if (map['id']?.toString() == preferredLangId && value.isNotEmpty) {
        preferred = map;
      }
      if (firstNonEmpty == null && value.isNotEmpty) {
        firstNonEmpty = map;
      }
    }
    final chosen = preferred ?? firstNonEmpty;
    return (chosen?['value'] ?? '').toString();
  }
  return field.toString();
}

/// Construit l'URL publique d'une image produit à partir de son ID.
/// PrestaShop range les images sur le serveur en éclatant l'ID chiffre
/// par chiffre : l'image 975 est servie depuis /img/p/9/7/5/975-home_default.jpg
/// (le suffixe -home_default correspond à la déclinaison "vignette" générée
/// par PrestaShop ; le fichier brut 975.jpg tout seul n'existe pas sur le
/// serveur, d'où le 404 avant ce fix).
///
/// Public (pas juste privé à ce fichier) car ApiService en a aussi besoin
/// pour reconstruire l'URL quand il récupère l'image d'un produit à part
/// (voir ApiService._fetchProductImageUrl).
String buildProductImageUrl(dynamic imageId) {
  final id = _toInt(imageId);
  if (id <= 0) return '';
  final path = id.toString().split('').join('/');
  return '$kShopBaseUrl/img/p/$path/$id-home_default.jpg';
}

class Product {
  final int id;
  final String name;
  final String brand;
  final double price;
  final double? oldPrice;
  // Pas `final` : ApiService complète cette valeur après coup, une fois
  // l'image récupérée séparément (voir ApiService.getProducts), pour ne
  // jamais faire dépendre le chargement de la liste de produits de la
  // présence d'une image côté serveur.
  String imageUrl;
  final String category;
  final double rating;
  final int reviewCount;
  final bool isFreeDelivery;
  final bool isNew;
  final int? discountPercent;
  // Rempli seulement par getProduct() (display=full) — vide dans les
  // listes (getProducts) pour ne pas alourdir le chargement de la grille.
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    this.oldPrice,
    required this.imageUrl,
    required this.category,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.isFreeDelivery = false,
    this.isNew = false,
    this.discountPercent,
    this.description = '',
  });

  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  /// Sérialisation "maison" (différente du format PrestaShop) utilisée
  /// uniquement pour sauvegarder le panier en local avec
  /// shared_preferences. Ne pas confondre avec Product.fromJson qui, lui,
  /// parse la réponse de l'API PrestaShop.
  Map<String, dynamic> toCacheJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'price': price,
        'oldPrice': oldPrice,
        'imageUrl': imageUrl,
        'category': category,
        'rating': rating,
        'reviewCount': reviewCount,
        'isFreeDelivery': isFreeDelivery,
        'isNew': isNew,
        'discountPercent': discountPercent,
      };

  factory Product.fromCacheJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        name: json['name'] as String,
        brand: json['brand'] as String,
        price: (json['price'] as num).toDouble(),
        oldPrice: (json['oldPrice'] as num?)?.toDouble(),
        imageUrl: json['imageUrl'] as String,
        category: json['category'] as String,
        rating: (json['rating'] as num).toDouble(),
        reviewCount: json['reviewCount'] as int,
        isFreeDelivery: json['isFreeDelivery'] as bool,
        isNew: json['isNew'] as bool,
        discountPercent: json['discountPercent'] as int?,
      );

  /// Construit un Product à partir du JSON réel renvoyé par l'API
  /// PrestaShop (avec `display=full`). Points particuliers gérés ici :
  /// - `name`, `description`, etc. sont des listes multilingues -> _localized()
  /// - `price` est une String ("49.900000") -> parsée en double
  /// - `manufacturer_name` peut valoir `false` (pas de marque) -> texte vide
  /// - il n'y a pas d'URL d'image directe, seulement `id_default_image`
  /// - il n'y a pas de champ "catégorie" en texte, seulement
  ///   `id_category_default` (l'ID) -> on stocke l'ID en attendant de le
  ///   croiser avec la liste des catégories (`Category`) si besoin.
  factory Product.fromJson(Map<String, dynamic> json) {
    final rawPrice = _toDouble(json['price']);
    return Product(
      id: _toInt(json['id']),
      name: _localized(json['name']),
      brand: json['manufacturer_name'] == false
          ? ''
          : _toText(json['manufacturer_name']),
      price: rawPrice,
      oldPrice: null,
      // Peut être vide ici si on n'a volontairement pas demandé ce champ
      // à l'API (voir ApiService._safeFields) pour éviter le crash 500
      // sur les produits sans image. ApiService la remplit ensuite à
      // part, produit par produit, avec gestion d'erreur individuelle.
      imageUrl: json.containsKey('id_default_image')
          ? buildProductImageUrl(json['id_default_image'])
          : '',
      category: _toText(json['id_category_default']),
      rating: 4.5,
      reviewCount: 0,
      isFreeDelivery: false,
      isNew: false,
      discountPercent: null,
      // N'est présent dans le JSON que si on a demandé display=full
      // (voir ApiService.getProduct) ; absent dans les listes -> vide.
      description: json.containsKey('description')
          ? _localized(json['description'])
          : '',
    );
  }
}

// --- Helpers de conversion partagés ---
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

String _toText(dynamic value) {
  if (value == null || value == false) return '';
  return value.toString();
}

/// PrestaShop ne donne ni icône ni couleur pour une catégorie : on fait
/// tourner une petite palette pour que chaque catégorie ait un look
/// distinct dans l'UI (au lieu du même 🏷️ violet pour toutes).
const List<String> _kCategoryIcons = ['🛍️', '👗', '👟', '💄', '📱', '🏠', '⌚', '👜'];
const List<Color> _kCategoryColors = [
  Color(0xFF9C27B0),
  Color(0xFFE91E63),
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFF4CAF50),
  Color(0xFF00BCD4),
  Color(0xFFFF5722),
  Color(0xFF3F51B5),
];

class Category {
  final int id;
  final String name;
  final String icon;
  final Color color;
  final int productCount;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.productCount,
  });

  /// Construit une Category à partir du JSON de l'API PrestaShop.
  /// `name` est aussi multilingue ici (même format que pour Product).
  /// `index` (position dans la liste renvoyée par l'API) sert juste à
  /// piocher une icône/couleur différente dans la palette ci-dessus.
  factory Category.fromJson(Map<String, dynamic> json, {int index = 0}) {
    return Category(
      id: _toInt(json['id']),
      name: _localized(json['name']),
      icon: _kCategoryIcons[index % _kCategoryIcons.length],
      color: _kCategoryColors[index % _kCategoryColors.length],
      productCount: 0,
    );
  }
}

/// Représente le client une fois connecté (résultat de login() ou
/// createCustomerAccount()). Séparé de Product/Category car il vient
/// d'un endpoint différent (authenticate.php, pas le Webservice standard).
class Customer {
  final int id;
  final String firstname;
  final String lastname;
  final String email;

  Customer({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
  });

  String get fullName => '$firstname $lastname'.trim();

  /// Pour la persistance locale de la session (shared_preferences),
  /// même logique que Product.toCacheJson / fromCacheJson.
  Map<String, dynamic> toCacheJson() => {
        'id': id,
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
      };

  factory Customer.fromCacheJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as int,
        firstname: json['firstname'] as String,
        lastname: json['lastname'] as String,
        email: json['email'] as String,
      );

  /// Construit un Customer à partir de la réponse JSON attendue de
  /// authenticate.php. À AJUSTER si Ramzi renvoie des noms de champs
  /// différents (voir TODO dans ApiService.login).
  factory Customer.fromAuthJson(Map<String, dynamic> json) => Customer(
        id: _toInt(json['id_customer'] ?? json['id']),
        firstname: _toText(json['firstname']),
        lastname: _toText(json['lastname']),
        email: _toText(json['email']),
      );
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;

  Map<String, dynamic> toCacheJson() => {
        'product': product.toCacheJson(),
        'quantity': quantity,
      };

  factory CartItem.fromCacheJson(Map<String, dynamic> json) => CartItem(
        product: Product.fromCacheJson(
          Map<String, dynamic>.from(json['product'] as Map),
        ),
        quantity: json['quantity'] as int,
      );
}
