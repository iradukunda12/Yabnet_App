import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/builders/CustomWrapListBuilder.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';
import 'package:yabnet/components/CustomWrappingLayout.dart';
import 'package:yabnet/data/UserConnectsData.dart';
import 'package:yabnet/data_notifiers/UserConnectsNotifier.dart';
import 'package:yabnet/drawer/ProfileDrawer.dart';
import 'package:yabnet/main.dart';

import '../../builders/TypeStateProvider.dart';
import '../../collections/common_collection/ProfileImage.dart';
import '../../components/CustomProject.dart';
import '../../components/WrappingSilverAppBar.dart';
import '../../data/UserData.dart';
import '../../data_notifiers/NetworkConnectsNotifier.dart';
import '../../data_notifiers/ProfileNotifier.dart';
import '../../db_references/Connect.dart';
import '../../handler/NetworkCardHandler.dart';
import '../../operations/MembersOperation.dart';
import 'DisplayConnectInfoPage.dart';
import 'SearchedPage.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends TypeStateProviderAwareState<NetworkPage>
    implements NetworkConnectsImplement {
  RetryStreamListener retryStreamListener = RetryStreamListener();

  UserConnectsStack userConnectsStack = UserConnectsStack();

  TypeStateProvider<ColorMode, Color> get colorProvider =>
      TypeStateProvider.of(context);

  TypeStateProvider<String, String> get textProvider =>
      TypeStateProvider.of(context);

  Map<int, bool> dataIsPresent = {};
  WidgetStateNotifier<bool> sendDataPresentNotifier =
      WidgetStateNotifier(currentValue: false);

  @override
  List<TypeStateProvider> retrieveProviders() {
    return [
      colorProvider,
      textProvider,
    ];
  }

  @override
  PaginationProgressController? getPaginationProgressController() {
    return null;
  }

  @override
  void initState() {
    super.initState();
    NetworkConnectsNotifier().start(this, UserConnectsNotifier());

    retryStreamListener.addListener(listenToRetry);
  }

  void listenToRetry() {
    if (retryStreamListener.retrying) {
      UserConnectsNotifier().restart(true, true);
    }
  }

  @override
  void dispose() {
    super.dispose();
    NetworkConnectsNotifier().stop();
    retryStreamListener.removeListener(listenToRetry);
  }

  @override
  BuildContext? getLatestContext() {
    return context;
  }

  @override
  RetryStreamListener? getRetryStreamListener() {
    return retryStreamListener;
  }

  void openNavigationBar(BuildContext scaffoldContext) {
    Scaffold.of(scaffoldContext).openDrawer();
  }

  void handleConnect() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DisplayConnectInfoPage(
                forMember: ProfileNotifier().state.currentValue?.fullName ?? '',
                titleType: Connect.connect,
                userConnectsNotifier: UserConnectsNotifier(),
                connectionRetryStreamListener: retryStreamListener))).then(
        (value) {
      setNormalUiViewOverlay();
    });
  }

  void handleConnection() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DisplayConnectInfoPage(
                forMember: ProfileNotifier().state.currentValue?.fullName ?? '',
                titleType: Connect.connection,
                userConnectsNotifier: UserConnectsNotifier(),
                connectionRetryStreamListener: retryStreamListener))).then(
        (value) {
      setNormalUiViewOverlay();
    });
  }

  void openSearchPage() {
    Navigator.push(
            context, MaterialPageRoute(builder: (context) => SearchedPage()))
        .then((value) {
      setNormalUiViewOverlay();
    });
  }

  Widget getTopWidget() {
    return WidgetStateConsumer(
        widgetStateNotifier: UserConnectsNotifier().state,
        widgetStateBuilder: (context, snapshot) {
          if (snapshot == null) {
            return SizedBox();
          }
          UserConnectsData userConnectsData = snapshot;
          int? connects = userConnectsData.connects?.length;
          int? connection = userConnectsData.connection?.length;

          return Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Color(getDarkGreyColor),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0.3),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: CustomWrappingLayout(
                            wlChildren: [
                              WLView(
                                  expandMain: true,
                                  child: CustomOnClickContainer(
                                    onTap: handleConnect,
                                    defaultColor: Colors.transparent,
                                    clickedColor: Colors.transparent,
                                    padding: EdgeInsets.all(4),
                                    child: Column(
                                      children: [
                                        Text(
                                          "${connects ?? 0}",
                                          style: TextStyle(
                                              color: connects != null
                                                  ? Colors.black
                                                  : Colors.grey,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        SizedBox(
                                          height: 16,
                                        ),
                                        Text(
                                          (connects ?? 0) > 1
                                              ? "Connects"
                                              : "Connect",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  )),
                              WLView(
                                  crossDimension: WlDimension.match,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 16,
                                      ),
                                      Container(
                                        height: 30,
                                        color: Color(getDarkGreyColor),
                                        width: 2,
                                      ),
                                      SizedBox(
                                        height: 16,
                                      ),
                                    ],
                                  )),
                              WLView(
                                  expandMain: true,
                                  child: CustomOnClickContainer(
                                    onTap: handleConnection,
                                    defaultColor: Colors.transparent,
                                    clickedColor: Colors.transparent,
                                    padding: EdgeInsets.all(4),
                                    child: Column(
                                      children: [
                                        Text(
                                          "${connection ?? 0}",
                                          style: TextStyle(
                                              color: connection != null
                                                  ? Colors.black
                                                  : Colors.grey,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        SizedBox(
                                          height: 16,
                                        ),
                                        Text(
                                          (connection ?? 0) > 1
                                              ? "Connections"
                                              : "Connection",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: ProfileDrawer(),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              WrappingSliverAppBar(
                  titleSpacing: 0,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  title: Column(children: [
                    // Top buttons
                    SizedBox(
                      height: 24,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomOnClickContainer(
                            onTap: () {
                              openNavigationBar(context);
                            },
                            defaultColor: Colors.grey.shade200,
                            clickedColor: Colors.grey.shade300,
                            height: 45,
                            width: 45,
                            clipBehavior: Clip.hardEdge,
                            shape: BoxShape.circle,
                            child: WidgetStateConsumer(
                                widgetStateNotifier: ProfileNotifier().state,
                                widgetStateBuilder: (context, snapshot) {
                                  UserData? userData = snapshot;
                                  return ProfileImage(
                                    iconSize: 45,
                                    fullName: snapshot?.fullName ?? '',
                                    imageUri: MembersOperation()
                                        .getMemberProfileBucketPath(
                                            snapshot?.userId ?? '',
                                            snapshot?.profileIndex),
                                    imageUrl: (imageAddress) {},
                                  );
                                }),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: CustomOnClickContainer(
                                onTap: openSearchPage,
                                defaultColor: Colors.transparent,
                                clickedColor: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.grey.shade500),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search,
                                        size: 20,
                                        color: Colors.grey.shade700,
                                      ),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        "Search here",
                                        textScaler: TextScaler.noScaling,
                                        style: TextStyle(
                                            color:
                                                Colors.black.withOpacity(0.7),
                                            fontSize: 16),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                  ])),
            ];
          },
          body: WidgetStateConsumer(
              widgetStateNotifier: NetworkConnectsNotifier().state,
              widgetStateBuilder: (context, data) {
                if (data == null) {
                  return SizedBox(
                      height: getScreenHeight(context) * 0.5,
                      child: Center(child: progressBarWidget()));
                }

                if (data.isEmpty) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      getTopWidget(),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 0.3,
                                color: Color(getDarkGreyColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return CustomWrapListBuilder(
                    retryStreamListener: retryStreamListener,
                    itemCount: data.length,
                    wrapListBuilder: (context, index) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (index == 0) getTopWidget(),
                          if (index == 0)
                            WidgetStateConsumer(
                                widgetStateNotifier: sendDataPresentNotifier,
                                widgetStateBuilder: (context, data) {
                                  if (data == true) {
                                    return Container(
                                      height: 0.25 * getScreenHeight(context),
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.only(),
                                          border: Border(
                                              top: BorderSide(
                                                  color:
                                                      Color(getDarkGreyColor),
                                                  width: 0.3))),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                    child: Text(
                                                  "New user connects will appear here",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey.shade900,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 17),
                                                )),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  } else {
                                    return SizedBox();
                                  }
                                }),
                          NetworkCardHandler(
                            networkConnectsNotifier: NetworkConnectsNotifier(),
                            connectFieldNotifier: data.values.elementAt(index),
                            index: index,
                            hasData: (bool value) {
                              dataIsPresent[index] = value;

                              sendDataPresentNotifier.sendNewState(
                                  (!dataIsPresent.values
                                          .every((element) => element)) &&
                                      (!dataIsPresent.values
                                          .any((element) => element)));
                            },
                          ),
                        ],
                      );
                    });
              }),
        ),
      ),
    );
  }
}
