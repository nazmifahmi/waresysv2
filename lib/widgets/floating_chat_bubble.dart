import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../constants/theme.dart';
import '../screens/chat/chat_screen.dart';

class FloatingChatBubble extends StatefulWidget {
  const FloatingChatBubble({super.key});

  @override
  State<FloatingChatBubble> createState() => _FloatingChatBubbleState();
}

class _FloatingChatBubbleState extends State<FloatingChatBubble>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Bounce animation controller
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Pulse animation controller untuk notifikasi
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Bounce animation (naik turun halus)
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
    
    // Pulse animation untuk notifikasi
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Scale animation untuk tap feedback
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
    
    // Start bounce animation
    _startBounceAnimation();
  }

  void _startBounceAnimation() {
    _bounceController.repeat(reverse: true);
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  void _stopPulseAnimation() {
    _pulseController.stop();
    _pulseController.reset();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onBubbleTap(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    
    // Haptic feedback
    // HapticFeedback.lightImpact();
    
    // Scale animation untuk feedback
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
    
    // Buka chat window
    _openChatWindow(context);
  }

  void _openChatWindow(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatScreen(),
    ).then((_) {
      // Stop pulse animation ketika chat ditutup
      _stopPulseAnimation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Start/stop pulse animation berdasarkan unread messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (chatProvider.hasUnreadMessages) {
            _startPulseAnimation();
          } else {
            _stopPulseAnimation();
          }
        });
        
        return Positioned(
          right: 16,
          bottom: 100, // Posisi di atas bottom navigation jika ada
          child: AnimatedBuilder(
            animation: Listenable.merge([_bounceAnimation, _pulseAnimation]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_bounceAnimation.value),
                child: Transform.scale(
                  scale: chatProvider.hasUnreadMessages 
                      ? _pulseAnimation.value 
                      : 1.0,
                  child: GestureDetector(
                    onTap: () => _onBubbleTap(context),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppTheme.mainGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 2,
                          ),
                          if (chatProvider.hasUnreadMessages)
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.6),
                              blurRadius: 20,
                              offset: const Offset(0, 0),
                              spreadRadius: 4,
                            ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Main icon
                          Center(
                            child: Icon(
                              Icons.smart_toy_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          
                          // Notification badge
                          if (chatProvider.hasUnreadMessages)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          
                          // Loading indicator
                          if (chatProvider.isLoading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Widget untuk menambahkan floating bubble ke screen
class FloatingChatWrapper extends StatelessWidget {
  final Widget child;
  final bool showBubble;
  
  const FloatingChatWrapper({
    super.key,
    required this.child,
    this.showBubble = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showBubble) const FloatingChatBubble(),
      ],
    );
  }
}

// Mixin untuk screen yang ingin menampilkan floating bubble
mixin FloatingChatMixin<T extends StatefulWidget> on State<T> {
  @override
  Widget build(BuildContext context) {
    return FloatingChatWrapper(
      child: buildScreen(context),
    );
  }
  
  // Method yang harus diimplementasi oleh screen
  Widget buildScreen(BuildContext context);
}