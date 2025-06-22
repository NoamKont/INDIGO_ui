import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:indigo_test/models/Room.dart';


class SvgFloorPlanPage extends StatefulWidget {
  const SvgFloorPlanPage({super.key});

  @override
  State<SvgFloorPlanPage> createState() => _SvgFloorPlanPageState();
}

class _SvgFloorPlanPageState extends State<SvgFloorPlanPage> {
  String? svgData;
  final List<Room> doors = [
    Room(id: 1, x: 200, y: 150),
    Room(id: 2, x: 400, y: 300),
    Room(id: 3, x: 600, y: 500),
  ];

  bool get allNamed =>
      doors.where((d) => d.name?.isNotEmpty ?? false).length >= doors.length - 2;

  @override
  void initState() {
    super.initState();
    _loadSvgFromServer();
  }

  Future<void> _loadSvgFromServer() async {
    final url = Uri.parse('https://example.com/floorplan.svg'); // replace with your real endpoint
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        svgData = response.body;
      });
    } else {
      // Handle error
    }
  }

  void _showNameDialog(Room door) {
    final controller = TextEditingController(text: door.name ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter door name'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                door.name = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (svgData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Label Rooms',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 16),

              // Floor Plan Viewer
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: InteractiveViewer(
                    minScale: 0.3,
                    maxScale: 5.0,
                    child: Stack(
                      children: [
                        SvgPicture.string(svgData!, width: 800, height: 800),
                        GestureDetector(
                          onTapDown: (details) {
                            final tap = details.localPosition;
                            for (var door in doors) {
                              final dx = door.x - tap.dx;
                              final dy = door.y - tap.dy;
                              if ((dx * dx + dy * dy) < 900) {
                                _showNameDialog(door);
                                break;
                              }
                            }
                          },
                          child: CustomPaint(
                            size: const Size(800, 800),
                            painter: DoorPainter(doors),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: allNamed ? () {} : null,
                  child: const Text("Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoorPainter extends CustomPainter {
  final List<Room> doors;
  DoorPainter(this.doors);

  @override
  void paint(Canvas canvas, Size size) {
    final hollow = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final filled = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    for (var door in doors) {
      final center = Offset(door.x, door.y);
      final paint = (door.name?.isNotEmpty ?? false) ? filled : hollow;
      canvas.drawCircle(center, 10, paint);

      if (door.name?.isNotEmpty ?? false) {
        final tp = TextPainter(
          text: TextSpan(
            text: door.name!,
            style: const TextStyle(color: Colors.green, fontSize: 14),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, center + const Offset(15, -10));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}