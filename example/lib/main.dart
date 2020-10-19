import 'package:flutter/material.dart';
import 'package:virtual_keyboard/virtual_keyboard.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Keyboard Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Virtual Keyboard Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _controllers = <TextInputType, TextEditingController>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Scrollbar(
              child: ListView(
                children: <Widget>[
                  for (final type in TextInputType.values)
                    TextField(
                      keyboardType: type,
                      controller: _controllers[type] ??=
                          TextEditingController(),
                      decoration: InputDecoration(
                        labelText: type.toJson()['name'].toString(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.deepPurple,
            child: VirtualKeyboard(
              height: 300,
              textColor: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}
