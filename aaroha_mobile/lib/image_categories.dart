// lib/utils/image_categories.dart
class ImageCategory {
  final String name;
  final List<String> images;

  ImageCategory({required this.name, required this.images});

  static List<ImageCategory> getAllCategories() {
    return [
      ImageCategory(
        name: 'Cat',
        images: [
          'assets/c1.jpg',
          'assets/c2.jpg',
          'assets/c3.jpg',
          'assets/c4.jpg',
        ],
      ),
      ImageCategory(
        name: 'Dog',
        images: [
          'assets/d1.jpg',
          'assets/d2.jpg',
          'assets/d3.jpg',
          'assets/d4.jpg',
        ],
      ),
      ImageCategory(
        name: 'Horse',
        images: [
          'assets/h1.jpg',
          'assets/h2.jpg',
          'assets/h3.jpg',
          'assets/h4.jpg',
        ],
      ),
      ImageCategory(
        name: 'Nature',
        images: [
          'assets/n1.jpg',
          'assets/n2.jpg',
          'assets/n3.jpg',
          'assets/n4.jpg',
        ],
      ),
      ImageCategory(
        name: 'Good Morning',
        images: [
          'assets/gm1.jpg',
          'assets/gm2.jpg',
          'assets/gm3.jpg',
          'assets/gm4.jpg',
        ],
      ),

    ];
  }
}