import 'package:emergex/helpers/widgets/feedback/movable_floating_button.dart';
import 'package:flutter/material.dart';
import 'package:emergex/helpers/widgets/glass_container.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/generated/assets.dart';
import 'package:go_router/go_router.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/widgets/utils/timer_widget.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/ai_insights_widget.dart';
import 'package:emergex/presentation/investigation/investigation_team_member/widgets/fault_tree_widgets.dart';

class RcaWorkflowBoardScreen extends StatefulWidget {
  final String? incidentId;
  const RcaWorkflowBoardScreen({super.key, this.incidentId});

  @override
  State<RcaWorkflowBoardScreen> createState() => _RcaWorkflowBoardScreenState();
}

class _RcaWorkflowBoardScreenState extends State<RcaWorkflowBoardScreen> {
  int _selectedTab = 0; // 0 for 5 Ways, 1 for Fault Tree
  bool _isFaultTreeStarted = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      useGradient: true,
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      showDrawer: false,
      appBar: const AppBarWidget(hasNotifications: true),
      showBottomNav: true,
      navSelectedIndex: 1, // Dashboard
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 120,
              top: 16,
            ), // Space for bottom buttons
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Back button + Title + floating chat
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: ColorHelper.white.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorHelper.white,
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: ColorHelper.black,
                            size: 18,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'RCA Workflow Board',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ColorHelper.black,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (widget.incidentId != null) {
                            context.push(
                              '${Routes.chatScreen}?incidentId=${widget.incidentId}',
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                ColorHelper.primaryColor,
                                ColorHelper.buttonColor,
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ColorHelper.primaryColor,
                              width: 1,
                            ),
                          ),
                          child: Image.asset(
                            Assets.chat,
                            width: 18,
                            height: 18,
                            color: ColorHelper.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Badges row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 47,
                      ), // Align with 'R' in RCA Workflow (35 container + 12 gap)
                      TimerWidget(
                        startDuration: const Duration(
                          hours: 4,
                          minutes: 43,
                          seconds: 12,
                        ),
                        timerColor: const Color(0xFF005B8B),
                        shouldRun: true,
                        iconAsset: Assets.tasktime,
                        iconSize: 10,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        borderRadius: 24,
                        borderWidth: 1,
                        textStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                              color: const Color(0xFF005B8B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Incident',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Card (Tabs + content)
                GlassContainer(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  borderRadius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(44),
                          border: Border.all(
                            color: ColorHelper.white,
                            width: 0.5,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFFFFFFF).withValues(alpha: 0.0),
                              const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                            ],
                            stops: const [0.0, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF656565,
                              ).withValues(alpha: 0.12),
                              blurRadius: 6.5,
                              offset: Offset.zero,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 0
                                        ? const Color(0xFF3DA229)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(44),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '5 Ways',
                                      style: TextStyle(
                                        color: _selectedTab == 0
                                            ? Colors.white
                                            : ColorHelper.black5.withValues(
                                                alpha: 0.5,
                                              ),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 1
                                        ? const Color(0xFF3DA229)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(44),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Fault Tree',
                                      style: TextStyle(
                                        color: _selectedTab == 1
                                            ? Colors.white
                                            : ColorHelper.black5.withValues(
                                                alpha: 0.5,
                                              ),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_selectedTab == 1 && _isFaultTreeStarted) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Fault Tree Analysis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ColorHelper.black5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const FaultTreeBuilderWidget(),
                      ] else ...[
                        const SizedBox(height: 48),
                        // Empty state content centered
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: ColorHelper.black.withValues(
                                      alpha: 0.8,
                                    ),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.help_outline,
                                  color: ColorHelper.black.withValues(
                                    alpha: 0.8,
                                  ),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedTab == 0
                                    ? 'No 5 whys created yet !'
                                    : 'No Fault Tree created yet !',
                                style: TextStyle(
                                  color: ColorHelper.black.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedTab == 0
                                    ? 'The 5 Whys Analysis Has Not Been Started\nGenerated 5 Whys To Begin Identifying The\nRoot Cause Of The Incident Through Iterative\nQuestions'
                                    : 'The Fault Tree Analysis Has Not Been Started. Create\nFault Nodes To Begin Identifying\nCauses And Failure Paths Leading To The Incident',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ColorHelper.black5.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontSize: 11,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Buttons
                              if (_selectedTab == 0)
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.auto_awesome,
                                          color: Color(0xFF3DA229),
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Suggest Why',
                                          style: TextStyle(
                                            color: Color(0xFF3DA229),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFF3DA229),
                                            width: 1,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          backgroundColor: const Color(
                                            0xFF3DA229,
                                          ).withValues(alpha: 0.1),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.add,
                                          color: Color(0xFF3DA229),
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'New Why',
                                          style: TextStyle(
                                            color: Color(0xFF3DA229),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFF3DA229),
                                            width: 1,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          backgroundColor: const Color(
                                            0xFF3DA229,
                                          ).withValues(alpha: 0.1),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                OutlinedButton.icon(
                                  onPressed: () => setState(
                                    () => _isFaultTreeStarted = true,
                                  ),
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF3DA229),
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Create Fault Tree',
                                    style: TextStyle(
                                      color: Color(0xFF3DA229),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF3DA229),
                                      width: 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 24,
                                    ),
                                    backgroundColor: const Color(
                                      0xFF3DA229,
                                    ).withValues(alpha: 0.1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // RCA Findings Card
                GlassContainer(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  borderRadius: 24,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RCA Findings',
                            style: TextStyle(
                              color: ColorHelper.black.withValues(alpha: 0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.edit,
                            color: ColorHelper.black.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: ColorHelper.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48), // Spacing for bottom actions
              ],
            ),
          ),

          // Bottom Actions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF388E3C)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF388E3C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF81C784,
                        ), // Lighter green for submit
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Submit RCA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          MovableFloatingButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: ColorHelper.transparent,
                isScrollControlled: true,
                builder: (context) => const AiInsightsCard(isTaskDetails: true),
              );
            },
          ),
        ],
      ),
    );
  }
}
