import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'vehicle_parser.dart';
import 'dart:io';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {

  final ImagePicker _picker = ImagePicker();

  final TextRecognizer _textRecognizer =
  TextRecognizer(script: TextRecognitionScript.latin);

  String extractedText = '';
  bool isProcessing = false;
  String? scannedImagePath;
  bool isSaved =false;

  VehicleData? vehicleData;


  Widget _buildInfoRow(String label, String value, ValueChanged<String> onChanged,){
    return Container(
      width:double.infinity,
      margin: const EdgeInsets.only(bottom:12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
      const SizedBox(height:6),
      TextFormField(
        initialValue: value,
        onChanged: onChanged,

        decoration: const InputDecoration(
          border:OutlineInputBorder(),
          isDense:true,
          hintText: 'Not detected',
        ),


        ),

      ],
      ),



    );

  }

  Future<void> scanDocument() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (image == null) {
      return;
    }
    setState((){
      scannedImagePath = image.path;
    });

    await processImage(image.path);
  }

  Future<void> processImage(String imagePath) async {
    setState(() {
      isProcessing = true;
      extractedText = '';
      vehicleData =null;
      isSaved=false;

    });

    try {
      final inputImage = InputImage.fromFilePath(imagePath);

      final RecognizedText recognizedText =
      await _textRecognizer.processImage(inputImage);




  

      if (recognizedText.text.trim().isEmpty) {
  setState(() {
    extractedText =
        'No text was detected. Please take a clearer photo of the document.';
    vehicleData = null;
  });
} else {
        final parsedData = VehicleParser.parse(recognizedText.text);

        setState(() {
          extractedText = recognizedText.text;
          vehicleData = parsedData;
        });
      }
    } catch (e) {
      setState(() {
        extractedText = 'Unable to read the document. Please try again.';
        vehicleData = null;
        scannedImagePath=null;
      });
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  void saveVehicleInformation() {
    if (vehicleData == null) {
      return;
    }
    if (vehicleData!.registrationNumber.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the registration number.'),
        ),
      );
      return;
    }

    if(vehicleData!.ownerName.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the owner name'),
        ),
      );
      return;
    }

    if(vehicleData!.make.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:Text ('Please enter the vehicle make'),
        ),
      );
      return;
    }

    if (vehicleData!.model.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:Text('Please enter the vehicle model.'),

          ),
      );
      return;
    }

    if (vehicleData!.chassisNumber.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:Text('Please enter the chassis number.'),

        ),
      );
      return;
    }

    if (vehicleData!.engineNumber.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:Text('Please enter the Engine Number.'),

        ),
      );
      return;
    }

    if (vehicleData!.registrationDate.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:Text('Please enter the Registration Date.'),

        ),
      );
      return;
    }

    if (vehicleData!.expiryDate.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:Text('Please enter the expiry date.'),

        ),
      );
      return;
    }

    if (vehicleData!.engineCapacity.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:Text('Please enter the engine capacity.'),

        ),
      );
      return;
    }

    if (vehicleData!.modelYear.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:Text('Please enter the model year.'),

        ),
      );
      return;
    }

    setState((){
      isSaved =true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehicle information saved successfully.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Document OCR'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : scanDocument,
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  'Scan Vehicle Document',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (scannedImagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(scannedImagePath!),
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 16),
            ],

            if (isProcessing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text(
                'Reading document...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OCR Result',
                      style: TextStyle(
                        fontSize:20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height:10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        extractedText.isEmpty
                            ? 'Scanned text will appear here.'
                            : extractedText,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    if(vehicleData!=null)...[
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Vehicle Information',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height:15),

                      _buildInfoRow(
                        'Registration Number',
                        vehicleData!.registrationNumber,
                            (value) {
                          setState(() {
                            vehicleData!.registrationNumber = value;
                          });
                        },
                      ),

                      _buildInfoRow(
                        'Owner Name',
                        vehicleData!.ownerName,
                            (value) {
                          setState(() {
                            vehicleData!.ownerName = value;
                          });
                        },
                      ),

                      _buildInfoRow(
                        'Make',
                        vehicleData!.make,
                            (value) {
                          setState(() {
                            vehicleData!.make = value;
                          });
                        },
                      ),

                      _buildInfoRow(
                        'Model',
                        vehicleData!.model,
                            (value) {
                          setState(() {
                            vehicleData!.model = value;
                          });
                        },
                      ),

                      _buildInfoRow(
                        'Chassis Number',
                        vehicleData!.chassisNumber,
                            (value) {
                          setState(() {
                            vehicleData!.chassisNumber = value;
                          });
                        },
                      ),

                      _buildInfoRow(
                        'Engine Number',
                        vehicleData!.engineNumber,
                            (value) {
                          setState(() {
                            vehicleData!.engineNumber = value;
                          });
                        },
                      ),

                      _buildInfoRow(
                        'Registration Date',
                        vehicleData!.registrationDate,
                            (value) {
                          setState(() {
                            vehicleData!.registrationDate = value;
                          });
                        },
                      ),

                      _buildInfoRow(
                        'Expiry Date',
                        vehicleData!.expiryDate,
                            (value) {
                          setState(() {
                            vehicleData!.expiryDate = value;
                          });
                        },
                      ),

                      _buildInfoRow(
                        'Engine Capacity',
                        vehicleData!.engineCapacity,
                            (value) {
                          setState(() {
                            vehicleData!.engineCapacity = value;
                          });
                        },
                      ),

                      _buildInfoRow(
                        'Model Year',
                        vehicleData!.modelYear,
                            (value) {
                          setState(() {
                            vehicleData!.modelYear = value;
                          });
                        },
                      ),


                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: saveVehicleInformation,
                          icon: const Icon(Icons.save),
                          label: const Text(
                            'Save Vehicle Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      if (isSaved) ...[
                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Vehicle information saved successfully.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              scannedImagePath = null;
                              extractedText = '';
                              vehicleData = null;
                              isSaved= false;
                            });
                          },

                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            'Clear Scan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),


                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}