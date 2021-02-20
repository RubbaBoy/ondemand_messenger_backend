# API

All methods are POST (because I'm lazy and internally it's fucked). If anything has an error that occurs, it will return something like:

```json
{
    "error": "Some message here"
}
```

With a relevant response code.

### `POST` /sendSMS

#### Request:

```json
{
    "number": "1234567890",
    "message": "Any text"
}
```

The `number` must be a 10-digit phone number (or more if you include the country code). All non-numeric characters are stripped before processing. `message` may be anything your heart desires (granted your heart desires nothing more than 2^12 characters).

#### Response

```json
{"id": "uuid"}
```

The UUID given by OnDemand when a text was successfully sent.

### `POST` /token

#### Response:

```json
{
    "token": "..."
}
```

The `token` is the authentication bearer token used by the OnDemand service.

### `POST` /createBook

Creates an address book with credentials.

```json
{
    "name": "Book name",
    "password": "The password"
}
```

#### Response

```json
{
    "book": {
        "id": "1",
        "name": "Book name"
    }
}
```

### `POST` /getBook

Gets a book by credentials.

```json
{
    "name": "Book name",
    "password": "The password"
}
```

#### Response

```json
{
    "numbers": [
        {
            "numberId": "1",
            "name": "Person name",
            "number": "1234567890"
        }
    ]
}
```

The `numbers` object is an array of numbers from the book. The `numberId` is the identifier used for things like deleting, as names are not unique.

### `POST` /addNumber

Adds a phone number to the address book.

```json
{
    "name": "Book name",
    "password": "The password",
    "numberName": "Person name",
    "number": "1234567890"
}
```

#### Response

```json
{
    "number": {
        "numberId": "1",
        "name": "Person name",
        "number": "1234567890"
    }
}
```

Returns a number object in `number`.

### `POST` /removeNumber

```json
{
    "name": "Book name",
    "password": "The password",
    "numberId": "1"
}
```

#### Response

```json
{}
```

