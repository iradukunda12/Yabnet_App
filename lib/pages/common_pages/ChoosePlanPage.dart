import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/components/CustomPlanView.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/data/PlanData.dart';
import 'package:yabnet/data_notifiers/PlansNotifier.dart';

import '../../components/CustomButtonRefreshCard.dart';

class ChoosePlanPage extends StatefulWidget {
  const ChoosePlanPage({super.key});

  @override
  State<ChoosePlanPage> createState() => _ChoosePlanPageState();
}

class _ChoosePlanPageState extends State<ChoosePlanPage>
    implements PlansImplement {
  PageController pageController = PageController();
  RetryStreamListener retryStreamListener = RetryStreamListener();
  PlansStack plansStack = PlansStack();

  @override
  BuildContext? getLatestContext() {
    return context;
  }

  @override
  RetryStreamListener? getRetryStreamListener() {
    return retryStreamListener;
  }

  @override
  void initState() {
    super.initState();
    setLightUiViewOverlay();
    PlansNotifier().start(this, plansStack);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> getEpChildren(List<PlanData> planData) {
      return planData
          .asMap()
          .map((key, value) {
            return MapEntry(
                key,
                //   EPView(
                // child:
                CustomPlanView(
                  planData: value, index: key,
                  //   )
                ));
          })
          .values
          .toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: WidgetStateConsumer(
            widgetStateNotifier: PlansNotifier().state,
            widgetControlStateBuilder: (context, snapshot, control) {
              bool showControl = (snapshot?.isEmpty ?? true) == true;
              if (control == WidgetStateControl.error && showControl) {
                return Center(
                  child: CustomButtonRefreshCard(
                      topIcon: const Icon(
                        Icons.not_interested,
                        size: 50,
                      ),
                      retryStreamListener: retryStreamListener,
                      displayText: "Error loading plan"),
                );
              }

              if (control == WidgetStateControl.loading && showControl) {
                return Center(
                  child: progressBarWidget(),
                );
              }

              return PageView(
                controller: pageController,
                children: getEpChildren(snapshot ?? []),
              );
            }),
      ),
    );
  }
}
