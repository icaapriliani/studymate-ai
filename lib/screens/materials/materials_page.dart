import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/material_model.dart';
import '../../providers/learning_provider.dart';
import '../../utils/theme_context.dart';
import 'material_detail_page.dart';

class MaterialsPage extends StatefulWidget {
  final VoidCallback onTanyaAI;

  const MaterialsPage({
    super.key,
    required this.onTanyaAI,
  });

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Ilmu Komputer',
    'Kecerdasan Buatan',
    'Bahasa'
  ];

  @override
  Widget build(BuildContext context) {
    final learningProvider = Provider.of<LearningProvider>(context);

    if (learningProvider.isLoading && learningProvider.materials.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(context.colors.primaryGradientStart),
          ),
        ),
      );
    }

    final materialsList = learningProvider.materials.isNotEmpty
        ? learningProvider.materials
        : MaterialModel.dummyMaterials;

    // Filter materials based on category and search query
    final filteredMaterials = materialsList.where((MaterialModel mat) {
      final matchesCategory = _selectedCategory == 'Semua' || mat.category == _selectedCategory;
      final matchesSearch = mat.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          mat.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Materi Belajar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: context.colors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temukan modul kuliah dan bahan belajarmu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: context.colors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: TextStyle(fontSize: 14, color: context.colors.textPrimary),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded, color: context.colors.textLight, size: 20),
                        hintText: 'Cari modul atau materi kuliah...',
                        hintStyle: TextStyle(color: context.colors.textLight, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Filter Categories Shelf
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return _buildFilterPill(cat, isSelected);
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Materials List
                  filteredMaterials.isEmpty
                      ? _buildEmptyState()
                      : Column(
                          children: filteredMaterials.map((mat) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: context.colors.cardBg,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(5),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () async {
                                    final result = await Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            MaterialDetailPage(material: mat),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0, 0.1),
                                              end: Offset.zero,
                                            ).animate(CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            )),
                                            child: FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                          );
                                        },
                                        transitionDuration: const Duration(milliseconds: 400),
                                      ),
                                    );

                                    if (result == 'tanya_ai') {
                                      widget.onTanyaAI();
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                mat.title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: context.colors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              color: context.colors.textLight.withAlpha(120),
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          mat.modules,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: context.colors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: context.colors.progressTrack,
                                                  borderRadius: BorderRadius.circular(100),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(100),
                                                  child: LinearProgressIndicator(
                                                    value: mat.progress,
                                                    backgroundColor: Colors.transparent,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      mat.color,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '${(mat.progress * 100).round()}%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                color: mat.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 85),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterPill(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: Material(
        color: isSelected ? context.colors.primaryGradientStart : context.colors.cardBg,
        borderRadius: BorderRadius.circular(100),
        elevation: isSelected ? 3 : 1,
        shadowColor: isSelected ? context.colors.primaryGradientStart.withAlpha(60) : Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () {
            setState(() {
              _selectedCategory = label;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.white : context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: context.colors.textLight.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'Materi Tidak Ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan coba gunakan kata kunci pencarian lain atau pilih kategori yang berbeda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
