import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/academic_models.dart';
import '../../providers/academic_provider.dart';
import 'chapters_screen.dart';

class SubjectsScreen extends StatefulWidget {
  final ClassModel classModel;
  const SubjectsScreen({super.key, required this.classModel});
  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicProvider>().loadSubjects(widget.classModel.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.classModel.className)),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(AcademicProvider provider) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return _retry(provider.error!);
    }

    if (provider.subjects.isEmpty) {
      return _retry('No subjects found for this class.');
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AcademicProvider>().loadSubjects(widget.classModel.id),
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: provider.subjects.length,
        itemBuilder: (_, i) => _SubjectCard(subject: provider.subjects[i]),
      ),
    );
  }

  Widget _retry(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('😕', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(msg, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.read<AcademicProvider>().loadSubjects(widget.classModel.id),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ]),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final isScience = subject.subjectName.toLowerCase().contains('science');
    final color = isScience ? AppColors.accent : AppColors.primary;
    final emoji = isScience ? '⚗️' : '📐';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ChaptersScreen(subject: subject))),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(subject.subjectName,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}