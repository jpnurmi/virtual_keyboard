part of virtual_keyboard;

/// The default keyboard height. Can we overriden by passing
///  `height` argument to `VirtualKeyboard` widget.
const double _virtualKeyboardDefaultHeight = 300;

const int _virtualKeyboardBackspaceEventPerioud = 250;

const int _virtualKeyboardSlideDuration = 125;

/// Virtual Keyboard widget.
class VirtualKeyboard extends StatefulWidget {
  /// Keyboard Type: Should be inited in creation time.
  final VirtualKeyboardType type;

  /// Callback for Key press event. Called with pressed `Key` object.
  final Function onKeyPress;

  /// Virtual keyboard height. Default is 300
  final double height;

  /// Color for key texts and icons.
  final Color textColor;

  /// Color for the background.
  final Color backgroundColor;

  /// Font size for keyboard keys.
  final double fontSize;

  /// The builder function will be called for each Key object.
  final Widget Function(BuildContext context, VirtualKeyboardKey key) builder;

  /// Set to true if you want only to show Caps letters.
  final bool alwaysCaps;

  VirtualKeyboard(
      {Key key,
      @required this.type,
      @required this.onKeyPress,
      this.builder,
      this.height = _virtualKeyboardDefaultHeight,
      this.textColor = Colors.black,
      this.backgroundColor = Colors.grey,
      this.fontSize = 14,
      this.alwaysCaps = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VirtualKeyboardState();
  }
}

/// Holds the state for Virtual Keyboard class.
class _VirtualKeyboardState extends State<VirtualKeyboard> {
  VirtualKeyboardType type;
  Function onKeyPress;
  // The builder function will be called for each Key object.
  Widget Function(BuildContext context, VirtualKeyboardKey key) builder;
  double height;
  Color textColor;
  Color backgroundColor;
  double fontSize;
  bool alwaysCaps;
  bool visible = false;
  // Text Style for keys.
  TextStyle textStyle;

  // True if shift is enabled.
  bool isShiftEnabled = false;

  // Client ID provided by Flutter to report events with.
  int clientId = -1;

  // Input action to perform when enter pressed.
  String inputAction;

  // The type of input.
  String inputType;

  // Handles underlying text input state, using a simple ASCII model.
  final model = VirtualKeyboardModel();

  // Filters text input channel messages
  final messenger = VirtualKeyboardMessenger();

  // Codec for encoding and decoding text input methods
  final codec = JSONMethodCodec();

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      type = widget.type;
      onKeyPress = widget.onKeyPress;
      height = widget.height;
      textColor = widget.textColor;
      backgroundColor = widget.backgroundColor;
      fontSize = widget.fontSize;
      alwaysCaps = widget.alwaysCaps;

      // Init the Text Style for keys.
      textStyle = TextStyle(
        fontSize: fontSize,
        color: textColor,
      );
    });
  }

  @override
  void initState() {
    super.initState();

    type = widget.type;
    onKeyPress = widget.onKeyPress;
    height = widget.height;
    backgroundColor = widget.backgroundColor;
    textColor = widget.textColor;
    fontSize = widget.fontSize;
    alwaysCaps = widget.alwaysCaps;

    // Init the Text Style for keys.
    textStyle = TextStyle(
      fontSize: fontSize,
      color: textColor,
    );

    window.onPlatformMessage = messenger.handlePlatformMessage;
    TextInput.setChannel(MethodChannel('virtual_keyboard', codec, messenger));
    messenger.setMessageFilter('virtual_keyboard', (ByteData message) {
      _handleMethodCall(codec.decodeMethodCall(message));
      return Future.value(codec.encodeSuccessEnvelope(null));
    });
  }

  @override
  void dispose() {
    window.onPlatformMessage =
        ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage;
    TextInput.setChannel(SystemChannels.textInput);
    messenger.setMessageFilter('virtual_keyboard', null);
    super.dispose();
  }

  void _setClient(int id, Map<String, dynamic> config) {
    clientId = id;
    inputAction = config['inputAction'].toString();
    inputType = config['inputType']['name'].toString();
  }

  void _show() {
    setState(() => visible = true);
  }

  // Updates the editing state from Flutter.
  void _setEditingState(Map<String, dynamic> state) {
    String text = state['text'].toString();
    int selectionBase = state['selectionBase'] as int;
    int selectionExtent = state['selectionExtent'] as int;
    // Flutter uses -1/-1 for invalid; translate that to 0/0 for the model.
    if (selectionBase == -1 && selectionExtent == -1) {
      selectionBase = selectionExtent = 0;
    }

    model.text = text;
    model.selection =
        TextSelection(baseOffset: selectionBase, extentOffset: selectionExtent);
  }

  void _clearClient() {
    clientId = -1;
  }

  void _hide() {
    setState(() => visible = false);
  }

  void _handleMethodCall(MethodCall call) {
    switch (call.method) {
      case 'TextInput.setClient':
        _setClient(call.arguments[0], call.arguments[1]);
        break;
      case 'TextInput.show':
        _show();
        break;
      case 'TextInput.setEditingState':
        _setEditingState(call.arguments);
        break;
      case 'TextInput.clearClient':
        _clearClient();
        break;
      case 'TextInput.hide':
        _hide();
        break;
      case 'TextInput.setEditableSizeAndTransform':
      case 'TextInput.setMarkedTextRect':
      case 'TextInput.setStyle':
        break;
      default:
        throw UnimplementedError(call.method);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: MediaQuery.of(context).size.width,
      height: visible ? height : 0,
      curve: Curves.easeInOutCubic,
      duration: Duration(milliseconds: _virtualKeyboardSlideDuration),
      color: backgroundColor,
      child: OverflowBox(
        minHeight: height,
        maxHeight: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _rows(),
        ),
      ),
    );
  }

  void _handleKeyPress(VirtualKeyboardKey key) {
    var changed = false;
    var action = false;
    switch (key.keyType) {
      case VirtualKeyboardKeyType.String:
        changed = model.addText(isShiftEnabled ? key.capsText : key.text);
        break;
      case VirtualKeyboardKeyType.Action:
        switch (key.action) {
          case VirtualKeyboardKeyAction.Backspace:
            changed = model.backspace();
            break;
          case VirtualKeyboardKeyAction.Return:
            if (inputType.contains('multiline')) {
              changed = model.addText('\n');
            }
            action = true;
            break;
          case VirtualKeyboardKeyAction.Space:
            changed = model.addText(' ');
            break;
          default:
            break;
        }
        break;
    }
    if (changed) {
      _updateEditingState();
    }
    if (action) {
      _performAction();
    }
    onKeyPress?.call(key);
  }

  void _updateEditingState() {
    final state = <String, dynamic>{};
    state['text'] = model.text;
    state['selectionBase'] = model.selection.baseOffset;
    state['selectionExtent'] = model.selection.extentOffset;

    // The following keys are not implemented and set to default values.
    state['selectionAffinity'] = 'TextAffinity.downstream';
    state['selectionIsDirectional'] = false;
    state['composingBase'] = -1;
    state['composingExtent'] = -1;

    _platformCall('TextInputClient.updateEditingState', [clientId, state]);
  }

  void _performAction() {
    _platformCall('TextInputClient.performAction', [clientId, inputAction]);
  }

  void _platformCall(String method, dynamic args) {
    final call = codec.encodeMethodCall(MethodCall(method, args));
    window.onPlatformMessage('virtual_keyboard', call, (data) {});
  }

  /// Returns the rows for keyboard.
  List<Widget> _rows() {
    // Get the keyboard Rows
    List<List<VirtualKeyboardKey>> keyboardRows =
        type == VirtualKeyboardType.Numeric
            ? _getKeyboardRowsNumeric()
            : _getKeyboardRows();

    // Generate keyboard row.
    List<Widget> rows = List.generate(keyboardRows.length, (int rowNum) {
      return Material(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          // Generate keboard keys
          children: List.generate(
            keyboardRows[rowNum].length,
            (int keyNum) {
              // Get the VirtualKeyboardKey object.
              VirtualKeyboardKey virtualKeyboardKey =
                  keyboardRows[rowNum][keyNum];

              Widget keyWidget;

              // Check if builder is specified.
              // Call builder function if specified or use default
              //  Key widgets if not.
              if (builder == null) {
                // Check the key type.
                switch (virtualKeyboardKey.keyType) {
                  case VirtualKeyboardKeyType.String:
                    // Draw String key.
                    keyWidget = _keyboardDefaultKey(virtualKeyboardKey);
                    break;
                  case VirtualKeyboardKeyType.Action:
                    // Draw action key.
                    keyWidget = _keyboardDefaultActionKey(virtualKeyboardKey);
                    break;
                }
              } else {
                // Call the builder function, so the user can specify custom UI for keys.
                keyWidget = builder(context, virtualKeyboardKey);

                if (keyWidget == null) {
                  throw 'builder function must return Widget';
                }
              }

              return keyWidget;
            },
          ),
        ),
      );
    });

    return rows;
  }

  // True if long press is enabled.
  bool longPress;

  /// Creates default UI element for keyboard Key.
  Widget _keyboardDefaultKey(VirtualKeyboardKey key) {
    return Expanded(
        child: InkWell(
      canRequestFocus: false,
      onTap: () {
        _handleKeyPress(key);
      },
      child: Container(
        height: height / _keyRows.length,
        child: Center(
            child: Text(
          alwaysCaps
              ? key.capsText
              : (isShiftEnabled ? key.capsText : key.text),
          style: textStyle,
        )),
      ),
    ));
  }

  /// Creates default UI element for keyboard Action Key.
  Widget _keyboardDefaultActionKey(VirtualKeyboardKey key) {
    // Holds the action key widget.
    Widget actionKey;

    // Switch the action type to build action Key widget.
    switch (key.action) {
      case VirtualKeyboardKeyAction.Backspace:
        actionKey = GestureDetector(
            onLongPress: () {
              longPress = true;
              // Start sending backspace key events while longPress is true
              Timer.periodic(
                  Duration(milliseconds: _virtualKeyboardBackspaceEventPerioud),
                  (timer) {
                if (longPress) {
                  onKeyPress(key);
                } else {
                  // Cancel timer.
                  timer.cancel();
                }
              });
            },
            onLongPressUp: () {
              // Cancel event loop
              longPress = false;
            },
            child: Container(
              height: double.infinity,
              width: double.infinity,
              child: Icon(
                Icons.backspace,
                color: textColor,
              ),
            ));
        break;
      case VirtualKeyboardKeyAction.Shift:
        actionKey = Icon(Icons.arrow_upward, color: textColor);
        break;
      case VirtualKeyboardKeyAction.Space:
        actionKey = actionKey = Icon(Icons.space_bar, color: textColor);
        break;
      case VirtualKeyboardKeyAction.Return:
        actionKey = Icon(
          Icons.keyboard_return,
          color: textColor,
        );
        break;
    }

    return Expanded(
      child: InkWell(
        canRequestFocus: false,
        onTap: () {
          if (key.action == VirtualKeyboardKeyAction.Shift) {
            if (!alwaysCaps) {
              setState(() {
                isShiftEnabled = !isShiftEnabled;
              });
            }
          }

          _handleKeyPress(key);
        },
        child: Container(
          alignment: Alignment.center,
          height: height / _keyRows.length,
          child: actionKey,
        ),
      ),
    );
  }
}
