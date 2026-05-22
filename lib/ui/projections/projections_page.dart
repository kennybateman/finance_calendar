// Dart and Flutter
import 'package:flutter/material.dart';
// DATA
import '../../data/repositories/projections_repository.dart';
// DOMAIN
//import 'package:finance_calendar/domain/use_cases/helpers.dart';
import 'package:finance_calendar/domain/models/projection_read_only.dart';
import 'package:finance_calendar/domain/use_cases/generate_projections.dart';
// UI
import '../shared/crud_list_page.dart';
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

    Widget toTileWidget(ProjectionReadModel projection, double scale){
      return Text(
        projection.toString(), 
        style: TextStyle(fontSize: 16 * scale)
      );
    }

    return CrudListPage<ProjectionReadModel>(
      preloadHook: generateProjections.generateProjections,
      preloadHookFailHandler: generateProjections.clearProjections,
      getAll: tryGetAllReadModels,
      buildTileWidget: toTileWidget,
      useAddButton: false,
      detailPage: (ProjectionReadModel p) => ProjectionDetailPage(
        projection: p
      )
    );
  }
}