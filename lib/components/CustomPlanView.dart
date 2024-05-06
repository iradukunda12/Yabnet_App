import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/Tumeny/TumenyConfig.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/components/CustomPlanPaymentView.dart';
import 'package:yabnet/components/CustomPrimaryButton.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/components/EllipsisText.dart';
import 'package:yabnet/data/PlanData.dart';
import 'package:yabnet/data/SubscriptionsData.dart';
import 'package:yabnet/data/TumenyCustomerData.dart';
import 'package:yabnet/data_notifiers/PlansNotifier.dart';
import 'package:yabnet/data_notifiers/SubscriptionNotifier.dart';
import 'package:yabnet/main.dart';
import 'package:yabnet/operations/AuthenticationOperation.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/operations/SubscriptionsOperation.dart';
import 'package:yabnet/pages/common_pages/SecondaryPage.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../db_references/Members.dart';
import '../db_references/Plans.dart';
import '../db_references/Subscription.dart';

class CustomPlanView extends StatefulWidget {
  final PlanData planData;
  final int index;

  const CustomPlanView(
      {super.key, required this.planData, required this.index});

  @override
  State<CustomPlanView> createState() => _CustomPlanViewState();
}

class _CustomPlanViewState extends State<CustomPlanView>
    implements SubscriptionsImplement {
  WidgetStateNotifier<int> selectedViewNotifier = WidgetStateNotifier();
  SubscriptionsStack subscriptionsStack = SubscriptionsStack();
  WidgetStateNotifier<SubscriptionData> subscriptionDataNotifier =
      WidgetStateNotifier(currentStateControl: WidgetStateControl.loading);
  WidgetStateNotifier<bool> checkedSubscriptionNotifier = WidgetStateNotifier(
      currentValue: false, currentStateControl: WidgetStateControl.loading);

  StreamSubscription? streamSubscription;
  bool paymentIsClicked = false;

  @override
  void initState() {
    super.initState();
    SubscriptionsNotifier().start(this, subscriptionsStack);
    handleSubscribed().then((value) {
      streamSubscription ??=
          SubscriptionsNotifier().state.stream.listen(handleOlderSubscription);
    });
  }

  void handleOlderSubscription(List<SubscriptionData>? event) {
    checkedSubscriptionNotifier.sendNewState(true);
    if (event != null && event.isNotEmpty) {
      int foundPending = event.indexWhere((element) =>
          element.subscriptionsStatus ==
              dbReference(Subscriptions.pending_payment) &&
          !element.subscriptionsActive &&
          !element.subscriptionsPaymentVerified);
      int foundSuccessful = event.indexWhere((element) =>
          element.subscriptionsStatus ==
              dbReference(Subscriptions.verified_payment) &&
          element.subscriptionsActive &&
          element.subscriptionsPaymentVerified);

      if (foundPending != -1 || foundSuccessful != -1) {
        int working = foundPending != -1 ? foundPending : foundSuccessful;
        subscriptionDataNotifier.sendNewState(event[working]);
        if (paymentIsClicked) {
          Navigator.pop(context);
          paymentIsClicked = false;
        }
        int? selected = int.tryParse(event[working].plansSelected ?? "");
        if (selected != null) {
          selectedViewNotifier.sendNewState(selected);
        }
        showSubscriptionProgress();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    SubscriptionsNotifier().stop(subscriptionsStack);
  }

  @override
  BuildContext? getLatestContext() {
    return context;
  }

  Future<void> handleSubscribed({bool online = false}) async {
    if (online) {
      showCustomProgressBar(context);
    }
    final membersInfo = await MembersOperation().getUserRecord();

    showDebug(msg: membersInfo);

    final subscriptionData = membersInfo[dbReference(Subscriptions.table)];
    final planData =
        membersInfo[dbReference(Subscriptions.table)][dbReference(Plans.table)];

    if (subscriptionData != null && planData != null) {
      final subscriptionsData =
          SubscriptionData.fromOnline(subscriptionData, planData);

      if (online) {
        closeCustomProgressBar(context);
      }

      if (SubscriptionsOperation().isTimeBetween(
              subscriptionsData.subscriptionsFrom,
              subscriptionsData.subscriptionsTo,
              DateTime.now()) &&
          subscriptionsData.subscriptionsActive &&
          subscriptionsData.subscriptionsPaymentVerified &&
          subscriptionsData.subscriptionsStatus ==
              dbReference(Subscriptions.verified_payment)) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const SecondaryPage()));
      } else {
        checkedSubscriptionNotifier.sendNewState(true);
        subscriptionDataNotifier.sendNewState(subscriptionsData);
        handleSuccessfulPayment(subscriptionsData);
      }
    } else {
      checkedSubscriptionNotifier.sendNewState(true);
      if (online) {
        closeCustomProgressBar(context);
      }
      showToastMobile(
          msg: "An error occurred. Try again or maybe sign in again!");
    }
  }

  @override
  RetryStreamListener? getRetryStreamListener() {
    return null;
  }

  Future<void> handleSubscription(
      DateTime fromTime,
      String planId,
      int planSelected,
      double planPrice,
      int planDuration,
      String planTitle,
      DateTime toTime) async {
    final userData = await MembersOperation().getUserRecord();
    final title = "$planTitle subscription";
    String? membersId = SupabaseConfig.client.auth.currentUser?.id;
    String? token = SupabaseConfig.client.auth.currentSession?.accessToken;
    String? customerFirstName = userData[dbReference(Members.firstname)];
    String? customerLastName = userData[dbReference(Members.lastname)];
    String? email = userData[dbReference(Members.email)];
    String? phoneNumber = userData[dbReference(Members.phone_code)] +
        userData[dbReference(Members.phone_no)];

    if (customerFirstName != null &&
        customerLastName != null &&
        email != null &&
        phoneNumber != null &&
        membersId != null &&
        token != null) {
      Navigator.pop(context);
      showSubscriptionProgress();
      TumenyConfig()
          .sendPaymentRequest(
              token,
              customerFirstName,
              customerLastName,
              phoneNumber,
              1,
              email,
              title,
              planId,
              membersId,
              fromTime.toString(),
              toTime.toString(),
              planSelected,
              false,
              false)
          .then((value) {
        showDebug(msg: value.data);
        if (value.data is List) {
          subscriptionDataNotifier.sendNewState(SubscriptionData.fromOnline(
              (value.data as List).single,
              PlansNotifier()
                  .state
                  .currentValue
                  ?.firstWhere((element) =>
                      element.plansId == value.data[dbReference(Plans.id)])
                  .toJson()));
        }
      }).onError((error, stackTrace) {
        subscriptionDataNotifier.sendStateWithControl(WidgetStateControl.error);
        if (error is FunctionException) {
          showDebug(
              msg:
                  "${error.reasonPhrase} \n${error.details}\n${error.status}\n $stackTrace");
        } else {
          showDebug(msg: "$error $stackTrace");
        }
      });
    } else {
      showToastMobile(
          msg: "An error occurred. You might cancel and sign in again");
    }
  }

  Future<void> verifySubscription(SubscriptionData data) async {
    Navigator.pop(context);

    final userData = await MembersOperation().getUserRecord();
    String? membersId = SupabaseConfig.client.auth.currentUser?.id;
    String? token = SupabaseConfig.client.auth.currentSession?.accessToken;
    String? customerFirstName = userData[dbReference(Members.firstname)];
    String? customerLastName = userData[dbReference(Members.lastname)];
    String? email = userData[dbReference(Members.email)];
    String? phoneNumber = userData[dbReference(Members.phone_code)] +
        userData[dbReference(Members.phone_no)];

    if (membersId != null &&
        customerFirstName != null &&
        customerLastName != null &&
        email != null &&
        phoneNumber != null) {
      showCustomProgressBar(context);
      TumenyCustomerData tumenyCustomerData = TumenyCustomerData(
          customerFirstName, customerLastName, email, phoneNumber);
      SubscriptionsOperation()
          .getPaymentStatus(tumenyCustomerData, data.paymentReference)
          .then((value) {
        showDebug(msg: "${value?.toJson()}");

        if (value?.status == "failed") {
          handleFailedSubscription(data).then((deleted) {
            subscriptionDataNotifier
                .sendStateWithControl(WidgetStateControl.loading, state: null);
            closeCustomProgressBar(context);

            if (deleted) {
              handleMaybeFailedPlanSelection(data);
            } else {
              showToastMobile(msg: "An error occurred. Try again!");
            }
          }).onError((error, stackTrace) {
            closeCustomProgressBar(context);
            showDebug(msg: "$email $stackTrace");
            showToastMobile(msg: "An error occurred. Try again!");
          });
        } else if (value?.status == "pending") {
          closeCustomProgressBar(context);
          showSubscriptionProgress();
          showToastMobile(msg: "Payment is still pending!");
        } else if (value?.status == "success") {
          showDebug(msg: "Successful");
          handleSuccessfulPayment(data);
        }
      }).onError((error, stackTrace) {
        closeCustomProgressBar(context);
        showDebug(msg: "$email $stackTrace");
        showToastMobile(msg: "An error occurred. Try again!");
      });
    } else {
      showToastMobile(
          msg: "An error occurred. You might want to cancel and sign in again");
    }
  }

  void cancelSubscription(SubscriptionData data) {}

  void showSubscriptionProgress() {
    if (!mounted) return;
    openBottomSheet(
            context,
            SizedBox(
              height: getScreenHeight(context) * 0.6,
              child: Builder(builder: (context) {
                setDarkGreyUiViewOverlay();

                return SafeArea(
                  child: WidgetStateConsumer(
                    widgetStateNotifier: subscriptionDataNotifier,
                    widgetControlStateBuilder: (context, data, control) {
                      bool showControls = data == null;
                      if (control == WidgetStateControl.error && showControls) {
                        return const Text("Error occurred");
                      }
                      if (control == WidgetStateControl.loading &&
                          showControls) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [progressBarWidget()],
                        );
                      }

                      PlanData planData = data!.plansData!;

                      String price = '0';

                      if (data.plansSelected == "0") {
                        price = planData.plansQuarterlyPayment.toString();
                      } else if (data.plansSelected == "1") {
                        price = planData.plansBiAnnualPayment.toString();
                      } else if (data.plansSelected == "2") {
                        price = planData.plansYearlyPayment.toString();
                      }

                      int duration = 0;

                      if (data.plansSelected == "0") {
                        duration = 3;
                      } else if (data.plansSelected == "1") {
                        duration = 6;
                      } else if (data.plansSelected == "2") {
                        duration = 12;
                      }

                      final toTime = data.subscriptionsFrom
                          .add(Duration(days: duration * 30));

                      return Column(
                        children: [
                          const SizedBox(
                            height: 16,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(
                                  "Complete Payment",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.black.withOpacity(0.8),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                )),
                                const SizedBox(
                                  width: 16,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Icon(
                                    Icons.cancel,
                                    size: 30,
                                    color: Colors.black.withOpacity(0.8),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 16,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${planData.plansCurrency}${double.parse(price).toStringAsFixed(0)}",
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 42,
                                            fontWeight: FontWeight.w900),
                                      ),
                                      Text(
                                        "/$duration ${(duration > 1) ? 'months' : 'month'}",
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 9,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                  child: Row(
                                    children: [Expanded(child: Divider())],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: Text(
                                        "Ending: ${"${toTime.day}/${toTime.month}/${toTime.year}"}",
                                        style: TextStyle(
                                            color:
                                                Colors.black.withOpacity(0.9),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17),
                                      )),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                  child: Row(
                                    children: [Expanded(child: Divider())],
                                  ),
                                ),
                                const SizedBox(
                                  height: 9,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: Text(
                                        "*Proceed to payment, and verify here once completed.",
                                        style: TextStyle(
                                            color: Colors.red, fontSize: 14),
                                      )),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: CustomPrimaryButton(
                                buttonText: "Verify Payment",
                                onTap: () {
                                  verifySubscription(
                                      data.copyWith(subscriptionsTo: toTime));
                                }),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  cancelSubscription(data);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "Cancel Subscription",
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 15),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      );
                    },
                  ),
                );
              }),
            ),
            color: Colors.grey.shade200)
        .then((value) {
      setLightUiViewOverlay();
    });
  }

  void handlePlanClicked(String planId, int planSelected, String planTitle,
      String planCurrency, double planPrice, int planDuration) {
    showCustomProgressBar(context);
    SupabaseConfig().getDatabaseTime().then((value) {
      closeCustomProgressBar(context);

      if (value != null) {
        DateTime toTime = value.add(Duration(days: planDuration * 30));
        paymentIsClicked = true;
        openBottomSheet(
                context,
                SizedBox(
                  height: getScreenHeight(context) * 0.6,
                  child: Builder(builder: (context) {
                    setDarkGreyUiViewOverlay();
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 24,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(
                                  "Payment Plan",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.black.withOpacity(0.8),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                )),
                                const SizedBox(
                                  width: 16,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Icon(
                                    Icons.cancel,
                                    size: 30,
                                    color: Colors.black.withOpacity(0.8),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Expanded(
                            child: Container(
                              color: Colors.white,
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "$planCurrency${planPrice.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 42,
                                              fontWeight: FontWeight.w900),
                                        ),
                                        Text(
                                          "/$planDuration ${(planDuration > 1) ? 'months' : 'month'}",
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 9,
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 24),
                                    child: Row(
                                      children: [Expanded(child: Divider())],
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Text(
                                          "Ending: ${"${toTime.day}/${toTime.month}/${toTime.year}"}",
                                          style: TextStyle(
                                              color:
                                                  Colors.black.withOpacity(0.9),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17),
                                        )),
                                      ],
                                    ),
                                  ),

                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 24),
                                    child: Row(
                                      children: [Expanded(child: Divider())],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 9,
                                  ),

                                  //   Text Widget

                                  const Expanded(child: SizedBox()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "With this subscription, you'll have access to all premium features for $planDuration ${(planDuration > 1) ? 'months' : 'month'}. Enjoy uninterrupted access to our app and all its features during this period!",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 4,
                                            style: TextStyle(
                                              color:
                                                  Colors.black.withOpacity(0.9),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: CustomPrimaryButton(
                                buttonText: "Subscribe",
                                onTap: () {
                                  handleSubscription(
                                      value,
                                      planId,
                                      planSelected,
                                      planPrice,
                                      planDuration,
                                      planTitle,
                                      toTime);
                                }),
                          ),
                          const SizedBox(
                            height: 16,
                          )
                        ],
                      ),
                    );
                  }),
                ),
                color: Colors.grey.shade200)
            .then((value) {
          setLightUiViewOverlay();
        });
      } else {
        showToastMobile(msg: "An error occurred");
      }
    }).onError((error, stackTrace) {
      showDebug(msg: "$error $stackTrace");
      showToastMobile(msg: "An error occurred");
      closeCustomProgressBar(context);
    });
  }

  Widget getPaymentView(bool selected, int index, String title, double price,
      int timePeriod, Color backgroundColor) {
    return WidgetStateConsumer(
        widgetStateNotifier: subscriptionDataNotifier,
        widgetStateBuilder: (context, subscriptionData) {
          bool pendingSub = subscriptionData != null &&
              subscriptionData.plansSelected == index.toString() &&
              subscriptionData.subscriptionsStatus ==
                  dbReference(Subscriptions.pending_payment);
          bool successSub = subscriptionData != null &&
              subscriptionData.plansSelected == index.toString() &&
              subscriptionData.subscriptionsStatus ==
                  dbReference(Subscriptions.verified_payment);

          return CustomPlanPaymentView(
            selected: selected,
            color: const Color(getMainPinkColor),
            borderColor: Colors.grey.shade700,
            currency: widget.planData.plansCurrency,
            titleStyle: GoogleFonts.arvo(
                color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
            title: title,
            period: timePeriod,
            price: price,
            subTitleStyle: const TextStyle(color: Colors.black, fontSize: 15),
            subMainTitleStyle: const TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            bottomStyle: const TextStyle(color: Colors.blue, fontSize: 14),
            buttonStyle: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold),
            onSelect: () {
              selectedViewNotifier.sendNewState(index);
            },
            backgroundColor: Colors.transparent,
            onTap: () {
              if (pendingSub || successSub) {
                showSubscriptionProgress();
              } else {
                handlePlanClicked(widget.planData.plansId, index, title,
                    widget.planData.plansCurrency, price, timePeriod);
              }
            },
            text: pendingSub || successSub ? "Verify" : "Get offer",
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return WidgetStateConsumer(
        widgetStateNotifier: checkedSubscriptionNotifier,
        widgetControlStateBuilder: (context, checked, control) {
          if (control == WidgetStateControl.loading && checked != true) {
            return Center(
              child: progressBarWidget(),
            );
          }

          return WidgetStateConsumer(
              widgetStateNotifier: selectedViewNotifier,
              widgetStateBuilder: (context, data) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  AuthenticationOperation().signOut(context);
                                },
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 30,
                                ))
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: Text(
                              widget.planData.plansTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold),
                            )),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: EllipsisText(
                                textAlign: TextAlign.center,
                                text: widget.planData.plansDescription,
                                maxLength: 150,
                                onMorePressed: () {},
                                textStyle: const TextStyle(
                                    color: Colors.black, fontSize: 15),
                                moreText: 'more',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 28,
                        ),

                        // getPaymentView((snapshot.data ?? 0) == 0,0, "Monthly", widget.planData.plansMonthlyPayment, 1,Colors.blueAccent,),
                        // SizedBox(height: 16),

                        getPaymentView(
                            (data ?? 0) == 0,
                            0,
                            "Quarterly",
                            widget.planData.plansQuarterlyPayment,
                            3,
                            Colors.green),
                        const SizedBox(height: 16),

                        getPaymentView(
                            (data ?? 0) == 1,
                            1,
                            "Bi-Annual",
                            widget.planData.plansBiAnnualPayment,
                            6,
                            Colors.red),
                        const SizedBox(height: 16),

                        getPaymentView(
                            (data ?? 0) == 2,
                            2,
                            "Yearly",
                            widget.planData.plansYearlyPayment,
                            12,
                            Colors.yellow),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              });
        });
  }

  Future<bool> handleFailedSubscription(SubscriptionData data) {
    return SubscriptionsOperation()
        .updateSubscription(data.subscriptionsId)
        .then((value) => (value?[dbReference(Subscriptions.status)] ==
            dbReference(Subscriptions.failed_payment)))
        .onError((error, stackTrace) => false);
  }

  void handleMaybeFailedPlanSelection(SubscriptionData data) {
    PlanData planData = data.plansData!;

    String price = '0';

    if (data.plansSelected == "0") {
      price = planData.plansQuarterlyPayment.toString();
    } else if (data.plansSelected == "1") {
      price = planData.plansBiAnnualPayment.toString();
    } else if (data.plansSelected == "2") {
      price = planData.plansYearlyPayment.toString();
    }

    int duration = 0;
    String title = '';

    if (data.plansSelected == "0") {
      duration = 3;
      title = "Quarterly";
    } else if (data.plansSelected == "1") {
      duration = 6;
      title = "Bi-Annual";
    } else if (data.plansSelected == "2") {
      title = "Yearly";
      duration = 12;
    }
    openDialog(
        context,
        const Text(
          "Subscription Failed",
          style: TextStyle(color: Colors.red, fontSize: 17),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.black,
                ),
                children: [
                  const TextSpan(text: 'Your previous '),
                  const TextSpan(
                    text: 'subscription ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: 'to get '),
                  TextSpan(
                    text:
                        '$duration ${duration > 1 ? "months" : "month"} access ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: 'to '),
                  const TextSpan(
                    text: 'Yabnet ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: 'for '),
                  TextSpan(
                    text:
                        '${planData.plansCurrency}${double.parse(price).toStringAsFixed(0)} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: 'failed. You can '),
                  const TextSpan(
                    text: 'retry ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: 'or '),
                  const TextSpan(
                    text: 'change plan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            )
          ],
        ),
        [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (data.plansData != null) {
                handlePlanClicked(
                    data.plansId,
                    int.parse(data.plansSelected),
                    title,
                    data.plansData!.plansCurrency,
                    double.parse(price),
                    duration);
              } else {
                showToastMobile(msg: "Unable to perform request");
              }
            },
            child: const Text(
              'Retry',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Change Plan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ]);
  }

  void handleSuccessfulPayment(SubscriptionData data) {
    SubscriptionsOperation()
        .updateVerifiedSubscription(
            data.subscriptionsId, data.subscriptionsTo.toString())
        .then((subscription) {
      showDebug(msg: subscription);
      MembersOperation()
          .updateMembersSubscription(
              data.subscriptionsId, SupabaseConfig.client.auth.currentUser?.id)
          .then((userData) {
        MembersOperation().saveOnlineUserRecordToLocal(userData).then((value) {
          closeCustomProgressBar(context);
          handleSubscribed(online: true);
        }).onError((error, stackTrace) {
          closeCustomProgressBar(context);
          showToastMobile(msg: "An error occurred");
          showDebug(msg: "3-> $error $stackTrace");
        });
      }).onError((error, stackTrace) {
        closeCustomProgressBar(context);
        showToastMobile(msg: "An error occurred");
        showDebug(msg: "2-> $error $stackTrace");
      });
    }).onError((error, stackTrace) {
      closeCustomProgressBar(context);
      showToastMobile(msg: "An error occurred");
      showDebug(msg: " 1-> $error $stackTrace");
    });
  }
}
