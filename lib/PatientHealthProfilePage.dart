import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientHealthProfilePage extends StatefulWidget {
  const PatientHealthProfilePage({super.key});

  @override
  State<PatientHealthProfilePage> createState() =>
      _PatientHealthProfilePageState();
}

class _PatientHealthProfilePageState extends State<PatientHealthProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Text Controllers for the 11 Health Profile Fields
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bloodPressureController =
      TextEditingController();
  final TextEditingController _healthConditionController =
      TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _medicalHistoryController =
      TextEditingController();
  final TextEditingController _emergencyContactNameController =
      TextEditingController();
  final TextEditingController _emergencyContactPhoneController =
      TextEditingController();

  // Dropdown options for Blood Group
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  String? _selectedBloodGroup;

  // State flags
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = true; // Enabled when entering or editing data
  bool _hasSavedData = false;

  // Calculated BMI value
  String _calculatedBmi = "--";

  @override
  void initState() {
    super.initState();
    _loadHealthProfile();

    // Recalculate BMI in real-time when height or weight changes
    _heightController.addListener(_calculateBmi);
    _weightController.addListener(_calculateBmi);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bloodPressureController.dispose();
    _healthConditionController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _medicalHistoryController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // BMI CALCULATION: weight (kg) / [height (m)]^2
  // --------------------------------------------------------------------------
  void _calculateBmi() {
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();

    final double? heightCm = double.tryParse(heightText);
    final double? weightKg = double.tryParse(weightText);

    if (heightCm != null &&
        weightKg != null &&
        heightCm > 0 &&
        weightKg > 0) {
      final double heightMeters = heightCm / 100.0;
      final double bmi = weightKg / (heightMeters * heightMeters);

      setState(() {
        _calculatedBmi = bmi.toStringAsFixed(1);
      });
    } else {
      if (_calculatedBmi != "--") {
        setState(() {
          _calculatedBmi = "--";
        });
      }
    }
  }

  // --------------------------------------------------------------------------
  // LOAD EXISTING HEALTH PROFILE FROM FIRESTORE
  // --------------------------------------------------------------------------
  Future<void> _loadHealthProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data();

        if (data != null) {
          _ageController.text = data['age']?.toString() ?? "";
          _heightController.text = data['height']?.toString() ?? "";
          _weightController.text = data['weight']?.toString() ?? "";
          _bloodPressureController.text = data['bloodPressure'] ?? "";

          final bloodGroupFromDb = data['bloodGroup']?.toString();
          if (bloodGroupFromDb != null &&
              _bloodGroups.contains(bloodGroupFromDb)) {
            _selectedBloodGroup = bloodGroupFromDb;
          }

          _healthConditionController.text = data['healthCondition'] ?? "";
          _allergiesController.text = data['allergies'] ?? "";
          _medicationsController.text = data['medications'] ?? "";
          _medicalHistoryController.text = data['medicalHistory'] ?? "";
          _emergencyContactNameController.text =
              data['emergencyContactName'] ?? "";
          _emergencyContactPhoneController.text =
              data['emergencyContactPhone'] ?? "";

          // Check if any health info is present
          final hasData = _ageController.text.isNotEmpty ||
              _heightController.text.isNotEmpty ||
              _weightController.text.isNotEmpty ||
              _selectedBloodGroup != null ||
              _healthConditionController.text.isNotEmpty;

          setState(() {
            _hasSavedData = hasData;
            // If data already exists, start in view mode with Edit option
            _isEditing = !hasData;
            _isLoading = false;
          });

          _calculateBmi();
          return;
        }
      }

      setState(() {
        _isEditing = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage("Error loading health profile: $e", isError: true);
    }
  }

  // --------------------------------------------------------------------------
  // SAVE / UPDATE HEALTH PROFILE IN FIRESTORE
  // --------------------------------------------------------------------------
  Future<void> _saveHealthProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage("Please log in to save your health profile", isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Merge with existing user document to avoid overwriting name/email/phone
      await _firestore.collection('users').doc(user.uid).set({
        'age': _ageController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'bloodPressure': _bloodPressureController.text.trim(),
        'bloodGroup': _selectedBloodGroup ?? '',
        'healthCondition': _healthConditionController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'medicalHistory': _medicalHistoryController.text.trim(),
        'emergencyContactName': _emergencyContactNameController.text.trim(),
        'emergencyContactPhone': _emergencyContactPhoneController.text.trim(),
      }, SetOptions(merge: true));

      setState(() {
        _isSaving = false;
        _isEditing = false;
        _hasSavedData = true;
      });

      _showMessage("Health Profile saved successfully!");
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showMessage("Failed to save health profile: $e", isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Patient Health Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Edit option toggle if data is already saved
          if (!_isLoading && _hasSavedData)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
              icon: Icon(
                _isEditing ? Icons.visibility : Icons.edit,
                color: Colors.blue,
                size: 18,
              ),
              label: Text(
                _isEditing ? "View" : "Edit",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ========================================================
                    // TOP BANNER / STATUS CARD
                    // ========================================================
                    _buildHeaderCard(),

                    const SizedBox(height: 16),

                    // ========================================================
                    // BMI DISPLAY CARD
                    // ========================================================
                    _buildBmiCard(),

                    const SizedBox(height: 20),

                    // ========================================================
                    // SECTION 1: PHYSICAL METRICS
                    // ========================================================
                    _buildSectionHeader("Physical Metrics", Icons.straighten),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        // Age
                        Expanded(
                          child: _buildTextField(
                            controller: _ageController,
                            label: "Age",
                            hint: "e.g. 28",
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                            enabled: _isEditing,
                            validator: (val) {
                              if (val != null && val.isNotEmpty) {
                                final age = int.tryParse(val);
                                if (age == null || age <= 0 || age > 130) {
                                  return "Enter valid age";
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Blood Group Dropdown
                        Expanded(
                          child: _buildBloodGroupDropdown(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        // Height (cm)
                        Expanded(
                          child: _buildTextField(
                            controller: _heightController,
                            label: "Height (cm)",
                            hint: "e.g. 175",
                            icon: Icons.height,
                            keyboardType: TextInputType.number,
                            enabled: _isEditing,
                            validator: (val) {
                              if (val != null && val.isNotEmpty) {
                                final height = double.tryParse(val);
                                if (height == null || height <= 0 || height > 300) {
                                  return "Enter valid height";
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Weight (kg)
                        Expanded(
                          child: _buildTextField(
                            controller: _weightController,
                            label: "Weight (kg)",
                            hint: "e.g. 70",
                            icon: Icons.monitor_weight_outlined,
                            keyboardType: TextInputType.number,
                            enabled: _isEditing,
                            validator: (val) {
                              if (val != null && val.isNotEmpty) {
                                final weight = double.tryParse(val);
                                if (weight == null || weight <= 0 || weight > 500) {
                                  return "Enter valid weight";
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Blood Pressure
                    _buildTextField(
                      controller: _bloodPressureController,
                      label: "Blood Pressure",
                      hint: "e.g. 120/80 mmHg",
                      icon: Icons.favorite_border,
                      keyboardType: TextInputType.text,
                      enabled: _isEditing,
                    ),

                    const SizedBox(height: 20),

                    // ========================================================
                    // SECTION 2: MEDICAL CONDITIONS & MEDICATIONS
                    // ========================================================
                    _buildSectionHeader(
                        "Medical Conditions", Icons.medical_services_outlined),
                    const SizedBox(height: 10),

                    // Health Condition / Existing Diseases
                    _buildTextField(
                      controller: _healthConditionController,
                      label: "Health Condition / Existing Diseases",
                      hint: "e.g. Hypertension, Diabetes, Asthma (or None)",
                      icon: Icons.healing_outlined,
                      keyboardType: TextInputType.text,
                      maxLines: 2,
                      enabled: _isEditing,
                    ),

                    const SizedBox(height: 12),

                    // Allergies
                    _buildTextField(
                      controller: _allergiesController,
                      label: "Allergies",
                      hint: "e.g. Penicillin, Peanuts, Pollen (or None)",
                      icon: Icons.warning_amber_outlined,
                      keyboardType: TextInputType.text,
                      maxLines: 2,
                      enabled: _isEditing,
                    ),

                    const SizedBox(height: 12),

                    // Current Medications
                    _buildTextField(
                      controller: _medicationsController,
                      label: "Current Medications",
                      hint: "e.g. Metformin 500mg, Aspirin 75mg daily",
                      icon: Icons.medication_outlined,
                      keyboardType: TextInputType.text,
                      maxLines: 2,
                      enabled: _isEditing,
                    ),

                    const SizedBox(height: 12),

                    // Medical History
                    _buildTextField(
                      controller: _medicalHistoryController,
                      label: "Medical History",
                      hint: "Past surgeries, chronic conditions, hospitalizations",
                      icon: Icons.history_outlined,
                      keyboardType: TextInputType.text,
                      maxLines: 3,
                      enabled: _isEditing,
                    ),

                    const SizedBox(height: 20),

                    // ========================================================
                    // SECTION 3: EMERGENCY CONTACT
                    // ========================================================
                    _buildSectionHeader(
                        "Emergency Contact", Icons.contact_phone_outlined),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _emergencyContactNameController,
                      label: "Emergency Contact Name",
                      hint: "e.g. Sarah Doe (Spouse/Parent)",
                      icon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                      enabled: _isEditing,
                    ),

                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _emergencyContactPhoneController,
                      label: "Emergency Contact Phone Number",
                      hint: "e.g. +91 9876543210",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      enabled: _isEditing,
                      validator: (val) {
                        if (val != null && val.isNotEmpty) {
                          if (val.length < 7) {
                            return "Enter a valid phone number";
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // ========================================================
                    // ACTION BUTTONS (Save / Edit)
                    // ========================================================
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveHealthProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline,
                                  color: Colors.white),
                          label: Text(
                            _isSaving ? "Saving Profile..." : "Save Health Profile",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          label: const Text(
                            "Edit Health Profile",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET BUILDERS
  // --------------------------------------------------------------------------

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffEEF3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blue.shade100,
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.blue,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasSavedData
                      ? (_isEditing
                          ? "Editing Health Profile"
                          : "Saved Health Profile")
                      : "New Health Profile",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0C67B1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _hasSavedData && !_isEditing
                      ? "Your health details are saved. Tap 'Edit' to update."
                      : "Enter your health details to share with consulting doctors.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBmiCard() {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.speed,
                color: Colors.blue,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Body Mass Index (BMI)",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "BMI: $_calculatedBmi",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            if (_calculatedBmi == "--")
              Text(
                "Enter height & weight",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      validator: validator,
      style: TextStyle(
        color: enabled ? Colors.black87 : Colors.grey.shade700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.blue.shade700, size: 22),
        filled: !enabled,
        fillColor: enabled ? Colors.transparent : Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildBloodGroupDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedBloodGroup,
      decoration: InputDecoration(
        labelText: "Blood Group",
        prefixIcon:
            Icon(Icons.bloodtype_outlined, color: Colors.blue.shade700, size: 22),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: !_isEditing,
        fillColor: _isEditing ? Colors.transparent : Colors.grey.shade100,
      ),
      items: _bloodGroups.map((group) {
        return DropdownMenuItem<String>(
          value: group,
          child: Text(group),
        );
      }).toList(),
      onChanged: _isEditing
          ? (val) {
              setState(() {
                _selectedBloodGroup = val;
              });
            }
          : null,
      hint: const Text("Select"),
    );
  }
}
