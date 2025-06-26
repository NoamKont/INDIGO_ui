import 'package:flutter/material.dart';
import '../../services/admin/new_building_service.dart';

class AddNewBuildingScreen extends StatefulWidget {
  const AddNewBuildingScreen({super.key});

  @override
  State<AddNewBuildingScreen> createState() => _AddNewBuildingScreenState();
}

class _AddNewBuildingScreenState extends State<AddNewBuildingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _buildingNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final BuildingService _buildingService = BuildingService();

  bool _isLoading = false;

  @override
  void dispose() {
    _buildingNameController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  String get _fullAddress => '${_streetController.text.trim()}, ${_cityController.text.trim()}';

  bool get _isFormValid {
    return _buildingNameController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _streetController.text.trim().isNotEmpty;
  }

  Future<void> _createBuilding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final building = await _buildingService.createBuilding(
        name: _buildingNameController.text.trim(),
        address: _fullAddress,
      );

      if (mounted) {
        // Return the created building to the previous screen
        Navigator.pop(context, building);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Building "${building.name}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create building: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Building'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Building Name Field
              _buildInputField(
                controller: _buildingNameController,
                label: 'Building Name *',
                hint: 'Enter building name',
                icon: Icons.business,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Building name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // City Field
              _buildInputField(
                controller: _cityController,
                label: 'City *',
                hint: 'Enter city name',
                icon: Icons.location_city,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'City is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Street Field
              _buildInputField(
                controller: _streetController,
                label: 'Street Address *',
                hint: 'Enter street address',
                icon: Icons.place,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Street address is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // Done Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createBuilding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Required fields note
              const Text(
                '* Required fields',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: (_) => setState(() {}), // Update button state
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}