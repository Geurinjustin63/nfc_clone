import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';

class PinInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final bool enabled;
  final int length;

  const PinInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.enabled = true,
    this.length = 4,
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged(widget.controller.text);
    setState(() {}); // Rebuild to update PIN dots
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PIN Input Title
        Text(
          'Enter your PIN',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: AppConstants.defaultPadding),
        
        // PIN Dots Display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.length, (index) {
            final isFilled = index < widget.controller.text.length;
            final isActive = index == widget.controller.text.length && widget.focusNode.hasFocus;
            
            return AnimatedContainer(
              duration: AppConstants.shortAnimation,
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: isActive ? 2 : 1,
                ),
                color: isFilled
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
              child: isFilled
                  ? Icon(
                      Icons.circle,
                      color: Colors.white,
                      size: 16,
                    )
                  : isActive
                      ? Icon(
                          Icons.circle_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16,
                        )
                      : null,
            );
          }),
        ),
        
        const SizedBox(height: AppConstants.defaultPadding),
        
        // Hidden TextField for input handling
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        
        // Custom Number Keypad
        if (widget.enabled) ...[
          const SizedBox(height: AppConstants.defaultPadding),
          _buildNumberKeypad(),
        ],
      ],
    );
  }

  Widget _buildNumberKeypad() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          // Numbers 1-3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          
          // Numbers 4-6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          
          // Numbers 7-9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          
          // 0 and Backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60), // Empty space
              _buildKeypadButton('0'),
              _buildKeypadButton(
                '⌫',
                onTap: _onBackspace,
                isBackspace: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(
    String text, {
    VoidCallback? onTap,
    bool isBackspace = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => _onNumberTap(text),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isBackspace
                ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          child: Center(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isBackspace
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onNumberTap(String number) {
    if (widget.controller.text.length < widget.length) {
      widget.controller.text += number;
      
      // Provide haptic feedback
      HapticFeedback.selectionClick();
    }
  }

  void _onBackspace() {
    if (widget.controller.text.isNotEmpty) {
      widget.controller.text = widget.controller.text.substring(
        0,
        widget.controller.text.length - 1,
      );
      
      // Provide haptic feedback
      HapticFeedback.selectionClick();
    }
  }
}