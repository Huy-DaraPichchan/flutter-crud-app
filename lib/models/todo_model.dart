class Todo {
  String id;
  final String description;
  late bool isCompleted;
  late bool isEdited;

  Todo({this.id = '', required this.description, required this.isCompleted, required this.isEdited});

  Map<String, dynamic> toJson() =>
      {'id': id, 'description': description, 'isCompleted': isCompleted, 'isEdited': isEdited};

  static Todo fromJson(Map<String, dynamic> json) => Todo(
      id: json['id'],
      description: json['description'],
      isCompleted: json['isCompleted'],
      isEdited: json['isEdited']);
}
