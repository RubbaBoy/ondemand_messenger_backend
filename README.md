## OnDemand Messenger Backend

This program is an API to send arbitrary messages to any phone number using the Agilysys OnDemand service used by RIT.

To use my self-hosted version of this, the base URL is `https://ondemand.yarr.is/`

For example, sending an SMS of `Hello World!` to `+1 (123) 456-7890` would be the cURL command:

```bash
curl --request POST \
  --data '{"number":"11234567890","message":"Hello World!"}' \
  https://ondemand.yarr.is/sendSMS
```

To run this yourself, you must have chromedriver installed. Then, run:
```bash
chromedriver --port=4444 --url-base=wd/hub --verbose
dart bin/ondemand_token_grabber.dart
```

## Basic request overview

### `POST` /sendSMS

#### Request:

```json
{
    "number": "11234567890",
    "message": "Any text"
}
```

The `number` must be a `11-digit phone number. `message` may be anything your heart desires (granted your heart desires nothing more than 2^12 characters).

#### Responses:

`200`

```json
{"id": "uuid"}
```

The UUID given by OnDemand when a text was successfully sent.

`400`

```json
{"error": "message yelling at you"}
```

When input parameters are incorrect

### `GET` /token

#### Response:

```json
{
    "token": "..."
}
```

The `token` is the authentication bearer token used by the OnDemand service.