part of virtual_keyboard;

class _VirtualKeyboardConnection extends TextInputConnection {
  final _VirtualKeyboardState vkb;
  _VirtualKeyboardConnection(TextInputClient client, this.vkb) : super(client);

  @override
  void show() {
    vkb.show();
  }

  @override
  void onAttach() {}

  @override
  void onDetach() {}

  @override
  void hide() {
    vkb.hide();
  }

  @override
  void setEditingState(TextEditingValue value) {
    vkb.setEditingState(value);
  }

  @override
  void setClient(TextInputConfiguration configuration) {
    vkb.setInputConfiguration(configuration);
  }

  @override
  void updateConfig(TextInputConfiguration configuration) {
    vkb.setInputConfiguration(configuration);
  }

  @override
  void clearClient() {
    vkb.setInputConfiguration(null);
  }

  @override
  void requestAutofill() {
    // TODO: implement requestAutofill
  }

  @override
  void setComposingRect(Rect rect) {
    // TODO: implement setComposingRect
  }

  @override
  void setEditableSizeAndTransform(Size editableBoxSize, Matrix4 transform) {
    // TODO: implement setEditableSizeAndTransform
  }

  @override
  void setStyle({
    String fontFamily,
    double fontSize,
    FontWeight fontWeight,
    TextDirection textDirection,
    TextAlign textAlign,
  }) {
    // TODO: implement setStyle
  }
}
