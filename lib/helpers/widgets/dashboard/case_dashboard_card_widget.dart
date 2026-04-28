import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:flutter/material.dart';

class CaseDashboardCardWidget extends StatelessWidget {
  final String caseId;
  final String status;
  final String? severityLevel;
  final String? caseType;
  final String? date;
  final VoidCallback? onTap;
  final VoidCallback? onAuditTap;

  const CaseDashboardCardWidget({
    super.key,
    required this.caseId,
    required this.status,
    this.severityLevel,
    this.caseType,
    this.date,
    this.onTap,
    this.onAuditTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppContainer(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        alpha: 0.4,
        radius: 20,
        borderWidth: 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 10),
            _buildDetailRows(context),
            if (onAuditTap != null) ...[
              const SizedBox(height: 10),
              _buildAuditLogButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final badge = _StatusBadge(status: status);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            caseId,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorHelper.black5,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        badge,
      ],
    );
  }

  Widget _buildDetailRows(BuildContext context) {
    final rows = <Widget>[];

    if (severityLevel != null && severityLevel!.isNotEmpty) {
      rows.add(
        _DetailRow(
          icon: Assets.severity,
          label: 'Severity Level',
          value: severityLevel!,
        ),
      );
    }

    if (caseType != null && caseType!.isNotEmpty) {
      rows.add(
        _DetailRow(
          icon: Assets.caseTypeIcon,
          label: 'Case Type',
          value: caseType!,
        ),
      );
    }

    if (date != null && date!.isNotEmpty) {
      rows.add(
        _DetailRow(
          icon: Assets.dashboardIconDatePicker,
          label: 'Date',
          value: date!,
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      children: rows
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key < rows.length - 1 ? 5 : 0,
              ),
              child: entry.value,
            ),
          )
          .toList(),
    );
  }

  Widget _buildAuditLogButton(BuildContext context) {
    return GestureDetector(
      onTap: onAuditTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: ColorHelper.white,
          borderRadius: BorderRadius.circular(21),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Audit Log',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColorHelper.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 5),
            Icon(Icons.open_in_new, size: 14, color: ColorHelper.primaryColor),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.text,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  _StatusColors _getStatusColors() {
    final lower = status.toLowerCase().trim();

    if (lower.contains('closed') ||
        lower.contains('approved') ||
        lower.contains('resolved') ||
        lower.contains('verified')) {
      return const _StatusColors(
        text: Color(0xFF109352),
        background: Color(0xFFE9F4E7),
        border: Color(0x52048746), // rgba(4,135,70,0.32)
      );
    }

    if (lower.contains('progress')) {
      return const _StatusColors(
        text: Color(0xFF2F50D1),
        background: Color(0xFFF3F5FE),
        border: Color(0x522F50D1), // rgba(47,80,209,0.32)
      );
    }

    if (lower.contains('pending')) {
      return const _StatusColors(
        text: Color(0xFFA27429),
        background: Color(0xFFFFF2DC),
        border: Color(0x52A27429), // rgba(162,116,41,0.32)
      );
    }

    if (lower.contains('rejected')) {
      return const _StatusColors(
        text: Color(0xFFD12F2F),
        background: Color(0xFFFFE7E7),
        border: Color(0x52D12F2F), // rgba(209,47,47,0.32)
      );
    }

    // Default — green
    return _StatusColors(
      text: ColorHelper.primaryColor,
      background: const Color(0xFFE9F4E7),
      border: ColorHelper.primaryColor.withValues(alpha: 0.32),
    );
  }
}

class _StatusColors {
  final Color text;
  final Color background;
  final Color border;

  const _StatusColors({
    required this.text,
    required this.background,
    required this.border,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Row (icon + label + value)
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Opacity(
          opacity: icon == Assets.caseTypeIcon ? 0.7 : 1.0,
          child: Image.asset(icon, height: 16, width: 16),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF777877),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ColorHelper.black5,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
