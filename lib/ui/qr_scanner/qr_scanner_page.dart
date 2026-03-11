import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null) return;

    setState(() => _scanned = true);
    _controller.stop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scanned: $value'),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.maybePop(context, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanFrameSize = MediaQuery.of(context).size.width * 0.65;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Dark overlay with transparent scan frame
          _buildScanOverlay(context, scanFrameSize),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instruction text below scan frame
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120),
              child: Text(
                'Align QR code to auto-recognize',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(BuildContext context, double frameSize) {
    return CustomPaint(
      painter: _ScanOverlayPainter(frameSize, _scanLineAnimation),
      child: const SizedBox.expand(),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double frameSize;
  final Animation<double> scanLineAnimation;

  _ScanOverlayPainter(this.frameSize, this.scanLineAnimation) : super(repaint: scanLineAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final halfFrame = frameSize / 2;

    final left = centerX - halfFrame;
    final top = centerY - halfFrame;
    final right = centerX + halfFrame;
    final bottom = centerY + halfFrame;

    // Dark overlay except the scan frame
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), overlayPaint); // top
    canvas.drawRect(Rect.fromLTWH(0, bottom, size.width, size.height - bottom), overlayPaint); // bottom
    canvas.drawRect(Rect.fromLTWH(0, top, left, frameSize), overlayPaint); // left
    canvas.drawRect(Rect.fromLTWH(right, top, size.width - right, frameSize), overlayPaint); // right

    // Corner brackets
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;
    // Top-left
    canvas.drawLine(Offset(left, top + cornerLen), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(right - cornerLen, top), Offset(right, top), cornerPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLen), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(left, bottom - cornerLen), Offset(left, bottom), cornerPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLen, bottom), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(right - cornerLen, bottom), Offset(right, bottom), cornerPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLen), cornerPaint);

    // Animated teal scan line
    final scanY = top + (frameSize * scanLineAnimation.value);
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, const Color(0xFF00E5CC), Colors.transparent],
      ).createShader(Rect.fromLTWH(left, scanY, frameSize, 1))
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(left, scanY), Offset(right, scanY), scanLinePaint);
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter oldDelegate) => true;
}
