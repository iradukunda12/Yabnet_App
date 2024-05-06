class VersionUtils {
  static int compareVersions(String version1, String version2) {
    List<String> parts1 = version1.split('.');
    List<String> parts2 = version2.split('.');

    int length =
        (parts1.length > parts2.length) ? parts1.length : parts2.length;

    for (int i = 0; i < length; i++) {
      int part1 = (i < parts1.length) ? int.parse(parts1[i]) : 0;
      int part2 = (i < parts2.length) ? int.parse(parts2[i]) : 0;

      if (part1 < part2) {
        return -1; // version1 is lower
      } else if (part1 > part2) {
        return 1; // version1 is higher
      }
    }

    return 0; // versions are the same
  }
}
