import 'dart:async';

enum AssetsEventType {
  netWorthChanged,
  checklistUpdated,
}

class AssetsEvent {
  const AssetsEvent(this.type, {this.metadata = const {}});

  final AssetsEventType type;
  final Map<String, dynamic> metadata;
}

class AssetsEventBus {
  AssetsEventBus() : _controller = StreamController<AssetsEvent>.broadcast();

  final StreamController<AssetsEvent> _controller;

  Stream<AssetsEvent> get stream => _controller.stream;

  void emit(AssetsEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
