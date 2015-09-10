/* global describe, it, before, after */

'use strict';

var cp = require('child_process');
var request = require('super-request');
var jwt = require('jsonwebtoken');
var expect = require('chai').expect;
var exec = require('child_process').exec;

var url = 'http://' + process.env.PROXY_HOST;

var secret, proxyName;

function runCommand (command, done) {
    exec(command, function (err) {
        if (err) { return done(err); }

        // add a small delay so port bindings are ready
        setTimeout(done, 100);
    });
}

function runProxyContainer (name, done) {
    console.log('      > Building and starting proxy container: ' + name);

    var command = 'cd ..; ./scripts/run_proxy_container.sh ' + name;
    runCommand(command, done);
}

function stopProxyContainer (name, done) {
    console.log('      > Stopping and deleting proxy container: ' + name);

    var command = 'cd ..; ./scripts/stop_proxy_container.sh ' + name;
    runCommand(command, done);
}

describe('proxy', function () {
    this.timeout(30000);

    before(function (done) {
        console.log('    > Building and starting backend container');

        var command = 'cd ..; ./scripts/run_backend.sh';
        runCommand(command, done);
    });

    after(function (done) {
        console.log('    > Stopping and deleting backend container');

        var command = 'cd ..; ./scripts/stop_backend.sh';
        runCommand(command, done);
    });

    describe("configured with normal secret", function () {
        before(function (done) {
            secret = 'JWTs are the best!';

            proxyName = 'default';
            runProxyContainer(proxyName, done);
        });

        after(function (done) {
            stopProxyContainer(proxyName, done);
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

        describe("GET /secure/admin", function () {
            it("should return 401 when an authenticated user is missing a required claim", function () {
                var token = jwt.sign(
                    // roles claim missing
                    { sub: 'foo-user', aud: 'foo1:bar' },
                    secret);

                return request(url)
                    .get('/secure/admin')
                    .headers({'Authorization': 'Bearer ' + token})
                    .expect(401)
                    .end();
            });

            it("should return 401 when a claim of an authenticated user doesn't pass a 'pattern' claim spec", function () {
                var token = jwt.sign(
                    // aud claim has incorrect value
                    { sub: 'foo-user', aud: 'foo1:bar', roles: ["sales", "marketing"] },
                    secret);

                return request(url)
                    .get('/secure/admin')
                    .headers({'Authorization': 'Bearer ' + token})
                    .expect(401)
                    .end();
            });

            it("should return 401 when a claim of an authenticated user doesn't pass a 'function' claim spec", function () {
                var token = jwt.sign(
                    // roles claim is missing 'marketing' role
                    { sub: 'foo-user', aud: 'foo:bar', roles: ["sales"] },
                    secret);

                return request(url)
                    .get('/secure/admin')
                    .headers({'Authorization': 'Bearer ' + token})
                    .expect(401)
                    .end();
            });

            it("should return 200 when an authenticated user is also authorized by all claims", function () {
                var token = jwt.sign(
                    // everything is good
                    { sub: 'foo-user', aud: 'foo:bar', roles: ["sales", "marketing"] },
                    secret);

                return request(url)
                    .get('/secure/admin')
                    .headers({'Authorization': 'Bearer ' + token})
                    .expect(200)
                    .expect('Content-Type', /json/)
                    .expect({ message: 'This endpoint needs to be secure for an admin.' })
                    .expect('X-Auth-UserId', 'foo-user')
                    .end();
            });
        });
    });

    describe("configured with URL-safe base-64 encoded secret", function () {
        before(function (done) {
            secret = 'This secret is stored base-64 encoded on the proxy host';

            proxyName = 'base64-secret';
            runProxyContainer(proxyName, done);
        });

        after(function (done) {
            stopProxyContainer(proxyName, done);
        });

        describe("GET /secure", function () {
            it("should return a 200 with the expected response header when a valid JWT is passed", function () {
                var token = jwt.sign(
                    { sub: 'foo-user' },
                    secret);

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

    describe("configured with claim_specs param that's not a table", function () {
        before(function (done) {
            secret = 'JWTs are the best!';

            proxyName = 'config-claim_specs-not-table';
            runProxyContainer(proxyName, done);
        });

        after(function (done) {
            stopProxyContainer(proxyName, done);
        });

        describe("GET /secure/admin", function () {
            it("should return a 500", function (done) {
                var token = jwt.sign(
                    // everything is good
                    { sub: 'foo-user', aud: 'foo:bar', roles: ["sales", "marketing"] },
                    secret);

                request(url)
                    .get('/secure/admin')
                    .headers({'Authorization': 'Bearer ' + token})
                    .expect(500)
                    .end(function (err) {
                        if (err) { done(err); }

                        // check docker logs for expected config error
                        cp.exec('docker logs proxy-config-claim_specs-not-table', function (err, stdout, stderr) {
                            if (err) { done(err); }

                            expect(stderr).to.have.string(
                                "Configuration error: claim_specs arg must be a table");

                            done();
                        });
                    });
            });
        });
    });

    describe("configured with claim_specs param that contains a spec that's not a pattern (string) or table", function () {
        before(function (done) {
            secret = 'JWTs are the best!';

            proxyName = 'config-unsupported-claim-spec-type';
            runProxyContainer(proxyName, done);
        });

        after(function (done) {
            stopProxyContainer(proxyName, done);
        });

        describe("GET /secure/admin", function () {
            it("should return a 500", function (done) {
                var token = jwt.sign(
                    // everything is good
                    { sub: 'foo-user', aud: 'foo:bar', roles: ["sales", "marketing"] },
                    secret);

                request(url)
                    .get('/secure/admin')
                    .headers({'Authorization': 'Bearer ' + token})
                    .expect(500)
                    .end(function (err) {
                        if (err) { done(err); }

                        // check docker logs for expected config error
                        cp.exec('docker logs proxy-config-unsupported-claim-spec-type', function (err, stdout, stderr) {
                            if (err) { done(err); }

                            expect(stderr).to.have.string(
                                "Configuration error: claim_specs arg claim 'aud' must be a string or a table");

                            done();
                        });
                    });
            });
        });
    });
});
