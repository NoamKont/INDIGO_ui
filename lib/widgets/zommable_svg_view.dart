import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';

class ZoomableSvgView extends StatelessWidget {
  final String rawSvg;

  const ZoomableSvgView({super.key, required this.rawSvg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PhotoView.customChild(
        childSize: const Size(800, 800),
        backgroundDecoration: const BoxDecoration(color: Colors.white),
        minScale: PhotoViewComputedScale.contained * 1.0,
        maxScale: PhotoViewComputedScale.covered * 3.0,
        child: SvgPicture.string(
          rawSvg,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
