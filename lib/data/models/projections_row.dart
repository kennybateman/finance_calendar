// ignore_for_file: non_constant_identifier_names
import 'abstract_database_row.dart';

class ProjectionsRow implements DatabaseRow {
  @override 
  final int? pk;
  final String date;

  ProjectionsRow({
    this.pk, 
    required this.date});

  static ProjectionsRow fromMap(Map<String, Object?> map) {
    return ProjectionsRow(
      pk: map['pk'] as int,
      date: map['date'] as String,
    );
  }

  static Map<String, Object?> toMap(ProjectionsRow row){
    return { 
      'pk': row.pk, 
      'date': row.date 
    };
  }
}
