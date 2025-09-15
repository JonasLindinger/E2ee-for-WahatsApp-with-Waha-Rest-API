import 'package:flutter/material.dart';
import 'package:secure_messanger_app/screens/SettingsScreen.dart'; // Import your settings file

class CenterCircle extends StatelessWidget {
  final Color color;
  final double height;
  final double width;
  final IconData icon;

  const CenterCircle({
    super.key,
    required this.color,
    this.height = 100,
    this.width = 100,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // You can choose different animations here
                // Example 1: Fade-in Transition
                // return FadeTransition(
                //   opacity: animation,
                //   child: child,
                // );

                // Example 2: Slide-up Transition
                const begin = Offset(0.0, 1.0); // Starts from the bottom
                const end = Offset.zero; // Ends at its normal position
                const curve = Curves.ease;

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ),
          );
        },
        child: Container(
          height: height,
          width: width,
          margin: const EdgeInsets.only(right: 16.0, bottom: 16.0),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: height * 0.6,
          ),
        ),
      ),
    );
  }
}