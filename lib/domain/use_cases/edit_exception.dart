class EditException implements Exception{
  final String message;

  EditException(this.message);

  @override
  String toString() => message;
}