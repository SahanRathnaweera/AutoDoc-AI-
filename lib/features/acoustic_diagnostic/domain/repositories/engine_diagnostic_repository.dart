import 'package:dartz/dartz.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/acoustic_diagnostic/domain/entities/engine_diagnostic_entity.dart';

abstract class EngineDiagnosticRepository {
  Future<Either<Failure, List<EngineDiagnosticEntity>>> getDiagnosticsByInspection(String inspectionId);
  Future<Either<Failure, String>> saveDiagnosticResult(EngineDiagnosticEntity diagnostic);
  Stream<List<EngineDiagnosticEntity>> streamDiagnostics(String inspectionId);
}
