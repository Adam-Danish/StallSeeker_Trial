const _stallShareHost = 'stallseeker.my';

String stallPath(String stallId) => '/stall/${Uri.encodeComponent(stallId)}';

Uri stallShareLink(String stallId) =>
    Uri.https(_stallShareHost).resolve(stallPath(stallId));

bool isSharedStallPath(Uri uri) =>
    uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'stall';

String? sharedStallId(Uri uri) {
  final segments = uri.pathSegments;
  if (!isSharedStallPath(uri) || segments.length != 2) return null;
  final id = segments.last;
  if (id.trim().isEmpty ||
      id == '.' ||
      id == '..' ||
      id.contains('/') ||
      id.contains(RegExp(r'^__.*__$'))) {
    return null;
  }
  return id;
}
