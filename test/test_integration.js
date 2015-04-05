/* global describe, it */

'use strict';

var request = require('super-request');
var jwt = require('jsonwebtoken');

var baseUrl = 'http://' + process.env.HOST_IP;
var JWT_SECRET = "JWT's are the best!";

describe('proxy', function () {
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
            var token = jwt.sign(
                { sub: 'foo-user' },
                JWT_SECRET
            );

            return request(baseUrl)
                .get('/secure')
                .headers({'Authorization': 'Bearer ' + token})
                .expect('Content-Type', /json/)
                .expect(200)
                .expect({ message: 'This endpoint needs to be secure.' })
                .expect('X-Auth-UserId', 'foo-user')
                .end();
        });
    });
});
