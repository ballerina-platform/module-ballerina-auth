import ballerina/test;
import ballerina/http;

http:Client testClient = check new ("https://localhost:9090",
    secureSocket= {
        cert: "/home/runner/work/module-ballerina-auth/module-ballerina-auth/examples/banking-accounts-service/resources/public.crt"
    }
);

@test:Config {}
public function testGet() returns error? {
    //Request without authorization header
    http:Response response = check testClient->get("/accounts/account");
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
    http:Response response = check testClient->get("/accounts/balances");
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
    http:Response response = check testClient->post("/payments/transfer", { amount: "100", currency: "INR", creditor: "bob" });
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);

    //Request with invalid authorization header
    map<string|string[]> headers = {
        "Authorization": "Basic random"
    };
    response = check testClient->get("/accounts/account");
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
    response = check testClient->get("/accounts/balances");
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
    response = check testClient->post("/payments/transfer", { amount: "100", currency: "INR", creditor: "bob" });
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
    
    //Request with correct authorization header
    headers = {
        "Authorization": "Basic YWxpY2U6YWxpY2VAMTIz"
    };
    //User has Authorization for scope read-account
    AccountWithBalances[] accountsAlice = check testClient->get("/accounts/account", headers);
    test:assertEquals(accountsAlice, accountBalances.filter(acc => acc.customerId == "alice").toArray());
    //User has Authorization for scope read-balance
    AccountWithBalances[] accountsWithBalanceAlice = check testClient->get("/accounts/balances", headers);
    test:assertEquals(accountsWithBalanceAlice, accountBalances.filter(acc => acc.customerId == "alice").toArray());
    //User has Authorization for scope funds-transfer
    PaymentResponse paymentResponse = check testClient->post("/payments/transfer", { amount: "100", currency: "INR", creditor: "bob" }, headers);
    test:assertEquals(paymentResponse.status, "Success");
}
