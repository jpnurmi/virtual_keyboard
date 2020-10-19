part of virtual_keyboard;

class VirtualKeyboardMessenger extends BinaryMessenger {
  final BinaryMessenger _messenger;
  final _filters = <String, MessageHandler>{};

  VirtualKeyboardMessenger([BinaryMessenger messenger])
      : _messenger =
            messenger ?? ServicesBinding.instance.defaultBinaryMessenger;

  void setMessageFilter(String channel, MessageHandler filter) {
    _filters[channel] = filter;
  }

  @override
  bool checkMessageHandler(String channel, handler) {
    return _messenger.checkMessageHandler(channel, handler);
  }

  @override
  void setMessageHandler(String channel, handler) {
    _messenger.setMessageHandler(channel, handler);
  }

  @override
  bool checkMockMessageHandler(String channel, handler) {
    return _messenger.checkMockMessageHandler(channel, handler);
  }

  @override
  void setMockMessageHandler(String channel, handler) {
    _messenger.setMockMessageHandler(channel, handler);
  }

  @override
  Future<void> handlePlatformMessage(String channel, ByteData data, callback) {
    return _messenger.handlePlatformMessage(channel, data, callback);
  }

  @override
  Future<ByteData> send(String channel, ByteData message) {
    final filter = _filters[channel];
    if (filter != null) {
      return filter.call(message);
    }
    return _messenger.send(channel, message);
  }
}
