abstract class DomainModel{
  final int? pk;
  DomainModel({this.pk});
}

Map<int?, T?> mapByPk<T extends DomainModel>(List<T> records){
  Map<int?, T?> map = { null: null };
  for (T record in records){
    map[record.pk] = record;
  }
  return map;
}