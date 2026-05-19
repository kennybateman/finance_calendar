// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import '../../data/repositories/projections_repository.dart';
// DOMAIN
//import 'package:finance_calendar/domain/use_cases/helpers.dart';
import 'package:finance_calendar/domain/models/projection_read_only.dart';
import 'package:finance_calendar/domain/use_cases/generate_projections.dart';
// UI
import '../shared/read_list_page.dart';
import 'projection_details_page.dart';

class ProjectionsPage extends StatelessWidget {
  final ProjectionsRepository repo;
  final GenerateProjectionsUseCase generateProjections;
  const ProjectionsPage({
    super.key, 
    required this.repo,
    required this.generateProjections,
  });

  @override
  Widget build(BuildContext context) {

    /* stupid fucking hack to prevent exception when trying to load readonly models in bad state */
    Future<List<ProjectionReadModel>> tryGetAllReadModels() async {
      try {
        return (await repo.getAllReadModels()).toList();
      }
      catch(e){
        generateProjections.clearProjections();
        return [];
      }
    }

    Widget toTileWidget(ProjectionReadModel projection){
      return Text(projection.toString());
    }

    return ReadListPage<ProjectionReadModel>(
      getAll: tryGetAllReadModels,
      buildTileWidget: toTileWidget,
      preloadHook: generateProjections.generateProjections,
      detailPage: (ProjectionReadModel p) => ProjectionDetailPage(projection: p));
  }
}