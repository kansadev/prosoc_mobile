import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/theme.dart';
import 'views/widgets/prosoc_date_picker.dart';
import 'controllers/main_controller.dart';
import 'services/auth_service.dart';
import 'views/screens/onboarding_screen.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/main_screen.dart';
import 'views/screens/percepteur/main_percepteur_screen.dart';
import 'views/screens/adhérent/main_adherent_screen.dart';
import 'views/screens/superviseur/main_superviseur_screen.dart';
import 'navigation/app_route_observer.dart';

// ============================================
// APPLICATION PRINCIPALE
// ============================================
class ProsocApp extends StatefulWidget {
  const ProsocApp({super.key});

  @override
  State<ProsocApp> createState() => _ProsocAppState();
}

class _ProsocAppState extends State<ProsocApp> {
  bool _isLoading = true;
  bool _showOnboarding = true;
  bool _showLogin = false;
  late final MainController _controller;
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _controller = MainController();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    // Vérifier si l'utilisateur est connecté
    final isLoggedIn = await AuthService.isLoggedIn();
    // Vérifier si l'onboarding a déjà été vu
    final hasSeenOnboarding = await AuthService.hasSeenOnboarding();
    
    // Récupérer le rôle de l'utilisateur
    final role = await AuthService.getNomRole();
    
    setState(() {
      _isLoading = false;
      _userRole = role ?? '';
      if (isLoggedIn) {
        // Si connecté, aller directement au MainScreen
        _showOnboarding = false;
        _showLogin = false;
      } else if (hasSeenOnboarding) {
        // Si onboarding déjà vu mais pas connecté, aller au login
        _showOnboarding = false;
        _showLogin = true;
      }
      // Sinon, afficher l'onboarding
    });
  }

  void _completeOnboarding() async {
    // Marquer l'onboarding comme vu
    await AuthService.setOnboardingSeen();
    setState(() {
      _showOnboarding = false;
      _showLogin = true;
    });
  }

  void _completeLogin() {
    // Récupérer le rôle après connexion
    final role = AuthService.userRole;
    setState(() {
      _userRole = role ?? '';
      _showLogin = false;
    });
  }

  /// Déterminer quel écran principal afficher en fonction du rôle
  Widget _buildMainScreen() {
    // Déterminer le rôle
    final isSuperviseur = _userRole.toLowerCase().contains('superviseur');
    final isPercepteur = _userRole.toLowerCase().contains('percepteur');
    final isAgentAT = _userRole.toLowerCase().contains('agent') && 
                     _userRole.toLowerCase().contains('at');
    final isAdherent = _userRole.toLowerCase().contains('adhérent') ||
                       _userRole.toLowerCase().contains('affilié') ||
                       _userRole.toLowerCase().contains('affilie') ||
                       _userRole.toLowerCase().contains('adherent');
    
    if (isSuperviseur) {
      return MainSuperviseurScreen(onLogout: _handleLogout);
    } else if (isPercepteur) {
      return MainPercepteurScreen(onLogout: _handleLogout);
    } else if (isAdherent) {
      return MainAdherentScreen(onLogout: _handleLogout);
    } else {
      // Par défaut, afficher l'écran Agent AT
      return MainScreen(controller: _controller, onLogout: _handleLogout);
    }
  }

  void _handleLogout() {
    setState(() {
      _userRole = '';
      _showLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prosoc - Mutuelle & Assistance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: ProsocDatePicker.frenchLocale,
      supportedLocales: ProsocDatePicker.supportedLocales,
      localizationsDelegates: ProsocDatePicker.localizationDelegates,
      navigatorObservers: [appRouteObserver],
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _showOnboarding
              ? OnboardingScreen(onComplete: _completeOnboarding)
              : _showLogin
                  ? LoginScreen(onLoginSuccess: _completeLogin)
                  : _buildMainScreen(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AuthService.configureApiSessionRefresh();

  // Initialiser les données de locale pour intl
  await initializeDateFormatting('fr_FR', null);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProsocApp());
}
