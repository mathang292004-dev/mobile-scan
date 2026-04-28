import 'package:flutter/material.dart';
import 'package:emergex/generated/assets.dart';

/// Bottom input bar widget for typing and sending messages
class ChatInputBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSendPressed;
  final VoidCallback? onAttachmentPressed;
  final VoidCallback? onGalleryPressed;
  final ValueChanged<String>? onChanged;
  final String placeholder;
  final bool isUploading;

  const ChatInputBarWidget({
    super.key,
    required this.controller,
    this.onSendPressed,
    this.onAttachmentPressed,
    this.onGalleryPressed,
    this.onChanged,
    this.placeholder = 'Will prepare full incident report...',
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color.fromRGBO(61, 162, 41, 0.15),
            width: 4,
          ),
        ),
        child: Row(
          children: [
            /// TEXT FIELD
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(
                  backgroundColor: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: Color(0xFF3D3D3D),
                ),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: Color(0xFF3D3D3D),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.only(left: 8),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSendPressed?.call(),
              ),
            ),

            /// ATTACHMENT BUTTON
            GestureDetector(
              onTap: isUploading ? null : onAttachmentPressed,
              child: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3DA229).withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    Assets.attach,
                    width: 18,
                    height: 18,
                    color: isUploading ? Colors.grey : const Color(0xFF3DA229),
                  ),
                ),
              ),
            ),

            /// IMAGE BUTTON
            GestureDetector(
              onTap: isUploading ? null : onGalleryPressed,
              child: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3DA229).withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    Assets.chatImage,
                    width: 18,
                    height: 18,
                    color: isUploading ? Colors.grey : const Color(0xFF3DA229),
                  ),
                ),
              ),
            ),

            /// SEND BUTTON
            GestureDetector(
              onTap: isUploading ? null : onSendPressed,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFF3DA229),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
