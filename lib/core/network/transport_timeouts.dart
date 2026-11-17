/// A direct API request can wake the hosted backend. No health preflight or
/// automatic retry is needed. Response waiting stays bounded during cold starts.
abstract final class TransportTimeouts {
  static const connect = Duration(seconds: 30);
  static const receive = Duration(seconds: 90);
  static const send = Duration(seconds: 30);
  static const longReceive = Duration(seconds: 75);
  static const uploadSend = Duration(seconds: 60);
}
