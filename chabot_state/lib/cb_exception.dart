class CBContractNotFoundException implements Exception  {

}

class CBPresenterNotFoundException implements Exception  {

}

class CBServiceNotFoundException implements Exception  {

}

class CBPresenterContextException implements Exception  {

}

class CBPresenterContractException implements Exception {
  final String message;

  CBPresenterContractException(this.message);

  @override
  String toString() {
    return 'CBPresenterContractException{message: $message}';
  }
}

