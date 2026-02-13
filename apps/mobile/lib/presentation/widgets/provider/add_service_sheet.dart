import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/entities/entities.dart';
import '../../../data/datasources/provider_datasource.dart';
import '../../bloc/categories/categories_bloc.dart';
import '../../bloc/categories/categories_event_state.dart';
import '../../bloc/services/services_bloc.dart';
import '../../bloc/services/services_event_state.dart';
import '../minimalist_widgets.dart';

/// Add Service Sheet - Modern Design
class AddServiceSheet extends StatefulWidget {
  final VoidCallback onServiceAdded;
  const AddServiceSheet({super.key, required this.onServiceAdded});

  @override
  State<AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<AddServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final ProviderDataSource _providerDataSource = ProviderDataSource();

  Category? _selectedCategory;
  Service? _selectedService;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng điền đầy đủ thông tin'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _providerDataSource.addService(
        serviceId: _selectedService!.id,
        price: double.parse(_priceController.text.replaceAll(',', '')),
      );
      widget.onServiceAdded();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Thêm dịch vụ thành công!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_task_rounded,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Thêm dịch vụ mới',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildLabel('Danh mục dịch vụ'),
              BlocBuilder<CategoriesBloc, CategoriesState>(
                builder: (context, state) {
                  if (state is CategoriesLoaded) {
                    return _buildDropdown<Category>(
                      value: _selectedCategory,
                      hint: 'Chọn một danh mục',
                      items: state.categories,
                      itemBuilder: (cat) => Text(cat.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      onChanged: (cat) {
                        if (cat != null) {
                          setState(() {
                            _selectedCategory = cat;
                            _selectedService = null;
                          });
                          context
                              .read<ServicesBloc>()
                              .add(LoadGenericServices(categoryId: cat.id));
                        }
                      },
                    );
                  }
                  return const Center(
                      child: LinearProgressIndicator(color: AppColors.primary));
                },
              ),
              const SizedBox(height: 24),
              _buildLabel('Tên dịch vụ cụ thể'),
              BlocBuilder<ServicesBloc, ServicesState>(
                builder: (context, state) {
                  if (state is GenericServicesLoaded) {
                    return _buildDropdown<Service>(
                      value: _selectedService,
                      hint: 'Chọn một dịch vụ cụ thể',
                      items: state.services,
                      itemBuilder: (svc) => Text(svc.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      onChanged: (svc) =>
                          setState(() => _selectedService = svc),
                    );
                  }
                  if (state is ServicesLoading) {
                    return const Center(
                        child:
                            LinearProgressIndicator(color: AppColors.primary));
                  }
                  return _buildDropdown<Service>(
                    value: null,
                    hint: _selectedCategory == null
                        ? 'Vui lòng chọn danh mục trước'
                        : 'Chọn một dịch vụ',
                    items: [],
                    itemBuilder: (svc) => const SizedBox(),
                    onChanged: null,
                  );
                },
              ),
              const SizedBox(height: 24),
              MinTextField(
                label: 'Giá dịch vụ của bạn (VND)',
                hint: 'Ví dụ: 150,000',
                controller: _priceController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.payments_rounded,
                    color: AppColors.textTertiary, size: 20),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập giá';
                  if (double.tryParse(v.replaceAll(',', '')) == null) {
                    return 'Giá không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),
              MinButton(
                text: 'Xác nhận thêm dịch vụ',
                isLoading: _isSubmitting,
                isFullWidth: true,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    required void Function(T?)? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map(
              (item) => DropdownMenuItem(value: item, child: itemBuilder(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
