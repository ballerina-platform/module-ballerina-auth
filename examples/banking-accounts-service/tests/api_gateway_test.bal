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

    //Request with invalid authorization header
    map<string|string[]> headers = {
        "Authorization": "Basic random"
    };
    response = check testClient->get("/accounts/account");
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
    
    //Request with correct authorization header
    //User has Authorization for scope read-account
    headers = {
        "Authorization": "Basic YWxpY2U6YWxpY2VAMTIz"
    };
    AccountWithBalances[] accountsAlice = check testClient->get("/accounts/account", headers);
    test:assertEquals(accountsAlice, accountBalances.filter(acc => acc.customerId == "alice").toArray());

    //Request with correct authorization header
    //User has Authorization for scope read-balance
    headers = {
        "Authorization": "Basic YWxpY2U6YWxpY2VAMTIz"
    };
    AccountWithBalances[] accountsWithBalanceAlice = check testClient->get("/accounts/balances", headers);
    test:assertEquals(accountsWithBalanceAlice, accountBalances.filter(acc => acc.customerId == "alice").toArray());

    //Request with correct authorization header
    //User has Authorization for scope funds-transfer
    headers = {
        "Authorization": "Basic YWxpY2U6YWxpY2VAMTIz"
    };
    PaymentResponse paymentResponse = check testClient->post("/payments/transfer", { amount: "100", currency: "INR", creditor: "bob" }, headers);
    test:assertEquals(paymentResponse.status, "Success1");
}
