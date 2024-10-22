import 'dart:collection';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class TaskQuee {
  // singleton
  TaskQuee._privateConstructor();
  static final TaskQuee _instance = TaskQuee._privateConstructor();
  factory TaskQuee() {
    return _instance;
  }

  DoubleLinkedQueue<Function> linkedList = DoubleLinkedQueue();
  bool downloading = false;

  void addTask(Function task) {
    linkedList.add(task);
  }

  void startQuee() {
    if (downloading == true) return;
    while (linkedList.isNotEmpty) {
      downloading = true;
      linkedList.first();
      linkedList.removeFirst();
    }
    downloading = false;
  }
}
