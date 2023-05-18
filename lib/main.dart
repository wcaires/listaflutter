import 'package:flutter/material.dart';

// firebase
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

// firestore
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Exemplo Firestore';

    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
        ),
        body: const MyCustomForm(),
      ),
    );
  }
}

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({Key? key}) : super(key: key);

  @override
  MyCustomFormState createState() => MyCustomFormState();
}

class MyCustomFormState extends State<MyCustomForm> {
  final myController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  CollectionReference nomes = FirebaseFirestore.instance.collection('nomes');
  List<String> nomeList = [];

  @override
  void initState() {
    super.initState();
    fetchNomes(); // Fetch names when the widget initializes
  }

  Future<void> fetchNomes() async {
    try {
      QuerySnapshot querySnapshot = await nomes.get();
      setState(() {
        nomeList = querySnapshot.docs.map((doc) => doc['nome'] as String).toList();
      });
    } catch (error) {
      print("Erro ao buscar nomes: $error");
    }
  }

  Future<void> adicionarNome(String nome) {
    return nomes
        .add({
      'nome': nome,
    })
        .then((value) {
      setState(() {
        nomeList.add(nome);
      });
      print("Nome adicionado");
    })
        .catchError((error) => print("Erro ao adicionar: $error"));
  }

  Future<void> removerNome(String nome) {
    return nomes
        .where('nome', isEqualTo: nome)
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.delete();
        setState(() {
          nomeList.remove(nome);
        });
      });
    })
        .catchError((error) => print("Erro ao remover: $error"));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextFormField(
                  controller: myController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe um nome';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      adicionarNome(myController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gravando dados no Firestore...'),
                        ),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: nomeList.length,
            itemBuilder: (context, index) {
              final nome = nomeList[index];
              return ListTile(
                title: Text(nome),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => removerNome(nome),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
