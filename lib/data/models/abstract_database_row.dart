abstract class DatabaseRow {
  final int? pk;
  DatabaseRow({this.pk});
}

extension ListX<T extends DatabaseRow> on List<T>{
  Map<int?, T?> mapByPk(){
    return {for (final item in this) item.pk: item};
  }
}
