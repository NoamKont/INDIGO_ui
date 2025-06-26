import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:indigo_test/screens/admin/yaml_form_screen.dart';
import '../../models/Building.dart';
import 'package:indigo_test/screens/user/navigate_screen.dart';

import '../../services/admin/new_building_service.dart';
import '../../widgets/admin_floor_view.dart';
import 'calibration_screen.dart';

class AdminBuildingCard extends StatelessWidget {
  final Building building;
  final VoidCallback? onTap; // Nullable in case it's optional

  const AdminBuildingCard({
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
              builder: (context) => AdminFloorView(buildingName: building.name, buildingId: building.buildingId),
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
            color: Colors.grey.shade200,
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: SvgPicture.asset(
              'assets/icons/building.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          building.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(building.address),
        trailing: _MoreOptionsMenu(building: building,),
      ),
    );
  }
}

class _MoreOptionsMenu extends StatelessWidget {
  final Building building;

  const _MoreOptionsMenu({
    super.key,
    required this.building,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More options',
      onSelected: (value) => _handleSelection(context, value),
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(
          value: 'add',
          child: _MenuItemWithIcon(icon: Icons.add, text: 'Add Floor'),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: _MenuItemWithIcon(icon: Icons.edit, text: 'Edit Floors'),
        ),
        const PopupMenuItem(
          value: 'calibrate',
          child: _MenuItemWithIcon(icon: Icons.compass_calibration, text: 'Calibrate floor plan'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: _MenuItemWithIcon(icon: Icons.delete, text: 'Delete Building'),
        ),
      ],
    );
  }

  Future<void> _handleSelection(BuildContext context, String value) async {
    switch (value) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit pressed')),
        );
        break;
      case 'delete':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete pressed')),
        );
        break;
      case 'add':
        final file = await BuildingService().pickDwgFile();
        if (file != null) {
          final yaml = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YamlDetailsForm(dwgFile: file.name),
            ),
          );
          if (yaml != null) {
            print('YAML returned:');
            print(yaml);
            // TODO: Send YAML and DWG to server
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file selected')),
          );
        }
        break;
        case 'calibrate':
        // Navigate to calibration screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalibrationScreen(
                buildingName: building.name,
                buildingId: building.buildingId,
              ),
            ),
          );
        break;
    }
  }
}

class _MenuItemWithIcon extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MenuItemWithIcon({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
