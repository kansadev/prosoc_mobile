import 'package:flutter/material.dart';
import '../../controllers/main_controller.dart';
import '../widgets/common_widgets.dart';

// ============================================
// ÉCRAN SERVICES (VIEW)
// ============================================
class ServicesScreen extends StatelessWidget {
  final ServicesController controller;

  const ServicesScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final services = controller.services;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nos Services',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Découvrez toutes nos offres',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final service = services[index];
                    return ServiceCard(
                      title: service.title,
                      subtitle: service.subtitle,
                      icon: service.icon,
                      color: service.color,
                      onTap: () => controller.onServiceTap(service),
                    );
                  },
                  childCount: services.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}
