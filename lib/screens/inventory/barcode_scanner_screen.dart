import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/barcode_service.dart';
import '../../constants/theme.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final Function(String)? onBarcodeScanned;
  final String? title;
  final bool showProductInfo;

  const BarcodeScannerScreen({
    super.key,
    this.onBarcodeScanned,
    this.title,
    this.showProductInfo = true,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  final BarcodeService _barcodeService = BarcodeService();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isInitialized = false;
  bool _isScanning = true;
  bool _torchEnabled = false;
  String? _lastScannedCode;
  Product? _scannedProduct;
  bool _isLoadingProduct = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _barcodeService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (_isScanning) {
          _barcodeService.startScanning();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _barcodeService.stopScanning();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeScanner() async {
    try {
      await _barcodeService.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      _showErrorDialog('Failed to initialize camera: $e');
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final code = _barcodeService.processBarcodeResult(capture);
    if (code == null || code == _lastScannedCode) return;

    setState(() {
      _lastScannedCode = code;
      _isScanning = false;
    });

    // Haptic feedback
    // HapticFeedback.mediumImpact();

    if (widget.showProductInfo) {
      await _searchProductByBarcode(code);
    }

    if (widget.onBarcodeScanned != null) {
      widget.onBarcodeScanned!(code);
    } else {
      _showBarcodeResult(code);
    }
  }

  Future<void> _searchProductByBarcode(String barcode) async {
    setState(() {
      _isLoadingProduct = true;
      _scannedProduct = null;
    });

    try {
      final products = await _firestoreService.getProducts();
      final product = products.where((p) => p.sku == barcode).firstOrNull;
      
      setState(() {
        _scannedProduct = product;
        _isLoadingProduct = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProduct = false;
      });
      debugPrint('Error searching product: $e');
    }
  }

  void _showBarcodeResult(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Barcode Detected',
          style: AppTheme.heading3.copyWith(color: AppTheme.accentOrange),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Code: $code',
              style: AppTheme.bodyMedium.copyWith(
                fontFamily: 'monospace',
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingProduct)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Searching product...'),
                ],
              )
            else if (_scannedProduct != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Found:',
                      style: AppTheme.labelMedium.copyWith(
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _scannedProduct!.name,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Category: ${_scannedProduct!.category}',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      'Stock: ${_scannedProduct!.stock}',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      'Price: \$${_scannedProduct!.price.toStringAsFixed(2)}',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No product found with this barcode',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanning();
            },
            child: Text(
              'Scan Again',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.accentOrange,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, code);
            },
            child: Text(
              'Done',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.accentGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Error',
          style: AppTheme.heading3.copyWith(color: Colors.red),
        ),
        content: Text(
          message,
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.accentOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resumeScanning() {
    setState(() {
      _isScanning = true;
      _lastScannedCode = null;
      _scannedProduct = null;
    });
  }

  void _toggleTorch() async {
    await _barcodeService.toggleTorch();
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
  }

  void _switchCamera() async {
    await _barcodeService.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.title ?? 'Scan Barcode',
          style: AppTheme.heading3.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.accentOrange),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Camera preview
                MobileScanner(
                  controller: _barcodeService.controller,
                  onDetect: _onBarcodeDetected,
                ),
                
                // Overlay with scanning frame
                Container(
                  decoration: ShapeDecoration(
                    shape: QrScannerOverlayShape(
                      borderColor: AppTheme.accentOrange,
                      borderRadius: 16,
                      borderLength: 30,
                      borderWidth: 4,
                      cutOutSize: 250,
                    ),
                  ),
                ),
                
                // Instructions
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isScanning
                              ? 'Position the barcode within the frame'
                              : 'Barcode detected!',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_lastScannedCode != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Code: $_lastScannedCode',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.accentOrange,
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Manual input button
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: _showManualInputDialog,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Manual Input'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Manual Barcode Input',
          style: AppTheme.heading3.copyWith(color: AppTheme.accentOrange),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter barcode',
            hintText: 'Type or paste barcode here',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                if (widget.onBarcodeScanned != null) {
                  widget.onBarcodeScanned!(code);
                } else {
                  setState(() {
                    _lastScannedCode = code;
                    _isScanning = false;
                  });
                  if (widget.showProductInfo) {
                    _searchProductByBarcode(code);
                  }
                  _showBarcodeResult(code);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Custom overlay shape for the scanner
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    Path cutOut = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
    return Path.combine(PathOperation.difference, path, cutOut);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mBorderLength = borderLength > cutOutSize / 2 + borderOffset
        ? borderWidthSize / 2
        : borderLength;
    final mCutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - mCutOutSize / 2 + borderOffset,
      rect.top + height / 2 - mCutOutSize / 2 + borderOffset,
      mCutOutSize - borderOffset * 2,
      mCutOutSize - borderOffset * 2,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        boxPaint,
      )
      ..restore();

    // Draw corner borders
    final path = Path()
      // Top left
      ..moveTo(cutOutRect.left - borderOffset, cutOutRect.top + mBorderLength)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.top + borderRadius)
      ..quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset,
          cutOutRect.left + borderRadius, cutOutRect.top - borderOffset)
      ..lineTo(cutOutRect.left + mBorderLength, cutOutRect.top - borderOffset)
      // Top right
      ..moveTo(cutOutRect.right - mBorderLength, cutOutRect.top - borderOffset)
      ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top - borderOffset)
      ..quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.top - borderOffset,
          cutOutRect.right + borderOffset, cutOutRect.top + borderRadius)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top + mBorderLength)
      // Bottom right
      ..moveTo(cutOutRect.right + borderOffset, cutOutRect.bottom - mBorderLength)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.bottom - borderRadius)
      ..quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset,
          cutOutRect.right - borderRadius, cutOutRect.bottom + borderOffset)
      ..lineTo(cutOutRect.right - mBorderLength, cutOutRect.bottom + borderOffset)
      // Bottom left
      ..moveTo(cutOutRect.left + mBorderLength, cutOutRect.bottom + borderOffset)
      ..lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom + borderOffset)
      ..quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset,
          cutOutRect.left - borderOffset, cutOutRect.bottom - borderRadius)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom - mBorderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}