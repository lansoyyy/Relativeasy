// import 'package:flutter/material.dart';
// import 'package:relativeasy/utils/colors.dart';
// import 'package:relativeasy/widgets/text_widget.dart';
// import 'package:relativeasy/widgets/button_widget.dart';
// import 'package:relativeasy/services/auth_service.dart';

// class ForgotPasswordDialog extends StatefulWidget {
//   const ForgotPasswordDialog({super.key});

//   @override
//   State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
// }

// class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
//   final TextEditingController _emailController = TextEditingController();
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     super.dispose();
//   }

//   String? _validateEmail(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Email is required';
//     }
//     if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//       return 'Please enter a valid email';
//     }
//     return null;
//   }

//   Future<void> _sendResetEmail() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final result = await AuthService().sendPasswordResetEmail(
//         email: _emailController.text.trim(),
//       );

//       if (mounted) {
//         if (result.isSuccess) {
//           // Show success message and close dialog
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(result.message),
//               backgroundColor: healthGreen,
//               behavior: SnackBarBehavior.floating,
//             ),
//           );
//           Navigator.of(context).pop();
//         } else {
//           // Show error message
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(result.message),
//               backgroundColor: healthRed,
//               behavior: SnackBarBehavior.floating,
//             ),
//           );
//         }
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: surface,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header
//               Row(
//                 children: [
//                   Container(
//                     width: 48,
//                     height: 48,
//                     decoration: BoxDecoration(
//                       color: primary.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Icon(
//                       Icons.lock_reset_outlined,
//                       color: primary,
//                       size: 24,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         TextWidget(
//                           text: 'Reset Password',
//                           fontSize: 20,
//                           color: textPrimary,
//                           fontFamily: 'Bold',
//                         ),
//                         const SizedBox(height: 4),
//                         TextWidget(
//                           text:
//                               'Enter your email to receive reset instructions',
//                           fontSize: 14,
//                           color: textSecondary,
//                           fontFamily: 'Regular',
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 24),

//               // Email field
//               TextFormField(
//                 controller: _emailController,
//                 keyboardType: TextInputType.emailAddress,
//                 validator: _validateEmail,
//                 style: const TextStyle(
//                   fontFamily: 'Regular',
//                   fontSize: 16,
//                   color: textPrimary,
//                 ),
//                 decoration: InputDecoration(
//                   labelText: 'Email Address',
//                   labelStyle: TextStyle(
//                     fontFamily: 'Regular',
//                     color: textSecondary,
//                   ),
//                   prefixIcon:
//                       const Icon(Icons.email_outlined, color: textSecondary),
//                   filled: true,
//                   fillColor: background,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: primary.withOpacity(0.2)),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: primary.withOpacity(0.2)),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: primary, width: 2),
//                   ),
//                   errorBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: healthRed, width: 2),
//                   ),
//                   focusedErrorBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: healthRed, width: 2),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 24),

//               // Action buttons
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextButton(
//                       onPressed:
//                           _isLoading ? null : () => Navigator.of(context).pop(),
//                       style: TextButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: TextWidget(
//                         text: 'Cancel',
//                         fontSize: 16,
//                         color: textSecondary,
//                         fontFamily: 'Medium',
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ButtonWidget(
//                       label: 'Send Reset Email',
//                       onPressed: _sendResetEmail,
//                       isLoading: _isLoading,
//                       height: 48,
//                       color: primary,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Helper function to show the forgot password dialog
// Future<void> showForgotPasswordDialog(BuildContext context) {
//   return showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) => const ForgotPasswordDialog(),
//   );
// }
