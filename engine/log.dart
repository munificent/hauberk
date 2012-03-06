/// The message log.
class Log {
  static final MAX_MESSAGES = 8;

  final Queue<Message> messages;

  Log() : messages = new Queue<Message>();

  void add(String message) {
    // See if it's a repeat of the last message.
    if (messages.length > 0) {
      final last = messages.last();
      if (last.text == message) {
        // It is, so just repeat the count.
        last.count++;
        return;
      }
    }

    // It's a new message.
    messages.add(new Message(message));
    if (messages.length > MAX_MESSAGES) messages.removeFirst();
  }
}

/// A single log entry.
class Message {
  final String text;

  /// The number of times this message has been repeated.
  int count = 1;

  Message(this.text);
}