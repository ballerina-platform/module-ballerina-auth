import ballerina/test;
import ballerina/http;

http:Client testClient = check new ("http://localhost:9090",
    auth= {
        scheme: http:BASIC_AUTH,
        username: "alice",
        password: "alice@123"
    }
);

@test:Config {}
public function testGet() returns error? {
    http:Response response = check testClient->get("/accounts/account");
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertEquals(response.getTextPayload(), "Hello, World!");

    response = check testClient->get("/accounts/account");
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertEquals(response.getTextPayload(), "Hello, World!");
}
