import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/sync_manager.dart';
import '../theme/carnival_theme.dart';

class SyncModal extends StatefulWidget {
  final SyncStatus status;
  final VoidCallback? onDismiss;

  const SyncModal({
    super.key,
    required this.status,
    this.onDismiss,
  });

  @override
  State<SyncModal> createState() => _SyncModalState();
}

class _SyncModalState extends State<SyncModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _mainEmoji {
    switch (widget.status) {
      case SyncStatus.initializing:
        return '🎭';
      case SyncStatus.syncing:
        return '🎉';
      case SyncStatus.success:
        return '✨';
      case SyncStatus.error:
        return '😢';
      case SyncStatus.offline:
        return '📡';
      default:
        return '🎪';
    }
  }

  String get _title {
    switch (widget.status) {
      case SyncStatus.initializing:
        return 'Preparando a folia!';
      case SyncStatus.syncing:
        return 'Buscando os blocos!';
      case SyncStatus.success:
        return 'Tudo pronto!';
      case SyncStatus.error:
        return 'Ops! Algo deu errado';
      case SyncStatus.offline:
        return 'Sem conexao';
      default:
        return 'Carregando...';
    }
  }

  String get _subtitle {
    switch (widget.status) {
      case SyncStatus.initializing:
        return '🎊 Carregando os melhores blocos de BH... 🎊';
      case SyncStatus.syncing:
        return '🥁 Sincronizando com a alegria do carnaval... 🥁';
      case SyncStatus.success:
        return '🎶 Bora pular! Os blocos te esperam! 🎶';
      case SyncStatus.error:
        return '💔 Nao foi possivel carregar os blocos 💔';
      case SyncStatus.offline:
        return '📶 Verifique sua conexao com a internet 📶';
      default:
        return '⏳ Aguarde um momento... ⏳';
    }
  }

  List<String> get _funFacts {
    return [
      '🎺 Sabia que BH tem mais de 500 blocos de rua?',
      '💃 O carnaval de BH e considerado um dos maiores do Brasil!',
      '🌟 Blocos tradicionais existem ha mais de 100 anos!',
      '🎤 A musica dos blocos vai do axe ao funk!',
      '🗺️ Os blocos passam pelos bairros mais bonitos da cidade!',
      '👑 Cada bloco tem sua propria identidade e historia!',
      '🎨 As fantasias sao parte essencial da folia!',
      '🍻 O carnaval de BH e conhecido pela alegria contagiante!',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.status == SyncStatus.initializing ||
        widget.status == SyncStatus.syncing;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        // 80% opacity black background
        color: Colors.black.withOpacity(0.80),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated emoji
              ScaleTransition(
                scale: _pulseAnimation,
                child: Text(
                  _mainEmoji,
                  style: const TextStyle(fontSize: 80),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                _title,
                style: GoogleFonts.pacifico(
                  fontSize: 32,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: CarnivalTheme.pink.withOpacity(0.5),
                      offset: const Offset(2, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Subtitle with emojis
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              // Loading indicator
              if (isLoading) ...[
                // Colorful carnival-themed progress indicator
                SizedBox(
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        CarnivalTheme.yellow,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Fun fact
                _buildFunFact(),
              ],

              // Decorative confetti emojis
              const SizedBox(height: 40),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🎭', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 16),
                  Text('🎊', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 16),
                  Text('🎉', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 16),
                  Text('🎶', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 16),
                  Text('💃', style: TextStyle(fontSize: 28)),
                ],
              ),

              // Dismiss button for error/offline states
              if (widget.status == SyncStatus.error ||
                  widget.status == SyncStatus.offline) ...[
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: widget.onDismiss,
                  icon: const Icon(Icons.close),
                  label: const Text('Continuar mesmo assim'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CarnivalTheme.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunFact() {
    // Show a random fun fact
    final facts = _funFacts;
    final randomFact = facts[DateTime.now().second % facts.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CarnivalTheme.yellow.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '💡 Voce sabia?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: CarnivalTheme.yellow,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            randomFact,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
