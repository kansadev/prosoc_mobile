import 'package:flutter/material.dart';

class OnboardingData {
  final String title;
  final String description;
  final String imagePath;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Liste complète des 10 slides avec vos images indexées de 1 à 10
  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Bienvenue chez Prosoc",
      description: "Votre partenaire de confiance pour toutes vos garanties sociales et assistances. Découvrez une plateforme complète dédiée à votre bien-être et à celui de votre famille.",
      imagePath: "assets/images/1.png",
    ),
    OnboardingData(
      title: "Soins Médicaux Standard",
      description: "Une couverture complète pour vos consultations, analyses et traitements médicaux. Accédez à un réseau de professionnels de santé qualifiés et bénéficiez de remboursements rapides.",
      imagePath: "assets/images/2.png",
    ),
    OnboardingData(
      title: "Soins Médicaux VIP",
      description: "Des soins premium avec accès prioritaire aux spécialistes et cliniques de renom. Profitez d'une expérience médicale personnalisée avec consultations dans les meilleurs établissements.",
      imagePath: "assets/images/3.png",
    ),
    OnboardingData(
      title: "Assistance Funérailles",
      description: "Un accompagnement digne pour vos proches en cas de besoin, avec prise en charge complète. Nous gérons toutes les formalités pour vous offrir sérénité et respect.",
      imagePath: "assets/images/4.png",
    ),
    OnboardingData(
      title: "Assistance Juridique",
      description: "Un soutien juridique professionnel pour résoudre vos litiges et questions légales. Bénéficiez de conseils d'avocats experts disponibles à tout moment pour vous assister.",
      imagePath: "assets/images/5.png",
    ),
    OnboardingData(
      title: "Retraite Complémentaire",
      description: "Préparez votre avenir avec nos plans d'épargne retraite adaptés à vos besoins. Constituez-vous un capital supplémentaire sécurisé et flexible pour votre retraite.",
      imagePath: "assets/images/6.png",
    ),
    OnboardingData(
      title: "Cantine Alimentaire",
      description: "Un service de restauration équilibrée pour les employés et leurs familles. Des repas nutritifs et savoureux préparés quotidiennement selon vos préférences.",
      imagePath: "assets/images/7.png",
    ),
    OnboardingData(
      title: "Microcrédit",
      description: "Des prêts solidaires pour financer vos projets personnels et professionnels. Obtenez un financement rapide et sans complications pour concrétiser vos ambitions.",
      imagePath: "assets/images/8.png",
    ),
    OnboardingData(
      title: "Formations Professionnelles",
      description: "Développez vos compétences avec nos programmes de formation certifiants. Accédez à des cours en ligne et en présentiel dispensés par des experts du secteur.",
      imagePath: "assets/images/9.png",
    ),
    OnboardingData(
      title: "Prêt à nous rejoindre ?",
      description: "Créez votre compte en quelques minutes et profitez de tous vos avantages. Rejoignez des milliers de membres satisfaits qui font confiance à Prosoc pour leur sécurité.",
      imagePath: "assets/images/10.png",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: SafeArea(
        child: Column(
          children: [
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onComplete,
                    child: const Text(
                      'Passer',
                      style: TextStyle(
                        color: Color(0xFF2DB467), // Vert de l'image
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu défilant
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),

            // Footer fixe : Indicateurs et Bouton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                children: [
                  // Indicateurs de pages (Dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildIndicator(index),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bouton d'action principal
                  _buildNextButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Zone Image - prend moins d'espace
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Image.asset(
                page.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_outlined, size: 100, color: Colors.grey),
              ),
            ),
          ),
          
          // Zone Texte - scrollable si nécessaire
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22, // Réduit de 24 à 22
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12), // Réduit de 15 à 12
                    Text(
                      page.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14, // Réduit de 15 à 14
                        color: Colors.grey.shade600,
                        height: 1.4, // Réduit de 1.5 à 1.4
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 12 : 8, // Dots simples
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2DB467) : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildNextButton() {
    bool isLastPage = _currentPage == _pages.length - 1;
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          if (isLastPage) {
            widget.onComplete();
          } else {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2DB467), // Le vert "Prosoc"
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // Bouton très arrondi
          ),
        ),
        child: Text(
          isLastPage ? 'Commencer' : 'Suivant',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}