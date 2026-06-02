import 'abstract_domain_model.dart';

class Settings extends DomainModel<Settings> {
  final bool darkMode;
  final double fontSize;
  Settings({
    required this.darkMode, 
    required this.fontSize, 
  });

  @override
  int? get pk => throw Exception("Not implemented");

  @override
  bool keyFieldsChanged(Settings other){
    return 
      darkMode != other.darkMode ||
      fontSize != other.fontSize;
  }
}