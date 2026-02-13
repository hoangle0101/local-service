import 'package:flutter/material.dart';
import 'package:mobile/data/repositories/payment_repository.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/payment_datasource.dart';

class ProviderWithdrawScreen extends StatefulWidget {
  const ProviderWithdrawScreen({super.key});

  @override
  State<ProviderWithdrawScreen> createState() => _ProviderWithdrawScreenState();
}

class _ProviderWithdrawScreenState extends State<ProviderWithdrawScreen> {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankHolderController = TextEditingController();
  final _momoPhoneController = TextEditingController();

  String _selectedMethod = 'BANK';
  double _availableBalance = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  static const double _minWithdrawal = 100000;
  static const double _momoFeePercent = 0.01;
  static const double _maxMomoFee = 50000;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankHolderController.dispose();
    _momoPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await _paymentRepository.getBalance();
      if (mounted) {
        setState(() {
          _availableBalance = balance.balance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  double get _withdrawAmount {
    final text = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(text) ?? 0;
  }

  double get _fee {
    if (_selectedMethod == 'MOMO') {
      final fee = _withdrawAmount * _momoFeePercent;
      return fee > _maxMomoFee ? _maxMomoFee : fee;
    }
    return 0;
  }

  double get _netAmount => _withdrawAmount - _fee;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _paymentRepository.createWithdrawal(
        amount: _withdrawAmount.toInt(),
        method: _selectedMethod,
        bankName: _selectedMethod == 'BANK' ? _bankNameController.text : null,
        bankAccount:
            _selectedMethod == 'BANK' ? _bankAccountController.text : null,
        bankHolder:
            _selectedMethod == 'BANK' ? _bankHolderController.text : null,
        momoPhone: _selectedMethod == 'MOMO' ? _momoPhoneController.text : null,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Yêu cầu thành công!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Yêu cầu rút ${_formatCurrency(_withdrawAmount)} đã được gửi.\nChúng tôi sẽ xử lý trong 1-3 ngày làm việc.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Hoàn tất',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Rút tiền',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 24),
                    _buildAmountSection(),
                    const SizedBox(height: 24),
                    _buildMethodSection(),
                    const SizedBox(height: 24),
                    if (_selectedMethod == 'BANK') _buildBankForm(),
                    if (_selectedMethod == 'MOMO') _buildMomoForm(),
                    const SizedBox(height: 24),
                    _buildSummary(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0AA1DD), Color(0xFF2155CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Số dư khả dụng',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCurrency(_availableBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return _buildCard(
      title: 'Số tiền rút',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey.shade300),
              suffixText: 'đ',
              suffixStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              border: InputBorder.none,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CurrencyInputFormatter(),
            ],
            onChanged: (_) => setState(() {}),
            validator: (value) {
              final amount = _withdrawAmount;
              if (amount < _minWithdrawal) {
                return 'Số tiền tối thiểu là ${_formatCurrency(_minWithdrawal)}';
              }
              if (amount > _availableBalance) {
                return 'Số dư không đủ';
              }
              return null;
            },
          ),
          const Divider(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [100000, 500000, 1000000, 2000000].map((amount) {
              return GestureDetector(
                onTap: () {
                  if (amount <= _availableBalance) {
                    _amountController.text =
                        NumberFormat('#,###').format(amount);
                    setState(() {});
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: amount <= _availableBalance
                        ? AppColors.primaryLight
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: amount <= _availableBalance
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    _formatCurrency(amount.toDouble()),
                    style: TextStyle(
                      color: amount <= _availableBalance
                          ? AppColors.primaryDark
                          : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSection() {
    return _buildCard(
      title: 'Phương thức',
      child: Row(
        children: [
          Expanded(
            child: _buildMethodOption(
              method: 'BANK',
              icon: Icons.account_balance,
              label: 'Ngân hàng',
              subtitle: 'Miễn phí',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMethodOption(
              method: 'MOMO',
              icon: Icons.phone_android,
              label: 'MoMo',
              subtitle: 'Phí 1%',
              color: const Color(0xFFAE2070),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOption({
    required String method,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankForm() {
    return _buildCard(
      title: 'Thông tin ngân hàng',
      child: Column(
        children: [
          _buildTextField(
            controller: _bankNameController,
            label: 'Tên ngân hàng',
            hint: 'VD: Vietcombank, Techcombank...',
            icon: Icons.business,
            validator: (v) =>
                v?.isEmpty ?? true ? 'Vui lòng nhập tên ngân hàng' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bankAccountController,
            label: 'Số tài khoản',
            hint: 'Nhập số tài khoản',
            icon: Icons.credit_card,
            keyboardType: TextInputType.number,
            validator: (v) =>
                v?.isEmpty ?? true ? 'Vui lòng nhập số tài khoản' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bankHolderController,
            label: 'Tên chủ tài khoản',
            hint: 'Tên đăng ký tài khoản',
            icon: Icons.person,
            validator: (v) =>
                v?.isEmpty ?? true ? 'Vui lòng nhập tên chủ tài khoản' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMomoForm() {
    return _buildCard(
      title: 'Thông tin MoMo',
      child: _buildTextField(
        controller: _momoPhoneController,
        label: 'Số điện thoại MoMo',
        hint: 'Nhập số điện thoại đã đăng ký MoMo',
        icon: Icons.phone,
        keyboardType: TextInputType.phone,
        validator: (v) =>
            v?.isEmpty ?? true ? 'Vui lòng nhập số điện thoại' : null,
      ),
    );
  }

  Widget _buildSummary() {
    return _buildCard(
      title: 'Chi tiết',
      child: Column(
        children: [
          _buildSummaryRow('Số tiền rút', _formatCurrency(_withdrawAmount)),
          if (_fee > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Phí rút tiền', '-${_formatCurrency(_fee)}',
                isNegative: true),
          ],
          const Divider(height: 24),
          _buildSummaryRow(
            'Thực nhận',
            _formatCurrency(_netAmount),
            isBold: true,
            color: AppColors.primaryDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, bool isNegative = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 18 : 15,
            color: isNegative ? Colors.red : (color ?? AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _withdrawAmount >= _minWithdrawal &&
        _withdrawAmount <= _availableBalance;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit && !_isSubmitting ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Gửi yêu cầu',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryDark),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final number = int.parse(digits);
    final formatted = NumberFormat('#,###').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
