# JWT Reverse Proxy Module for Nginx

**nginx-jwt** is an authentication/authorization module for the [Nginx](http://nginx.org/) server.  It will allow you to use Nginx as a reverse proxy in front of your existing set of HTTP services and secure them using a trusted [JSON Web Token (JWT)](http://jwt.io/) in the `Authorization` request header, making little or no changes to the backing services themselves.

## Table of Contents

* [Installation](#installation)
* [API](#api)
* [Overview](#overview)
* [Contributing](#contributing)

## Installation

It is recommended to use the latest [ngx_openresty bundle](http://openresty.org/) directly as this module (and its dependencies) depend on components that are installed by openresty.

Install steps:

1. Deploy the [`nginx-jwt.lua`](nginx-jwt.lua) script to your Nginx server.
1. Specify this library's path in ngx_lua's [lua_package_path](https://github.com/openresty/lua-nginx-module#lua_package_path) directive:  
    ```lua
    # nginx.conf:

    http {
        lua_package_path "/path/to/nginx-jwt.lua;;";
        ...
    }
    ```
1. Install the [lua-resty-jwt](https://github.com/SkyLothar/lua-resty-jwt#installation) dependency on your Nginx server.
1. Install the [lua-resty-hmac](https://github.com/jkeys089/lua-resty-hmac#installation) dependency on your Nginx server.
1. Export the `JWT_SECRET` environment variable on the Nginx host, setting it equal to your JWT secret.  Then expose it to Nginx server:  
    ```lua
    # nginx.conf:

    env JWT_SECRET;
    ```
1. Use the [access_by_lua](https://github.com/openresty/lua-nginx-module#access_by_lua) directive to call the `nginx-jwt.auth` function before executing any [proxy_* directives](http://nginx.org/en/docs/http/ngx_http_proxy_module.html):  
    ```lua
    # nginx.conf:

    server {
        location /secure {
            access_by_lua '
                local jwt = require("nginx-jwt")
                jwt.auth()
            ';

            proxy_pass http://my-backend.com$uri;
        }
    }
    ```


## API

### auth

`syntax: jwt.auth()`

Authenticates the current request, requiring a JWT bearer token in the `Authorization` request header.  Verification uses the value set in the `JWT_SECRET` environment variable.

This function should be called within the [access_by_lua](https://github.com/openresty/lua-nginx-module#access_by_lua) or [access_by_lua_file](https://github.com/openresty/lua-nginx-module#access_by_lua_file) directive so that it can occur before the Nginx **content** [phase](http://wiki.nginx.org/Phases).

## Overview

Building modern apps is not easy.  Besides delivering the core business need, developers have to worry about things like: user experience, choosing the best platform (native mobile vs. mobile web vs. hybrid), flexible design, and lets not forget about security.  And in today's world of test and learn, all of this has become accelerated.

### Challenges with an Existing Backend

And then there's the backend.  Most useful apps are transacting important data or delivering useful content.  And its not uncommon that at least a portion of that data is being sourced from an existing or legacy system.  In this scenario, one of the biggest challenges is security, and more specifically: *managing user identities*.  If your backend provides content that users need to pay for, you need a way to identify that user and ensure they are authorized to consume the content.  Maybe you need to store user information in your legacy CRM system and would like users to be able to log in with their Google or Facebook account.

As you can imagine presenting identity management requirements like this to your existing backend system can result in several challenges:

* Your backend may not have been designed to easily incorporate a new security layer and making this change could potentially destabilize it for other existing consuming apps and services
* Your backend codebase is maintained by another team and they told you it would take 6 months to make this kind of change, given their other priorities
* Your backend is a 3rd-party service and has an even more inflexible infrastructure

### The Nginx Solution

Situations like the above are common, which is why many people turn to a product like **Nginx** as a [reverse proxy](http://en.wikipedia.org/wiki/Reverse_proxy) service, placing it in front of the various backend services required by their app.  Nginx allows a host of reverse proxy capabilities, such as caching, adding SSL, and redirecting.  Now with the **nginx-jwt** module, you can easily enforce token-based authentication and authorization, simply by having your client app obtain a JWT that the module trusts, which identifies a user (authentication) and optionally their security rights (authorization).

> For more information on how JWT's work take a look at the [IEFT draft spec](http://tools.ietf.org/html/draft-ietf-oauth-json-web-token) or play around with them on [jwt.io](http://jwt.io).


### The Client Side

So how does all this work?  The first step is to enable your client app so that it can obtain a valid JWT on behalf of the user.  The generation of this token has to be done external to the app itself by an authentication service that has the ability to identify a user (usually using a login form) and then geneate and *sign* a JWT with the same secret that your **nginx-jwt** module will use to *verify* that JWT.

> An example of an authentication service that can generate trusted JWT's is [Auth0](http://auth0.com).  While they can host your app's user database, they also allow your users to authenticate against a variety of social providers like Google and Facebook or even against your enterprise's Active Directory or LDAP service.  They also make it easy to integrate the login view into your app with a variety of [UI widgets and client libraries]((https://auth0.com/docs).

Once the authentication service has been used by the app to login the user and obtain a valid JWT, the app is free to call the backend by passing the JWT as a bearer token via the `Authorization` request header:

```
GET https://my-backend.com/secured/resource
Authorization Bearer YOUR_USERS_JWT_HERE
```

### The Server Side

The Nginx server, with the help of the **nginx-jwt** module can now sit in front of your backend services (as a reverse proxy) and through configuration can secure whatever endpoints you desire.  In the example above, the `my-backend.com` host actually resolves to your Nginx server, not your actual backend.  If the `/secured/resource` endpoint was configured to be secured with the module, it would enforce that a valid JWT was sent with each request.  Without it, the module will return an HTTP `401 Unauthorized`.  With it, the request will continue to be proxied to the actual backend endpoint.

### Authorization

In the above scenario, the user has been authenticated (identified) and they are then authorized to access the `/secured/resource` endpoint simply because they are a valid user.  However, often times your endpoint requires that a user also be in a specific security role or have certain security rights.  The **nginx-jwt** module can be configured to enforce this by requiring the existence of a specific claim.  Claims are just data in the JWT payload and since the JWT is created and signed by the authentication service, they can be trusted.

## Contributing

The best way to develop and test the **nginx-jwt** module is to run it in a virtualized development environment.  This allows you to run Ngnix separate from your host machine (i.e. your Mac) in a controlled execution environment.  It also allows you to easily test the module with any number of backing services that Nginx will reverse proxy to.

This repo contains everything you need to do just that.  It's set up to run Nginx as well as a simple backend server in individual [Docker](http://www.docker.com) containers.

### Prerequisites (Mac OS)

1. [boot2docker](http://boot2docker.io/)
1. [Node.js](https://nodejs.org/)

### Build the containers and run integration tests

  ```bash
  ./run.sh
  ```

  **NOTE**: On the first run the script may take a few minutes to download all the base Docker images, so go grab a fresh cup of coffee.  Successive runs are much faster.
