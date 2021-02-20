## OnDemand Messenger Backend

This program is an API to send arbitrary messages to any phone number using the Agilysys OnDemand service used by RIT.

To use my self-hosted version of this, the base URL is `https://ondemand.yarr.is/` There is also a user-friendly frontend backed by this API available at https://yarr.is/ondemand

For example, sending an SMS of `Hello World!` to `+1 (123) 456-7890` would be the cURL command (the formatting of the phone number is not necessary):

```bash
curl --request POST \
  --data '{"number":"(123) 456-7890","message":"Hello World!"}' \
  https://ondemand.yarr.is/sendSMS
```

For a detailed overview of the API, please see the [API docs](/API.md).

### Features

- A ratelimitless way of sending anonymous texts
- Extremely simple API
- Address books with credentials

## Running It Yourself

If you don't want to use my self-hosted copy, getting it running yourself is easy.

First, install [docker](https://www.docker.com/) and [docker compose](https://docs.docker.com/compose/install/). Then, save [docker-compose.yml](/blob/master/docker-compose.yml) to your local machine. Lastly, run

```bash
sudo docker-compose up
```

The port by default is `8090`, which may be changed in the compose file.

