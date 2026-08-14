import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/models.dart';

class ApiService {
  // TODO: remplace par ton vrai domaine et ta vraie clé API
  static const String _baseUrl = 'https://www.demos.twenty.tn/api';
  static const String _apiKey = '6ELKQAUU8TB6FXJW3DSJTT5F42E5UW1S';

  static String get _authHeader =>
      'Basic ${base64Encode(utf8.encode('$_apiKey:'))}';

  static Map<String, String> get _headers => {
        'Authorization': _authHeader,
        'Accept': 'application/json',
      };

  // --- Config boutique nécessaire pour créer une commande ---
  // Valeurs confirmées via /api/languages, /api/countries, /api/currencies,
  // /api/carriers, /api/order_states et le back-office (Modules > Paiement) :
  // - id_lang       : 2 = Français
  // - id_country    : 208 = Tunisia, seul pays actif (active=1) sur cette boutique
  // - id_currency   : 2 = TND (Dinar tunisien), seule devise active
  // - id_carrier    : 39 = "Livraison à domicile / Home delivery", actif et non
  //                   supprimé (la plupart des autres carriers ont deleted=1)
  // - paymentModule : 'ps_checkpayment' = module "Chèque", seul module de
  //                   paiement actif dans Modules > Paiement du back-office
  // - idOrderStatePending : 1 = "En attente du paiement par chèque"
  //                   (order_states, module_name=ps_checkpayment -> confirmé)
  static const int _idLang = 2;
  static const int _idCountry = 208; // Tunisia
  static const int _idCurrency = 2; // TND
  static const int _idCarrier = 39; // Livraison à domicile
  static const String _paymentModule = 'ps_checkpayment'; // Chèque
  static const String _paymentLabel = 'Paiement par chèque';
  static const int _idOrderStatePending =
      1; // "Awaiting check payment" (module_name=ps_checkpayment)

  /// En-têtes pour une écriture (POST/PUT) : PrestaShop attend un corps XML,
  /// peu importe le output_format utilisé pour les lectures.
  static Map<String, String> get _writeHeaders => {
        'Authorization': _authHeader,
        'Content-Type': 'text/xml',
      };

  /// Extrait le contenu d'une balise <id> depuis la réponse XML renvoyée
  /// par PrestaShop après un POST réussi (ex: <address><id>12</id>...).
  /// On prend le PREMIER <id> du document, qui correspond à la ressource
  /// qu'on vient de créer.
  static int _extractCreatedId(String xmlBody) {
    final doc = xml.XmlDocument.parse(xmlBody);
    final idNode = doc.findAllElements('id').first;
    return int.parse(idNode.innerText.trim());
  }

  static const String _productListFields =
      'id,name,price,manufacturer_name,id_category_default,active';

  static Future<List<Product>> getProducts({
    int offset = 0,
    int count = 20,
    int? categoryId,
    String? search,
  }) async {
    final buffer = StringBuffer(
      '$_baseUrl/products?output_format=JSON'
      '&display=[$_productListFields]'
      '&filter[active]=1&limit=$offset,$count',
    );
    if (categoryId != null) {
      buffer.write('&filter[id_category_default]=$categoryId');
    }
    // Recherche par nom : PrestaShop utilise la syntaxe filter[name]=%terme%
    // (équivalent SQL LIKE '%terme%'). Le "%" doit être encodé dans l'URL,
    // d'où Uri.encodeQueryComponent plutôt qu'une simple concaténation.
    if (search != null && search.trim().isNotEmpty) {
      final likeValue = '%${search.trim()}%';
      buffer.write('&filter[name]=${Uri.encodeQueryComponent(likeValue)}');
    }
    final uri = Uri.parse(buffer.toString());
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // PrestaShop renvoie parfois littéralement [] (une Liste) au lieu de
      // {"products": []} quand AUCUN produit ne correspond au filtre
      // (ex: une recherche sans résultat). Sans ce test, `decoded['products']`
      // plante avec "type 'String' is not a subtype of type 'int' of 'index'"
      // car on essaierait d'indexer une Liste avec un texte.
      if (decoded is List) {
        return [];
      }

      final rawProducts = decoded['products'];
      final List<dynamic> rawList;
      if (rawProducts == null) {
        rawList = [];
      } else if (rawProducts is List) {
        rawList = rawProducts;
      } else if (rawProducts is Map) {
        rawList = [rawProducts];
      } else {
        // Cas rare : PrestaShop renvoie parfois "" ou "0" quand rien ne
        // correspond au filtre.
        rawList = [];
      }

      final products = <Product>[];
      for (final item in rawList) {
        try {
          products.add(Product.fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // Un produit avec un JSON inattendu/incomplet ne doit pas
          // faire planter toute la liste : on le saute simplement.
          continue;
        }
      }

      // On va chercher l'image de chaque produit à part, en parallèle.
      // Chaque échec (produit sans image, notice PHP, timeout réseau...)

      await Future.wait(
        products.map((product) async {
          final url = await _fetchProductImageUrl(product.id);
          if (url != null) product.imageUrl = url;
        }),
      );

      return products;
    } else if (response.statusCode == 401) {
      throw ApiException(
        'Authentification refusée (401). Vérifie la clé API et la '
        'configuration serveur (transmission du header Authorization).',
      );
    } else {
      throw ApiException(
        'Erreur ${response.statusCode} lors de la récupération des produits.',
      );
    }
  }

  /// Récupère l'URL de l'image de couverture d'UN produit précis
  static Future<String?> _fetchProductImageUrl(int productId) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/products/$productId'
        '?output_format=JSON&display=[id_default_image]',
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        // DEBUG TEMPORAIRE : à retirer une fois le problème identifié.
        debugPrint(
          'IMAGE FETCH FAIL produit $productId -> HTTP ${response.statusCode} : ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body);
      final idImage = data['product']?['id_default_image'];
      if (idImage == null || idImage == false || idImage.toString() == '0') {
        debugPrint(
            'IMAGE FETCH produit $productId -> pas d\'id_default_image (valeur: $idImage)');
        return null;
      }
      final url = buildProductImageUrl(idImage);
      debugPrint('IMAGE FETCH produit $productId -> OK : $url');
      return url.isEmpty ? null : url;
    } catch (e) {
      // DEBUG TEMPORAIRE : à retirer une fois le problème identifié.
      debugPrint('IMAGE FETCH EXCEPTION produit $productId -> $e');
      return null;
    }
  }

  /// Récupère la liste des catégories actives.

  static Future<List<Category>> getCategories() async {
    final uri = Uri.parse(
      '$_baseUrl/categories?output_format=JSON&display=full&filter[active]=1',
    );
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // Même souci que pour getProducts : PrestaShop peut renvoyer [] tout
      // seul quand il n'y a aucune catégorie active.
      if (decoded is List) {
        return [];
      }

      final rawCategories = decoded['categories'];
      final List<dynamic> rawList;
      if (rawCategories == null) {
        rawList = [];
      } else if (rawCategories is List) {
        rawList = rawCategories;
      } else if (rawCategories is Map) {
        rawList = [rawCategories];
      } else {
        rawList = [];
      }
      final categories = <Category>[];
      for (var i = 0; i < rawList.length; i++) {
        try {
          categories.add(
            Category.fromJson(rawList[i] as Map<String, dynamic>, index: i),
          );
        } catch (_) {
          // Même logique que pour les produits : une catégorie mal
          // formée ne doit pas faire planter toute la liste.
          continue;
        }
      }
      // Exclusion des catégories techniques PrestaShop (Racine = id 1,

      categories.removeWhere((c) => c.id == 1 || c.id == 2);
      return categories;
    } else if (response.statusCode == 401) {
      throw ApiException('Authentification refusée (401).');
    } else {
      throw ApiException(
        'Erreur ${response.statusCode} lors de la récupération des catégories.',
      );
    }
  }

  /// Récupère un produit précis par son id (utile pour une page détail produit).

  static Future<Product> getProduct(int id) async {
    final fullUri = Uri.parse(
      '$_baseUrl/products/$id?output_format=JSON&display=full',
    );
    final fullResponse = await http.get(fullUri, headers: _headers);

    if (fullResponse.statusCode == 200) {
      final data = jsonDecode(fullResponse.body);
      return Product.fromJson(data['product']);
    }

    // Repli : on redemande sans le champ qui fait planter le serveur.
    final safeUri = Uri.parse(
      '$_baseUrl/products/$id?output_format=JSON&display=[$_productListFields]',
    );
    final safeResponse = await http.get(safeUri, headers: _headers);

    if (safeResponse.statusCode == 200) {
      final data = jsonDecode(safeResponse.body);
      final product = Product.fromJson(data['product']);
      final imageUrl = await _fetchProductImageUrl(id);
      if (imageUrl != null) product.imageUrl = imageUrl;
      return product;
    }

    throw ApiException(
      'Erreur ${fullResponse.statusCode} pour le produit $id.',
    );
  }

  // ================================================================
  // FLUX DE COMMANDE (checkout) — 4 étapes obligatoires côté
  // Webservice PrestaShop, dans cet ordre précis :
  //   1. createGuestCustomer  -> renvoie id_customer
  //   2. createAddress        -> renvoie id_address
  //   3. createCart           -> renvoie id_cart
  //   4. createOrder          -> renvoie id_order
  // Chaque étape a besoin du résultat de la précédente.
  // ================================================================

  /// Étape 1 : crée un client "invité" (pas de vrai compte/mot de passe
  /// géré par l'utilisateur). Nécessaire car une commande PrestaShop est
  /// toujours rattachée à un id_customer, même en achat invité.
  static Future<int> createGuestCustomer({
    required String firstname,
    required String lastname,
    required String phone,
  }) async {
    // Email unique obligatoire côté PrestaShop : on en génère un à partir
    // du timestamp puisqu'on n'a pas de vraie authentification pour l'instant.
    final generatedEmail =
        'guest_${DateTime.now().millisecondsSinceEpoch}@twenty.tn';
    final generatedPasswd = 'g${DateTime.now().millisecondsSinceEpoch}';

    final bodyXml = '''<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <customer>
    <firstname>$firstname</firstname>
    <lastname>$lastname</lastname>
    <email>$generatedEmail</email>
    <passwd>$generatedPasswd</passwd>
    <id_default_group>3</id_default_group>
    <id_lang>$_idLang</id_lang>
    <active>1</active>
  </customer>
</prestashop>''';

    final response = await http.post(
      Uri.parse('$_baseUrl/customers'),
      headers: _writeHeaders,
      body: bodyXml,
    );

    if (response.statusCode == 201) {
      return _extractCreatedId(response.body);
    }
    throw ApiException(
      'Erreur ${response.statusCode} lors de la création du client invité.\n'
      '${response.body}',
    );
  }

  /// Étape 2 : crée l'adresse de livraison, rattachée au client créé
  /// juste avant. Sert à la fois d'adresse de livraison ET de facturation.
  static Future<int> createAddress({
    required int idCustomer,
    required String firstname,
    required String lastname,
    required String address1,
    required String city,
    required String phone,
  }) async {
    final bodyXml = '''<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <address>
    <id_customer>$idCustomer</id_customer>
    <alias>Livraison</alias>
    <firstname>$firstname</firstname>
    <lastname>$lastname</lastname>
    <address1>$address1</address1>
    <city>$city</city>
    <id_country>$_idCountry</id_country>
    <phone>$phone</phone>
  </address>
</prestashop>''';

    final response = await http.post(
      Uri.parse('$_baseUrl/addresses'),
      headers: _writeHeaders,
      body: bodyXml,
    );

    if (response.statusCode == 201) {
      return _extractCreatedId(response.body);
    }
    throw ApiException(
      'Erreur ${response.statusCode} lors de la création de l\'adresse.\n'
      '${response.body}',
    );
  }

  /// Étape 3 : crée le panier "officiel" côté serveur PrestaShop à partir
  /// du panier local (CartProvider). C'est ce panier serveur, pas le
  /// panier local, que la commande va référencer.
  static Future<int> createCart({
    required int idCustomer,
    required int idAddress,
    required List<CartItem> items,
  }) async {
    final rowsXml = items.map((item) => '''
      <cart_row>
        <id_product>${item.product.id}</id_product>
        <id_product_attribute>0</id_product_attribute>
        <id_address_delivery>$idAddress</id_address_delivery>
        <quantity>${item.quantity}</quantity>
      </cart_row>''').join();

    final bodyXml = '''<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <cart>
    <id_currency>$_idCurrency</id_currency>
    <id_lang>$_idLang</id_lang>
    <id_address_delivery>$idAddress</id_address_delivery>
    <id_address_invoice>$idAddress</id_address_invoice>
    <id_customer>$idCustomer</id_customer>
    <associations>
      <cart_rows>$rowsXml
      </cart_rows>
    </associations>
  </cart>
</prestashop>''';

    final response = await http.post(
      Uri.parse('$_baseUrl/carts'),
      headers: _writeHeaders,
      body: bodyXml,
    );

    if (response.statusCode == 201) {
      return _extractCreatedId(response.body);
    }
    throw ApiException(
      'Erreur ${response.statusCode} lors de la création du panier serveur.\n'
      '${response.body}',
    );
  }

  /// Étape 4 : crée la commande finale, en reliant client + adresse +
  /// panier serveur + totaux. C'est l'étape la plus stricte de PrestaShop :
  /// tous les champs ci-dessous sont généralement obligatoires.
  static Future<int> createOrder({
    required int idCustomer,
    required int idAddress,
    required int idCart,
    required double totalProducts,
    required double totalShipping,
    required double totalPaid,
  }) async {
    final bodyXml = '''<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <order>
    <id_address_delivery>$idAddress</id_address_delivery>
    <id_address_invoice>$idAddress</id_address_invoice>
    <id_cart>$idCart</id_cart>
    <id_currency>$_idCurrency</id_currency>
    <id_lang>$_idLang</id_lang>
    <id_customer>$idCustomer</id_customer>
    <id_carrier>$_idCarrier</id_carrier>
    <current_state>$_idOrderStatePending</current_state>
    <module>$_paymentModule</module>
    <payment>$_paymentLabel</payment>
    <total_paid>$totalPaid</total_paid>
    <total_paid_tax_incl>$totalPaid</total_paid_tax_incl>
    <total_paid_tax_excl>$totalPaid</total_paid_tax_excl>
    <total_paid_real>0</total_paid_real>
    <total_products>$totalProducts</total_products>
    <total_products_wt>$totalProducts</total_products_wt>
    <total_shipping>$totalShipping</total_shipping>
    <total_shipping_tax_incl>$totalShipping</total_shipping_tax_incl>
    <total_shipping_tax_excl>$totalShipping</total_shipping_tax_excl>
    <conversion_rate>1</conversion_rate>
    <valid>0</valid>
  </order>
</prestashop>''';

    final response = await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: _writeHeaders,
      body: bodyXml,
    );

    if (response.statusCode == 201) {
      return _extractCreatedId(response.body);
    }
    throw ApiException(
      'Erreur ${response.statusCode} lors de la création de la commande.\n'
      '${response.body}',
    );
  }

  /// Crée un vrai compte client (par opposition à createGuestCustomer) :
  /// l'utilisateur choisit lui-même son email et son mot de passe, et le
  /// compte n'est pas marqué invité — il pourra se reconnecter plus tard
  /// (une fois que le login sera branché sur authenticate.php).
  static Future<int> createCustomerAccount({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
  }) async {
    final bodyXml = '''<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <customer>
    <firstname>$firstname</firstname>
    <lastname>$lastname</lastname>
    <email>$email</email>
    <passwd>$password</passwd>
    <id_default_group>3</id_default_group>
    <id_lang>$_idLang</id_lang>
    <active>1</active>
  </customer>
</prestashop>''';

    final response = await http.post(
      Uri.parse('$_baseUrl/customers'),
      headers: _writeHeaders,
      body: bodyXml,
    );

    if (response.statusCode == 201) {
      return _extractCreatedId(response.body);
    }

    // PrestaShop renvoie un 400/500 avec un message explicite si l'email
    // existe déjà (contrainte unique en base) : on essaie de le détecter
    // pour afficher un message clair plutôt que "Erreur 400".
    if (response.body.toLowerCase().contains('email') &&
        (response.body.toLowerCase().contains('already') ||
            response.body.toLowerCase().contains('existe'))) {
      throw ApiException('Un compte existe déjà avec cet email.');
    }

    throw ApiException(
      'Erreur ${response.statusCode} lors de la création du compte.\n'
      '${response.body}',
    );
  }

  /// Connexion via le script custom authenticate.php de Ramzi (le
  /// Webservice PrestaShop standard n'a pas d'endpoint login).
  ///
  /// TODO(à confirmer avec Ramzi une fois le script déployé) :
  /// - URL exacte du script (ici on suppose $_baseUrl/authenticate.php,
  ///   mais ça peut être un autre chemin, ex: à la racine du domaine)
  /// - Méthode HTTP (POST supposé) et noms des champs envoyés
  ///   (ici 'email' / 'password')
  /// - Format de la réponse en cas de succès (ici JSON avec id_customer,
  ///   firstname, lastname, email — voir Customer.fromAuthJson) et en cas
  ///   d'échec (ici on suppose un code HTTP 401/403 + message)
  static Future<Customer> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/authenticate.php');
    final response = await http.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return Customer.fromAuthJson(decoded);
      }
      throw ApiException('Réponse inattendue du serveur lors de la connexion.');
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw ApiException('Email ou mot de passe incorrect.');
    } else {
      throw ApiException(
        'Erreur ${response.statusCode} lors de la connexion.\n${response.body}',
      );
    }
  }

  /// fonction que checkout_screen.dart appelle depuis _placeOrder.
  static Future<int> submitOrder({
    required String firstname,
    required String lastname,
    required String phone,
    required String address1,
    required String city,
    required List<CartItem> items,
    required double totalProducts,
    required double totalShipping,
    required double totalPaid,
  }) async {
    final idCustomer = await createGuestCustomer(
      firstname: firstname,
      lastname: lastname,
      phone: phone,
    );

    final idAddress = await createAddress(
      idCustomer: idCustomer,
      firstname: firstname,
      lastname: lastname,
      address1: address1,
      city: city,
      phone: phone,
    );

    final idCart = await createCart(
      idCustomer: idCustomer,
      idAddress: idAddress,
      items: items,
    );

    final idOrder = await createOrder(
      idCustomer: idCustomer,
      idAddress: idAddress,
      idCart: idCart,
      totalProducts: totalProducts,
      totalShipping: totalShipping,
      totalPaid: totalPaid,
    );

    return idOrder;
  }
}

/// Exception dédiée pour distinguer une erreur API d'une erreur Dart classique,
/// et pouvoir afficher un message clair dans l'UI (ex: SnackBar).
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
