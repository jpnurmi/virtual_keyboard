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

  /// Whether the keyboard is active
  final bool active;

  VirtualKeyboard(
      {Key key,
      this.type,
      this.onKeyPress,
      this.builder,
      this.height = _virtualKeyboardDefaultHeight,
      this.textColor = Colors.black,
      this.backgroundColor = Colors.grey,
      this.fontSize = 14,
      this.alwaysCaps = false,
      this.active = true})
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

  TextInputClient inputClient;
  TextInputConfiguration inputConfiguration;

  // Handles underlying text input state, using a simple ASCII model.
  final model = VirtualKeyboardModel();

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
    register();
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

    register();
  }

  @override
  void dispose() {
    TextInput.registerConnectionFactory(null);
    super.dispose();
  }

  void register() {
    if (widget.active) {
      TextInput.registerConnectionFactory((client) {
        inputClient = client;
        return _VirtualKeyboardConnection(client, this);
      });
    } else {
      TextInput.registerConnectionFactory(null);
      if (mounted) {
        hide();
        FocusManager.instance.primaryFocus?.unfocus();
      }
    }
  }

  void show() {
    setState(() => visible = true);
  }

  void hide() {
    setState(() => visible = false);
  }

  void setInputConfiguration(TextInputConfiguration configuration) {
    setState(() => inputConfiguration = configuration);
  }

  void setEditingState(TextEditingValue value) {
    String text = value.text;
    int selectionBase = value.selection.baseOffset;
    int selectionExtent = value.selection.extentOffset;
    // Flutter uses -1/-1 for invalid; translate that to 0/0 for the model.
    if (selectionBase == -1 && selectionExtent == -1) {
      selectionBase = selectionExtent = 0;
    }

    model.text = text;
    model.selection =
        TextSelection(baseOffset: selectionBase, extentOffset: selectionExtent);
  }

  @override
  Widget build(BuildContext context) {
    return SwipeGestureRecognizer(
      child: AnimatedContainer(
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
      ),
      onSwipeDown: hide,
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
            if (inputConfiguration.inputType == TextInputType.multiline) {
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
    final value =
        TextEditingValue(text: model.text, selection: model.selection);
    inputClient.updateEditingValue(value);
  }

  void _performAction() {
    inputClient.performAction(inputConfiguration.inputAction);
  }

  bool get _isNumeric {
    return type == VirtualKeyboardType.Numeric ||
        (type == null &&
            inputConfiguration != null &&
            (inputConfiguration.inputType == TextInputType.number ||
                inputConfiguration.inputType == TextInputType.phone));
  }

  /// Returns the rows for keyboard.
  List<Widget> _rows() {
    // Get the keyboard Rows
    List<List<VirtualKeyboardKey>> keyboardRows =
        _isNumeric ? _getKeyboardRowsNumeric() : _getKeyboardRows();

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
