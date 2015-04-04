/* global describe, it */

'use strict';

var request = require('super-request');
var jws = require('jws');

var baseUrl = 'http://' + process.env.HOST_IP;
var JWT_SECRET = 'g20id5X656tIYmbb3e4oIM4x1nI43947D87134uu5B';

describe('proxy endpoint', function () {
    describe("GET /", function () {
        it("should return 200 with expected proxied response", function () {
            return request(baseUrl)
                .get('/')
                .expect(200, "Backend API root")
                .end();
        });
    });

    describe("GET /secure", function () {
        it("should return 401 when passing no JWT", function () {
            return request(baseUrl)
                .get('/secure')
                .expect(401)
                .end();
        });

        it("should return 401 when passing a bogus JWT", function () {
            return request(baseUrl)
                .get('/secure')
                .headers({'Authorization': 'Bearer not-a-valid-jwt'})
                .expect(401)
                .end();
        });

        it("should return a 200 with the expected response header when a valid JWT is passed", function () {
            var jwt = jws.sign({
                header: { alg: 'HS256' },
                payload: { sub: 'foo-user' },
                secret: JWT_SECRET
            });

            return request(baseUrl)
                .get('/secure')
                .headers({'Authorization': 'Bearer ' + jwt})
                .expect('Content-Type', /json/)
                .expect(200)
                .expect({ message: 'This endpoint needs to be secure.' })
                .expect('X-Auth-UserId', 'foo-user')
                .end();
        });
    });
});
