import 'package:ondemand_messenger_backend/book_manager.dart';
import 'package:ondemand_messenger_backend/token_utils.dart';

/// Handles authentication for books
class BookAuthManager {

  final BookManager _bookManager;
  final List<BookAuth> authedBooks = [];

  BookAuthManager(this._bookManager);

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

    var token = TokenUtils.generateToken(Duration(days: 1));
    bookAuth.tokens.add(token.token);
    return token;
  }

  /// Gets the [BookResult] object for the given [token].
  BookResult getBook(String token) {
    if (!TokenUtils.isValid(token)) {
      return BookResult.Invalid;
    }

    var authBook = authedBooks.firstWhere((e) => e.isValid(token), orElse: () => null);
    if (TokenUtils.isExpired(token)) {
      authBook?.tokens?.remove(token);
      return BookResult.Expired;
    }

    if (authBook == null) {
      return BookResult.Invalid;
    }

    return BookResult(book: authBook.book);
  }

}

enum Result {
  Invalid, Expired, Okay
}

class BookResult {
  static final Invalid = BookResult(result: Result.Invalid);
  static final Expired = BookResult(result: Result.Expired);

  final Result result;
  final Book book;

  BookResult({this.result = Result.Okay, this.book});
}

class BookAuth {
  final Book book;
  final List<String> tokens = [];

  BookAuth._(this.book);

  /// Returns if the given token is for the current book. Does not check for
  /// token validity.
  bool isValid(String token) => token.contains(token);
}
