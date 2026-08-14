import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/favorites_provider.dart';
import '../models/auth_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'favorites_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(
          isLoggedIn ? 'Mon Compte' : 'Connexion',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: isLoggedIn ? _buildProfile(auth) : _buildAuth(),
    );
  }

  Future<void> _onSubmit() async {
    if (!_isLoginMode) {
      // --- Inscription : branchée sur le vrai Webservice PrestaShop ---
      final firstname = _firstNameController.text.trim();
      final lastname = _lastNameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (firstname.isEmpty ||
          lastname.isEmpty ||
          email.isEmpty ||
          password.isEmpty) {
        _showError('Merci de remplir tous les champs.');
        return;
      }
      final nameRegex = RegExp(r'^[a-zA-ZÀ-ÿ.]+( [a-zA-ZÀ-ÿ.]+)*$');
      if (!nameRegex.hasMatch(firstname) || !nameRegex.hasMatch(lastname)) {
        _showError(
          'Le prénom et le nom ne peuvent contenir que des lettres et le '
          'caractère (.).',
        );
        return;
      }
      if (!email.contains('@') || !email.contains('.')) {
        _showError('Adresse email invalide.');
        return;
      }
      if (password.length < 5) {
        _showError('Le mot de passe doit faire au moins 5 caractères.');
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        final idCustomer = await ApiService.createCustomerAccount(
          firstname: firstname,
          lastname: lastname,
          email: email,
          password: password,
        );
        if (!mounted) return;
        // On connecte directement le compte fraîchement créé, pas besoin
        // d'un aller-retour login séparé.
        context.read<AuthProvider>().setSession(
              Customer(
                id: idCustomer,
                firstname: firstname,
                lastname: lastname,
                email: email,
              ),
            );
        setState(() => _isSubmitting = false);
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _showError(e.message);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _showError('Erreur inattendue : $e');
      }
    } else {
      // --- Connexion : branchée sur ApiService.login() / authenticate.php ---
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        _showError('Merci de remplir tous les champs.');
        return;
      }
      if (!email.contains('@') || !email.contains('.')) {
        _showError('Adresse email invalide.');
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        final customer = await ApiService.login(
          email: email,
          password: password,
        );
        if (!mounted) return;
        context.read<AuthProvider>().setSession(customer);
        setState(() => _isSubmitting = false);
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _showError(e.message);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _showError(
          'Connexion indisponible pour le moment (script serveur pas '
          'encore prêt). Détail : $e',
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildAuth() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/logo_twenty.png',
              width: 220,
              height: 88,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ليك إنت',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 32),

          // Toggle
          Container(
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _AuthTab(
                  'Connexion',
                  _isLoginMode,
                  () => setState(() => _isLoginMode = true),
                ),
                _AuthTab(
                  'Inscription',
                  !_isLoginMode,
                  () => setState(() => _isLoginMode = false),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Form
          if (!_isLoginMode) ...[
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                prefixIcon: Icon(Icons.person_outline),
                helperText: 'Uniquement des lettres et le caractère (.), suivi '
                    'd\'un espace, sont autorisés.',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                prefixIcon: Icon(Icons.person_outline),
                helperText: 'Uniquement des lettres et le caractère (.), suivi '
                    'd\'un espace, sont autorisés.',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),

          if (_isLoginMode) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Mot de passe oublié?',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _onSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                  : Text(
                      _isLoginMode ? 'Se connecter' : 'Créer mon compte',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Suivez-nous',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SocialBtn(
                Icons.facebook,
                'Facebook',
                'https://www.facebook.com/twentytunisie?mibextid=zLoPMf',
              ),
              const SizedBox(width: 12),
              _SocialBtn(
                Icons.camera_alt_outlined,
                'Instagram',
                'https://www.instagram.com/twentytunisie/',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(AuthProvider auth) {
    final fullName = auth.customer?.fullName ?? '';
    final email = auth.customer?.email ?? '';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isNotEmpty ? fullName : 'Mon compte',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '⭐ Client Gold',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB8860B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Stats
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const _StatItem('3', 'Commandes'),
                _Divider(),
                _StatItem(
                  '${context.watch<FavoritesProvider>().count}',
                  'Favoris',
                ),
                _Divider(),
                const _StatItem('12.5 TND', 'Points'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Menu
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _MenuItem(
                  Icons.shopping_bag_outlined,
                  'Mes commandes',
                  '3 commandes',
                  () {},
                ),
                _MenuItem(
                  Icons.location_on_outlined,
                  'Mes adresses',
                  'Tunis, Tunisie',
                  () {},
                ),
                _MenuItem(
                  Icons.favorite_border,
                  'Mes favoris',
                  '${context.watch<FavoritesProvider>().count} produits',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  ),
                ),
                _MenuItem(
                  Icons.credit_card_outlined,
                  'Paiement',
                  'Carte / Cash',
                  () {},
                ),
                _MenuItem(
                  Icons.notifications_outlined,
                  'Notifications',
                  'Activées',
                  () {},
                ),
                _MenuItem(Icons.language, 'Langue', 'Français', () {}),
                _MenuItem(Icons.help_outline, 'Aide & Support', '', () {}),
                _MenuItem(
                  Icons.logout,
                  'Se déconnecter',
                  '',
                  () => context.read<AuthProvider>().logout(),
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Twenty.tn v1.0.0',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AuthTab(this.label, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color:
                  isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  const _SocialBtn(this.icon, this.label, this.url);

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir $label.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: AppTheme.borderColor);
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem(
    this.icon,
    this.title,
    this.subtitle,
    this.onTap, {
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (color ?? AppTheme.secondaryColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color ?? AppTheme.secondaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: color ?? AppTheme.textPrimary,
                ),
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
