class Product {
  final String uuid;
  final String title;

  Product(this.uuid, this.title);

  Map<String, dynamic> toMap({bool withId = false}) => {
        if (withId) 'uuid': uuid,
        'title': title,
      };

  static Product fromMap(Map map) => Product(
        map['uuid'],
        map['title'],
      );

  @override
  String toString() {
    return 'Product{uuid: $uuid, title: $title}';
  }
}
