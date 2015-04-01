# Auth0 Module for Nginx

**nginx-auth0** is an authentication/authorization module for the [Nginx](http://nginx.org/) server.  It will allow you to use Nginx as a reverse proxy in front of your existing set of backend services and secure them using Auth0 without having to make any changes to the services themselves.

## Overview

[Auth0](http://www.auth0.com) provides an easy way for apps and APIs to incorporate user identities.  Integrating it into your mobile or web app is easy as Auth0 provides [libraries and guides](https://auth0.com/docs) for many of the most popular frontned frameworks.

Auth0 also makes it easy to make the [necessary changes to your *backend*](https://auth0.com/docs/quickstart/webapp).  However, often times its not as easy.  Some of the barriers may include:

* Adding in a new security layer to your existing backend may be too difficult, depending on how well it's been architected
* Your backend codebase is maintained by another team and they told you it would take 6 months to integrate Auth0, given their other priorities
* Introducing a new security layer to your backend may be too disruptive and could potentially destabilize it for other existing apps
* Your backend is a 3rd party service and it doesn't support token-based authentication

Scenarios like the above are common, which is why many people turn to **Nginx** as a [reverse proxy](http://en.wikipedia.org/wiki/Reverse_proxy) service, placing it in front of the various backend endpoints required by their app.  Nginx allows a host of reverse proxy capabilities, including caching, doctoring responses, and redirecting.  Now with the **nginx-auth0** module, you can easily enforce Auth0 authentication and authorization, simply by configuring it with your Auth0 app's information.
