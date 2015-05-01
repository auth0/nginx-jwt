/* global describe, it, before */

'use strict';

var request = require('super-request');
var jwt = require('jsonwebtoken');

var baseUrl = 'http://' + process.env.HOST_IP;
var url, secret;

describe('proxy', function () {
    describe("configured with normal secret", function () {
        before(function () {
            url = baseUrl;
            secret = 'JWTs are the best!';
        });

        describe("GET /", function () {
            it("should return 200 with expected proxied response", function () {
                return request(url)
                    .get('/')
                    .expect(200, "Backend API root")
                    .end();
            });
        });

        describe("GET /secure", function () {
            it("should return 401 when passing no JWT", function () {
                return request(url)
                    .get('/secure')
                    .expect(401)
                    .end();
            });

            it("should return 401 when passing a bogus JWT", function () {
                return request(url)
                    .get('/secure')
                    .headers({'Authorization': 'Bearer not-a-valid-jwt'})
                    .expect(401)
                    .end();
            });

            it("should return a 200 with the expected response header when a valid JWT is passed", function () {
                var token = jwt.sign(
                    { sub: 'foo-user' },
                    secret
                );

                return request(url)
                    .get('/secure')
                    .headers({'Authorization': 'Bearer ' + token})
                    .expect(200)
                    .expect('Content-Type', /json/)
                    .expect({ message: 'This endpoint needs to be secure.' })
                    .expect('X-Auth-UserId', 'foo-user')
                    .end();
            });
        });
    });

    describe("configured with URL-safe base-64 encoded secret", function () {
        before(function () {
            url = baseUrl + ':81';
            secret = 'This secret is stored base-64 encoded on the proxy host';
        });

        describe("GET /secure", function () {
            it("should return a 200 with the expected response header when a valid JWT is passed", function () {
                var token = jwt.sign(
                    { sub: 'foo-user' },
                    secret
                );

                return request(url)
                    .get('/secure')
                    .headers({'Authorization': 'Bearer ' + token})
                    .expect(200)
                    .expect('Content-Type', /json/)
                    .expect({ message: 'This endpoint needs to be secure.' })
                    .expect('X-Auth-UserId', 'foo-user')
                    .end();
            });
        });
    });
});
