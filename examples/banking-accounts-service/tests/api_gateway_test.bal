import ballerina/test;
import ballerina/http;

http:Client testClient = check new ("http://localhost:9090/foo");

@test:Config {}
public function testGet() returns error? {
    http:Response response = check testClient->get("/bar");
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertEquals(response.getTextPayload(), "Hello, World!");

    response = check testClient->get("/bar/");
    test:assertEquals(response.statusCode, http:STATUS_BAD_REQUEST);
    test:assertEquals(response.getTextPayload(), "Hello, World!");
}
