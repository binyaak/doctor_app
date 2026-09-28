import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_app/DoctorDetail.dart';
import 'package:doctor_app/PatientHealthProfilePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// ------------------------------------------------------
// CAROUSEL DATA
// ------------------------------------------------------

final List<Map<String, String>> doctorSlides = [
  {
    "title": "Your Health\nis Our Priority",
    "subtitle": "Book appointments with\ntrusted doctors.",
    "image": "asset/doc1.png",
  },
  {
    "title": "Consult Top\nDoctors",
    "subtitle": "Expert healthcare\nat your fingertips.",
    "image": "asset/doc2.png",
  },
  {
    "title": "24/7 Medical\nSupport",
    "subtitle": "Get instant\nconsultation anytime.",
    "image": "asset/doc3.png",
  },
];

// ------------------------------------------------------
// CAROUSEL DOCTOR CARD
// ------------------------------------------------------

Widget doctorCard({
  required String title,
  required String subtitle,
  required String image,
}) {
  return Card(
    color: const Color.fromARGB(255, 186, 230, 238),

    child: Row(
      children: [

        // LEFT SIDE
        Expanded(
          flex: 2,

          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.all(8.0),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Padding(
                      padding: const EdgeInsets.all(5.0),

                      child: Text(
                        title,

                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 3, 56, 99),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(5.0),

                      child: Text(
                        subtitle,

                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 2, 57, 102),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 100,

                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 9, 115, 202),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),

                        onPressed: () {},

                        child: const Text(
                          "Book now",

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // RIGHT SIDE
        Expanded(
          flex: 2,

          child: SizedBox(
            height: 170,

            child: Padding(
              padding: const EdgeInsets.only(right: 8),

              child: Stack(
                alignment: Alignment.bottomRight,

                children: [

                  // BACKGROUND CIRCLE
                  Positioned(
                    bottom: -40,

                    child: Container(
                      width: 155,
                      height: 155,

                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 89, 199, 243),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // DOCTOR IMAGE
                  Align(
                    alignment: Alignment.bottomRight,

                    child: Image.asset(
                      image,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // HEART ICON
                  Positioned(
                    right: .8,
                    top: 49,

                    child: Container(
                      width: 43,
                      height: 43,

                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),

                      child: Center(
                        child: Image.asset(
                          "asset/heart-removebg-preview.png",
                          height: 30,
                          width: 30,
                          fit: BoxFit.contain,
                        ),
                      ),
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

// ======================================================
// HOME PAGE STATE
// ======================================================

class _HomePageState extends State<HomePage> {

  int _currentIndex = 0;

  String userName = "User";
  String userEmail = "";
  String userPhone = "";

  @override
  void initState() {
    super.initState();

    loadUserData();
  }

  // ----------------------------------------------------
  // LOAD USER DATA
  // ----------------------------------------------------

  Future<void> loadUserData() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {

        final data = doc.data();

        if (mounted) {

          setState(() {

            userName = data?['name'] ?? "User";

            userEmail =
                data?['email'] ?? user.email ?? "";

            userPhone =
                data?['phone'] ?? "";
          });
        }
      }

    } catch (e) {

      debugPrint(
        "Error loading user data: $e",
      );
    }
  }

  // ----------------------------------------------------
  // LOAD DOCTORS FROM FIRESTORE
  // ----------------------------------------------------

  Future<List<Map<String, dynamic>>> loadDoctors() async {

    try {

      final snapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .get();

      return snapshot.docs.map((doc) {

        final data = doc.data();

        return {

          'id': doc.id,

          'docPic':
              data['docPic'] ??
              'asset/doc1.png',

          'DocName':
              data['DocName'] ??
              '',

          'specialist':
              data['specialist'] ??
              '',

          // IMPORTANT:
          // Firestore field is Rating
          'Rating':
              data['Rating']?.toString() ??
              '0',

          // IMPORTANT:
          // Firestore field is Review
          'Review':
              data['Review'] ??
              '',

          'experience':
              data['experience']?.toString() ??
              '0',

          'fee':
              data['fee']?.toString() ??
              '0',
        };

      }).toList();

    } catch (e) {

      debugPrint(
        "Error loading doctors: $e",
      );

      return [];
    }
  }

  // ====================================================
  // BUILD
  // ====================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      // ------------------------------------------------
      // APP BAR
      // ------------------------------------------------

      appBar: AppBar(

        backgroundColor: Colors.transparent,

        leading: const Icon(
          Icons.menu,
          color: Color.fromARGB(255, 15, 15, 15),
        ),

        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            SizedBox(
              height: 35,
              width: 35,

              child: Image.asset(
                'asset/logo.jpg',
              ),
            ),

            const Text(
              " Doctor App",

              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(
                  255,
                  12,
                  103,
                  177,
                ),
              ),
            ),
          ],
        ),

        actions: const [

          Icon(
            Icons.notifications,
            color: Color.fromARGB(
              255,
              15,
              15,
              15,
            ),
          ),
        ],
      ),

      // ------------------------------------------------
      // BODY
      // ------------------------------------------------

      body: SingleChildScrollView(

        child: Column(

          children: [

            // ==========================================
            // GREETING
            // ==========================================

            Padding(
              padding:
                  const EdgeInsets.all(8.0),

              child: Row(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Expanded(

                    child: Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Row(

                          children: [

                            Expanded(

                              child: Text(
                                "Good Morning, $userName",

                                style:
                                    const TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.bold,
                                ),

                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ),

                            const Icon(
                              Icons.waving_hand,
                              color: Color.fromARGB(
                                255,
                                238,
                                215,
                                13,
                              ),
                            ),
                          ],
                        ),

                        const Text(
                          "Find and book the best doctors near you.",
                        ),
                      ],
                    ),
                  ),

                  const CircleAvatar(
                    radius: 30,

                    backgroundImage:
                        AssetImage(
                      'asset/logo.jpg',
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // SEARCH
            // ==========================================

            Padding(
              padding:
                  const EdgeInsets.all(8.0),

              child: TextField(

                decoration:
                    InputDecoration(

                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color.fromARGB(
                      255,
                      153,
                      149,
                      149,
                    ),
                  ),

                  labelText:
                      "Search doctors, hospitals ...",

                  labelStyle:
                      const TextStyle(
                    color: Color.fromARGB(
                      255,
                      153,
                      149,
                      149,
                    ),
                  ),

                  suffixIcon:
                      const Icon(
                    Icons.filter_alt,
                    color: Color.fromARGB(
                      255,
                      153,
                      149,
                      149,
                    ),
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                ),
              ),
            ),

            // ==========================================
            // CAROUSEL
            // ==========================================

            CarouselSlider(

              options:
                  CarouselOptions(

                height: 170,

                enlargeCenterPage: true,

                viewportFraction: 0.95,

                autoPlayInterval:
                    const Duration(
                  seconds: 3,
                ),

                onPageChanged:
                    (index, reason) {

                  setState(() {

                    _currentIndex =
                        index;
                  });
                },
              ),

              items:
                  doctorSlides.map(
                (slide) {

                  return doctorCard(

                    title:
                        slide["title"]!,

                    subtitle:
                        slide["subtitle"]!,

                    image:
                        slide["image"]!,
                  );
                },
              ).toList(),
            ),

            const SizedBox(
              height: 30,
            ),

            // ==========================================
            // CAROUSEL DOTS
            // ==========================================

            Row(

              mainAxisAlignment:
                  MainAxisAlignment.center,

              children:
                  doctorSlides
                      .asMap()
                      .entries
                      .map(
                (entry) {

                  return Container(

                    width: 8.0,
                    height: 8.0,

                    margin:
                        const EdgeInsets.symmetric(
                      horizontal: 4.0,
                    ),

                    decoration:
                        BoxDecoration(

                      shape:
                          BoxShape.circle,

                      color:
                          _currentIndex ==
                                  entry.key
                              ? const Color
                                  .fromARGB(
                                  255,
                                  9,
                                  115,
                                  202,
                                )
                              : const Color
                                  .fromARGB(
                                  255,
                                  186,
                                  230,
                                  238,
                                ),
                    ),
                  );
                },
              ).toList(),
            ),

            // ==========================================
            // HEALTH PROFILE BANNER
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientHealthProfilePage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff0C67B1), Color(0xff2196F3)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.health_and_safety_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "My Health Profile",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "View & update your medical info & BMI",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==========================================
            // CATEGORIES
            // ==========================================

            Column(

              children: [

                Padding(
                  padding:
                      const EdgeInsets.all(
                    8.0,
                  ),

                  child: Row(

                    children: [

                      const Expanded(

                        child: Text(
                          "Categories",

                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      const Text(
                        "See All",

                        style:
                            TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                SingleChildScrollView(

                  scrollDirection:
                      Axis.horizontal,

                  child: Padding(

                    padding:
                        const EdgeInsets.all(
                      8.0,
                    ),

                    child: Row(

                      children: [

                        categoryItem(
                          "asset/cardioo-removebg-preview.png",
                          "Cardiologist",
                        ),

                        categoryItem(
                          "asset/dental-removebg-preview.png",
                          "Dentist",
                        ),

                        categoryItem(
                          "asset/pediatric-removebg-preview.png",
                          "Pediatrician",
                        ),

                        categoryItem(
                          "asset/nuero-removebg-preview.png",
                          "Neurologist",
                        ),

                        categoryItem(
                          "asset/eye-removebg-preview.png",
                          "Eye specialist",
                        ),

                        categoryItem(
                          "asset/ortho-removebg-preview.png",
                          "Orthopedic",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ==========================================
            // TOP DOCTORS TITLE
            // ==========================================

            Padding(
              padding:
                  const EdgeInsets.all(
                16.0,
              ),

              child: Row(

                children: [

                  const Expanded(

                    child: Text(
                      "Top Doctors",

                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const Text(
                    "See All",

                    style:
                        TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // DOCTORS FROM FIRESTORE
            // ==========================================

            FutureBuilder<
                List<Map<String, dynamic>>>(
              
              future: loadDoctors(),

              builder:
                  (context, snapshot) {

                // LOADING
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {

                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                // ERROR
                if (snapshot.hasError) {

                  return const Center(
                    child: Text(
                      "Error loading doctors",
                    ),
                  );
                }

                final doctors =
                    snapshot.data ?? [];

                // EMPTY
                if (doctors.isEmpty) {

                  return const Center(
                    child: Text(
                      "No doctors found",
                    ),
                  );
                }

                // ====================================
                // LIST VIEW BUILDER
                // ====================================

                return ListView.builder(

                  itemCount:
                      doctors.length,

                  shrinkWrap:
                      true,

                  physics:
                      const NeverScrollableScrollPhysics(),

                  itemBuilder:
                      (context, index) {

                    // GET CURRENT DOCTOR
                    final Doc =
                        doctors[index];

                    return Padding(

                      padding:
                          const EdgeInsets.all(
                        8.0,
                      ),

                      child: Card(

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),

                          side:
                              const BorderSide(
                            color: Color.fromARGB(
                              255,
                              216,
                              218,
                              218,
                            ),

                            width: 1,
                          ),
                        ),

                        child: Column(

                          children: [

                            // --------------------------------
                            // DOCTOR INFORMATION
                            // --------------------------------

                            Padding(

                              padding:
                                  const EdgeInsets.all(
                                10.0,
                              ),

                              child: Row(

                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [

                                  // DOCTOR IMAGE
                                  CircleAvatar(

                                    radius: 50,

                                    backgroundImage:
                                        AssetImage(
                                      Doc['docPic'],
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  // DOCTOR DETAILS
                                  Expanded(

                                    child: Column(

                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [

                                        // NAME
                                        Text(
                                          Doc['DocName'],

                                          style:
                                              const TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 3,
                                        ),

                                        // SPECIALIST
                                        Text(
                                          Doc['specialist'],

                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.blueAccent,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 3,
                                        ),

                                        // RATING
                                        Row(

                                          children: [

                                            const Icon(
                                              Icons.star,

                                              color:
                                                  CupertinoColors
                                                      .systemYellow,

                                              size: 12,
                                            ),

                                            const SizedBox(
                                              width: 3,
                                            ),

                                            Text(
                                              Doc['Rating'],
                                            ),

                                            const SizedBox(
                                              width: 3,
                                            ),

                                            Text(
                                              Doc['Review'],

                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.blueGrey,
                                                fontSize:
                                                    10,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(
                                          height: 3,
                                        ),

                                        // EXPERIENCE
                                        Row(

                                          children: [

                                            const Icon(
                                              Icons.work_outline,

                                              color:
                                                  Colors.blueGrey,

                                              size: 10,
                                            ),

                                            const SizedBox(
                                              width: 3,
                                            ),

                                            Text(
                                              "${Doc['experience']} Years Experience",

                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.blueGrey,
                                                fontSize:
                                                    10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // AVAILABLE TODAY
                                  Card(

                                    color:
                                        const Color.fromARGB(
                                      255,
                                      221,
                                      220,
                                      220,
                                    ),

                                    child:
                                        const Padding(
                                      padding:
                                          EdgeInsets.all(
                                        8.0,
                                      ),

                                      child: Text(
                                        "Available Today",

                                        style:
                                            TextStyle(
                                          color:
                                              Colors.green,
                                          fontSize:
                                              12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // --------------------------------
                            // FEE + BOOK NOW
                            // --------------------------------

                            Padding(

                              padding:
                                  const EdgeInsets.all(
                                8.0,
                              ),

                              child: Row(

                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,

                                children: [

                                  // FEE
                                  Text(
                                    "\u20B9 ${Doc['fee']} Consultation Fee",

                                    style:
                                        const TextStyle(
                                      fontSize: 16,
                                      color:
                                          Colors.green,
                                    ),
                                  ),

                                  // BOOK NOW
                                  SizedBox(

                                    width: 120,

                                    child:
                                        ElevatedButton(

                                      onPressed: () {

                                        Navigator.push(

                                          context,

                                          MaterialPageRoute(

                                            builder:
                                                (context) =>
                                                    Doctordetail(
                                              doctor:
                                                  Doc,
                                            ),
                                          ),
                                        );
                                      },

                                      style:
                                          ElevatedButton
                                              .styleFrom(
                                        backgroundColor:
                                            const Color
                                                .fromARGB(
                                          255,
                                          9,
                                          115,
                                          202,
                                        ),

                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            7,
                                          ),
                                        ),
                                      ),

                                      child:
                                          const Text(
                                        "Book Now",

                                        style:
                                            TextStyle(
                                          fontSize:
                                              14,
                                          color:
                                              Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// CATEGORY ITEM
// ======================================================

Widget categoryItem(
  String image,
  String title,
) {

  return Padding(
    padding:
        const EdgeInsets.only(
      right: 10,
    ),

    child: Column(

      children: [

        SizedBox(
          width: 60,

          child: Card(

            child: Padding(

              padding:
                  const EdgeInsets.all(
                8.0,
              ),

              child: Image.asset(
                image,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        Text(
          title,

          style:
              const TextStyle(
            fontSize: 9,
          ),
        ),
      ],
    ),
  );
}