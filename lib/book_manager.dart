import 'package:mysql1/mysql1.dart';
import 'package:ondemand_messenger_backend/utility.dart';

class BookManager {
  final List<Book> books;
  final List<Number> numbers;
  final MySqlConnection _conn;

  BookManager._(this._conn, this.books, this.numbers);

  static Future<BookManager> createBookManager(MySqlConnection conn) async {
    var queriedBooks = await conn.query('SELECT * FROM books;');
    var books = queriedBooks.map((row) => Book.fromRow(row)).toList();

    var queriedNumbers = await conn.query('SELECT * FROM numbers;');
    var numbers = queriedNumbers.map((row) => Number.fromRow(row)).toList();

    print('Loaded ${books.length} books and ${numbers.length} numbers');

    return BookManager._(conn, books, numbers);
  }

  List<Number> getNumbers(Book book) =>
      numbers.where((element) => element.bookId == book.bookId).toList();

  Future<Number> addNumber(String name, String number, Book book) async {
    await _conn.query('INSERT INTO numbers (name, number, book_id) VALUES(?, ?, ?)', [name, number, book.bookId]);
    var id = await getLastId(_conn);
    var addedNumber = Number(id, name, number, book.bookId);
    print('Adding number #$id');
    numbers.add(addedNumber);
    return addedNumber;
  }

  Future<void> removeNumber(int numberId) async {
    await _conn.query('DELETE FROM numbers WHERE number_id = ?;', [numberId]);
    numbers.removeWhere((element) => element.numberId == numberId);
  }

  Future<Book> addBook(String name, String password) async {
    await _conn.query('INSERT INTO books (name, password) VALUES(?, ?)', [name, password]);
    var id = await getLastId(_conn);
    var book = Book(id, name, password);
    print('Adding book id #$id');
    books.add(book);
    return book;
  }

  bool containsBook(String name) =>
      books.any((book) => book.name == name);

  Book getBook(String name, String password) {
    var book = books.firstWhere((book) => book.name == name, orElse: () => null);
    if (book?.password == password ?? false) {
      return book;
    }
    return null;
  }
}

class Number {
  final int numberId;
  final String name;
  final String number;
  final int bookId;

  Number(this.numberId, this.name, this.number, this.bookId);

  Number.fromRow(Row row)
      : numberId = row['number_id'],
        name = row['name'],
        number = row['number'],
        bookId = row['book_id'];

  /// Gets the JSON representation without the [bookId] field.
  Map<String, dynamic> toJson() => {
    'numberId': numberId,
    'name': name,
    'number': number,
  };

  @override
  String toString() {
    return 'Number{numberId: $numberId, name: $name, number: $number, bookId: $bookId}';
  }
}

class Book {
  final int bookId;
  final String name;
  final String password;

  Book(this.bookId, this.name, this.password);

  Book.fromRow(Row row)
      : bookId = row['book_id'],
        name = row['name'],
        password = row['password'];

  @override
  String toString() {
    return 'Book{bookId: $bookId, name: $name, password: $password}';
  }
}
