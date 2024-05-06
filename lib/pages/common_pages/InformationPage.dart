import 'package:flag/flag_enum.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/collections/common_collection/ZambiaLocation.dart';
import 'package:yabnet/data_notifiers/AppFileServiceData.dart';
import 'package:yabnet/firebase/FirebaseConfig.dart';
import 'package:yabnet/operations/ProfessionFieldOperation.dart';
import 'package:yabnet/services/AppFileService.dart';

import '../../collections/common_collection/CountryCollection.dart';
import '../../components/CustomEditTextField.dart';
import '../../components/CustomOnClickContainer.dart';
import '../../components/CustomPrimaryButton.dart';
import '../../components/CustomProject.dart';
import '../../components/CustomSelectDialogField.dart';
import '../../data/CountryData.dart';
import '../../data/ProfessionData.dart';
import '../../db_references/AppFile.dart';
import '../../main.dart';
import '../../operations/MembersOperation.dart';
import '../../supabase/SupabaseConfig.dart';
import 'ChoosePlanPage.dart';
import 'LoginPage.dart';

class InformationPage extends StatefulWidget {
  final String uuid;
  final AppFileServiceData privacyPolicy;

  const InformationPage(
      {Key? key, required this.uuid, required this.privacyPolicy})
      : super(key: key);

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  DateTime? selectedDate;
  String? selectedGender;

  // int referralCodeLength = ReferralOperation.referralCodeLength;
  bool firstNameAvail = false;
  bool lastNameAvail = false;
  bool addressAvail = false;
  bool phoneAvail = false;
  bool referralAvail = true;
  bool phoneCodeChange = false;
  bool professionChange = false;
  bool churchChange = false;
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final referralCodeController = TextEditingController();
  final professionController = TextEditingController();
  final churchController = TextEditingController();
  TextEditingController locationSearchController = TextEditingController();
  TextEditingController countryCodeSearchController = TextEditingController();

  List<ProfessionData> cachedProfessionField = [];
  String? field;
  String? countryCode;
  String? location;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    referralCodeController.dispose();
    addressController.dispose();
    phoneController.dispose();
    professionController.dispose();
    churchController.dispose();
    locationSearchController.dispose();
    countryCodeSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    setLightUiViewOverlay();

    firstNameController.addListener(() {
      setState(() {
        firstNameAvail = firstNameController.text.isNotEmpty;
      });
    });
    lastNameController.addListener(() {
      setState(() {
        lastNameAvail = lastNameController.text.isNotEmpty;
      });
    });
    addressController.addListener(() {
      setState(() {
        addressAvail = addressController.text.isNotEmpty;
      });
    });
    phoneController.addListener(() {
      setState(() {
        phoneAvail = phoneController.text.isNotEmpty;
      });
    });
    professionController.addListener(() {
      setState(() {
        professionChange = professionController.text.isNotEmpty;
      });
    });
    churchController.addListener(() {
      setState(() {
        churchChange = churchController.text.isNotEmpty;
      });
    });
    referralCodeController.addListener(() {
      setState(() {
        // referralAvail = referralCodeController.text.isNotEmpty && referralCodeController.text.length == referralCodeLength || referralCodeController.text.isEmpty;
      });
    });
  }

  void backPressed(bool isSomething) async {}

  String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd - MM - yyyy');
    return formatter.format(dateTime);
  }

  void displayDatePicker() {
    DateTime today = DateTime.now();
    hideKeyboard(context);
    showDatePicker(
            context: context,
            initialDate: today,
            firstDate: today.subtract(const Duration(days: 44057)),
            lastDate: today.subtract(const Duration(days: -365)),
            helpText: "Select Date of Birth",
            initialEntryMode: DatePickerEntryMode.calendarOnly)
        .then((value) {
      if (value != null) {
        setState(() {
          selectedDate = value;
        });
      }
    });
  }

  String capitalizeString(String value) {
    if (value.isEmpty) {
      return "";
    }

    String firstChar = value[0].toUpperCase();
    String restOfString = "";

    if (value.length > 2) {
      restOfString = value.substring(1, value.length);
    } else if (value.length == 2) {
      restOfString = value.substring(1);
    }

    return (firstChar + restOfString).trim();
  }

  void handleUserInfo() async {
    hideKeyboard(context);
    showCustomProgressBar(context);
    String firstName = capitalizeString(firstNameController.text);
    String lastName = capitalizeString(lastNameController.text);
    String address = addressController.text;
    String phone = phoneController.text;
    String profession = professionController.text;
    String church = churchController.text;
    String? email = SupabaseConfig.client.auth.currentUser?.email;
    String referee = referralCodeController.text.toUpperCase().trim();
    // String referId = ReferralOperation().generateReferralCode().trim();

    String? fcmToken = FirebaseConfig().getFcmToken;

    if (referee.isNotEmpty && email != null && fcmToken != null) {
      Future<bool?> verifyReferee = Future.value(true);
      // ReferralOperation().verifyReferee(referee);
      Future<bool?> verifyReferId = Future.value(true);
      // ReferralOperation().verifyReferId(referId);

      await Future.wait([verifyReferee, verifyReferId]).then((verification) {
        if (verification.every((verified) => verified == true)) {
          String sessionCode = MembersOperation().getSessionCode();
          saveUserInfo(
              widget.uuid,
              firstName,
              lastName,
              address,
              phone,
              email,
              selectedDate,
              "referId",
              referee,
              selectedGender!,
              countryCode!,
              widget.privacyPolicy.onlineIndex ??
                  dbReference(AppFile.no_policy),
              sessionCode,
              fcmToken,
              field!,
              profession,
              church,
              location!);
        } else if (verification[0] == false) {
          closeCustomProgressBar(context);
          showToastMobile(msg: "Invalid Referral Code");
        } else if (verification[1] == false) {
          closeCustomProgressBar(context);
          showToastMobile(msg: "Try again!!!");
        } else if (verification[0] == null || verification[1] == null) {
          closeCustomProgressBar(context);
          showToastMobile(msg: "Unable to reach server.");
        }
      }).onError((error, stackTrace) {
        closeCustomProgressBar(context);
        showDebug(msg: "$error $stackTrace");
        showToastMobile(msg: "An error has occurred.");
      });
    } else if (email != null && fcmToken != null) {
      String sessionCode = MembersOperation().getSessionCode();
      saveUserInfo(
          widget.uuid,
          firstName,
          lastName,
          address,
          phone,
          email,
          selectedDate,
          "referId",
          referee,
          selectedGender!,
          countryCode!,
          widget.privacyPolicy.onlineIndex ?? dbReference(AppFile.no_policy),
          sessionCode,
          fcmToken,
          field!,
          profession,
          church,
          location!);
    } else {
      closeCustomProgressBar(context);
      showToastMobile(msg: "Unable to proceed at the moment. Log in again!!!");
      returnToLoginPage();
    }
  }

  void saveUserInfo(
    String id,
    String firstName,
    String lastName,
    String address,
    String phone,
    String email,
    DateTime? dob,
    String referId,
    String referee,
    String gender,
    String phoneCode,
    String privacy_policy,
    String sessionCode,
    String fcm_token,
    String field,
    String profession,
    String church,
    String location,
  ) {
    //   Fetch AppFiles

    AppFileService().fetchAppFiles().then((value) {
      MembersOperation()
          .insertUserRecordBothOnlineAndLocal(
        id,
        lastName,
        firstName,
        "",
        email,
        location,
        address,
        gender,
        phone,
        phoneCode,
        privacy_policy,
        sessionCode,
        fcm_token,
        dob.toString(),
        field,
        church,
        referId,
        referee,
      )
          .then((saved) {
        closeCustomProgressBar(context);
        if (saved) {
          goToPlanPage();
        } else {
          showToastMobile(msg: "Unable to save information at the moment.");
        }
      }).onError((error, stackTrace) {
        closeCustomProgressBar(context);

        showToastMobile(msg: "Unable to save information at the moment.");
      });
    }).onError((error, stackTrace) {
      closeCustomProgressBar(context);
      showToastMobile(msg: "Unable to continue. Try again!");
    });
  }

  void goToPlanPage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ChoosePlanPage()),
      (Route<dynamic> route) => false,
    );
  }

  void returnToLoginPage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  bool enableButtonOnValidateCheck() {
    return firstNameAvail &&
        lastNameAvail &&
        addressAvail &&
        phoneAvail &&
        // professionChange &&
        churchChange &&
        countryCode != null &&
        location != null &&
        selectedDate != null &&
        selectedGender != null &&
        field != null;
  }

  Future<String?> openListOfCountryCodes(BuildContext thisContext) async {
    String? selected;
    CountryData? country;
    WidgetStateNotifier<String> searchNotifier = WidgetStateNotifier();
    String text = '';
    countryCodeSearchController.addListener(() {
      String newText = countryCodeSearchController.text.trim();

      if (text != newText) {
        searchNotifier.sendNewState(newText.trim());
      }
      text = newText;
    });

    await openBottomSheet(thisContext, Builder(builder: (context) {
      setDarkGreyUiViewOverlay();
      return SizedBox(
        height: getScreenHeight(context) * 0.85,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 4,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.cancel),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),

                TextField(
                  controller: countryCodeSearchController,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                      hintText: "eg: Country  ",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black,
                      )),
                ),

                const SizedBox(
                  height: 10,
                ),

                Expanded(
                  child: WidgetStateConsumer(
                      widgetStateNotifier: searchNotifier,
                      widgetStateBuilder: (context, stream) {
                        final countries = CountryCollection.getCountryList();
                        List<MapEntry<String, FlagsCode?>> countryCodes =
                            FlagsCode.values.map((e) {
                          String isoCode = e.toString().split(".")[1];
                          return MapEntry(isoCode, e);
                        }).toList();

                        countries.removeWhere((element) => !element.name
                            .toLowerCase()
                            .contains(stream?.toLowerCase() ?? ''));

                        return ListView.builder(
                            itemCount: countries.length,
                            itemBuilder: (context, index) {
                              CountryData countryData = countries[index];

                              FlagsCode? flagCode;
                              try {
                                flagCode = countryCodes.firstWhere((element) {
                                  return element.key == countryData.isoCode;
                                }).value;
                              } catch (e) {
                                flagCode = null;
                              }

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: StatefulBuilder(builder: (context, set) {
                                  return CustomOnClickContainer(
                                    onTap: () {
                                      set(() {
                                        if (countryData.iso3Code !=
                                            country?.iso3Code) {
                                          selected = countryData.phoneCode;
                                          country = countryData;
                                          Navigator.pop(context);
                                        }
                                      });
                                    },
                                    defaultColor: Colors.transparent,
                                    clickedColor: Colors.grey.shade100,
                                    child: Row(children: [
                                      flagCode != null
                                          ? Flag.fromCode(flagCode,
                                              height: 30,
                                              width: 30,
                                              borderRadius: 15)
                                          : Container(
                                              height: 30,
                                              width: 30,
                                              decoration: BoxDecoration(
                                                  color: Colors.teal,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                            ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                    child: Text(
                                                  countryData.name,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                    child: Text(
                                                        "+${countryData.phoneCode}")),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: Radio<String?>(
                                          value: countryData.iso3Code,
                                          groupValue: country?.iso3Code,
                                          onChanged: (value) {
                                            set(() {
                                              selected = countryData.phoneCode;
                                              country = countryData;
                                              Navigator.pop(context);
                                            });
                                          },
                                        ),
                                      ),
                                    ]),
                                  );
                                }),
                              );
                            });
                      }),
                ),
                //   Continue
                const SizedBox(
                  height: 8,
                ),
              ]),
        ),
      );
    }), color: Colors.grey.shade200)
        .then((value) {
      setLightUiViewOverlay();
    });

    return selected;
  }

  Future<String?> openListOfZambiaLocation(BuildContext thisContext) async {
    String? selected;
    WidgetStateNotifier<String> searchNotifier = WidgetStateNotifier();
    String text = '';
    locationSearchController.addListener(() {
      String newText = locationSearchController.text.trim();

      if (text != newText) {
        searchNotifier.sendNewState(newText.trim());
      }
      text = newText;
    });

    await openBottomSheet(thisContext, Builder(builder: (context) {
      setDarkGreyUiViewOverlay();
      return SizedBox(
        height: getScreenHeight(context) * 0.85,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 4,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.cancel),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),

                TextField(
                  controller: locationSearchController,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                      hintText: "eg: Location ",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black,
                      )),
                ),

                const SizedBox(
                  height: 10,
                ),

                Expanded(
                  child: StreamBuilder(
                      stream: searchNotifier.stream,
                      builder: (context, stream) {
                        final locations = ZambiaLocation().allLocations;
                        locations.removeWhere((element) => !element
                            .toLowerCase()
                            .contains(stream.data?.toLowerCase() ?? ''));
                        return ListView.builder(
                            itemCount: locations.length,
                            itemBuilder: (context, index) {
                              String location = locations[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: StatefulBuilder(builder: (context, set) {
                                  return CustomOnClickContainer(
                                    onTap: () {
                                      set(() {
                                        if (selected != location) {
                                          selected = location;
                                          Navigator.pop(context);
                                        }
                                      });
                                    },
                                    defaultColor: Colors.transparent,
                                    clickedColor: Colors.grey.shade100,
                                    child: Row(children: [
                                      Container(
                                        height: 16,
                                        width: 16,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.black
                                                    .withOpacity(0.6))),
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Expanded(
                                          child: Text(
                                        location,
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold),
                                      )),
                                    ]),
                                  );
                                }),
                              );
                            });
                      }),
                ),
                //   Continue
                const SizedBox(
                  height: 8,
                ),
              ]),
        ),
      );
    }), color: Colors.grey.shade200)
        .then((value) {
      setLightUiViewOverlay();
    });

    return selected;
  }

  Future<String?> openListOfProfessionField(BuildContext thisContext) async {
    String? selected;
    WidgetStateNotifier<String> searchNotifier = WidgetStateNotifier();
    String text = '';
    TextEditingController searchController = TextEditingController();
    searchController.addListener(() {
      String newText = searchController.text.trim();

      if (text != newText) {
        searchNotifier.sendNewState(newText.trim());
      }
      text = newText;
    });

    await openBottomSheet(thisContext, Builder(builder: (context) {
      setDarkGreyUiViewOverlay();
      return SizedBox(
        height: getScreenHeight(context) * 0.85,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 4,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.cancel),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),

                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                      hintText: "eg: Software Developer",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black,
                      )),
                ),

                const SizedBox(
                  height: 10,
                ),

                Expanded(
                  child: StreamBuilder(
                      stream: searchNotifier.stream,
                      builder: (context, stream) {
                        return FutureBuilder(
                            future: ProfessionFieldOperation()
                                .getProfessionList()
                                .timeout(Duration(seconds: 30)),
                            builder: (context, snapshot) {
                              List<ProfessionData> professionField = [];

                              if (cachedProfessionField.isEmpty == true) {
                                if (snapshot.data?.isEmpty == true ||
                                    snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      "No data to show",
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 16),
                                    ),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data == null) {
                                  return Center(
                                    child: progressBarWidget(),
                                  );
                                }

                                professionField = snapshot.data!
                                    .map((e) =>
                                        ProfessionData.fromOnline(e as Map))
                                    .toList();
                              } else {
                                professionField = cachedProfessionField;
                              }
                              professionField.removeWhere((element) => !element
                                  .professionTitle
                                  .toLowerCase()
                                  .contains(stream.data?.toLowerCase() ?? ''));

                              return ListView.builder(
                                  itemCount: professionField.length,
                                  itemBuilder: (context, index) {
                                    String profession =
                                        professionField[index].professionTitle;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      child: StatefulBuilder(
                                          builder: (context, set) {
                                        return CustomOnClickContainer(
                                          onTap: () {
                                            set(() {
                                              if (selected != profession) {
                                                selected = profession;
                                                Navigator.pop(context);
                                              }
                                            });
                                          },
                                          defaultColor: Colors.transparent,
                                          clickedColor: Colors.grey.shade100,
                                          child: Row(children: [
                                            Container(
                                              height: 16,
                                              width: 16,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.black
                                                          .withOpacity(0.6))),
                                            ),
                                            SizedBox(
                                              width: 4,
                                            ),
                                            Expanded(
                                                child: Text(
                                              profession,
                                              style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold),
                                            )),
                                          ]),
                                        );
                                      }),
                                    );
                                  });
                            });
                      }),
                ),
                //   Continue
                const SizedBox(
                  height: 8,
                ),
              ]),
        ),
      );
    }), color: Colors.grey.shade200)
        .then((value) {
      setLightUiViewOverlay();
    });

    return selected;
  }

  List<MapEntry<Widget, dynamic Function()>> getGender() {
    return [
      MapEntry(
          const Text(
            "Male",
            style: TextStyle(fontSize: 18),
            textScaler: TextScaler.noScaling,
          ), () {
        setState(() {
          selectedGender = "Male";
        });
      }),
      MapEntry(
          const Text(
            "Female",
            style: TextStyle(fontSize: 18),
            textScaler: TextScaler.noScaling,
          ), () {
        setState(() {
          selectedGender = "Female";
        });
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PopScope(
        onPopInvoked: backPressed,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      //  Confirm Text
                      const SizedBox(height: 50),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("What about you?",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            )),
                      ),

                      // Confirming Text
                      const SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "Tell us something we only want to know from you.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),
                      //  First Name Text
                      const SizedBox(
                        height: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CustomEditTextField(
                            capitalization: TextCapitalization.words,
                            keyboardType: TextInputType.text,
                            controller: firstNameController,
                            hintText: "Firstname",
                            obscureText: false,
                            useShadow: false,
                            textSize: 16),
                      ),

                      //  Last Name Text
                      const SizedBox(
                        height: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CustomEditTextField(
                            capitalization: TextCapitalization.words,
                            keyboardType: TextInputType.text,
                            controller: lastNameController,
                            hintText: "Lastname",
                            obscureText: false,
                            useShadow: false,
                            textSize: 16),
                      ),

                      //  DOB Picker
                      const SizedBox(
                        height: 16,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: GestureDetector(
                                onTap: displayDatePicker,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Date of birth",
                                      style: TextStyle(
                                          color: Color(getDarkGreyColor),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          boxShadow: [
                                            // BoxShadow(
                                            //   color: Colors.black.withOpacity(0.1),
                                            //   blurRadius: 8,
                                            //   offset: const Offset(0, 4),
                                            // ),
                                          ],
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 20),
                                            child: Text(
                                              selectedDate == null
                                                  ? "Date of birth"
                                                  : formatDateTime(
                                                      selectedDate!),
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: selectedDate == null
                                                      ? const Color(
                                                          getLighterGreyColor)
                                                      : Colors.black),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Gender",
                                    style: TextStyle(
                                        color: Color(getDarkGreyColor),
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  PopupMenuButton(
                                      color: Colors.grey.shade200,
                                      surfaceTintColor: Colors.transparent,
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            boxShadow: [
                                              // BoxShadow(
                                              //   color: Colors.black.withOpacity(0.1),
                                              //   blurRadius: 8,
                                              //   offset: const Offset(0, 4),
                                              // ),
                                            ],
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 20),
                                              child: Text(
                                                selectedGender == null
                                                    ? "Gender"
                                                    : selectedGender!,
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: selectedGender ==
                                                            null
                                                        ? const Color(
                                                            getLighterGreyColor)
                                                        : Colors.black),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      onSelected: (itemIndex) {
                                        getGender()
                                            .elementAtOrNull(itemIndex)
                                            ?.value
                                            .call();
                                      },
                                      itemBuilder: (context) {
                                        return getGender()
                                            .asMap()
                                            .map((index, e) {
                                              return MapEntry(
                                                  index,
                                                  PopupMenuItem(
                                                      value: index,
                                                      child: e.key));
                                            })
                                            .values
                                            .toList();
                                      }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      //  Phone Text
                      const SizedBox(
                        height: 16,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            // Code
                            CustomSelectDialogField<String?>(
                              wrap: true,
                              hintText: 'Code',
                              text:
                                  countryCode != null ? " +$countryCode" : null,
                              useShadow: false,
                              textStyle: const TextStyle(fontSize: 16),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 8),
                              onTap: () async {
                                final code =
                                    await openListOfCountryCodes(context);
                                countryCodeSearchController.clear();
                                if (code != null) {
                                  setState(() {
                                    countryCode = code;
                                  });
                                }
                              },
                            ),

                            // Phone
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: CustomEditTextField(
                                  keyboardType: TextInputType.number,
                                  controller: phoneController,
                                  hintText: "Phone",
                                  useShadow: false,
                                  obscureText: false,
                                  textSize: 16),
                            ),
                          ],
                        ),
                      ),

                      // Location

                      SizedBox(
                        height: 16,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CustomSelectDialogField<String?>(
                          hintText: 'Location',
                          text: location != null ? " $location" : null,
                          useShadow: false,
                          textStyle: const TextStyle(fontSize: 16),
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 8),
                          onTap: () async {
                            final getLocation =
                                await openListOfZambiaLocation(context);
                            locationSearchController.clear();
                            if (getLocation != null) {
                              setState(() {
                                location = getLocation;
                              });
                            }
                          },
                        ),
                      ),

                      //  Address Text
                      const SizedBox(
                        height: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CustomEditTextField(
                            controller: addressController,
                            hintText: "Address",
                            useShadow: false,
                            obscureText: false,
                            textSize: 16),
                      ),

                      //  Church
                      const SizedBox(
                        height: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CustomEditTextField(
                            capitalization: TextCapitalization.words,
                            controller: churchController,
                            hintText: "Church",
                            obscureText: false,
                            useShadow: false,
                            textSize: 16),
                      ),

                      // Profession Field

                      SizedBox(
                        height: 16,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CustomSelectDialogField<String?>(
                          hintText: 'Profession Field',
                          text: field != null ? " $field" : null,
                          useShadow: false,
                          textStyle: const TextStyle(fontSize: 16),
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 8),
                          onTap: () async {
                            final getProfessionField =
                                await openListOfProfessionField(context);
                            if (getProfessionField != null) {
                              setState(() {
                                field = getProfessionField;
                              });
                            }
                          },
                        ),
                      ),

                      // //  Profession Entering
                      // const SizedBox(
                      //   height: 16,
                      // ),
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 24),
                      //   child: CustomEditTextField(
                      //       capitalization: TextCapitalization.words,
                      //       controller: professionController,
                      //       hintText: "Specify Profession",
                      //       obscureText: false,
                      //       useShadow: false,
                      //       textSize: 16),
                      // ),

                      //  Referral code Text
                      const SizedBox(
                        height: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CustomEditTextField(
                            // maxLength: referralCodeLength,
                            capitalization: TextCapitalization.characters,
                            controller: referralCodeController,
                            useShadow: false,
                            hintText: "Referral code (Optional)",
                            obscureText: false,
                            textSize: 16),
                      ),

                      //  Save Button
                      const SizedBox(
                        height: 50,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: CustomPrimaryButton(
                                  buttonText: "Save",
                                  onTap: handleUserInfo,
                                  isEnabled: enableButtonOnValidateCheck()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 50,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
