import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with SingleTickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Hide keyboard when opening scanner
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    // Hide keyboard before disposing
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanArea = size.width * 0.7;

    return WillPopScope(
      onWillPop: () async {
        // Hide keyboard before closing scanner
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
          backgroundColor: const Color(0xFFFFC7C7),
          elevation: 0,
        ),
        body: Stack(
          children: [
            // Camera view
            MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    // Hide keyboard before closing scanner
                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                    Navigator.pop(context, barcode.rawValue);
                  }
                }
              },
            ),
            // Semi-transparent overlay
            Container(
              color: Colors.black.withOpacity(0.5),
            ),
            // Scanning area
            Center(
              child: Container(
                width: scanArea,
                height: scanArea,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC7C7).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Transparent center
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFC7C7),
                          width: 2,
                        ),
                      ),
                    ),
                    // Corner decorations
                    ..._buildCornerDecorations(scanArea),
                    // Scanning line
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned(
                          top: scanArea * _animation.value,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFFC7C7).withOpacity(0),
                                  const Color(0xFFFFC7C7),
                                  const Color(0xFFFFC7C7).withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Instructions
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Position the QR code within the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    onPressed: () {
                      cameraController.toggleTorch();
                    },
                    icon: const Icon(
                      Icons.flashlight_on,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerDecorations(double size) {
    return [
      // Top left
      Positioned(
        top: 0,
        left: 0,
        child: _buildCorner(true, true),
      ),
      // Top right
      Positioned(
        top: 0,
        right: 0,
        child: _buildCorner(false, true),
      ),
      // Bottom left
      Positioned(
        bottom: 0,
        left: 0,
        child: _buildCorner(true, false),
      ),
      // Bottom right
      Positioned(
        bottom: 0,
        right: 0,
        child: _buildCorner(false, false),
      ),
    ];
  }

  Widget _buildCorner(bool isLeft, bool isTop) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: const Color(0xFFFFC7C7),
            width: isLeft ? 4 : 0,
          ),
          top: BorderSide(
            color: const Color(0xFFFFC7C7),
            width: isTop ? 4 : 0,
          ),
          right: BorderSide(
            color: const Color(0xFFFFC7C7),
            width: !isLeft ? 4 : 0,
          ),
          bottom: BorderSide(
            color: const Color(0xFFFFC7C7),
            width: !isTop ? 4 : 0,
          ),
        ),
      ),
    );
  }
} 