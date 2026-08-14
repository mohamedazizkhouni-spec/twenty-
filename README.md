# Twenty.tn - Application Mobile Flutter

Application mobile pour le marketplace tunisien [twenty.tn](https://twenty.tn), développée avec Flutter.

## 📱 Pages incluses

| Page | Description |
|------|-------------|
| 🏠 **Accueil** | Bannières promo, catégories, produits en grille |
| 📦 **Catégories** | Navigation sidebar + filtres |
| 🛒 **Panier** | Gestion quantités, résumé commande |
| 👤 **Profil** | Connexion / Inscription / Compte |

## 🎨 Design

- **Couleurs** : Rouge Twenty (#E63946), Bleu foncé (#1D3557), Jaune promo (#FFB703)
- **Typo** : Google Fonts - Poppins
- **Style** : Material Design 3, coins arrondis, ombres douces

## 🚀 Installation

### Prérequis
- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Android Studio ou VS Code

### Étapes

```bash
# 1. Cloner / dézipper le projet
cd twenty_app

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'application
flutter run
```

## 📁 Structure du projet

```
lib/
├── main.dart                    # Point d'entrée + Navigation
├── theme/
│   └── app_theme.dart           # Couleurs & thème Twenty
├── models/
│   ├── models.dart              # Modèles: Product, Category, CartItem
│   ├── mock_data.dart           # Données de démonstration
│   └── cart_provider.dart       # State management panier
├── screens/
│   ├── home_screen.dart         # Page Accueil
│   ├── categories_screen.dart   # Page Catégories
│   ├── cart_screen.dart         # Page Panier
│   └── profile_screen.dart      # Page Profil / Connexion
└── widgets/
    └── product_card.dart        # Carte produit réutilisable
```

## 📦 Dépendances

```yaml
cached_network_image: ^3.3.1     # Chargement images réseau
carousel_slider: ^4.2.1          # Slider bannières
smooth_page_indicator: ^1.1.0    # Indicateur dots
google_fonts: ^6.1.0             # Poppins font
provider: ^6.0.0                 # State management
badges: ^3.1.2                   # Badge panier
```

## 🔌 Prochaines étapes (backend)

1. **Connecter l'API Twenty.tn** via `http` ou `dio`
2. **Authentification** avec JWT tokens
3. **Paiement** intégration Konnect / Flouci
4. **Push notifications** avec Firebase
5. **Géolocalisation** pour la livraison

## 📸 Fonctionnalités

- ✅ Navigation avec BottomNavigationBar animée
- ✅ Carrousel de bannières auto-scroll
- ✅ Filtre par catégorie en temps réel
- ✅ Panier avec gestion quantités
- ✅ Livraison gratuite > 100 TND
- ✅ Formulaire Connexion / Inscription
- ✅ Wishlist (favoris)
- ✅ Badges promotionnels (-X%)
- ✅ Support multilingue (FR/AR/EN ready)
