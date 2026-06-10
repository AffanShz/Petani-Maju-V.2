import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  // Factory constructor for rectangular skeleton
  const SkeletonContainer.square({
    super.key,
    required double width,
    required double height,
    BorderRadius? borderRadius,
  })  : width = width,
        height = height,
        borderRadius =
            borderRadius ?? const BorderRadius.all(Radius.circular(12));

  // Factory constructor for rounded/circular skeleton
  const SkeletonContainer.circular({
    super.key,
    required double width,
    required double height,
  })  : width = width,
        height = height,
        borderRadius = const BorderRadius.all(Radius.circular(100));

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
