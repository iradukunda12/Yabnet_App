import 'package:flutter/material.dart';

import '../components/FeatureComingSoonWidget.dart';

class ProfilePagePollHandler extends StatefulWidget {
  const ProfilePagePollHandler({super.key});

  @override
  State<ProfilePagePollHandler> createState() => _ProfilePagePollHandlerState();
}

class _ProfilePagePollHandlerState extends State<ProfilePagePollHandler> {
  @override
  Widget build(BuildContext context) {
    // return Center(
    //   child: Container(
    //     height: 150,
    //     width: 150,
    //     decoration: BoxDecoration(
    //       color: Colors.pink.shade400,
    //       borderRadius: BorderRadius.circular(15),
    //     ),
    //     child: Padding(
    //       padding: const EdgeInsets.all(10),
    //       child: Container(
    //         decoration: BoxDecoration(
    //           color: Colors.transparent,
    //           border: Border.all(color: Colors.white,width: 10),
    //           borderRadius: BorderRadius.circular(15),
    //         ),
    //         child:Center(
    //           child: Padding(
    //             padding: const EdgeInsets.symmetric(horizontal: 10,),
    //             child: Text("Popcorn",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18),),
    //           ),
    //         ),
    //       ),
    //     ),
    //   ),
    // );

    return Scaffold(
      body: Center(
        child: FeatureComingSoon(
          icon: Icons.poll,
          featureName: 'Poll Post',
          description:
              "Cast your vote now and be a part of the decision-making process",
        ),
      ),
    );
  }
}
