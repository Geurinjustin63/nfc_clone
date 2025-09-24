import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/themes.dart';
import '../../../core/constants/app_constants.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../cards/providers/cards_provider.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, CardsProvider>(
      builder: (context, authProvider, cardsProvider, child) {
        final session = authProvider.currentSession;
        final totalCards = cardsProvider.cards.length;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.secondary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Welcome message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getWelcomeMessage(authProvider.currentMethod),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Authentication status icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAuthStatusColor(authProvider.currentMethod).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getAuthStatusIcon(authProvider.currentMethod),
                      color: _getAuthStatusColor(authProvider.currentMethod),
                      size: 24,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Quick stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Total Cards',
                      totalCards.toString(),
                      Icons.credit_card,
                      AppColors.info,
                    ),
                  ),
                  
                  const SizedBox(width: AppConstants.defaultPadding),
                  
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Favorites',
                      cardsProvider.favoriteCards.length.toString(),
                      Icons.favorite,
                      AppColors.warning,
                    ),
                  ),
                  
                  const SizedBox(width: AppConstants.defaultPadding),
                  
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Session Time',
                      _formatRemainingTime(session?.remainingTime),
                      Icons.access_time,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getWelcomeMessage(AuthMethod method) {
    switch (method) {
      case AuthMethod.biometric:
        return 'Authenticated with biometrics';
      case AuthMethod.pin:
        return 'Authenticated with PIN';
      case AuthMethod.password:
        return 'Authenticated with password';
      case AuthMethod.none:
        return 'Guest access';
    }
  }

  IconData _getAuthStatusIcon(AuthMethod method) {
    switch (method) {
      case AuthMethod.biometric:
        return Icons.fingerprint;
      case AuthMethod.pin:
        return Icons.pin;
      case AuthMethod.password:
        return Icons.password;
      case AuthMethod.none:
        return Icons.person_outline;
    }
  }

  Color _getAuthStatusColor(AuthMethod method) {
    switch (method) {
      case AuthMethod.biometric:
        return AppColors.success;
      case AuthMethod.pin:
        return AppColors.info;
      case AuthMethod.password:
        return AppColors.primary;
      case AuthMethod.none:
        return AppColors.warning;
    }
  }

  String _formatRemainingTime(Duration? duration) {
    if (duration == null) return 'N/A';
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}