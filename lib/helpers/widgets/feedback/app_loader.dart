import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui'; // For ImageFilter

class LogoLoader extends StatelessWidget {
  final double size; // overall size of the loader
  final bool canPop; // whether user can pop/back when loader is shown

  const LogoLoader({super.key, this.size = 75, this.canPop = false});

  @override
  Widget build(BuildContext context) {
    const String svgCode = '''
    <svg viewBox="0 0 314 287" xmlns="http://www.w3.org/2000/svg">
      <path d="M221.594 286.854H311.866L221.594 138.401L314 0H223.728L136.098 138.401L221.594 286.854Z" fill="#3DA229"/>
      <path d="M182.727 201.853L142.986 257.806H54.7653L134.533 138.401L54.5195 27.6133H144.791L182.727 84.3503L220.03 138.401L182.727 201.853Z" fill="#272727"/>
      <path d="M147.289 108.596V175.74H13V108.596H147.289Z" fill="#272727"/>
    </svg>
    ''';

    return PopScope(
      canPop: canPop,
      child: Container(
        color: ColorHelper.transparent,
        width: double.infinity,
        height: double.infinity,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SvgPicture.string(
                    svgCode,
                    width: size * 0.45,
                    height: size * 0.45,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoaderService extends ChangeNotifier {
  static final LoaderService _instance = LoaderService._internal();
  factory LoaderService() => _instance;
  LoaderService._internal();

  bool _isShowing = false;

  void showLoader() {
    if (!_isShowing) {
      _isShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void hideLoader() {
    if (_isShowing) {
      _isShowing = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  bool get isShowing => _isShowing;
}

final loaderService = LoaderService();
