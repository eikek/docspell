+++
title = "Reverse Proxy"
weight = 50
+++

This contains examples for how to use docspell behind a reverse proxy.

For the examples below, assume the following:

- Docspell app is available at `192.168.1.11:7880`. If it is running
  on the same machine as the reverse proxy server, you can set
  `localhost:7880` instead.
- The external domain/hostname is `docspell.example.com`

## Configuring Docspell

These settings require a complement config part in the docspell
configuration file:

- First, if Docspell REST server is on a different machine, you need
  to change the `bind.address` setting to be either `0.0.0.0` or the
  ip address of the network interface that the reverse proxy server
  connects to.
  ``` conf
  docspell.server {
    # Where the server binds to.
    bind {
      address = "192.168.1.11"
      port = 7880
    }
  }
  ```
  Note that a value of `0.0.0.0` instead of `192.168.1.11` will bind
  the server to every network interface.
- Docspell needs to know the external url. The `base-url` setting
  must point to the external address. Using above values, it must be
  set to `https://docspell.example.com`.
  ``` conf
  docspell.server {
    # This is the base URL this application is deployed to. This is used
    # to create absolute URLs and to configure the cookie.
    base-url = "https://docspell.example.com"
   ...
  }
  ```

Note that this example assumes that the docspell-joex component is on
the same machine. This page is only related for exposing the REST
server and web application.

If you have examples for more servers, please let me know or add it to
this site.

## Nginx

This defines two servers: one listens for http traffic and redirects
to the https variant. Additionally it defines the let's encrypt
`.well-known` folder name.

The https server endpoint is configured with the let's encrypt
certificates and acts as a proxy for the application at
`192.168.1.11:7880`.

``` conf
server {
    listen 0.0.0.0:80 ;
    listen [::]:80 ;
    server_name docspell.example.com ;
    location /.well-known/acme-challenge {
        root /var/data/nginx/ACME-PUBLIC;
        auth_basic off;
    }
    location / {
        return 301 https://$host$request_uri;
    }
}
server {
    listen 0.0.0.0:443 ssl http2 ;
    listen [::]:443 ssl http2 ;
    server_name docspell.example.com ;
    location /.well-known/acme-challenge {
        root /var/data/nginx/ACME-PUBLIC;
        auth_basic off;
    }
    ssl_certificate /var/lib/acme/docspell.example.com/fullchain.pem;
    ssl_certificate_key /var/lib/acme/docspell.example.com/key.pem;
    ssl_trusted_certificate /var/lib/acme/docspell.example.com/full.pem;
    location / {
        proxy_pass http://192.168.1.11:7880;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
```
