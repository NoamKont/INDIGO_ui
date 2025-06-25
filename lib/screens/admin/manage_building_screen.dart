import 'package:flutter/material.dart';
import 'package:indigo_test/services/admin/admin_service.dart';

import '../../models/Building.dart';
import '../../services/admin/new_building_service.dart';
import '../../screens/admin/yaml_form_screen.dart';
import '../add_new_building.dart';
import 'admin_building_card.dart';


class ManageBuildingsPage extends StatefulWidget {
  const ManageBuildingsPage({super.key});

  @override
  State<ManageBuildingsPage> createState() => _ManageBuildingsPageState();
}

class _ManageBuildingsPageState extends State<ManageBuildingsPage> {
  List<Building> buildings = [];

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top:16,bottom: 16, left: 6, right: 6),
          child: Column(
            children: [
              _buildTopPanel(context),
              const SizedBox(height: 16),
              _buildExistingBuildingsLabel(),
              const SizedBox(height: 10),
              _buildBuildingList(),
              const SizedBox(height: 16),
              _buildAddButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadBuildings() async {
    final result = await AdminService().getUserBuildings();
    setState(() {
      buildings = result;
    });
  }

  Widget _buildTopPanel(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        const Text(
          'Manage Buildings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // TODO: Handle settings button tap
          },
        ),
      ],
    );
  }

  Widget _buildExistingBuildingsLabel() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Existing Buildings',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF7F7F7F),
        ),
      ),
    );
  }

  Widget _buildBuildingList() {
    return Expanded(
      child: ListView.builder(
        itemCount: buildings.length,
        itemBuilder: (context, index) {
          final building = buildings[index];
          return AdminBuildingCard(building: building);
        }
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF225FFF),
          foregroundColor: Colors.white,
        ),
        onPressed: () => _handleAddBuilding(context),
        child: const Text('+ Add New Building'),
      ),
    );
  }

  Future<void> _handleAddBuilding(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddNewBuildingScreen(),
      ),
    ).then((newBuilding) {
      if (newBuilding != null) {
        // Handle the newly created building
        // Add it to your buildings list and refresh UI
        _loadBuildings();
      }
    });
    // final file = await BuildingService().pickDwgFile();
    // if (file != null) {
    //   final yaml = await Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (_) => YamlDetailsForm(dwgFile: file),
    //     ),
    //   );
    //   if (yaml != null) {
    //     print('YAML returned:');
    //     print(yaml);
    //     // TODO: Send YAML and DWG to server
    //   }
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('No file selected')),
    //   );
    // }
  }


}
