import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/presentation/case_report/approver/utils/approver_utils.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PropertyDamageSection extends StatefulWidget {
  const PropertyDamageSection({
    super.key,
    this.incident,
    this.propertyDamage,
    this.isEdit = false,
    this.onSave,
  });

  final IncidentDetails? incident;
  final Map<String, dynamic>? propertyDamage;
  final bool isEdit;
  final Function(IncidentDetails updatedIncident)? onSave;

  @override
  State<PropertyDamageSection> createState() => _PropertyDamageSectionState();
}

class _PropertyDamageSectionState extends State<PropertyDamageSection>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;

  IncidentDetails? _localIncidentData;
  Map<String, dynamic> _localPropertyDamage = {};
  List<Map<String, dynamic>> _editablePropertyDamage = [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLocalData();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(covariant PropertyDamageSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cubitState = AppDI.incidentDetailsCubit.state;
    final isEditing = cubitState is IncidentDetailsLoaded &&
        (cubitState.propertyDamageEdit ?? false);
    if (!isEditing &&
        (widget.incident != oldWidget.incident ||
            widget.propertyDamage != oldWidget.propertyDamage)) {
      _initializeLocalData();
      _initializeControllers();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _initializeLocalData() {
    _localIncidentData = widget.incident != null
        ? deepCopyIncident(widget.incident!)
        : null;
    _localPropertyDamage = _deepCopyPropertyDamage(widget.propertyDamage);
    _updateEditableList();
  }

  Map<String, dynamic> _deepCopyPropertyDamage(Map<String, dynamic>? source) {
    if (source == null) return {};
    try {
      final copy = <String, dynamic>{};
      source.forEach((key, value) {
        if (value is List) {
          copy[key] = value.map((e) {
            if (e is Map) return Map<String, dynamic>.from(e);
            return e;
          }).toList();
        } else if (value is Map) {
          copy[key] = Map<String, dynamic>.from(value);
        } else {
          copy[key] = value;
        }
      });
      return copy;
    } catch (_) {
      return Map<String, dynamic>.from(source);
    }
  }

  void _updateEditableList() {
    final details = _localPropertyDamage['details'] as List? ?? [];
    _editablePropertyDamage = details
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final totalCost = _calculateTotalCost();
    _localPropertyDamage['totalCost'] = totalCost;
  }

  void _initializeControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();

    for (int i = 0; i < _editablePropertyDamage.length; i++) {
      final item = _editablePropertyDamage[i];
      _controllers['propertyType_$i'] = TextEditingController(
        text: item['propertyType']?.toString() ?? '',
      );
      _controllers['description_$i'] = TextEditingController(
        text: item['description']?.toString() ?? '',
      );
      _controllers['price_$i'] = TextEditingController(
        text: item['price']?.toString() ?? '0',
      );
    }
  }

  void _toggleExpansion() {
    if (!mounted) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleEdit() {
    if (AppDI.incidentDetailsCubit.isAnyEditActive()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please save or cancel current edits first'),
          backgroundColor: ColorHelper.errorColor,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    AppDI.incidentDetailsCubit.setPropertyDamageEdit(true);
  }

  void _handleCancel() {
    AppDI.incidentDetailsCubit.setPropertyDamageEdit(false);
    _resetToOriginalData();
  }

  void _resetToOriginalData() {
    _initializeLocalData();
    _initializeControllers();
  }

  bool _hasDataChanged() {
    final originalList = (widget.propertyDamage?['details'] as List? ?? []).map(
      (e) {
        return Map<String, dynamic>.from(e);
      },
    ).toList();

    if (_editablePropertyDamage.length != originalList.length) return true;

    for (int i = 0; i < _editablePropertyDamage.length; i++) {
      final original = originalList[i];
      final curType = _controllers['propertyType_$i']?.text.trim() ?? '';
      final curDesc = _controllers['description_$i']?.text.trim() ?? '';
      final curPrice = _parsePrice(_controllers['price_$i']?.text);

      if (curType != (original['propertyType']?.toString().trim() ?? '')) {
        return true;
      }
      if (curDesc != (original['description']?.toString().trim() ?? '')) {
        return true;
      }
      if (curPrice != _parsePrice(original['price'])) {
        return true;
      }
    }
    return false;
  }

  void _handleSave() {
    AppDI.incidentDetailsCubit.setPropertyDamageEdit(false);
    if (_localIncidentData == null) return;

    if (!_hasDataChanged()) {
      return;
    }

    _updateLocalPropertyDamage();
    _saveToServer();
  }

  void _updateLocalPropertyDamage() {
    for (int i = 0; i < _editablePropertyDamage.length; i++) {
      _editablePropertyDamage[i]['propertyType'] =
          _controllers['propertyType_$i']?.text ?? '';
      _editablePropertyDamage[i]['description'] =
          _controllers['description_$i']?.text ?? '';
      _editablePropertyDamage[i]['price'] =
          _controllers['price_$i']?.text ?? '0';
    }
    _localPropertyDamage['details'] = _editablePropertyDamage;
  }

  void _updateIncidentData() {
    if (_localIncidentData!.incident is Map) {
      (_localIncidentData!.incident as Map)['propertyDamage'] =
          _localPropertyDamage;
    } else {
      _localIncidentData!.incident = {'propertyDamage': _localPropertyDamage};
    }
  }

  void _saveToServer() {
    final payload = {
      'caseId': _localIncidentData!.incidentId,
      'propertyDamage': _editablePropertyDamage
          .map(
            (item) => {
              'propertyType': item['propertyType'] ?? '',
              'description': item['description'] ?? '',
              'price': item['price'] ?? '0',
            },
          )
          .toList(),
    };
    AppDI.incidentDetailsCubit.updateReportFieldsPayload(
      payload,
      incidentId: _localIncidentData!.incidentId,
    );
  }

  double _calculateTotalCost() {
    double total = 0;
    for (var item in _editablePropertyDamage) {
      final price = _parsePrice(item['price']);
      total += price;
    }
    return total;
  }

  double _parsePrice(dynamic value) {
    if (value == null) return 0;
    final str = value.toString().trim();
    if (str.isEmpty) return 0;
    return double.tryParse(str) ?? 0;
  }

  String _formatPrice(double price) {
    if (price.isNaN || price.isInfinite) return '0';
    final intPrice = price.round();
    final str = intPrice.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(str[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }

  String _getCurrency() {
    if (_editablePropertyDamage.isNotEmpty &&
        _editablePropertyDamage.first['currency'] != null) {
      return _editablePropertyDamage.first['currency'].toString();
    }
    final total = _localPropertyDamage['total'] as Map<String, dynamic>?;
    return total?['currency']?.toString() ?? '\u20B9';
  }

  void _addNewPropertyItem() {
    setState(() {
      final index = _editablePropertyDamage.length;
      _editablePropertyDamage.add({
        'propertyType': '',
        'description': '',
        'price': '0',
      });
      _controllers['propertyType_$index'] = TextEditingController();
      _controllers['description_$index'] = TextEditingController();
      _controllers['price_$index'] = TextEditingController(text: '0');
    });
    _checkDataChanged();
  }

  void _checkDataChanged() {
    _updateLocalPropertyDamage();
    final totalCost = _calculateTotalCost();
    _localPropertyDamage['totalCost'] = totalCost;
    _updateIncidentData();
    final changed = _hasDataChanged();
    AppDI.incidentDetailsCubit.setPropertyDamageEdit(changed);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
      bloc: AppDI.incidentDetailsCubit,
      buildWhen: (previous, current) {
        if (previous is IncidentDetailsLoaded &&
            current is IncidentDetailsLoaded) {
          return previous.propertyDamageEdit != current.propertyDamageEdit;
        }
        return false;
      },
      builder: (context, state) {
        final isEditing = state is IncidentDetailsLoaded &&
            (state.propertyDamageEdit ?? false);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: ColorHelper.surfaceColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: ColorHelper.surfaceColor, width: 1),
          ),
          child: Column(
            children: [
              _buildHeader(isEditing),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: _buildPropertyDamageContent(isEditing),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isEditing) {
    return GestureDetector(
      onTap: _toggleExpansion,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            TextHelper.propertyDamage,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 16,
              color: ColorHelper.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              if (widget.incident?.adminStatus != 'ERT Assigned' &&
                  widget.incident?.incidentStatus != 'Closed' &&
                  widget.incident?.incidentStatus != 'Resolved' &&
                  _isExpanded &&
                  widget.isEdit)
                _buildActionButtons(isEditing),
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: ColorHelper.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isEditing) {
    if (isEditing) {
      return Row(
        children: [
          IconButton(
            icon: Icon(Icons.add, color: ColorHelper.textSecondary),
            onPressed: _addNewPropertyItem,
            tooltip: 'Add Item',
          ),
          IconButton(
            icon: Icon(Icons.close, color: ColorHelper.textSecondary),
            onPressed: _handleCancel,
            tooltip: TextHelper.cancel,
          ),
          IconButton(
            icon: Icon(Icons.check, color: ColorHelper.textSecondary),
            onPressed: _handleSave,
            tooltip: TextHelper.save,
          ),
        ],
      );
    }
    return IconButton(
      icon: Image.asset(Assets.reportApEdit, width: 20, height: 20),
      onPressed: _handleEdit,
      tooltip: TextHelper.edit,
    );
  }

  Widget _buildPropertyDamageContent(bool isEditing) {
    if (_editablePropertyDamage.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorHelper.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'No property damage reported',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColorHelper.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _editablePropertyDamage.length; i++)
            _buildPropertyDamageItem(i, isEditing),
          Divider(
            color: Colors.white.withValues(alpha: 0.8),
            thickness: 1,
          ),
          const SizedBox(height: 8),
          _buildTotalSection(),
        ],
      ),
    );
  }

  Widget _buildPropertyDamageItem(int index, bool isEditing) {
    final item = _editablePropertyDamage[index];
    final propertyType = item['propertyType'] ?? '--';
    final description = item['description'] ?? '--';
    final price = _parsePrice(item['price']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorHelper.surfaceColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isEditing
          ? _buildEditableItem(index)
          : _buildReadOnlyItem(propertyType, description, price),
    );
  }

  Widget _buildEditableItem(int index) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Property Type',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: ColorHelper.black4,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
        AppTextField(
          controller: _controllers['propertyType_$index'],
          fillColor: ColorHelper.white.withValues(alpha: 0.8),
          maxLines: 3,
          onChanged: (_) => _checkDataChanged(),
        ),
        const SizedBox(height: 12),
        Text('Description',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: ColorHelper.black4,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
        AppTextField(
          controller: _controllers['description_$index'],
          fillColor: ColorHelper.white.withValues(alpha: 0.8),
          maxLines: 3,
          onChanged: (_) => _checkDataChanged(),
        ),
        const SizedBox(height: 12),
        Text('Price',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: ColorHelper.black4,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
        AppTextField(
          numericOnly: true,
          controller: _controllers['price_$index'],
          fillColor: ColorHelper.white.withValues(alpha: 0.8),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _checkDataChanged(),
          maxLength: 6,
        ),
      ],
    );
  }

  Widget _buildReadOnlyItem(
    String propertyType,
    String description,
    double price,
  ) {
    final currency = _getCurrency();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          propertyType.isEmpty ? 'Property type not available' : propertyType,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorHelper.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$currency ${_formatPrice(price)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorHelper.successColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 8),
          Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ColorHelper.warningColor,
          ),
        ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    final totalCost = _calculateTotalCost();
    final currency = _getCurrency();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: ColorHelper.totalCostColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorHelper.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              '$currency ${_formatPrice(totalCost)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ColorHelper.warningRedColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
