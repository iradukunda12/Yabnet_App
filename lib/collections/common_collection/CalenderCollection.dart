import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/components/ExpandedPageView.dart';
import 'package:yabnet/main.dart';

class CalenderCollection extends StatefulWidget {
  const CalenderCollection({super.key});

  @override
  State<CalenderCollection> createState() => _CalenderCollectionState();
}

class _CalenderCollectionState extends State<CalenderCollection> {
  PageController pageController = PageController();

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                  child: Text("Calender",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold))),
              CustomOnClickContainer(
                defaultColor: Colors.transparent,
                clickedColor: Colors.grey.shade300,
                onTap: () {},
                child: Text("View all",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.normal)),
              )
            ],
          ),
        ),
        SizedBox(
          height: 12,
        ),
        SizedBox(
          height: 200,
          child: ExpandablePageView(
            pageController: pageController,
            epViews: List.generate(
                10,
                (index) => EPView(
                        child: getCalenderView(
                      "May ${index + 10}th",
                      "President of zambia is coming to kigali to have breakfast, lunch and dinner with Mr Ajibewa Johnson Irekanmi",
                    ))),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        SmoothPageIndicator(
          controller: pageController,
          count: 10,
          effect: WormEffect(
              dotHeight: 10,
              dotWidth: 10,
              activeDotColor: Color(getMainPinkColor)),
        ),
        SizedBox(
          height: 8,
        ),
      ],
    );
  }

  Widget getCalenderView(String title, String description,
      {Function()? onTapped}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        child: Row(
          children: [
            Expanded(
              child: CustomOnClickContainer(
                  onTap: onTapped,
                  height: 200,
                  borderRadius: BorderRadius.circular(15),
                  defaultColor: Colors.transparent,
                  clickedColor: Colors.grey.shade800,
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CachedNetworkImage(
                          filterQuality: FilterQuality.medium,
                          fit: BoxFit.cover,
                          imageUrl:
                              'https://hhzjrsdoyuquaonivive.supabase.co/storage/v1/object/public/profile_bucket/12ee29b3-1022-4946-b360-f4fb385a7f2e_LVM1OTUUDCR6XN',
                          errorWidget: (a, b, c) {
                            showDebug(msg: a);
                            showDebug(msg: b);
                            showDebug(msg: c);
                            return SizedBox();
                          },
                          progressIndicatorBuilder: (a, b, c) {
                            return Center(
                              child: progressBarWidget(),
                            );
                          },
                        ),
                      ),
                      Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.grey.withOpacity(0.4),
                                  Colors.grey.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, bottom: 8, right: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ))
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
