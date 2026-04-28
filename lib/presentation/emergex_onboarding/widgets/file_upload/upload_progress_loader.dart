import 'dart:async';
import 'dart:ui';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

enum _StepStatus { completed, active, pending }

const List<double> _kPendingOpacity = [1.0, 0.50, 0.30, 0.10];

class UploadProgressLoader extends StatefulWidget {
  final double progress;
  final String? fileName;
  final String? statusText;
  final bool isCompleted;
  final bool isFailed;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final List<String>? steps;
  final String? message;

  const UploadProgressLoader({
    super.key,
    required this.progress,
    this.fileName,
    this.statusText,
    this.isCompleted = false,
    this.isFailed = false,
    this.onRetry,
    this.onCancel,
    this.steps,
    this.message,
  });

  @override
  State<UploadProgressLoader> createState() => _UploadProgressLoaderState();
}

class _UploadProgressLoaderState extends State<UploadProgressLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prevProgress = 0.0;

  Timer? _dotTimer;
  int _dotCount = 1;

  late final List<String> _steps;

  double get _ep =>
      widget.isCompleted ? 1.0 : widget.progress.clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _steps = widget.steps ??
        const [
          TextHelper.analyzingIncidentData,
          TextHelper.searchingAvailableMembers,
          TextHelper.assigningResponsibilities,
          TextHelper.finalizingTeams,
        ];

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = Tween<double>(begin: 0.0, end: _ep).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _ctrl.forward();

    if (!widget.isCompleted && !widget.isFailed) _startDots();
  }

  void _startDots() {
    _dotTimer?.cancel();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 480), (_) {
      if (mounted) setState(() => _dotCount = (_dotCount % 4) + 1);
    });
  }

  @override
  void didUpdateWidget(covariant UploadProgressLoader old) {
    super.didUpdateWidget(old);
    if (_ep != _prevProgress) {
      _prevProgress = _anim.value;
      _anim = Tween<double>(begin: _prevProgress, end: _ep).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      );
      _ctrl
        ..reset()
        ..forward();
    }
    if ((widget.isCompleted || widget.isFailed) && _dotTimer != null) {
      _dotTimer?.cancel();
      _dotTimer = null;
    } else if (!widget.isCompleted && !widget.isFailed && _dotTimer == null) {
      _startDots();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _dotTimer?.cancel();
    super.dispose();
  }

  int get _activeIdx {
    if (_steps.isEmpty) return 0;
    if (widget.isCompleted) return _steps.length;
    final idx = (_ep / (1.0 / _steps.length)).floor();
    return idx.clamp(0, _steps.length - 1);
  }

  _StepStatus _status(int i) {
    if (widget.isCompleted) return _StepStatus.completed;
    if (i < _activeIdx) return _StepStatus.completed;
    if (i == _activeIdx) return _StepStatus.active;
    return _StepStatus.pending;
  }

  double _pendingOpacity(int i) {
    final offset = i - _activeIdx;
    if (offset <= 0) return 1.0;
    final idx = (offset - 1).clamp(0, _kPendingOpacity.length - 1);
    return _kPendingOpacity[idx + 1];
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 42.75, sigmaY: 42.75),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: ColorHelper.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorHelper.white),
          ),
          padding: const EdgeInsets.all(24),
          child: widget.isFailed
              ? _buildFailed(context)
              : _buildNormal(context),
        ),
      ),
    );
  }

  Widget _buildNormal(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(),
        const SizedBox(height: 14),

        _buildTitleBlock(context),
        const SizedBox(height: 14),

        _buildProgressSection(context),
        const SizedBox(height: 14),

        _buildStepSection(context),

        if (widget.onCancel != null && !widget.isCompleted) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.onCancel,
            child: Text(
              TextHelper.cancel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColorHelper.errorColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFailed(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: ColorHelper.errorColor,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.error_outline_rounded,
                size: 28, color: ColorHelper.white),
          ),
        ),
        const SizedBox(height: 14),

        Text(
          TextHelper.uploadFailed,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: ColorHelper.errorColor,
              ),
        ),
        const SizedBox(height: 5),

        Text(
          widget.statusText ?? TextHelper.somethingWentWrong,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: ColorHelper.black4,
              ),
        ),

        if (widget.onRetry != null) ...[
          const SizedBox(height: 20),
          GestureDetector(
            onTap: widget.onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: ColorHelper.errorColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                TextHelper.retry,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorHelper.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: ColorHelper.selectedIconBackground,
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          size: 26,
          color: ColorHelper.white,
        ),
      ),
    );
  }

  Widget _buildTitleBlock(BuildContext context) {
    final subtitle = widget.statusText ??
        (widget.fileName != null
            ? '${TextHelper.uploading} ${widget.fileName}'
            : TextHelper.aiAnalysisSubtitle);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          TextHelper.aiAnalysis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: ColorHelper.black5,
                height: 26 / 16,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(height: 5),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: ColorHelper.black4,
                height: 20 / 12,
              ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final value = _anim.value.clamp(0.0, 1.0);
        final pct = (value * 100).toInt();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TextHelper.progressLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: ColorHelper.primaryColor,
                        letterSpacing: -0.2,
                      ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pct',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: ColorHelper.primaryColor,
                          ),
                    ),
                    Text(
                      '%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: ColorHelper.primaryColor,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: ColorHelper.white,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  ColorHelper.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _steps.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _buildStepRow(context, i),
            ],
          ],
        ),
        const SizedBox(height: 14),

        Text(
          TextHelper.aiAnalysisFooter,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.normal,
                fontSize: 11,
                color: const Color(0xFFA4A4A4),
                height: 18 / 11,
              ),
        ),
      ],
    );
  }

  Widget _buildStepRow(BuildContext context, int i) {
    final st = _status(i);
    final isActive = st == _StepStatus.active;
    final isPending = st == _StepStatus.pending;
    final isCompleted = st == _StepStatus.completed;

    final opacity = isPending ? _pendingOpacity(i) : 1.0;

    if (isCompleted) {
      return Opacity(
        opacity: 0.63,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0x100A9952),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check, size: 12, color: ColorHelper.white),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  _trimDots(_steps[i]),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: const Color(0xFF0A0C11),
                      ),
                ),
              ),

              Text(
                'Completed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.normal,
                      fontSize: 11,
                      color: const Color(0xFF0A9952),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: ColorHelper.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ColorHelper.white),
        ),
        child: Row(
          children: [
            _buildStepIcon(),
            const SizedBox(width: 10),

            Expanded(
              child: Text(
                _steps[i],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: const Color(0xFF0A0C11),
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(
              width: 32,
              height: 10,
              child: isActive ? _buildDots() : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIcon() {
    return ClipOval(
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment(-0.47, -0.88),
            end: Alignment(0.47, 0.88),
            colors: [
              Color(0xFF3DA229),
              Color(0xFF397626),
              Color(0xFF173C0F),
            ],
            stops: [0.0, 0.611, 1.0],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 13,
            color: ColorHelper.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    const dotSizes = [4.0, 6.0, 4.0, 4.0];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(4, (i) {
        final sz = dotSizes[i];
        final isLit = i < _dotCount;
        return Padding(
          padding: EdgeInsets.only(right: i < 3 ? 4.0 : 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: sz,
            height: sz,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLit
                  ? const Color(0xFF51AC3F)
                  : const Color(0xFF51AC3F).withValues(alpha: 0.25),
            ),
          ),
        );
      }),
    );
  }

  String _trimDots(String text) => text.replaceAll(RegExp(r'[.]+$'), '');
}

class UploadProgressBar extends StatelessWidget {
  final double progress;
  final String message;

  const UploadProgressBar({
    super.key,
    required this.progress,
    this.message = TextHelper.uploading,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0.0, 1.0) * 100).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: ColorHelper.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorHelper.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColorHelper.textPrimary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorHelper.primaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: ColorHelper.primaryColor.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                ColorHelper.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UploadOverlay extends StatelessWidget {
  final double progress;
  final String? message;
  final String? fileName;
  final bool isCompleted;
  final bool isFailed;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  const UploadOverlay({
    super.key,
    required this.progress,
    this.message,
    this.fileName,
    this.isCompleted = false,
    this.isFailed = false,
    this.onCancel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarH = MediaQuery.of(context).padding.top;
    final appBarH = AppBar().preferredSize.height;

    return Positioned(
      top: -(statusBarH + appBarH),
      left: 0,
      right: 0,
      bottom: 0,
      child: PopScope(
        canPop: false,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: ColorHelper.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: UploadProgressLoader(
                    progress: progress,
                    fileName: fileName,
                    statusText: message,
                    isCompleted: isCompleted,
                    isFailed: isFailed,
                    onCancel: onCancel,
                    onRetry: onRetry,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
