import '../../components/CustomProject.dart';
import '../../data/ChannelData.dart';

enum LocalNotificationConstant {
  general,
  report,
}

class LocalNotificationCollection {
  static final generalNotification = ChannelData(
      androidChannelId: dbReference(LocalNotificationConstant.general),
      androidChannelName: "General");
  static final reportNotification = ChannelData(
      androidChannelId: dbReference(LocalNotificationConstant.report),
      androidChannelName: "Reports");

  List<ChannelData> listOfChannelData = [
    generalNotification,
    reportNotification
  ];
}
