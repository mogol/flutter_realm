class Product {
  final String uuid;
  final String title;

  Product(this.uuid, this.title);

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'title': title,
      };

  static Product fromMap(Map map) => Product(
        map['uuid'],
        map['title'],
      );
}
