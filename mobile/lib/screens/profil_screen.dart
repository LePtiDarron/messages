import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/profil_service.dart';
import './login_screen.dart';
import '../services/token_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  _ProfilScreenState createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final ProfilService profilService = ProfilService();
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;
  File? _image;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  void fetchUserProfile() async {
    try {
      final homeData = await profilService.getUserData();
      setState(() {
        userData = homeData;
        isLoading = false;
      });
    } catch (err) {
      setState(() {
        errorMessage = 'Erreur : $err';
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_image == null) return;
    try {
      final result =
          await profilService.uploadProfilePicture(_image!);
      if (result) {
        fetchUserProfile();
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du téléchargement de la photo : $e';
      });
    }
  }

  void _logout() {
    removeToken();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmation de suppression'),
          content: const Text(
              'Êtes-vous sûr de vouloir supprimer définitivement ce compte ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final result =
                      await profilService.deleteProfile();
                  if (result) {
                    _logout();
                  }
                } catch (e) {
                  setState(() {
                    errorMessage =
                        'Erreur lors de la suppression du compte : $e';
                  });
                }
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 75,
                              backgroundImage: _image != null
                                  ? FileImage(_image!)
                                  : userData?['picture'] == '/'
                                      ? const AssetImage(
                                              'assets/images/defaultProfilPicture.png')
                                          as ImageProvider
                                      : NetworkImage(
                                          'http://localhost:5000${userData?['picture']}',
                                        ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _pickImage,
                                child: const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.blue,
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          '${userData?['firstName']} ${userData?['lastName']}',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          '${userData?['email']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Spacer(),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: ElevatedButton(
                            onPressed: _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text(
                              'Se déconnecter',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: ElevatedButton(
                            onPressed: _deleteAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text(
                              'Supprimer ce compte',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
