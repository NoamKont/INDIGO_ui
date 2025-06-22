import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../models/Building.dart';
import 'package:indigo_test/screens/user/navigate_screen.dart';

class BuildingCard extends StatelessWidget {
  final Building building;
  final VoidCallback? onTap; // Nullable in case it's optional

  const BuildingCard({
    super.key,
    required this.building,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SvgZoomView(buildingName: building.name, buildingId: building.buildingId),
            ),
          );
          // final svgBytes = await FloorService.fetchSvgFromUrlWithCache(building.buildingId);
          // if (svgBytes != null) {
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (_) => SvgZoomViewFromBytes(svgBytes: svgBytes),
          //     ),
          //   );
          // } else {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(content: Text("Failed to load floorplan")),
          //   );
          // }
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200, // Optional background color
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0), // Adjust as needed
            child: SvgPicture.asset(
              'assets/icons/building.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(building.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(building.address),
      ),
    );
  }
}