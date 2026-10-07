import 'dart:convert';
import 'package:doctor_app/bookAppointment.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Doctordetail extends StatefulWidget {
  final dynamic doctor;

  const Doctordetail({
    super.key,
    required this.doctor,
  });

  @override
  State<Doctordetail> createState() => _DoctordetailState();
}

class _DoctordetailState extends State<Doctordetail>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  bool isFavourite = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _animController.forward();
  }

  Widget _buildDoctorHeroImage(String docPic) {
    final cleanPic = docPic.trim();
    if (cleanPic.startsWith('http://') || cleanPic.startsWith('https://')) {
      return Image.network(
        cleanPic,
        height: 240,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset('asset/doc1.png', height: 240, fit: BoxFit.contain),
      );
    } else if (cleanPic.startsWith('data:image')) {
      try {
        final base64Str = cleanPic.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          height: 240,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset('asset/doc1.png', height: 240, fit: BoxFit.contain),
        );
      } catch (_) {
        return Image.asset('asset/doc1.png', height: 240, fit: BoxFit.contain);
      }
    } else {
      return Image.asset(
        cleanPic.isNotEmpty ? cleanPic : 'asset/doc1.png',
        height: 240,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset('asset/doc1.png', height: 240, fit: BoxFit.contain),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // =====================================================
          // HERO HEADER
          // =====================================================
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0C67B1),

            leading: _circleIconButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () => Navigator.pop(context),
            ),

            actions: [
              _circleIconButton(
                icon: isFavourite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: isFavourite ? Colors.redAccent : Colors.white,
                onTap: () {
                  setState(() {
                    isFavourite = !isFavourite;
                  });
                },
              ),
              const SizedBox(width: 4),
            ],

            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2196F3),
                          Color(0xFF0C67B1),
                        ],
                      ),
                    ),
                  ),

                  // Doctor image
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Hero(
                      tag: 'doctor_${doctor['DocName']}',
                      child: _buildDoctorHeroImage(doctor['docPic']?.toString() ?? ''),
                    ),
                  ),

                  // Bottom gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0xCC0C67B1),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Doctor information
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFC107),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                doctor["Rating"].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Doctor name
                        Text(
                          doctor["DocName"].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),

                        const SizedBox(height: 2),

                        // Specialty
                        Text(
                          doctor["specialist"].toString(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =====================================================
          // BODY
          // =====================================================
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // =================================================
                    // STAT CARDS
                    // =================================================
                    Row(
                      children: [
                        // Rating
                        _statCard(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFFFC107),
                          value: (doctor['rating'] ??
                                  doctor['Rating'] ??
                                  '0')
                              .toString(),
                          label: "Rating",
                        ),

                        const SizedBox(width: 12),

                        // Experience
                        _statCard(
                          icon: Icons.work_history_outlined,
                          iconColor: const Color(0xFF2196F3),
                          value: (doctor['experience'] ?? '0')
                              .toString(),
                          label: "Experience",
                        ),

                        const SizedBox(width: 12),

                        // Reviews
                        _statCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          iconColor: const Color(0xFF4CAF50),
                          value: (doctor['Review'] ?? '0')
                              .toString(),
                          label: "Reviews",
                          valueSize: 16,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // ABOUT SECTION
                    // =================================================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "About",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          AnimatedCrossFade(
                            firstChild: const Text(
                              "Dr. Alan Smith is a compassionate and experienced Pediatric Cardiologist dedicated to providing comprehensive healthcare for infants, children, and adolescents. With over 10 years of clinical experience, he specializes in diagnosing and treating congenital and acquired heart conditions in children.",
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                height: 1.5,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),

                            secondChild: const Text(
                              "Dr. Alan Smith is a compassionate and experienced Pediatric Cardiologist dedicated to providing comprehensive healthcare for infants, children, and adolescents. With over 10 years of clinical experience, he specializes in diagnosing and treating congenital and acquired heart conditions in children. Dr. Smith is committed to delivering personalized, evidence-based care while ensuring every young patient and their family feels comfortable, informed, and supported throughout the treatment journey. He believes in combining advanced medical expertise with a caring approach to achieve the best possible outcomes for every child.",
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                height: 1.5,
                              ),
                            ),

                            crossFadeState: isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,

                            duration:
                                const Duration(milliseconds: 300),
                          ),

                          const SizedBox(height: 8),

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isExpanded = !isExpanded;
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isExpanded
                                      ? "Read Less"
                                      : "Read More",
                                  style: const TextStyle(
                                    color: Color(0xFF2196F3),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: const Color(0xFF2196F3),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // WORKING HOURS
                    // =================================================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Working Hours",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50)
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      color: Color(0xFF4CAF50),
                                      size: 8,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Available Today",
                                      style: TextStyle(
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _workingHourRow(
                            icon: Icons.calendar_today_rounded,
                            text: "Monday – Friday",
                          ),

                          const SizedBox(height: 12),

                          _workingHourRow(
                            icon: Icons.access_time_rounded,
                            text: "09:00 AM – 05:00 PM",
                          ),

                          const SizedBox(height: 12),

                          _workingHourRow(
                            icon: Icons.weekend_outlined,
                            text: "Saturday: 09:00 AM – 01:00 PM",
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            child: Divider(height: 1),
                          ),

                          _workingHourRow(
                            icon: Icons.location_on_outlined,
                            text:
                                "City Hospital, Floor 3, Room 302",
                            iconColor: const Color(0xFFFF5722),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // CONSULTATION FEE
                    // =================================================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.currency_rupee_rounded,
                              color: Color(0xFF4CAF50),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Consultation Fee",
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 2),

                              Text(
                                "₹ ${doctor['fee']}",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3)
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Per Visit",
                              style: TextStyle(
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ===========================================================
      // BOOK APPOINTMENT BUTTON
      // ===========================================================
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C67B1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookAppointment(
                      DocName: doctor["DocName"],
                      docspecialist: doctor["specialist"],
                      docPic: doctor["docPic"],
                      Rating: doctor['Rating'],
                      fee: doctor["fee"],
                    ),
                  ),
                );
              },

              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Book Appointment",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
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

  // ====================================================
  // CIRCULAR ICON BUTTON
  // ====================================================

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.15),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ====================================================
  // STAT CARD
  // ====================================================

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    double valueSize = 20,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),

            const SizedBox(height: 8),

            Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 2),

            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // WORKING HOUR ROW
  // ====================================================

  Widget _workingHourRow({
    required IconData icon,
    required String text,
    Color iconColor = const Color(0xFF2196F3),
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),

        const SizedBox(width: 12),

        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}