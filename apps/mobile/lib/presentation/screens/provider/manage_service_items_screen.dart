import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/provider_datasource.dart';
import '../../widgets/minimalist_widgets.dart';

class ManageServiceItemsScreen extends StatefulWidget {
  final int serviceId;
  final String serviceName;

  const ManageServiceItemsScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  State<ManageServiceItemsScreen> createState() =>
      _ManageServiceItemsScreenState();
}

class _ManageServiceItemsScreenState extends State<ManageServiceItemsScreen> {
  final ProviderDataSource _datasource = ProviderDataSource();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _datasource.getServiceItems(widget.serviceId);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _addItem() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditItemSheet(serviceId: widget.serviceId),
    );

    if (result != null) {
      try {
        await _datasource.createServiceItem(widget.serviceId, result);
        _loadItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm mục dịch vụ!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _editItem(Map<String, dynamic> item) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditItemSheet(
        serviceId: widget.serviceId,
        existingItem: item,
      ),
    );

    if (result != null) {
      try {
        await _datasource.updateServiceItem(item['id'], result);
        _loadItems();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _deleteItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa mục dịch vụ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _datasource.deleteServiceItem(itemId);
        _loadItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa mục dịch vụ'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  String _formatCurrency(dynamic price) {
    final value = price is int ? price.toDouble() : (price as num).toDouble();
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
        .format(value)
        .replaceAll(',00', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bảng giá dịch vụ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.serviceName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: _addItem,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmptyState()
              : _buildItemsList(),
      floatingActionButton: _items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addItem,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Thêm mục',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có bảng giá',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thêm các mục dịch vụ cụ thể với giá\nđể khách hàng biết chi tiết.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            MinButton(
              text: 'Thêm mục đầu tiên',
              onPressed: _addItem,
              icon: Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () => _editItem(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image or placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.shelf,
                  borderRadius: BorderRadius.circular(12),
                  image: item['imageUrl'] != null
                      ? DecorationImage(
                          image: NetworkImage(item['imageUrl']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item['imageUrl'] == null
                    ? const Icon(
                        Icons.build_rounded,
                        color: AppColors.textTertiary,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (item['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item['description'],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(item['price'] ?? 0),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: () => _editItem(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, size: 20),
                    color: AppColors.error,
                    onPressed: () => _deleteItem(item['id']),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddEditItemSheet extends StatefulWidget {
  final int serviceId;
  final Map<String, dynamic>? existingItem;

  const _AddEditItemSheet({
    required this.serviceId,
    this.existingItem,
  });

  @override
  State<_AddEditItemSheet> createState() => _AddEditItemSheetState();
}

class _AddEditItemSheetState extends State<_AddEditItemSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool get isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _nameController.text = widget.existingItem!['name'] ?? '';
      _descriptionController.text = widget.existingItem!['description'] ?? '';
      _priceController.text = (widget.existingItem!['price'] ?? 0).toString();
      _imageUrlController.text = widget.existingItem!['imageUrl'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên mục')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập giá hợp lệ')),
      );
      return;
    }

    Navigator.pop(context, {
      'name': _nameController.text,
      'description': _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      'price': price,
      'imageUrl':
          _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Sửa mục dịch vụ' : 'Thêm mục dịch vụ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name
            MinTextField(
              controller: _nameController,
              label: 'Tên mục dịch vụ *',
              hint: 'Vd: Bơm gas R32',
            ),
            const SizedBox(height: 16),

            // Description
            MinTextField(
              controller: _descriptionController,
              label: 'Mô tả (tùy chọn)',
              hint: 'Mô tả chi tiết...',
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Price
            MinTextField(
              controller: _priceController,
              label: 'Giá (VNĐ) *',
              hint: '0',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
            ),
            const SizedBox(height: 16),

            // Image URL
            MinTextField(
              controller: _imageUrlController,
              label: 'URL ảnh (tùy chọn)',
              hint: 'https://...',
              prefixIcon: const Icon(Icons.image_rounded, size: 20),
            ),
            const SizedBox(height: 24),

            // Submit button
            MinButton(
              text: isEditing ? 'Cập nhật' : 'Thêm mục',
              isFullWidth: true,
              onPressed: _submit,
              icon: isEditing ? Icons.save_rounded : Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
