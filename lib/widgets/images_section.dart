import 'package:flutter/material.dart';
import '../pages/image_gallery_page.dart';

class ImagesSection extends StatelessWidget {
  final List<String> imageUrls;

  const ImagesSection({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => ImageGalleryViewer(
                  imageUrls: imageUrls,
                  initialIndex: index,
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                imageUrls[index],
                width: 260,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 260,
                  height: 160,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}