import 'package:collection/collection.dart';
import 'package:fpdart/fpdart.dart';
import 'package:roozaneh/core/http_client/dio_http_client.dart';
import 'package:roozaneh/core/model/constants.dart';
import 'package:roozaneh/core/model/environment.dart';
import 'package:roozaneh/core/utils/exception_handler.dart';
import 'package:roozaneh/features/app_update/data/github_release_parser.dart';
import 'package:roozaneh/features/app_update/model/app_update_failure.dart';
import 'package:roozaneh/features/app_update/model/remote_version_entity.dart';
import 'package:roozaneh/utils/utils.dart';

abstract interface class AppUpdateRepository {
  TaskEither<AppUpdateFailure, RemoteVersionEntity?> getLatestVersion({
    bool includePreReleases = false,
    Release release = Release.general,
  });
}

class AppUpdateRepositoryImpl with ExceptionHandler, InfraLogger implements AppUpdateRepository {
  AppUpdateRepositoryImpl({required this.httpClient});

  final DioHttpClient httpClient;

  @override
  TaskEither<AppUpdateFailure, RemoteVersionEntity?> getLatestVersion({
    bool includePreReleases = false,
    Release release = Release.general,
  }) {
    return exceptionHandler(() async {
      if (!release.allowCustomUpdateChecker) {
        throw Exception("custom update checkers are not supported");
      }
      final response = await httpClient.get<List>(Constants.githubReleasesApiUrl);
      if (response.statusCode != 200 || response.data == null || response.data!.isEmpty) {
        loggy.warning("failed to fetch latest version info");
        return right(null);
      }

      final releases = response.data!
          .map((e) {
            try {
              return GithubReleaseParser.parse(e as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<RemoteVersionEntity>()
          .toList();

      if (releases.isEmpty) {
        return right(null);
      }

      RemoteVersionEntity? latest;
      if (includePreReleases) {
        latest = releases.firstOrNull;
      } else {
        latest = releases.firstWhereOrNull((e) => !e.preRelease) ?? releases.firstOrNull;
      }
      return right(latest);
    }, AppUpdateFailure.unexpected);
  }
}
