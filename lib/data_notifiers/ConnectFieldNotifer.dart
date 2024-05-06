import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/data_notifiers/NetworkConnectsNotifier.dart';

import '../data/ConnectData.dart';
import '../data/ConnectInfo.dart';
import '../data/NetworkConnectInfo.dart';
import '../data/ProfessionData.dart';
import '../data/UserData.dart';
import '../operations/MembersOperation.dart';
import '../operations/PostOperation.dart';

class ConnectFieldNotifier {
  WidgetStateNotifier<List<NetworkConnectInfo>> state = WidgetStateNotifier();
  List<NetworkConnectInfo> _data = [];

  ProfessionData? _professionData;
  NetworkConnectsNotifier? _networkConnectsNotifier;

  ConnectFieldNotifier attachProfessionField(ProfessionData professionData,
      NetworkConnectsNotifier networkConnectsNotifier,
      {bool startFetching = false}) {
    _professionData = professionData;
    _networkConnectsNotifier = networkConnectsNotifier;
    return this;
  }

  Future<void> getResponse() {
    return _start();
  }

  Future<void> _start() async {
    if (_professionData == null || _networkConnectsNotifier == null) return;

    List<ConnectInfo>? userConnects =
        _networkConnectsNotifier?.getUserConnects();

    if (userConnects == null) return;

    final userInfoFuture = await MembersOperation().allUserOnlineNotInRecord(
        _professionData!.professionTitle,
        userConnects.map((e) => e.membersId).toList());

    final userInfoData = userInfoFuture
        .map((userRecord) => UserData.fromOnlineData(userRecord))
        .toList();

    final connectsFuture = userInfoData.map((e) async {
      final postConnects =
          await PostOperation().getThisMemberConnects(e.userId);
      return postConnects
          .map((postConnect) => ConnectData.fromOnline(postConnect))
          .toList();
    }).toList();

    final connects = await Future.wait(connectsFuture);

    final info = connects
        .asMap()
        .map((key, value) {
          final json = userInfoFuture[key];
          return MapEntry(key, NetworkConnectInfo.fromOnline(json, value));
        })
        .values
        .toList();
    _configure(info);
  }

  void _configure(List<NetworkConnectInfo> allNetworkConnects) {
    List<String> membersIds = _data.map((e) => e.membersId).toList();
    allNetworkConnects
        .removeWhere((element) => membersIds.contains(element.membersId));

    updateLatestData(allNetworkConnects);
    sendUpdateToUi();
  }

  List<NetworkConnectInfo> getLatestData() {
    return _data;
  }

  void updateLatestData(List<NetworkConnectInfo> connectField) {
    _data.addAll(connectField);
    if (_data.isEmpty) {
      _networkConnectsNotifier?.removeThisField(_professionData);
    }
  }

  void removeNetworkInfo(NetworkConnectInfo networkConnectInfo) {
    int found = getLatestData().indexWhere((element) {
      return element.membersId == networkConnectInfo.membersId;
    });
    if (found != -1) {
      _data.removeAt(found);
      sendUpdateToUi();
    }
  }

  void sendUpdateToUi() {
    state.sendNewState(_data);
  }
}
