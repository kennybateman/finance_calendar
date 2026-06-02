import '../../domain/models/settings.dart';
import '../services/settings_wrapper.dart';
import 'abstract_repository.dart';

class SettingsRepository implements Repository<Settings>{
  final SettingsWrapper settingsWrapper;
  SettingsRepository({
    required this.settingsWrapper,
  });

  Settings getSettings() {
    final darkMode = settingsWrapper.getDarkMode();
    final fontSize = settingsWrapper.getFontSize();
    return Settings(darkMode: darkMode, fontSize: fontSize);
  }

  void updateSettings(Settings updatedSettings) {
    settingsWrapper.setDarkMode(updatedSettings.darkMode);
    settingsWrapper.setFontSize(updatedSettings.fontSize);
  }

  @override
  Future<List<Settings>> getAll() async {
    throw Exception("Not implemented");
  }
  @override
  Future<Settings> createNew(Settings _){
    throw Exception("Not implemented");
  }
  @override
  Future<Settings> saveChanges(Settings _){
    throw Exception("Not implemented");
  }
  @override
  Future<void> delete(Settings _){
    throw Exception("Not implemented");
  }
}