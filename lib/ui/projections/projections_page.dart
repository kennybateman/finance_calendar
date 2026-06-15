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

import 'dart:developer' as dev;

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

    Future<void> preloadHook() async {
      final projections = await repo.getAll();
      if (projections.isEmpty){
        await generateProjections.generateInitialProjections();
      }
    }

    Widget toTileWidget(Projection projection, double scale){
      return Text(
        projection.toString(), 
        style: TextStyle(fontSize: 16 * scale)
      );
    }

    return CrudListPage<Projection>(
      preloadHook: preloadHook,
      preloadHookFailHandler: generateProjections.clearProjections,
      settingsRepo: settingsRepo,
      getAll: repo.getAll,
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