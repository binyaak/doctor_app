import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Favourites extends StatefulWidget {
  const Favourites({super.key});

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> {
  // ------------------------------------------------------
  // DUMMY FAVORITE DOCTORS LIST
  // ------------------------------------------------------
  List<Map<String, dynamic>> favoriteDoctors = [
    {
      'name': 'Dr. Kiran Mathew',
      'specialist': 'Dental Specialist',
      'rating': '4.8',
      'reviews': '120',
      'experience': '8',
      'fee': '500',
      'image': 'asset/doc1.png',
    },
    {
      'name': 'Dr. Anjali Kishor',
      'specialist': 'Cardiologist',
      'rating': '4.9',
      'reviews': '250',
      'experience': '12',
      'fee': '700',
      'image': 'asset/doc2.png',
    },
    {
      'name': 'Dr. Rahul Varma',
      'specialist': 'Neurologist',
      'rating': '4.7',
      'reviews': '95',
      'experience': '10',
      'fee': '650',
      'image': 'asset/doc3.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      // --------------------------------------------------
      // APP BAR
      // --------------------------------------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite,
              color: Colors.redAccent,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              "Favorite Doctors",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color.fromARGB(255, 12, 103, 177),
              ),
            ),
          ],
        ),
      ),

      // --------------------------------------------------
      // BODY
      // --------------------------------------------------
      body: favoriteDoctors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 60,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No Favorite Doctors Yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Doctors you mark as favorite will appear here.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: favoriteDoctors.length,
              itemBuilder: (context, index) {
                final doc = favoriteDoctors[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(
                      color: Color.fromARGB(255, 230, 235, 240),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // DOCTOR IMAGE
                            CircleAvatar(
                              radius: 40,
                              backgroundColor:
                                  const Color.fromARGB(255, 186, 230, 238),
                              backgroundImage: AssetImage(doc['image']),
                            ),
                            const SizedBox(width: 12),

                            // DOCTOR DETAILS
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    doc['specialist'],
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // RATING & REVIEWS
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: CupertinoColors.systemYellow,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        doc['rating'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "(${doc['reviews']} Reviews)",
                                        style: const TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // EXPERIENCE
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.work_outline,
                                        color: Colors.blueGrey,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${doc['experience']} Years Experience",
                                        style: const TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // FAVORITE TOGGLE BUTTON
                            IconButton(
                              icon: const Icon(
                                Icons.favorite,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                final removedName = doc['name'];
                                setState(() {
                                  favoriteDoctors.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "$removedName removed from favorites"),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        // CONSULTATION FEE + BOOK BUTTON
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "\u20B9 ${doc['fee']} Fee",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 9, 115, 202),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text("Booking for ${doc['name']}"),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: const Text(
                                "Book Now",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}