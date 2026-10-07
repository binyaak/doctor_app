import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddDoctorPage extends StatefulWidget {
  const AddDoctorPage({super.key});

  @override
  State<AddDoctorPage> createState() => _AddDoctorPageState();
}

class _AddDoctorPageState extends State<AddDoctorPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController specialistController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController ratingController = TextEditingController(text: "5.0");
  final TextEditingController reviewController = TextEditingController(text: "100");
  final TextEditingController feeController = TextEditingController();
  final TextEditingController customImageController = TextEditingController();

  final List<String> defaultAvatars = [
    'asset/doc1.png',
    'asset/doc2.png',
    'asset/doc3.png',
  ];

  late String selectedImage;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    selectedImage = defaultAvatars[0];
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    specialistController.dispose();
    experienceController.dispose();
    ratingController.dispose();
    reviewController.dispose();
    feeController.dispose();
    customImageController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // SAVE DOCTOR TO FIRESTORE
  // ----------------------------------------------------
  Future<void> saveDoctor() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    final imagePath = customImageController.text.trim().isNotEmpty
        ? customImageController.text.trim()
        : selectedImage;

    try {
      // Save doctor document using the EXACT field names expected across the app
      await FirebaseFirestore.instance.collection('doctors').add({
        'DocName': nameController.text.trim(),
        'email': emailController.text.trim(),
        'specialist': specialistController.text.trim(),
        'experience': experienceController.text.trim(),
        'Rating': ratingController.text.trim(),
        'Review': reviewController.text.trim(),
        'fee': feeController.text.trim(),
        'docPic': imagePath,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Doctor added successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add doctor: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Doctor",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar selector
              const Text(
                "Select Doctor Avatar",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: defaultAvatars.map((path) {
                  final isSelected = selectedImage == path &&
                      customImageController.text.trim().isEmpty;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedImage = path;
                        customImageController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                          width: isSelected ? 3 : 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: AssetImage(path),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Optional custom image path
              TextFormField(
                controller: customImageController,
                decoration: InputDecoration(
                  labelText: "Custom Image Path (optional)",
                  hintText: "e.g. asset/doc1.png",
                  prefixIcon: const Icon(Icons.image_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 20),

              // Doctor Name
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Doctor Name *",
                  hintText: "Dr. Jane Doe",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Please enter doctor name" : null,
              ),

              const SizedBox(height: 14),

              // Doctor Email
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Doctor Email *",
                  hintText: "doctor@example.com",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Please enter email";
                  }
                  if (!v.contains('@')) {
                    return "Please enter a valid email";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Specialization
              TextFormField(
                controller: specialistController,
                decoration: InputDecoration(
                  labelText: "Specialization *",
                  hintText: "Cardiologist, Dentist, Pediatric...",
                  prefixIcon: const Icon(Icons.medical_information_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? "Please enter specialization"
                    : null,
              ),

              const SizedBox(height: 14),

              // Experience & Fee in a row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: experienceController,
                      decoration: InputDecoration(
                        labelText: "Experience *",
                        hintText: "5 Years",
                        prefixIcon: const Icon(Icons.work_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? "Enter experience"
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: feeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Consultation Fee *",
                        hintText: "500",
                        prefixIcon: const Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Enter fee" : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Rating & Review in a row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: ratingController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Rating *",
                        hintText: "4.8",
                        prefixIcon: const Icon(Icons.star_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Enter rating" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: reviewController,
                      decoration: InputDecoration(
                        labelText: "Reviews Count *",
                        hintText: "120",
                        prefixIcon: const Icon(Icons.rate_review_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Enter review count" : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSaving ? null : saveDoctor,
                  child: isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Save Doctor",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
