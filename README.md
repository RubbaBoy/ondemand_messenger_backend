## OnDemand Messenger Backend

This program is an API to send arbitrary messages to any phone number using the Agilysys OnDemand service used by RIT. For the frontend repo written in Dart using AngularDart, see [ondemand_messenger_web](RubbaBoy/ondemand_messenger_web).

To use my self-hosted version of this, the base URL is `https://ondemand.yarr.is/` There is also a user-friendly frontend backed by this API available at https://yarr.is/ondemand

For example, sending an SMS of `Hello World!` to `+1 (123) 456-7890` would be the cURL command (the formatting of the phone number is not necessary):

```bash
curl --request POST \
  --data '{"number":"(123) 456-7890","message":"Hello World!","captchaOverride":"api-key"}' \
  https://ondemand.yarr.is/sendSMS
```

For a detailed overview of the API, please see the [API docs](/API.md).

### Features

- A fast way of sending anonymous texts via onDemand
- Extremely simple API
- Address books with credentials
- Google reCaptcha support
- No logs (don't make me implement them...)

## Running It Yourself

If you don't want to use my self-hosted copy, getting it running yourself is easy.

First, install [docker](https://www.docker.com/) and [docker compose](https://docs.docker.com/compose/install/). Then, save [docker-compose.yml](/docker-compose.yml) to your local machine.

Go into the docker-comnpose.yml file and replace `override-here` with your secret token generating override password. Put in your secret server-side [Google reCaptcha v2](https://developers.google.com/recaptcha/docs/invisible) key in place for `captcha-secret-here`.

Lastly, run

```bash
sudo docker-compose up
```

The port by default is `8090`, which may be changed in the compose file.

