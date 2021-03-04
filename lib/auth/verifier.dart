import 'dart:async';

mixin Verifier {

  /// Checks the validity of a token
  FutureOr<bool> isValid(String token);
}