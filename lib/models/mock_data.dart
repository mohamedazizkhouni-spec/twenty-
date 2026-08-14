import 'package:flutter/material.dart';
import 'models.dart';

class MockData {
  static List<Product> get products => [
        Product(
          id: 1,
          name: 'Tablette Panda 10"',
          brand: 'BEST TRADING',
          price: 49.680,
          oldPrice: 69.000,
          imageUrl:
              'https://images.unsplash.com/photo-1585790050230-5dd28404ccb9?w=400',
          category: 'Téléphones & Tablettes',
          rating: 4.3,
          reviewCount: 128,
          isFreeDelivery: true,
          isNew: true,
          discountPercent: 28,
        ),
        Product(
          id: 2,
          name: 'Montre Connectée WUW-J07',
          brand: 'WUW Tunisie',
          price: 112.500,
          oldPrice: 150.000,
          imageUrl:
              'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=400',
          category: 'Téléphones & Tablettes',
          rating: 4.7,
          reviewCount: 85,
          isFreeDelivery: true,
          isNew: true,
          discountPercent: 25,
        ),
        Product(
          id: 3,
          name: 'Accessoire Voiture BH-60',
          brand: 'BEST TRADING',
          price: 33.000,
          oldPrice: 55.000,
          imageUrl:
              'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=400',
          category: 'Maison & Bureau',
          rating: 4.1,
          reviewCount: 42,
          isFreeDelivery: false,
          isNew: true,
          discountPercent: 40,
        ),
        Product(
          id: 4,
          name: 'Shampoing ING Tunisie',
          brand: 'Wafa Nat',
          price: 17.445,
          oldPrice: 23.260,
          imageUrl:
              'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400',
          category: 'Santé & Beauté',
          rating: 4.8,
          reviewCount: 210,
          isFreeDelivery: false,
          isNew: true,
          discountPercent: 25,
        ),
        Product(
          id: 5,
          name: 'Ustensile Cuisine Tramontina',
          brand: 'Magic Home',
          price: 18.000,
          oldPrice: 25.000,
          imageUrl:
              'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400',
          category: 'Maison & Bureau',
          rating: 4.5,
          reviewCount: 67,
          isFreeDelivery: false,
          isNew: true,
          discountPercent: 28,
        ),
        Product(
          id: 6,
          name: 'Sérum Visage ING',
          brand: 'Wafa Nat',
          price: 38.250,
          oldPrice: 42.500,
          imageUrl:
              'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400',
          category: 'Santé & Beauté',
          rating: 4.6,
          reviewCount: 95,
          isFreeDelivery: false,
          isNew: true,
          discountPercent: 10,
        ),
        Product(
          id: 7,
          name: 'Appareil de Massage Pro',
          brand: 'HappyHappy',
          price: 59.000,
          imageUrl:
              'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=400',
          category: 'Santé & Beauté',
          rating: 4.4,
          reviewCount: 33,
          isFreeDelivery: false,
          isNew: true,
        ),
        Product(
          id: 8,
          name: 'Jeu Éducatif Ajyel',
          brand: 'Ajyel',
          price: 35.000,
          imageUrl:
              'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
          category: 'Jouets & Jeux',
          rating: 4.9,
          reviewCount: 156,
          isFreeDelivery: false,
          isNew: true,
        ),
      ];

  static List<Category> get categories => [
        Category(
            id: 1,
            name: 'Téléphones & Tablettes',
            icon: '📱',
            color: const Color(0xFF4361EE),
            productCount: 245),
        Category(
            id: 2,
            name: 'Santé & Beauté',
            icon: '💄',
            color: const Color(0xFFE63946),
            productCount: 312),
        Category(
            id: 3,
            name: 'Maison & Bureau',
            icon: '🏠',
            color: const Color(0xFF2DC653),
            productCount: 198),
        Category(
            id: 4,
            name: 'Mode & Bijoux',
            icon: '👗',
            color: const Color(0xFFFFB703),
            productCount: 421),
        Category(
            id: 5,
            name: 'Gaming',
            icon: '🎮',
            color: const Color(0xFF7B2FBE),
            productCount: 87),
        Category(
            id: 6,
            name: 'Jouets & Jeux',
            icon: '🧸',
            color: const Color(0xFFFF6B6B),
            productCount: 134),
        Category(
            id: 7,
            name: 'Made In Tunisia',
            icon: '🇹🇳',
            color: const Color(0xFF1D3557),
            productCount: 89),
        Category(
            id: 8,
            name: 'Électroménager',
            icon: '🏪',
            color: const Color(0xFF06A77D),
            productCount: 176),
        Category(
            id: 9,
            name: 'Décoration',
            icon: '🎨',
            color: const Color(0xFFFF9F1C),
            productCount: 203),
        Category(
            id: 10,
            name: 'Animalerie',
            icon: '🐾',
            color: const Color(0xFF6D6875),
            productCount: 45),
      ];

  static List<String> get banners => [
        'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800',
        'https://images.unsplash.com/photo-1607082350899-7e105aa886ae?w=800',
        'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800',
      ];
}
