import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/auth_provider.dart'; // [UPDATE] Cần để gọi createSecondaryAccount
import '../../../services/auth_service.dart'; // [UPDATE]

void showAddUserModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _UserFormModal(),
  );
}

// [NEW] Mở modal chế độ sửa user
void showEditUserModal(BuildContext context, UserModel user) {
  showDialog(
    context: context,
    builder: (ctx) => _UserFormModal(userToEdit: user),
  );
}

class _UserFormModal extends StatefulWidget {
  final UserModel? userToEdit; // [NEW] null = thêm mới, có giá trị = sửa
  const _UserFormModal({super.key, this.userToEdit});

  @override
  State<_UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends State<_UserFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _submitError;
  String _selectedRole = 'employee';

  bool get _isEditMode => widget.userToEdit != null; // [NEW]

  @override
  void initState() { // [NEW] Pre-fill data khi sửa
    super.initState();
    if (_isEditMode) {
      final u = widget.userToEdit!;
      _nameController.text = u.name;
      _emailController.text = u.email;
      _phoneController.text = u.phone;
      _selectedRole = u.role;
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _submitError = null; });

    final userProvider = context.read<UserProvider>();

    try {
      if (_isEditMode) {
        // [NEW] CHừe ĐỘ Sửa: Cập nhật Firestore, không đụng Firebase Auth
        final updatedUser = widget.userToEdit!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole,
        );
        final success = await userProvider.updateUser(updatedUser);
        if (success && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thông tin thành công!')),
          );
        }
      } else {
        // CHừe ĐỘ THÊM: Tạo Firebase Auth + Firestore
        final authService = AuthService();
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final uc = await authService.createSecondaryAccount(email, password);
        final uid = uc.user!.uid;
        final newUser = UserModel(
          id: uid,
          name: _nameController.text.trim(),
          email: email,
          role: _selectedRole,
          phone: _phoneController.text.trim(),
          createdAt: DateTime.now(),
        );
        final success = await userProvider.addUser(newUser);
        if (success && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã tạo tài khoản cho $email thành công!')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _submitError = e.toString().replaceAll('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // [UPDATE] Sử dụng Dialog thay vì Center + Container đơn thuần để có Material Widget bọc ngoài
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        // [UPDATE] Bọc trong SingleChildScrollView để tránh lỗi tràn nội dung (overflow) dọc khi hiện bàn phím
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditMode ? 'Sửa Thông Tin' : 'Tạo Tài Khoản', // [UPDATE]
                    style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
                  ),
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
                    
                    // [NEW] Khi sửa: hiển email dạng read-only, ẩn password
                    if (_isEditMode) ...[
                      Text('EMAIL', style: AppTextStyles.labelMonoSmall),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mail_outline, size: 18, color: AppColors.neutral),
                            const SizedBox(width: 12),
                            Text(widget.userToEdit!.email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Chế độ thêm: có đủ email + password
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
                      Text('MẬT KHẨU', style: AppTextStyles.labelMonoSmall),
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
                    ],

                    Text('CHỌN CHỨC VỤ', style: AppTextStyles.labelMonoSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.badge_outlined, size: 18),
                      ),
                      dropdownColor: AppColors.surfaceElevated,
                      items: const [
                        DropdownMenuItem(value: 'employee', child: Text('Nhân viên')), // [UPDATE] lowercase
                        DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')), // [UPDATE] lowercase
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 16), // [UPDATE]
                    Text('SỐ ĐIỆN THOẠI', style: AppTextStyles.labelMonoSmall), // [UPDATE]
                    const SizedBox(height: 8), // [UPDATE]
                    TextFormField( // [UPDATE]
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        hintText: '+84 xxx xxx xxx',
                        prefixIcon: Icon(Icons.phone_outlined, size: 18),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),

                    // [UPDATE] Hiện lỗi submit ngay trong dialog
                    if (_submitError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_submitError!, style: TextStyle(color: AppColors.error, fontSize: 13))),
                            ],
                          ),
                        ),
                      ),

                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit, // [UPDATE]
                        icon: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.background))
                            : const Icon(Icons.person_add_alt_1, color: AppColors.background, size: 18),
                        label: Text(_isSubmitting ? 'Đang tạo...' : 'Tạo Tài Khoản'), // [UPDATE]
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
