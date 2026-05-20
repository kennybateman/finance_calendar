abstract class DomainModel<T extends DomainModel<T>> {
  int? get pk;
  bool keyFieldsChanged(T other);
}

Map<int?, T?> mapByPk<T extends DomainModel<T>>(List<T> records){
  Map<int?, T?> map = { null: null };
  for (T record in records){
    map[record.pk] = record;
  }
  return map;
}