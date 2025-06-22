import 'package:flutter/material.dart';
import 'package:indigo_test/services/user/home_screen_service.dart';
import '../../models/Building.dart';
import '../../widgets/google_map.dart';
import '../../widgets/menu_bar.dart';
import 'building_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Building> buildings = [];

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(),
      body: SafeArea(
        child: Column(
          children: [
            TopBar(),
            SizedBox(height: 350,child: MapPage()),
            _buildBuildingList()
          ],
        ),
      ),
    );
  }

  Future<void> _loadBuildings() async {
    final result = await HomeService().getALLBuildings();
    setState(() {
      buildings = result;
    });
  }

  Widget _buildBuildingList() {
    return Expanded(
      child: ListView.builder(
          itemCount: buildings.length,
          itemBuilder: (context, index) {
            final building = buildings[index];
            return BuildingCard(building: building);
          }
      ),
    );
  }
}