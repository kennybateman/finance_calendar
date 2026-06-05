// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import '../../data/repositories/projections_repository.dart';
import '../../data/repositories/settings_repository.dart';
// DOMAIN
//import 'package:finance_calendar/domain/use_cases/helpers.dart';
import 'package:finance_calendar/domain/models/projection.dart';
import 'package:finance_calendar/domain/use_cases/generate_projections.dart';
// UI
import '../shared/crud_list_page.dart';
import 'projection_details_page.dart';

class ProjectionsPage extends StatelessWidget {
  final ProjectionsRepository repo;
  final GenerateProjectionsUseCase generateProjections;
  final SettingsRepository settingsRepo;
  const ProjectionsPage({
    super.key, 
    required this.repo,
    required this.generateProjections,
    required this.settingsRepo,
  });

  @override
  Widget build(BuildContext context) {

    /* stupid fucking hack to prevent exception when trying to load readonly models in bad state */
    Future<List<Projection>> tryGetAllReadModels() async {
      try {
        return (await repo.getAll()).toList();
      }
      catch(e){
        generateProjections.clearProjections();
        return [];
      }
    }

    Widget toTileWidget(Projection projection, double scale){
      return Text(
        projection.toString(), 
        style: TextStyle(fontSize: 16 * scale)
      );
    }

    return CrudListPage<Projection>(
      settingsRepo: settingsRepo,
      getAll: tryGetAllReadModels,
      getMoreAfter: repo.getAllAfter,
      scrollToBottomHandler: generateProjections.generateMoreProjections,
      buildTileWidget: toTileWidget,
      useAddButton: false,
      detailPage: (Projection p) => ProjectionDetailPage(
        projection: p,
        settingsRepo: settingsRepo,
      )
    );
  }
}