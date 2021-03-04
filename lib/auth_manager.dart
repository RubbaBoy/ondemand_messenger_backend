import 'package:ondemand_messenger_backend/book_manager.dart';
import 'package:ondemand_messenger_backend/token_utils.dart';

class AuthManager {

  final BookManager _bookManager;
  final List<BookAuth> authedBooks = [];

  AuthManager(this._bookManager);

  /// Generates and stores a token for either a given [Book], or by both the
  /// book's [username] and [password].
  Token getToken({Book book, String username, String password}) {
    book ??= _bookManager.getBook(username, password);
    if (book == null) {
      return null;
    }

    var bookAuth = authedBooks.firstWhere((e) => e.book == book, orElse: () {
      var created = BookAuth._(book);
      authedBooks.add(created);
      return created;
    });

    var token = TokenUtils.generateToken(Duration(minutes: 10));
    bookAuth.tokens.add(token.token);
    return token;
  }

  /// Gets the [Book] object for the given [token]. If the token is invalid or
  /// expired, null is returned.
  Book getBook(String token) {
    if (!TokenUtils.isValid(token)) {
      return null;
    }

    var authBook = authedBooks.firstWhere((e) => e.isValid(token), orElse: () => null);
    if (TokenUtils.isExpired(token)) {
      authBook.tokens.remove(token);
      return null;
    }

    return authBook.book;
  }

}

class BookAuth {
  final Book book;
  final List<String> tokens = [];

  BookAuth._(this.book);

  /// Returns if the given token is for the current book. Does not check for
  /// token validity.
  bool isValid(String token) => token.contains(token);
}
