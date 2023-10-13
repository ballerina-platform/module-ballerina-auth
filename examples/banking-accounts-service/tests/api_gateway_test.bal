import ballerina/test;
import ballerina/http;

http:Client testClient = check new ("http://localhost:9090",
    auth= {
        username: "alice",
        password: "alice@123"
    }
);

@test:Config {}
public function testGet() returns error? {
    map<string|string[]> headers = {
        "Authorization": "Basic YWxpY2U6YWxpY2VAMTIz"
    };
    http:Response response = check testClient->get("/accounts/account", headers);
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertEquals(response.getTextPayload(), "Hello, World!");

    response = check testClient->get("/accounts/account", headers);
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertEquals(response.getTextPayload(), "Hello, World!");
}
