import 'package:dartx/dartx.dart';
import 'package:roozaneh/core/model/constants.dart';
import 'package:roozaneh/core/model/environment.dart';
import 'package:roozaneh/features/app_update/model/remote_version_entity.dart';

abstract class GithubReleaseParser {
  static RemoteVersionEntity parse(Map<String, dynamic> json) {
    final fullTag = (json['tag_name'] as String?) ?? "";
    final cleanTag = fullTag.removePrefix("v").removePrefix("V");
    final fullVersion = cleanTag.split("-").first.split("+");
    var version = fullVersion.first;
    var buildNumber = fullVersion.elementAtOrElse(1, (index) => "");
    var flavor = Environment.prod;
    for (final env in Environment.values) {
      final suffix = ".${env.name}";
      if (version.endsWith(suffix)) {
        version = version.removeSuffix(suffix);
        flavor = env;
        break;
      } else if (buildNumber.endsWith(suffix)) {
        buildNumber = buildNumber.removeSuffix(suffix);
        flavor = env;
        break;
      }
    }
    final preRelease = (json["prerelease"] as bool?) ?? false;
    final publishedAtStr = (json["published_at"] as String?) ?? (json["created_at"] as String?) ?? DateTime.now().toIso8601String();
    final publishedAt = DateTime.tryParse(publishedAtStr) ?? DateTime.now();
    return RemoteVersionEntity(
      version: version,
      buildNumber: buildNumber,
      releaseTag: fullTag,
      preRelease: preRelease,
      url: (json["html_url"] as String?) ?? Constants.githubLatestReleaseUrl,
      publishedAt: publishedAt,
      flavor: flavor,
    );
  }
}
