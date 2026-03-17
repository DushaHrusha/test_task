import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:test_task/core/adaptive_size_extension.dart';
import 'package:test_task/presentation/sign_up_screen.dart';

class CustomTextFieldWithGradientButton extends StatelessWidget {
  final String text;
  final TextStyle style;
  const CustomTextFieldWithGradientButton({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.adaptiveSize(56),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.adaptiveSize(30)),
        color: Color.fromARGB(0, 177, 11, 11),
        border: Border.all(
          color: const Color.fromARGB(255, 224, 224, 224),
          width: context.adaptiveSize(1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text,
              style: context.adaptiveTextStyle(
                fontSize: style.fontSize ?? 14,
                fontWeight: style.fontWeight,
                color: style.color,
                fontFamily: style.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              height: context.adaptiveSize(56),
              width: context.adaptiveSize(190),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 255, 127, 80),
                    Color.fromARGB(255, 85, 97, 178),
                  ],
                  begin: AlignmentGeometry.directional(-2, -3),
                ),
                borderRadius: BorderRadius.circular(context.adaptiveSize(30)),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(127, 255, 175, 175),
                    spreadRadius: 0,
                    blurRadius: context.adaptiveSize(20),
                    offset: Offset(
                      context.adaptiveSize(-5),
                      context.adaptiveSize(-5),
                    ),
                  ),
                  BoxShadow(
                    color: Color.fromARGB(127, 132, 147, 197),
                    spreadRadius: 0,
                    blurRadius: context.adaptiveSize(20),
                    offset: Offset(
                      context.adaptiveSize(3),
                      context.adaptiveSize(3),
                    ),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Book now',
                          style: context.adaptiveTextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: context.adaptiveSize(56),
                    width: context.adaptiveSize(1),
                    color: const Color.fromARGB(255, 138, 120, 178),
                  ),
                  SizedBox(
                    width: context.adaptiveSize(60),
                    child: SvgPicture.asset(
                      "assets/file/Vector(1).svg",
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
