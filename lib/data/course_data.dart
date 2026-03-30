import 'package:cikgoo_math_ai/models/course_node.dart';

class CourseData {
  // Using 'static' means we can access this list anywhere in the app
  // without having to create a new instance of CourseData.
  static final List<CourseNode> levelOnePath = [
    CourseNode(id: "1", isRevision: false, alignX: -0.6),
    CourseNode(id: "2", isRevision: false, alignX: 0.1),
    CourseNode(id: "3", isRevision: false, alignX: 0.5),
    CourseNode(id: "4", isRevision: false, alignX: -0.2),
    CourseNode(id: "5", isRevision: true, alignX: -0.5),
  ];

  // You can easily add more levels here later!
  static final List<CourseNode> levelTwoPath = [
    // ... more nodes here
  ];
}