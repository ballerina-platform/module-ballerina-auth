import ballerina/test;
import ballerina/http;

http:Client testClient = check new ("https://localhost:9090",
    secureSocket= {
        cert: "/home/runner/work/module-ballerina-auth/module-ballerina-auth/examples/banking-accounts-service/resources/public.crt"
    }
);

table<AccountWithBalances> key(customerId) accountBalancesTest = table [
    {id: "vgshdkrokjhbbb", accountNumber: "1234 1234 1234", customerId: "alice", customerName: "Alice Alice", productType: "Savings Account", status: "Active", balances: [ { name: "Available", amount: "1000", currency: "INR" } ] },

    {id: "vgksurbkfldppd", accountNumber: "1234 1234 6789", customerId: "bob", customerName: "Bob Bob", productType: "Current Account", status: "Active", balances: [] },

    {id: "vgskspwldkdddn", accountNumber: "1234 1234 2345", customerId: "david", customerName: "David David", productType: "Savings Account", status: "Active", balances: [] }
];

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
    //User has Authorization for scope get-account
    headers = {
        "Authorization": "Basic YWxpY2U6YWxpY2VAMTIz"
    };
    response = check testClient->get("/accounts/account", headers);
    test:assertEquals(response.statusCode, http:STATUS_OK);
    test:assertEquals(response.getTextPayload(), accountBalances.filter(acc => acc.customerId == "alice").toArray());
    //test:assertEquals(response.getTextPayload(), '[{"id":"vgshdkrokjhbbb", "accountNumber":"1234 1234 1234", "customerId":"alice", "customerName":"Alice Alice", "productType":"Savings Account", "status":"Active", "balances":[{"name":"Available", "amount":"1000", "currency":"INR"}]}]');
}
