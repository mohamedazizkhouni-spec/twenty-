import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Écran de checkout : formulaire d'adresse + récap + validation.
///
/// La validation appelle maintenant ApiService.submitOrder, qui enchaîne
/// les 4 étapes obligatoires côté Webservice PrestaShop : création du
/// client invité, de l'adresse, du panier serveur, puis de la commande.
/// Voir les commentaires dans api_service.dart pour le détail de chaque
/// étape et les valeurs (id_carrier, id_currency, module de paiement...)
/// encore à confirmer avec Ramzi.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();

  String _deliveryMethod = 'standard';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _deliveryFeeFor(String method, double subtotal) {
    return 7.000;
  }

  Future<void> _placeOrder(CartProvider cart) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Le nom complet du formulaire est un seul champ ("Nom complet"), on le
    // coupe en deux pour coller au modèle firstname/lastname de PrestaShop.
    final parts = _nameController.text.trim().split(' ');
    final firstname = parts.first;
    final lastname = parts.length > 1 ? parts.sublist(1).join(' ') : '.';

    final deliveryFee = _deliveryFeeFor(_deliveryMethod, cart.subtotal);
    final total = cart.subtotal + deliveryFee;

    try {
      await ApiService.submitOrder(
        firstname: firstname,
        lastname: lastname,
        phone: _phoneController.text.trim(),
        address1: _addressController.text.trim(),
        city: _cityController.text.trim(),
        items: cart.items,
        totalProducts: cart.subtotal,
        totalShipping: deliveryFee,
        totalPaid: total,
      );

      if (!mounted) return;
      cart.clearCart();
      setState(() => _isSubmitting = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successColor, size: 28),
              SizedBox(width: 10),
              Text('Commande confirmée'),
            ],
          ),
          content: const Text(
            'Votre commande a bien été enregistrée. Vous recevrez une confirmation par téléphone.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // ferme le dialog
                Navigator.of(context).pop(); // retour au panier (vide)
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      // Erreur venant du Webservice PrestaShop (permissions, champ
      // manquant, module de paiement inconnu...) : on l'affiche telle
      // quelle pour pouvoir la montrer à Ramzi si besoin.
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Échec de la commande'),
          content: SingleChildScrollView(child: Text(e.message)),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inattendue : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final deliveryFee = _deliveryFeeFor(_deliveryMethod, cart.subtotal);
    final total = cart.subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text(
          'Finaliser la commande',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionTitle('Adresse de livraison'),
            const SizedBox(height: 10),
            _FormCard(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Champ requis';
                    final digits = v.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 8) return 'Numéro invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ville',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes de livraison (optionnel)',
                    prefixIcon: Icon(Icons.note_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Mode de livraison'),
            const SizedBox(height: 10),
            RadioGroup<String>(
              groupValue: _deliveryMethod,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _deliveryMethod = value);
                }
              },
              child: _FormCard(
                children: [
                  _DeliveryOption(
                    value: 'standard',
                    title: 'Standard (2-4 jours)',
                    price: '7.000 TND',
                    onTap: () => setState(() => _deliveryMethod = 'standard'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Récapitulatif'),
            const SizedBox(height: 10),
            _FormCard(
              children: [
                _SummaryRow(
                  'Articles (${cart.itemCount})',
                  '${cart.subtotal.toStringAsFixed(3)} TND',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  'Livraison',
                  '${deliveryFee.toStringAsFixed(3)} TND',
                ),
                const Divider(height: 20),
                _SummaryRow(
                  'Total',
                  '${total.toStringAsFixed(3)} TND',
                  isBold: true,
                  valueColor: AppTheme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _placeOrder(cart),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Confirmer - ${total.toStringAsFixed(3)} TND',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final String value;
  final String title;
  final String price;
  final VoidCallback onTap;

  const _DeliveryOption({
    required this.value,
    required this.title,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            activeColor: AppTheme.primaryColor,
          ),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(
            price,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value,
      {this.isBold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
