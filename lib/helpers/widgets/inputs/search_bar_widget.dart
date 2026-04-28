import 'dart:async';
import 'package:emergex/presentation/emergex_onboarding/widgets/client/client_filter_dialog.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/project/project_filter_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/presentation/case_report/member/cubit/dashboard_cubit.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';

class SearchBarWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final String? hintText;
  final TextStyle? textStyle;
  final IconData? prefixIcon;
  final double? prefixIconSize;
  final Color? prefixIconColor;
  final IconData? suffixIcon;
  final Widget? suffixIconWidget;
  final OutlineInputBorder? border;
  final bool? incidentSection;
  final bool? clientSection;
  final bool? projectSection;
  final ValueChanged<String>? onChanged;

  const SearchBarWidget({
    super.key,
    this.width,
    this.height,
    this.hintText,
    this.textStyle,
    this.prefixIcon,
    this.prefixIconSize,
    this.prefixIconColor,
    this.suffixIcon,
    this.suffixIconWidget,
    this.border,
    this.incidentSection = false,
    this.clientSection = false,
    this.projectSection = false,
    this.onChanged,
  });

  @override
  State<SearchBarWidget> createState() => SearchBarWidgetState();
}

class SearchBarWidgetState extends State<SearchBarWidget> {
  Timer? _debounceTimer;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    // Initialize focus node to manage focus explicitly
    _focusNode = FocusNode();

    // Initialize controller with current search query from Cubit state.
    // This ensures the search text is restored when navigating back to the screen.
    // The Cubit is the single source of truth for the search query.
    _controller = TextEditingController(text: _getInitialSearchText());
  }

  /// Gets the initial search text from the appropriate Cubit based on section type.
  /// This ensures UI state (TextEditingController) syncs with Cubit state on rebuild.
  String _getInitialSearchText() {
    if (widget.incidentSection == true) {
      // Restore from DashboardCubit for incident section
      final currentState = AppDI.dashboardCubit.state;
      if (currentState is DashboardLoaded && currentState.searchQuery != null) {
        return currentState.searchQuery!;
      }
    } else if (widget.clientSection == true) {
      // Restore from ClientCubit for client section
      final searchQuery = AppDI.clientCubit.state.appliedFilters?.search;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        return searchQuery;
      }
    } else if (widget.projectSection == true) {
      // Restore from ProjectCubit for project section
      final searchQuery = AppDI.projectCubit.state.appliedFilters?.search;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        return searchQuery;
      }
    }
    return '';
  }

  String get _dynamicPlaceholder {
    // If custom hintText is explicitly provided, use it
    if (widget.hintText?.isNotEmpty ?? false) {
      return widget.hintText!;
    }
    // Otherwise, determine based on section flags
    if (widget.projectSection == true) return 'Search Project';
    if (widget.clientSection == true) return 'Search Client';
    if (widget.incidentSection == true) return 'Search Incidents';
    return 'Search'; // default fallback
  }

  void clearSearchBar() {
    _controller.clear();
  }

  String getSearchBarText() {
    return _controller.text;
  }

  /// Explicitly clears focus from the search bar.
  /// This should be called before opening drawer/sidebar to prevent keyboard flicker.
  void unfocus() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  /// Check if the search bar currently has focus.
  bool get hasFocus => _focusNode.hasFocus;

  @override
  Widget build(BuildContext context) {
    // Only listen to cubit state changes for incident section when no custom callback
    final isIncidentSection = widget.incidentSection == true;
    final needsCubitSync = isIncidentSection && widget.onChanged == null;

    final textField = Stack(
      alignment: Alignment.centerLeft,
      children: [
        AppTextField(
          controller: _controller,
          focusNode: _focusNode,
          hint: '', // 🔥 disable default hint
          textStyle: TextStyle(color: ColorHelper.searchInputTextColor),
          fillColor: ColorHelper.surfaceColor.withValues(alpha: 0.5),
          border: widget.border,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          onChanged: _handleSearchChanged,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 6),
            child: Image.asset(
              Assets.searchicon,
              width: widget.prefixIconSize ?? 14,
              height: widget.prefixIconSize ?? 14,
              color: widget.prefixIconColor,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 20,
            minHeight: 20,
          ),
          suffixIcon: _buildSuffixIcon(context),
        ),

        // ✅ Custom placeholder (never truncates)
        IgnorePointer(
          child: Padding(
            padding: const EdgeInsets.only(left: 32), // icon spacing
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                if (_controller.text.isNotEmpty) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _dynamicPlaceholder,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorHelper.searchInputTextColor,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );

    if (needsCubitSync) {
      return BlocListener<DashboardCubit, DashboardState>(
        listener: (context, state) {
          if (state is DashboardLoaded &&
              state.searchQuery != null &&
              _controller.text != state.searchQuery) {
            _controller.text = state.searchQuery!;
          }
        },
        child: textField,
      );
    }

    return textField;
  }

  void _handleSearchChanged(String value) {
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();

    // If custom onChanged callback is provided, use it
    if (widget.onChanged != null) {
      // If value is empty (cleared), call immediately without debounce
      if (value.isEmpty) {
        widget.onChanged!(value);
      } else {
        _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
          widget.onChanged!(value);
        });
      }
      return;
    }

    // If no onChanged callback provided, just update the search query for incident section
    // (for backward compatibility, but API calls should be handled by screens)
    if (widget.incidentSection ?? false) {
      AppDI.dashboardCubit.updateSearchQuery(value);
    }
  }

  Widget? _buildSuffixIcon(BuildContext context) {
    if (widget.suffixIcon == null && widget.suffixIconWidget == null) {
      return null;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _handleSuffixIconTap(context),
      child: widget.suffixIcon != null
          ? Icon(widget.suffixIcon, size: 20, color: Colors.grey)
          : widget.suffixIconWidget,
    );
  }

  void _handleSuffixIconTap(BuildContext context) {
    if (widget.suffixIcon == Icons.clear) {
      _controller.clear();
      // If custom onChanged callback is provided, call it with empty string
      if (widget.onChanged != null) {
        widget.onChanged!('');
      } else if (widget.incidentSection ?? false) {
        // For backward compatibility
        AppDI.dashboardCubit.updateSearchQuery('');
      }
    } else if (widget.clientSection ?? false) {
      ClientFilterDialog.show(context);
    } else if (widget.projectSection ?? false) {
      ProjectFilterDialog.show(context);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    // Clear search query on dispose to reset filters when navigating away
    if (widget.onChanged != null) {
      widget.onChanged!('');
    } else if (widget.incidentSection == true) {
      AppDI.dashboardCubit.updateSearchQuery('');
    }
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
