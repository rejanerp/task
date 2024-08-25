import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/light_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? '';
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (userDoc.exists) {
        _roleController.text = userDoc['role'] ?? 'Seu Cargo';
      }
    } catch (e) {
      print('Erro ao carregar o cargo: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (user != null) {
      String? photoURL;

      if (_imageFile != null) {
        try {
          // Upload da imagem para o Firebase Storage
          final storageRef = FirebaseStorage.instance.ref().child('user_profiles').child('${user!.uid}.jpg');
          await storageRef.putFile(_imageFile!);

          // Obtém a URL da imagem carregada
          photoURL = await storageRef.getDownloadURL();
          
          // Atualiza a foto do perfil no Firebase Authentication
          await user!.updatePhotoURL(photoURL);
        } catch (e) {
          print('Erro ao fazer upload da imagem: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao fazer upload da imagem')),
          );
          return;
        }
      }

      // Atualiza o nome do usuário
      await user!.updateDisplayName(_nameController.text);

      // Atualiza o cargo do usuário no Firestore
      try {
  await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
    'name': _nameController.text,
    'role': _roleController.text,
    'photoURL': photoURL ?? user!.photoURL,
  }, SetOptions(merge: true)); // merge: true mantém os dados existentes e atualiza apenas os campos especificados
} catch (e) {
  print('Erro ao atualizar o Firestore: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Erro ao atualizar o Firestore')),
  );
  return;
}

      // Exibe uma mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil do Usuário'),
        backgroundColor: LightColors.kBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : AssetImage('assets/images/avatar.jpg')) as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 30.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _roleController,
              decoration: InputDecoration(labelText: 'Cargo'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
