import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'add_payment_screen.dart';
import 'paymob_payment_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String _selectedPaymentMethod = 'نقداً';
  double _balance = 0.00;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    setState(() => _isLoading = true);
    final userProfile = await ApiService().fetchUserProfile();
    if (mounted) {
      setState(() {
        if (userProfile != null && userProfile['walletBalance'] != null) {
           _balance = (userProfile['walletBalance'] as num).toDouble();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _addCredit(double amount) async {
    Navigator.pop(context); // Close bottom sheet
    
    // Show a loading indicator while fetching Iframe URL
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (c) => const Center(child: CircularProgressIndicator(color: AppColors.primary))
    );

    final iframeUrl = await ApiService().initiateWalletCharge(amount);
    
    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    if (iframeUrl != null) {
      // Launch Paymob
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymobPaymentScreen(
            iframeUrl: iframeUrl,
            orderId: 'Wallet Topup',
          ),
        ),
      );

      // Re-fetch balance since Webhook might have added it
      _fetchBalance();

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت عملية الدفع بنجاح! جاري تحديث الرصيد...'), backgroundColor: Colors.green),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في بدء عملية الدفع، حاول مجدداً'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddPromoCodeDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة رمز ترويجي'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'أدخل الرمز هنا (مثال: FREE50)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () async {
                Navigator.pop(context);
                final code = controller.text.trim().toUpperCase();
                if (code.isNotEmpty) {
                  showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
                  final success = await ApiService().applyPromoCode(code);
                  if (mounted) Navigator.pop(context);

                  if (success) {
                    _fetchBalance();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تفعيل الرمز بنجاح!'), backgroundColor: Colors.green),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('الرمز الترويجي غير صالح أو مستخدم مسبقاً.'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              child: const Text('تفعيل الرمز', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAddCreditSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر مبلغ الشحن',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [50.0, 100.0, 200.0, 500.0].map((amount) {
                return InkWell(
                  onTap: () => _addCredit(amount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${amount.toInt()} ج.م.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'أو أدخل مبلغاً مخصصاً (قريباً)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفظة', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GO تروسيكل Cash Section
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'رصيد GO تروسيكل',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                     const LinearProgressIndicator(color: AppColors.primary)
                  else
                     Text(
                      '${_balance.toStringAsFixed(2)} ج.م.',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddCreditSheet,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('إضافة رصيد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryBackground,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Payment Methods Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'طرق الدفع',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildPaymentMethodItem(
              icon: Icons.money,
              title: 'نقداً',
              isSelected: _selectedPaymentMethod == 'نقداً',
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = 'نقداً';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم اختيار الدفع نقدًا كطريقة افتراضية'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _buildPaymentMethodItem(
              icon: Icons.credit_card,
              title: 'إضافة طريقة دفع',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPaymentScreen()),
                );
              },
              isAction: true,
            ),
            
            const SizedBox(height: 24),
            // Vouchers Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'العروض الترويجية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildPaymentMethodItem(
              icon: Icons.local_offer,
              title: 'إضافة رمز ترويجي',
              onTap: _showAddPromoCodeDialog,
              isAction: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isAction = false,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isAction ? Colors.blue : (isSelected ? Colors.green : Colors.black)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isAction ? Colors.blue : (isSelected ? Colors.green : Colors.black),
          fontWeight: (isAction || isSelected) ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected 
          ? const Icon(Icons.check, color: Colors.green) 
          : const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}
