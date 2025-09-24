import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import '../models/card_balance.dart';
import '../../../app/themes.dart';

class TotalBalanceCard extends StatefulWidget {
  final Decimal totalBalance;
  final Currency currency;
  final DateTime? lastUpdated;
  final bool isLoading;

  const TotalBalanceCard({
    super.key,
    required this.totalBalance,
    required this.currency,
    this.lastUpdated,
    this.isLoading = false,
  });

  @override
  State<TotalBalanceCard> createState() => _TotalBalanceCardState();
}

class _TotalBalanceCardState extends State<TotalBalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation.value,
            child: _buildCard(),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryVariant,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: AppColors.textOnPrimary,
                size: 32,
              ),
              const Spacer(),
              if (widget.isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textOnPrimary,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.trending_up,
                  color: AppColors.secondary,
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Total Balance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textOnPrimary.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _formatBalance(),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                ),
              ),
              if (!widget.isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    CardBalance.getCurrencyName(widget.currency),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLastUpdatedInfo(),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedInfo() {
    if (widget.lastUpdated == null) {
      return Text(
        'No recent updates',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textOnPrimary.withOpacity(0.7),
            ),
      );
    }

    final updateText = _formatLastUpdated(widget.lastUpdated!);
    final isRecent = DateTime.now().difference(widget.lastUpdated!).inMinutes < 5;

    return Row(
      children: [
        Icon(
          isRecent ? Icons.check_circle : Icons.schedule,
          color: AppColors.textOnPrimary.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          'Updated $updateText',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textOnPrimary.withOpacity(0.7),
              ),
        ),
        if (isRecent) ...[
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  String _formatBalance() {
    if (widget.isLoading) {
      return '${CardBalance.getCurrencySymbol(widget.currency)}---.--';
    }

    final symbol = CardBalance.getCurrencySymbol(widget.currency);
    
    if (widget.totalBalance >= Decimal.fromInt(1000000)) {
      final millions = widget.totalBalance / Decimal.fromInt(1000000);
      return '$symbol${millions.toStringAsFixed(1)}M';
    } else if (widget.totalBalance >= Decimal.fromInt(1000)) {
      final thousands = widget.totalBalance / Decimal.fromInt(1000);
      return '$symbol${thousands.toStringAsFixed(1)}K';
    } else {
      return '$symbol${widget.totalBalance.toStringAsFixed(2)}';
    }
  }

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastUpdated.day}/${lastUpdated.month}/${lastUpdated.year}';
    }
  }
}