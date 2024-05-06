enum Operation { operation }

class Result {
  static String complete = "Complete";

  static String error = "error";

  bool isPartialTask(String taskIdentifier) {
    return taskIdentifier.contains("${Operation.operation}_");
  }

  String setTaskResult(String taskIdentifier) {
    return "${Operation.operation}_$taskIdentifier";
  }
}
