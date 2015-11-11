# JWT Auth for Nginx

**nginx-jwt** is a [Lua](http://www.lua.org/) script for the [Nginx](http://nginx.org/) server (running the [HttpLuaModule](http://wiki.nginx.org/HttpLuaModule)) that will allow you to use Nginx as a reverse proxy in front of your existing set of HTTP services and secure them (authentication/authorization) using a trusted [JSON Web Token (JWT)](http://jwt.io/) in the `Authorization` request header, having to make little or no changes to the backing services themselves.

## Contents

- [Key Features](#key-features)
- [Install](#install)
- [Configuration](#configuration)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Tests](#tests)
- [Packaging](#packaging)
- [Issue Reporting](#issue-reporting)
- [Contributors](#contributors)
- [License](#license)

## Key Features

* Secure an existing HTTP service (ex: REST API) using Nginx reverse-proxy and this script
* Authenticate an HTTP request with the verified identity contained with in a JWT
* Optionally, authorize the same request using helper functions for asserting required JWT claims

## Install

> **IMPORTANT**: **nginx-jwt** is a Lua script that is designed to run on Nginx servers that have the [HttpLuaModule](http://wiki.nginx.org/HttpLuaModule) installed. But ultimately its dependencies require components available in the [OpenResty](http://openresty.org/) distribution of Nginx. Therefore, it is recommended that you use **OpenResty** as your Nginx server, and these instructions make that assumption.

Install steps:

1. Download the latest archive package from [releases](https://github.com/auth0/nginx-jwt/releases).
1. Extract the archive and deploy its contents to a directory on your Nginx server.
1. Specify this directory's path using ngx_lua's [lua_package_path](https://github.com/openresty/lua-nginx-module#lua_package_path) directive:  
    ```lua
    # nginx.conf:

    http {
        lua_package_path "/path/to/lua/scripts;;";
        ...
    }
    ```

## Configuration

> At the moment, `nginx-jwt` only supports symmetric keys (`alg` = `hs256`), which is why you need to configure your server with the shared JWT secret below.

1. Export the `JWT_SECRET` environment variable on the Nginx host, setting it equal to your JWT secret.  Then expose it to Nginx server:  
    ```lua
    # nginx.conf:

    env JWT_SECRET;
    ```
1. If your JWT secret is Base64 (URL-safe) encoded, export the `JWT_SECRET_IS_BASE64_ENCODED` environment variable on the Nginx host, setting it equal to `true`.  Then expose it to Nginx server:  
    ```lua
    # nginx.conf:

    env JWT_SECRET_IS_BASE64_ENCODED;
    ```

## Usage

Now we can start using the script in reverse-proxy scenarios to secure our backing service.  This is done by using the [access_by_lua](https://github.com/openresty/lua-nginx-module#access_by_lua) directive to call the `nginx-jwt` script's [`auth()`](#auth) function before executing any [proxy_* directives](http://nginx.org/en/docs/http/ngx_http_proxy_module.html):

```lua
# nginx.conf:

server {
    location /secure_this {
        access_by_lua '
            local jwt = require("nginx-jwt")
            jwt.auth()
        ';

        proxy_pass http://my-backend.com$uri;
    }
}
```

If you attempt to cURL the above `/secure_this` endpoint, you're going to get a `401` response from Nginx since it requires a valid JWT to be passed:

```bash
curl -i http://your-nginx-server/secure_this
```

```
HTTP/1.1 401 Unauthorized
Server: openresty/1.7.7.1
Date: Sun, 03 May 2015 18:05:00 GMT
Content-Type: text/html
Content-Length: 200
Connection: keep-alive

<html>
<head><title>401 Authorization Required</title></head>
<body bgcolor="white">
<center><h1>401 Authorization Required</h1></center>
<hr><center>openresty/1.7.7.1</center>
</body>
</html>
```

To create a valid JWT, we've included a handy tool that will generate one given a payload and a secret.  The payload must be in JSON format and at a minimum should contain a `sub` (subject) element.  The following command will generate a JWT with an arbitrary payload and the specific secret used by the proxy:

```bash
test/sign '{"sub": "flynn"}' 'My JWT secret'
```

```
Payload: { sub: 'flynn' }
Secret: JWTs are the best!
Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJwZXRlIiwiaWF0IjoxNDMwNjc3NjYzfQ.Zt4qnQyljbqLvAN7BQSuu14z5PjKcPpZZY85hDFVN3E
```

You can then use the above `Token` (the JWT) and call the Nginx server's `/secure_this` endpoint again:

```bash
curl -i http://your-nginx-server/secure_this -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJwZXRlIiwiaWF0IjoxNDMwNjc3NjYzfQ.Zt4qnQyljbqLvAN7BQSuu14z5PjKcPpZZY85hDFVN3E'
```

```
HTTP/1.1 200 OK
Server: openresty/1.7.7.1
Date: Sun, 03 May 2015 18:34:18 GMT
Content-Type: text/plain
Content-Length: 47
Connection: keep-alive
X-Auth-UserId: flynn
X-Powered-By: Express
ETag: W/"2f-8fc49de2"

The reverse-proxied response!
```

In this case the Nginx server has authorized the caller and performed a reverse proxy call to the backing service's endpoint.  Notice too that the **nginx-jwt** script has tacked on an extra response header called `X-Auth-UserId` that contains the value passed in the JWT payload's subject.  This is just for convenience, but it does help verify that the server does indeed know who you are.

The `jwt.auth()` function used above can actually do a lot more. See the [API Reference](#api-reference) section for more details.

## API Reference

### auth

Syntax: `auth([claim_specs])`

Authenticates the current request, requiring a JWT bearer token in the `Authorization` request header.  Verification uses the value set in the `JWT_SECRET` (and optionally `JWT_SECRET_IS_BASE64_ENCODED`) environment variables.

If authentication succeeds, then by default the current request is authorized by virtue of a valid user identity.  More specific authorization can be accomplished via the optional `claim_specs` parameter.  If provided, it must be a Lua [Table](http://www.lua.org/pil/2.5.html) where each key is the name of a desired claim and each value is a [pattern](http://www.lua.org/pil/20.2.html) that can be used to test the actual value of the claim.  If your claim value is more complex that what a pattern can handle, you can pass an anonymous function instead that has the signature `function (val)` and returns a truthy value (or just `true`) if `val` is a match.  You can also use the [`table_contains`](#table_contains) helper function to easily check for an existing value in an array table.

For example if we wanted to ensure that the JWT had an `aud` (Audience) claim value that started with `foo:` and a `roles` claim that contained a `marketing` role, then the `claim_specs` parameter might look like this:

```lua
# nginx.conf:

server {
    location /secure {
        access_by_lua '
            local jwt = require("nginx-jwt")
            jwt.auth({
                aud="^foo:",
                role=function (val) return jwt.table_contains(val, "marketing") end
            })
        ';

        proxy_pass http://my-backend.com$uri;
    }
}
```
and if our JWT's payload of claims looked something like this, the above `auth()` call would succeed:

```json
{
    "aud": "foo:user",
    "roles": [ "sales", "marketing" ]
}
```

**NOTE:** the **auth** function should be called within the [access_by_lua](https://github.com/openresty/lua-nginx-module#access_by_lua) or [access_by_lua_file](https://github.com/openresty/lua-nginx-module#access_by_lua_file) directive so that it can occur before the Nginx **content** [phase](http://wiki.nginx.org/Phases).

### table_contains

Syntax: `table_contains(table, item)`

A helper function that checks to see if `table` (a Lua [Table](http://www.lua.org/pil/2.5.html)) contains the specified `item`.  If it does, the function returns `true`; otherwise `false`.  This is particularly helpful for checking for a value in an array:

```lua
array = { "foo", "bar" }
table_contains(array, "foo") --> true
```

## Tests

The best way to develop and test the **nginx-jwt** script is to run it in a virtualized development environment.  This allows you to run Ngnix separate from your host machine (i.e. your Mac) in a controlled execution environment.  It also allows you to easily test the script with any combination of Nginx proxy host configurations and backing services that Nginx will reverse proxy to.

This repo contains everything you need to do just that.  It's set up to run Nginx as well as a simple backend server in individual [Docker](http://www.docker.com) containers.

### Prerequisites

#### Mac OS

1. [Docker Toolbox](https://www.docker.com/toolbox)
1. [Node.js](https://nodejs.org/)

> **IMPORTANT**: The test scripts expect your **Docker Toolbox** `docker-machine` VM name to be `default`

#### Ubuntu

1. [Docker](https://docs.docker.com/installation/ubuntulinux/)
1. [Node.js](https://nodejs.org/)

Besides being able to install Docker and run Docker directly in the host OS, the other different between Ubuntu (and more specifically Linux) and Mac OS is that all Docker commands need to be called using `sudo`. In the examples that follow, a helper script called `build` is used to perform all Docker commands and should therefore be prefixed with `sudo`, like this:

```bash
sudo ./build run
```

#### Ubuntu on MacOS (via Vagrant)

If your host OS is Mac OS but you'd like to test that the build scripts run on Ubuntu, you can use the provided Vagrant scripts to spin up an Ubuntu VM that has all the necessary tools installed.

First, if you haven't already, install **Vagrant** either by [installing the package](http://www.vagrantup.com/downloads.html) or using [Homebrew](http://sourabhbajaj.com/mac-setup/Vagrant/README.html).

Then in the repo directory, start the VM:

```bash
vagrant up
```

And then SSH into it:

```bash
vagrant ssh
```

Once in, you'll need to use git to clone this repo and `cd` into the project:

```bash
git clone THIS_REPO_URL
cd nginx-jwt
```

All other tools should be installed. And like with the [Ubuntu](#ubuntu) host OS, you'll need to prefix all calls to the `build` script with `sudo`, like this:

```bash
sudo ./build run
```

### Build and run the default containers

If you just want to see the **nginx-jwt** script in action, you can run the [`backend`](hosts/backend) container and the [`default`](hosts/proxy/default) proxy (Nginx) container:

```bash
./build run
```

> **NOTE**: On the first run, the above script may take several minutes to download and build all the base Docker images, so go grab a fresh cup of coffee.  Successive runs are much faster.

You can then run cURL commands against the endpoints exposed by the backend through Nginx.  The root URL of the proxy is reported back by the script when it is finished.  It will look something like this:

```
...
Proxy:
curl http://192.168.59.103
```

Notice the proxy container (which is running in the Docker Machine VM) is listening on port 80.  The actual backend container is not directly accessible via the VM.  All calls are configured to reverse-proxy through the Nginx host and the connection between the two is done via [docker container linking](https://docs.docker.com/userguide/dockerlinks/).

If you issue the above cURL command, you'll hit the [proxy's root (`/`) endpoint](hosts/proxy/default/nginx/conf/nginx.conf#L14), which simply reverse-proxies to the [non-secure backend endpoint](hosts/backend/server.js#L7), which doesn't require any authentication:

```bash
curl -i http://192.168.59.103
```

```
HTTP/1.1 200 OK
Server: openresty/1.7.7.1
Date: Sun, 03 May 2015 18:05:10 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 16
Connection: keep-alive
X-Powered-By: Express
ETag: W/"10-574c3064"

Backend API root
```

However, if you attempt to cURL the [proxy's `/secure` endpoint](hosts/proxy/default/nginx/conf/nginx.conf#L18), you're going to get a `401` response from Nginx since it requires a valid JWT:

```bash
curl -i http://192.168.59.103/secure
```

```
HTTP/1.1 401 Unauthorized
Server: openresty/1.7.7.1
Date: Sun, 03 May 2015 18:05:00 GMT
Content-Type: text/html
Content-Length: 200
Connection: keep-alive

<html>
<head><title>401 Authorization Required</title></head>
<body bgcolor="white">
<center><h1>401 Authorization Required</h1></center>
<hr><center>openresty/1.7.7.1</center>
</body>
</html>
```

Just like we showed in the [Usage](#usage) section, we can use the included `sign` tool to generate a JWT and call the Nginx proxy again, this time with a `200` response:

```bash
test/sign '{"sub": "flynn"}' 'JWTs are the best!'
```

```
Payload: { sub: 'flynn' }
Secret: JWTs are the best!
Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJwZXRlIiwiaWF0IjoxNDMwNjc3NjYzfQ.Zt4qnQyljbqLvAN7BQSuu14z5PjKcPpZZY85hDFVN3E
```

```bash
curl -i http://192.168.59.103/secure -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJwZXRlIiwiaWF0IjoxNDMwNjc3NjYzfQ.Zt4qnQyljbqLvAN7BQSuu14z5PjKcPpZZY85hDFVN3E'
```

```
HTTP/1.1 200 OK
Server: openresty/1.7.7.1
Date: Sun, 03 May 2015 18:34:18 GMT
Content-Type: application/json; charset=utf-8
Content-Length: 47
Connection: keep-alive
X-Auth-UserId: flynn
X-Powered-By: Express
ETag: W/"2f-8fc49de2"

{"message":"This endpoint needs to be secure."}
```

The proxy exposes other endpoints, which have different JWT requirements.  To see them all, take a look at the default proxy's [`nginx.conf`](hosts/proxy/default/nginx/conf/nginx.conf) file.

If you want to run the script with one of the [other proxy containers](hosts/proxy), simply pass the name of the desired container.  Example:

```bash
./build run base64-secret
```

### Build the containers and run integration tests

This script is similar to `run` except it executes all the [integration tests](test/test_integration.js), which end up building and running additional proxy containers to simulate different scenarios.

```bash
./build tests
```

Use this script while developing new features.

### Clean everything up

If you need to simply stop/delete all running Docker containers and remove their associated images, use this command:

```bash
./build clean
```

### Updating dependencies

It's always nice to keep dependencies up to date. This library (and the tools used to test it) has three sources of dependencies that should be maintained: Lua dependencies, test script Node.js dependencies, and updates to the proxy base Docker image.

#### Lua dependencies

These are the Lua scripts that [this library](nginx-jwt.lua) uses.  They are maintained in the [`build_deps.sh`](scripts/build_deps.sh) bash script.

Since these dependencies don't have any built-in versioning (like npm), we download a specific GitHub commit instead. We also check that a previously downloaded script is current by examining its SHA-1 digest hash. All this is done via the included  `load_dependency` bash function.

If a Lua dependency needs to be updated, find its associated `load_dependency` function call and update its GitHub `commit` and `sha1` parameter values. You can generate the required SHA-1 digest of a new script file using this command:

```bash
openssh sha1 NEW_SCRIPT
```

To add a new dependency simply add a new `load_dependency` command to the script.

#### Test script Node.js dependencies

All Node.js dependencies (npm packages) for tests are maintained in this [`package.json`](test/package.json) file and should be updated as needed using the `npm` command.

#### Proxy base Docker image

The proxy base Docker image may need to be updated periodically, usually to just rev the version of OpenResty that its using. This can be done by modifying the image's [`Dockerfile`](hosts/proxy/Dockerfile). Any change to this file will automatically result in new image builds when the `build` script is run.

## Packaging

When a new version of the script needs to be released, the following should be done:

> **NOTE**: These steps can only performed by GitHub users with commit access to the project.

1. Increment the [Semver](http://semver.org/) version in the [`version.txt`](version.txt) file as needed.
1. Create a new git tag with the same version value (prefiexed with `v`):

  ```bash
  git tag v$(cat version.txt)
  ```

1. Push the tag to GitHub.
1. Create a new GitHub release in [releases](https://github.com/auth0/nginx-jwt/releases) that's associated with the above tag.
1. Run the following command to create a release package archive and then upload it to the release created above:  

  ```bash
  ./build package
  ```

## Issue Reporting

If you have found a bug or if you have a feature request, please report them at this repository issues section. Please do not report security vulnerabilities on the public GitHub issue tracker. The [Responsible Disclosure Program](https://auth0.com/whitehat) details the procedure for disclosing security issues.

## Contributors

Check them out [here](https://github.com/auth0/nginx-jwt/graphs/contributors).

## License

This project is licensed under the MIT license. See the [LICENSE](LICENSE) file for more info.
