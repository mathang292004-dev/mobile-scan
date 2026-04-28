import 'dart:ui';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';

class UserGuidancePopup extends StatefulWidget {
  const UserGuidancePopup({super.key});

  @override
  State<UserGuidancePopup> createState() => _UserGuidancePopupState();
}

class _UserGuidancePopupState extends State<UserGuidancePopup> {
  final OverlayPortalController _controller = OverlayPortalController();
  final LayerLink _link = LayerLink();
  bool _isOpen = false;

  void _togglePopup() {
    setState(() {
      _isOpen = !_isOpen;
    });
    _controller.toggle();
  }

  void _closePopup() {
    setState(() {
      _isOpen = false;
    });
    _controller.hide();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (BuildContext context) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closePopup, // tap outside to close
            child: Stack(
              children: [
                Positioned.fill(child: Container(color: Colors.transparent)),
                CompositedTransformFollower(
                  link: _link,
                  targetAnchor: Alignment.bottomLeft,
                  followerAnchor: Alignment.topLeft,
                  offset: Offset(-MediaQuery.of(context).size.width * 0.82, 5), // matches your design
                  child: Material(
                    color: Colors.transparent,
                    child: UserGuidanceCard(onClose: _closePopup),
                  ),
                ),
              ],
            ),
          );
        },
        child: GestureDetector(
          onTap: _togglePopup,
          child: Image.asset(
            Assets.infoIcon,
            height: 30,
            width: 30,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class UserGuidanceCard extends StatelessWidget {
  final VoidCallback onClose;
  const UserGuidanceCard({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.35, sigmaY: 10.35),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ColorHelper.surfaceColor , width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.15),
                blurRadius: 37.8,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TextHelper.userGuidanceTitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _buildPoint(
                context,
                title: TextHelper.userGuidanceRecordByVoiceTitle,
                points: [
                  TextHelper.userGuidanceRecordByVoicePoint1,
                  TextHelper.userGuidanceRecordByVoicePoint2,
                ],
              ),
              const SizedBox(height: 10),
              _buildPoint(
                context,
                title: TextHelper.userGuidanceEnterByTextTitle,
                points: [
                  TextHelper.userGuidanceEnterByTextPoint1,
                  TextHelper.userGuidanceEnterByTextPoint2,
                ],
              ),
              const SizedBox(height: 10),
              _buildPoint(
                context,
                title: TextHelper.userGuidanceContinueTitle,
                isBulletin: false,
                points: [
                  TextHelper.userGuidanceContinuePoint,
                ],
              ),
              const SizedBox(height: 16),
              EmergexButton(
                text: TextHelper.userGuidanceGotItBtnTxt,
                fontWeight: FontWeight.w500,
                onPressed: onClose,
                borderRadius: 8,
                textColor: Colors.white,
                colors: const [
                  Color(0xFF3DA229), // gradient start
                  Color(0xFF247814), // gradient end
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoint(BuildContext context, {required String title, required List<String> points, bool isBulletin = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        ...points.map(
              (e) => Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(isBulletin) Text("•  ", style: Theme.of(context).textTheme.bodyMedium),
                Expanded(
                  child: Text(
                    e,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
