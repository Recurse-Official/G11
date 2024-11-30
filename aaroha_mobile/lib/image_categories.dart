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
          'https://placekitten.com/200/300',
          'https://placekitten.com/201/301',
          'https://placekitten.com/202/302',
          'https://placekitten.com/203/303',
          'https://placekitten.com/204/304',
        ],
      ),
      ImageCategory(
        name: 'Dog',
        images: [
          'https://place.dog/300/200',
          'https://place.dog/300/201',
          'https://place.dog/300/202',
          'https://place.dog/300/203',
          'https://place.dog/300/204',
        ],
      ),
      ImageCategory(
        name: 'Horse',
        images: [
          'https://placehold.co/300x200?text=Horse1',
          'https://placehold.co/300x200?text=Horse2',
          'https://placehold.co/300x200?text=Horse3',
          'https://placehold.co/300x200?text=Horse4',
          'https://placehold.co/300x200?text=Horse5',
        ],
      ),
      ImageCategory(
        name: 'Good Morning',
        images: [
          'https://placehold.co/300x200?text=GoodMorning1',
          'https://placehold.co/300x200?text=GoodMorning2',
          'https://placehold.co/300x200?text=GoodMorning3',
          'https://placehold.co/300x200?text=GoodMorning4',
          'https://placehold.co/300x200?text=GoodMorning5',
        ],
      ),
      ImageCategory(
        name: 'Good Night',
        images: [
          'https://placehold.co/300x200?text=GoodNight1',
          'https://placehold.co/300x200?text=GoodNight2',
          'https://placehold.co/300x200?text=GoodNight3',
          'https://placehold.co/300x200?text=GoodNight4',
          'https://placehold.co/300x200?text=GoodNight5',
        ],
      ),
      ImageCategory(
        name: 'Nature',
        images: [
          'https://placehold.co/300x200?text=Nature1',
          'https://placehold.co/300x200?text=Nature2',
          'https://placehold.co/300x200?text=Nature3',
          'https://placehold.co/300x200?text=Nature4',
          'https://placehold.co/300x200?text=Nature5',
        ],
      ),
    ];
  }
}