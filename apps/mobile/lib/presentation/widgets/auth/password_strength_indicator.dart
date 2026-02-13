import 'package:flutter/material.dart';

enum PasswordStrength {
  weak,
  medium,
  strong,
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showRequirements;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showRequirements = true,
  });

  PasswordStrength _calculateStrength() {
    if (password.isEmpty) return PasswordStrength.weak;

    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score >= 4) return PasswordStrength.strong;
    if (score >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  Color _getStrengthColor() {
    final strength = _calculateStrength();
    switch (strength) {
      case PasswordStrength.strong:
        return Colors.green;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.weak:
        return Colors.red;
    }
  }

  String _getStrengthText() {
    final strength = _calculateStrength();
    switch (strength) {
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.weak:
        return 'Weak';
    }
  }

  bool _meetsRequirement(String pattern) {
    if (password.isEmpty) return false;
    return RegExp(pattern).hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = _calculateStrength();
    final color = _getStrengthColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength == PasswordStrength.weak
                      ? 0.33
                      : strength == PasswordStrength.medium
                          ? 0.66
                          : 1.0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _getStrengthText(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        if (showRequirements) ...[
          const SizedBox(height: 12),
          _buildRequirement('At least 8 characters', password.length >= 8),
          _buildRequirement('Uppercase letter', _meetsRequirement(r'[A-Z]')),
          _buildRequirement('Lowercase letter', _meetsRequirement(r'[a-z]')),
          _buildRequirement('Number', _meetsRequirement(r'[0-9]')),
          _buildRequirement('Special character',
              _meetsRequirement(r'[!@#$%^&*(),.?":{}|<>]')),
        ],
      ],
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isMet ? Colors.green : Colors.grey.shade600,
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
