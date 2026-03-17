import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_task/bloc/cubits/bookmarks_cubit.dart';
import 'package:test_task/data/models/bookmark.dart';
import 'package:test_task/core/adaptive_size_extension.dart';
import 'package:test_task/core/constants/base_colors.dart';
import 'package:test_task/data/models/card_data.dart';
import 'package:test_task/presentation/apartment_detail_screen.dart';
import 'package:test_task/core/constants/custom_text_field_with_gradient_button.dart';

class SecondCard extends StatelessWidget {
  final CardData data;
  final BuildContext context;
  final TextStyle style;
  final int index;
  const SecondCard({
    super.key,
    required this.index,
    required this.context,
    required this.style,
    required this.data,
  });

  String _getFirstSentence(String text) {
    final sentenceRegex = RegExp(r'^(.*?[.!?])');
    final match = sentenceRegex.firstMatch(text);
    return match != null ? match.group(1)!.trim() : text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.adaptiveSize(44)),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(context.adaptiveSize(32)),
              ),
              border: Border.all(color: Color.fromARGB(255, 224, 224, 224)),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(context.adaptiveSize(32)),
                        topRight: Radius.circular(context.adaptiveSize(32)),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: data.imageUrl.first,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) =>
                                Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                    Positioned(
                      right: context.adaptiveSize(24),
                      top: context.adaptiveSize(24),
                      child: BlocBuilder<BookmarksCubit, List<Bookmark>>(
                        builder: (context, bookmarks) {
                          final isBookmarked = context
                              .read<BookmarksCubit>()
                              .isBookmarked(data);
                          return GestureDetector(
                            onTap: () {
                              context.read<BookmarksCubit>().toggleBookmark(
                                data,
                              );
                            },
                            child: Container(
                              height: context.adaptiveSize(56),
                              width: context.adaptiveSize(56),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(context.adaptiveSize(16)),
                                ),
                                shape: BoxShape.rectangle,
                                color: Color.fromARGB(87, 255, 255, 255),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(context.adaptiveSize(16)),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 5.0,
                                    sigmaY: 5.0,
                                  ),
                                  child: Icon(
                                    isBookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_outline,
                                    color:
                                        isBookmarked
                                            ? BaseColors.accent
                                            : Color.fromARGB(
                                              255,
                                              251,
                                              251,
                                              253,
                                            ),
                                    size: context.adaptiveSize(25),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.adaptiveSize(16)),
                Padding(
                  padding: EdgeInsets.only(
                    left: context.adaptiveSize(23),
                    right: context.adaptiveSize(23),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: context.adaptiveSize(8),
                          runSpacing: context.adaptiveSize(8),
                          children: [
                            Text(
                              data.title,
                              softWrap: true,
                              style: context.adaptiveTextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: BaseColors.text,
                              ),
                            ),
                            StarRating(rating: data.rating),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.adaptiveSize(12)),
                Padding(
                  padding: EdgeInsets.only(
                    left: context.adaptiveSize(23),
                    right: context.adaptiveSize(23),
                  ),
                  child: Container(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      _getFirstSentence(data.description),
                      style: context.adaptiveTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: BaseColors.text,
                      ),
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),

                SizedBox(height: context.adaptiveSize(21)),
              ],
            ),
          ),
          SizedBox(height: context.adaptiveSize(21)),
          CustomTextFieldWithGradientButton(
            text: "${data.price.toStringAsFixed(0)} €",
            style: style,
          ),
        ],
      ),
    );
  }
}
