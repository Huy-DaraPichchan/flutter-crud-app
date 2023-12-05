class Todo {
  String id;
  final String description;
  late bool isCompleted;

  Todo({this.id = '', required this.description, required this.isCompleted});

  Map<String, dynamic> toJson() =>
      {'id': id, 'description': description, 'isCompleted': isCompleted};

  static Todo fromJson(Map<String, dynamic> json) => Todo(
      id: json['id'],
      description: json['description'],
      isCompleted: json['isCompleted']);
}
