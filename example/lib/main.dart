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
  // Holds the text that user typed.
  TextEditingController controller = TextEditingController(text: '...');

  // is true will show the numeric keyboard.
  bool isNumericMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            TextField(
              controller: controller,
            ),
            SwitchListTile(
              title: Text(
                'Keyboard Type = ' +
                    (isNumericMode
                        ? 'VirtualKeyboardType.Numeric'
                        : 'VirtualKeyboardType.Alphanumeric'),
              ),
              value: isNumericMode,
              onChanged: (val) {
                setState(() {
                  isNumericMode = val;
                });
              },
            ),
            Expanded(
              child: Container(),
            ),
            Container(
              color: Colors.deepPurple,
              child: VirtualKeyboard(
                height: 300,
                textColor: Colors.white,
                type: isNumericMode
                    ? VirtualKeyboardType.Numeric
                    : VirtualKeyboardType.Alphanumeric,
              ),
            )
          ],
        ),
      ),
    );
  }
}
