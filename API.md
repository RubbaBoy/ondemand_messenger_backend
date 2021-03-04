# API

To use the API yourself, you need an API key. Currently I'm unsure of a great way to disperse API keys, so you can request one by contacting me on Discord at `RubbaBoy#2832` or emailing me at [adam@yarr.is](mailto:adam@yarr.is), or make an issue suggesting a better way. Right now, when you make a request, a 10-minute API key is stored in your cookies which you may use.

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

### `POST` /requestToken

Requests a book token with given a book username/password.

### `POST` /requestCaptchaOverride

**RESTRICTED** Requests a token to override the reCaptcha present in the client website. Takes in a static password.

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

