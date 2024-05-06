import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/collections/common_collection/ResourceCollection.dart';
import 'package:yabnet/operations/MembersOperation.dart';

import '../../components/CustomPrimaryButton.dart';
import '../../components/CustomProject.dart';
import '../../data/SubscriptionsData.dart';
import '../../db_references/Plans.dart';
import '../../db_references/Subscription.dart';
import '../../local_navigation_controller.dart';
import '../../operations/AuthenticationOperation.dart';
import '../../operations/SubscriptionsOperation.dart';
import '../../supabase/SupabaseConfig.dart';
import 'ChoosePlanPage.dart';
import 'LoginPage.dart';
import 'SecondaryPage.dart';
import 'SignUpPage.dart';

class CheckAuth extends StatelessWidget {
  const CheckAuth({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseAuthChange = SupabaseConfig.client.auth.onAuthStateChange;

    return Scaffold(
      body: StreamBuilder<AuthState?>(
        stream: supabaseAuthChange,
        builder: (context, authSnapshot) {
          if (authSnapshot.data?.event == AuthChangeEvent.tokenRefreshed) {
            showToastMobile(msg: "Token has expired!!. Sign in again");
            AuthenticationOperation().signOut(context, expiredToken: true);
          }

          if (authSnapshot.data?.event == AuthChangeEvent.userDeleted) {
            showToastMobile(msg: "You have been removed from Yabnet");
            AuthenticationOperation().signOut(context, expiredToken: true);
          }
          return const LoginPage();
          // }
        },
      ),
    );
  }
}

class PrimaryPage extends StatefulWidget {
  const PrimaryPage({super.key});

  @override
  State<PrimaryPage> createState() => _PrimaryPageState();
}

class _PrimaryPageState extends State<PrimaryPage> {
  WidgetStateNotifier<bool> widgetStateNotifier =
      WidgetStateNotifier(currentValue: false);

  Future<bool> navigateToPlanPage() async {
    // Check current user
    Session? initialSession = await AuthenticationOperation().getSessions();

    dynamic userData = await MembersOperation().getUserRecord();

    if (initialSession?.user != null) {
      if (userData == null) {
        AuthenticationOperation().signOut(context);
        return true;
      }
      final subscriptionData = userData[dbReference(Subscriptions.table)];
      final planData =
          userData[dbReference(Subscriptions.table)][dbReference(Plans.table)];

      bool moved = false;
      if (subscriptionData != null && planData != null) {
        final subscriptionsData =
            SubscriptionData.fromOnline(subscriptionData, planData);
        if ((SubscriptionsOperation().isTimeBetween(
                subscriptionsData.subscriptionsFrom,
                subscriptionsData.subscriptionsTo,
                DateTime.now()) &&
            subscriptionsData.subscriptionsActive &&
            subscriptionsData.subscriptionsPaymentVerified &&
            subscriptionsData.subscriptionsStatus ==
                dbReference(Subscriptions.verified_payment))) {
          moved = true;
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const SecondaryPage()));
        }
      }
      if (!moved) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const ChoosePlanPage()));
      }
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    setLightUiViewOverlay();
    LocalNavigationController()
        .addNavigatorKey(LocalNavigationController.useNavigatorKey);
    navigateToPlanPage().then((value) {
      if (value) {
        widgetStateNotifier.sendNewState(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    void signUpUser() {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const SignUpPage()));
    }

    void signInUser() {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: WidgetStateConsumer(
            widgetStateNotifier: widgetStateNotifier,
            widgetStateBuilder: (context, snapshot) {
              if (snapshot == false) {
                return Center(
                  child: progressBarWidget(),
                );
              }
              // return ChoosePlanPage();
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Center(
                        child: Column(
                          children: [
                            // Image Illustration
                            const SizedBox(height: 50),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Lottie.asset(
                                      ResourceCollection.connectLottie,
                                      fit: BoxFit.cover,
                                      height: getScreenHeight(context) * 0.4)),
                            ),
                            // Welcome Text
                            const SizedBox(height: 25),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Welcome to YabNet",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.sigmarOne(
                                    color: Colors.black, fontSize: 24),
                              ),
                            ),

                            // Attached Text
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "CONNECT, ENGAGE, AND THRIVE WITH LIKE-MINDED INDIVIDUALS IN YOUR INDUSTRY",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.carroisGothicSc(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Sign up Button
                        Expanded(
                          child: CustomPrimaryButton(
                            buttonText: "Sign Up",
                            onTap: signUpUser,
                            isEnabled: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomPrimaryButton(
                            buttonText: "Sign In",
                            onTap: signInUser,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),
      ),
    );
  }
}
