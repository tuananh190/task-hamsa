import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../providers/user_provider.dart';

void showAddUserModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _UserFormModal(),
  );
}

class _UserFormModal extends StatefulWidget {
  const _UserFormModal({super.key});

  @override
  State<_UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends State<_UserFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); // Tạm thời nhập pass giả để lưu vào Firebase Auth sau nếu cần
  
  bool _obscurePassword = true;
  String _selectedRole = 'Staff';

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    final newUser = UserModel(
      id: const Uuid().v4(),
      name: _nameController.text,
      email: _emailController.text,
      role: _selectedRole,
      createdAt: DateTime.now(),
    );

    final success = await userProvider.addUser(newUser);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo tài khoản nhân viên thành công!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${userProvider.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tạo Tài Khoản', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary)),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.neutral),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // BODY FORM
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HỌ VÀ TÊN', style: AppTextStyles.labelMonoSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập họ và tên',
                        prefixIcon: Icon(Icons.person_outline, size: 18),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    Text('EMAIL', style: AppTextStyles.labelMonoSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'email@otakustore.com',
                        prefixIcon: Icon(Icons.mail_outline, size: 18),
                      ),
                      validator: (val) => (val == null || !val.contains('@')) ? 'Email không hợp lệ' : null,
                    ),
                    const SizedBox(height: 16),

                    Text('MẬT KHẨU (TẠM)', style: AppTextStyles.labelMonoSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.neutral),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) => (val == null || val.length < 6) ? 'Mật khẩu > 6 ký tự' : null,
                    ),
                    const SizedBox(height: 16),

                    Text('CHỌN CHỨC VỤ', style: AppTextStyles.labelMonoSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.badge_outlined, size: 18),
                      ),
                      dropdownColor: AppColors.surfaceElevated,
                      items: const [
                        DropdownMenuItem(value: 'Staff', child: Text('Nhân viên (Staff)')),
                        DropdownMenuItem(value: 'Admin', child: Text('Quản trị viên (Admin)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                    
                    const SizedBox(height: 32),

                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: context.watch<UserProvider>().isLoading ? null : _submit,
                        icon: context.watch<UserProvider>().isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.background))
                            : const Icon(Icons.person_add_alt_1, color: AppColors.background, size: 18),
                        label: const Text('Tạo Tài Khoản'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
