import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/academic_models.dart';
import '../../providers/academic_provider.dart';
import 'subjects_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});
  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicProvider>().loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Class')),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(AcademicProvider provider) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return _ErrorState(
        message: provider.error!,
        onRetry: () => context.read<AcademicProvider>().loadClasses(),
      );
    }

    if (provider.classes.isEmpty) {
      return _ErrorState(
        message: 'No classes found. Make sure the backend is running and seeded.',
        onRetry: () => context.read<AcademicProvider>().loadClasses(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AcademicProvider>().loadClasses(),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: provider.classes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _ClassCard(cls: provider.classes[i]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassModel cls;
  const _ClassCard({required this.cls});

  @override
  Widget build(BuildContext context) {
    final colors = [
      [AppColors.primary, const Color(0xFF7C3AED)],
      [AppColors.secondary, const Color(0xFF0891B2)],
      [AppColors.accent, const Color(0xFF15803D)],
    ];
    final idx = int.tryParse(cls.className.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    final color = colors[(idx - 8).clamp(0, 2)];

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => SubjectsScreen(classModel: cls))),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: color,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Text('🎓', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cls.className,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  Text(cls.board,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}