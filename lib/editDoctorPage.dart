import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditDoctorPage extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;

  const EditDoctorPage({
    super.key,
    required this.doctorId,
    required this.doctorData,
  });

  @override
  State<EditDoctorPage> createState() => _EditDoctorPageState();
}

class _EditDoctorPageState extends State<EditDoctorPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController specialistController;
  late TextEditingController experienceController;
  late TextEditingController ratingController;
  late TextEditingController reviewController;
  late TextEditingController feeController;
  late TextEditingController customImageController;

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
    final data = widget.doctorData;

    nameController = TextEditingController(text: data['DocName'] ?? '');
    specialistController = TextEditingController(text: data['specialist'] ?? '');
    experienceController = TextEditingController(text: data['experience']?.toString() ?? '');
    ratingController = TextEditingController(text: data['Rating']?.toString() ?? '5.0');
    reviewController = TextEditingController(text: data['Review']?.toString() ?? '100');
    feeController = TextEditingController(text: data['fee']?.toString() ?? '');

    final existingPic = data['docPic']?.toString() ?? 'asset/doc1.png';
    if (defaultAvatars.contains(existingPic)) {
      selectedImage = existingPic;
      customImageController = TextEditingController();
    } else {
      selectedImage = defaultAvatars[0];
      customImageController = TextEditingController(text: existingPic);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    specialistController.dispose();
    experienceController.dispose();
    ratingController.dispose();
    reviewController.dispose();
    feeController.dispose();
    customImageController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // UPDATE DOCTOR IN FIRESTORE
  // ----------------------------------------------------
  Future<void> updateDoctor() async {
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
      // Update the EXISTING doctor document without creating a new one
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .update({
        'DocName': nameController.text.trim(),
        'specialist': specialistController.text.trim(),
        'experience': experienceController.text.trim(),
        'Rating': ratingController.text.trim(),
        'Review': reviewController.text.trim(),
        'fee': feeController.text.trim(),
        'docPic': imagePath,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Doctor updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update doctor: $e"),
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
          "Edit Doctor",
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
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Please enter doctor name" : null,
              ),

              const SizedBox(height: 14),

              // Specialization
              TextFormField(
                controller: specialistController,
                decoration: InputDecoration(
                  labelText: "Specialization *",
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

              // Experience & Fee
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: experienceController,
                      decoration: InputDecoration(
                        labelText: "Experience *",
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

              // Rating & Review
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: ratingController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Rating *",
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
                        prefixIcon: const Icon(Icons.rate_review_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Enter reviews" : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Update Button
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
                  onPressed: isSaving ? null : updateDoctor,
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
                          "Update Doctor",
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
