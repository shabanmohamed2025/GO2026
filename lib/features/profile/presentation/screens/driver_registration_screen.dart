import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedVehicleType = 'Tricycle';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  
  String? _idCardFrontBase64;
  String? _idCardBackBase64;
  
  bool _isLoading = false;

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      final base64String = base64Encode(bytes);
      setState(() {
        if (isFront) {
          _idCardFrontBase64 = base64String;
        } else {
          _idCardBackBase64 = base64String;
        }
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idCardFrontBase64 == null || _idCardBackBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إرفاق صور البطاقة (الأمامية والخلفية)', textAlign: TextAlign.center), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    final success = await ApiService().registerDriver(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      vehicleType: _selectedVehicleType,
      plateNumber: _plateController.text.trim(),
      nationalId: _nationalIdController.text.trim(),
      idCardFront: _idCardFrontBase64!,
      idCardBack: _idCardBackBase64!,
    );
    
    setState(() => _isLoading = false);
    
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم استلام طلبك ومراجعته قريباً من قبل الإدارة.'), backgroundColor: Colors.green),
      );
      // Navigate to Home or Profile
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل التسجيل. قد تكون سائقاً بالفعل أو حدث خطأ ما.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التسجيل ككابتن 🛵', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('بإكمالك هذا النموذج، ستتمكن من استقبال طلبات الركاب والبدء في جني الأرباح عبر تطبيق GO.', style: TextStyle(color: AppColors.primary, height: 1.5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              const Text('الاسم الكامل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'أدخل اسمك',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'يرجى إدخال اسمك';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              const Text('رقم الهاتف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: InputDecoration(
                  hintText: 'أدخل رقم هاتفك (11 رقم)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'يرجى إدخال رقم الهاتف';
                  if (value.trim().length != 11) return 'يجب إدخال 11 رقماً بالضبط';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              const Text('نوع المركبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedVehicleType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'Tricycle', child: Text('تروسيكل (نقل عفش/بضائع)')),
                  DropdownMenuItem(value: 'Motorcycle', child: Text('موتوسيكل (توصيل طلبات / أفراد)')),
                  DropdownMenuItem(value: 'Car', child: Text('سيارة (ملاكي / أجرة)')),
                ],
                onChanged: (val) => setState(() => _selectedVehicleType = val!),
              ),
              
              const SizedBox(height: 24),
              const Text('رقم اللوحة المعدنية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _plateController,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'مثال: أ ب ج ١٢٣',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.pin),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'يرجى إدخال رقم اللوحة';
                  if (value.trim().length != 6) return 'يجب إدخال 6 أحرف/أرقام بالضبط';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text('الرقم القومي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nationalIdController,
                keyboardType: TextInputType.number,
                maxLength: 14,
                decoration: InputDecoration(
                  hintText: 'أدخل 14 رقماً',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.trim().length != 14) {
                    return 'يجب إدخال 14 رقماً صحيحاً';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              const Text('صور البطاقة الشخصية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildImagePickerButton(
                      title: 'الوجه الأمامي',
                      isUploaded: _idCardFrontBase64 != null,
                      onTap: () => _pickImage(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImagePickerButton(
                      title: 'الوجه الخلفي',
                      isUploaded: _idCardBackBase64 != null,
                      onTap: () => _pickImage(false),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('انضم لفريق GO الآن 🚀', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerButton({required String title, required bool isUploaded, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isUploaded ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          border: Border.all(color: isUploaded ? Colors.green : Colors.grey, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isUploaded ? Icons.check_circle : Icons.camera_alt, color: isUploaded ? Colors.green : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: isUploaded ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
