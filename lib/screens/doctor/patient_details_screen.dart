import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/glucose_reading.dart';
import '../../models/meal.dart';
import '../../services/doctor_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class PatientDetailsScreen extends StatefulWidget {
  final UserProfile patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> with SingleTickerProviderStateMixin {
  final DoctorService _doctorService = DoctorService();
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? _statistics;
  bool _loadingStats = true;
  int _selectedTab = 0; // 0 = Glucose, 1 = Meals
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await _doctorService.getPatientStatistics(
        widget.patient.uid,
      );
      setState(() {
        _statistics = stats;
        _loadingStats = false;
      });
    } catch (e) {
      setState(() => _loadingStats = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading statistics: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Patient Details'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue,
                AppTheme.primaryBlue.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Patient Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.primaryBlue.withOpacity(0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.patient.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.patient.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 14,
                              color: AppTheme.successGreen,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Active Patient',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.successGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.show_chart), text: 'Glucose Data'),
                Tab(icon: Icon(Icons.restaurant_menu), text: 'Meal History'),
              ],
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryBlue,
              indicatorWeight: 3,
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Glucose Tab
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics Section
                      if (_loadingStats)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        )
                      else if (_statistics != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildStatisticsCards(_statistics!),
                        ),

                      StreamBuilder<List<GlucoseReading>>(
                        stream: _doctorService.getPatientGlucoseReadings(
                          widget.patient.uid,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.show_chart_outlined,
                                      size: 64,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No glucose readings yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final readings = snapshot.data!;
                          return _buildReadingsList(readings);
                        },
                      ),
                    ],
                  ),
                ),

                // Meals Tab
                StreamBuilder<List<Meal>>(
                  stream: _firestoreService.getPatientMealsStream(
                    patientId: widget.patient.uid,
                    limit: 30,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No meals recorded yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final meals = snapshot.data!;
                    return _buildMealsList(meals);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Average',
          '${stats['average'].toStringAsFixed(0)}',
          Icons.show_chart,
          AppTheme.primaryBlue,
        ),
        _buildStatCard(
          'In Range',
          '${stats['timeInRange'].toStringAsFixed(0)}%',
          Icons.timer,
          AppTheme.successGreen,
        ),
        _buildStatCard(
          'Low',
          '${stats['min'].toStringAsFixed(0)}',
          Icons.arrow_downward,
          AppTheme.lowRed,
        ),
        _buildStatCard(
          'High',
          '${stats['max'].toStringAsFixed(0)}',
          Icons.arrow_upward,
          AppTheme.warningOrange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReadingsList(List<GlucoseReading> readings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            'Recent Readings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: readings.length > 20 ? 20 : readings.length,
          itemBuilder: (context, index) {
            final reading = readings[index];
            final date = DateTime.fromMillisecondsSinceEpoch(reading.timestamp);
            final value = reading.value;

            Color valueColor = AppTheme.successGreen;
            if (value < 70) {
              valueColor = AppTheme.lowRed;
            } else if (value > 180) {
              valueColor = AppTheme.warningOrange;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: valueColor.withOpacity(0.1),
                  child: Icon(Icons.water_drop, color: valueColor),
                ),
                title: Text(
                  '${value.toStringAsFixed(0)} mg/dL',
                  style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
                ),
                subtitle: Text(
                  '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMealsList(List<Meal> meals) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                meal.mealType.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            title: Text(
              meal.foodName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${DateFormat('MMM d, yyyy').format(meal.timestamp)} at ${meal.formattedTime} • ${meal.mealType.displayName}',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nutritional Info:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMealDetailRow(
                      'Calories',
                      '${meal.nutritionalData.calories.toStringAsFixed(0)} kcal',
                    ),
                    _buildMealDetailRow(
                      'Carbs',
                      '${meal.nutritionalData.carbs.toStringAsFixed(1)}g',
                    ),
                    _buildMealDetailRow(
                      'Protein',
                      '${meal.nutritionalData.protein.toStringAsFixed(1)}g',
                    ),
                    _buildMealDetailRow(
                      'Fat',
                      '${meal.nutritionalData.fat.toStringAsFixed(1)}g',
                    ),
                    if (meal.glucoseImpact != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Glucose Impact:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getRiskColor(
                            meal.glucoseImpact!.riskLevel,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMealDetailRow(
                              'Predicted Peak',
                              '${meal.glucoseImpact!.predictedPeakGlucose.toStringAsFixed(0)} mg/dL',
                            ),
                            _buildMealDetailRow(
                              'Risk Level',
                              meal.glucoseImpact!.riskLevel,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              meal.glucoseImpact!.recommendation,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Notes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meal.notes!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Low':
        return AppTheme.successGreen;
      case 'Moderate':
        return AppTheme.warningOrange;
      case 'High':
        return AppTheme.dangerRed;
      case 'Very High':
        return AppTheme.lowRed;
      default:
        return AppTheme.primaryBlue;
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark 
          ? AppTheme.darkCard 
          : Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
