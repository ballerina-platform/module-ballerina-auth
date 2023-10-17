import ballerina/test;
import ballerina/http;

http:Client testClient = check new ("https://localhost:9090",
    secureSocket= {
        cert: "../banking-accounts-service/resources/public.crt"
    }
);

@test:Config {}
public function testRequestsWithoutAuthorizationHeader() returns error? {
    //Request without authorization header
    http:Response response = check testClient->get("/accounts/account");
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
    response = check testClient->get("/accounts/balances");
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
    response = check testClient->post("/payments/transfer", { amount: "100", currency: "INR", creditor: "bob" });
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
}

@test:Config {}
public function testRequestsWithInvalidAuthorizationHeader() returns error? {
    //Request with invalid authorization header
    map<string|string[]> headers = {
        "Authorization": "Basic random"
    };
    http:Response response = check testClient->get("/accounts/account", headers);
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
    response = check testClient->get("/accounts/balances", headers);
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
    response = check testClient->post("/payments/transfer", { amount: "100", currency: "INR", creditor: "bob" }, headers);
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
}

//Test for user alice, scopes = read-account, read-balance, funds-transfer
@test:Config {}
public function testRequestsWithUserHavingAuthorizationOfAllScopes() returns error? {
    //Request with correct authorization header
    map<string|string[]> headers = {
        "Authorization": "Basic YWxpY2U6YWxpY2VAMTIz"
    };
    //User has Authorization for scope read-account
    AccountWithBalances[] accountsAlice = check testClient->get("/accounts/account", headers);
    test:assertEquals(accountsAlice, getExpectedAccounts("alice"));
    //User has Authorization for scope read-balance
    AccountWithBalances[] accountsWithBalanceAlice = check testClient->get("/accounts/balances", headers);
    test:assertEquals(accountsWithBalanceAlice, getExpectedAccountsWithBalance("alice"));
    //User has Authorization for scope funds-transfer
    PaymentResponse paymentResponse = check testClient->post("/payments/transfer", { amount: "100", currency: "INR", creditor: "bob" }, headers);
    test:assertEquals(paymentResponse.status, "SUCCESS");
    //User tried to do transfer for amount more than available balance
    paymentResponse = check testClient->post("/payments/transfer", { amount: "1001", currency: "INR", creditor: "bob" }, headers);
    test:assertEquals(paymentResponse.status, "FAILED");
    test:assertEquals(paymentResponse.failureReason, "Insufficient Balance in account");
}

//Test for user bob, scopes = read-account, read-balance
@test:Config {}
public function testRequestsWithUserHavingAuthorizationOfFewScopes() returns error? {
    //Request with correct authorization header
    map<string|string[]> headers = {
        "Authorization": "Basic Ym9iOmJvYkAxMjM="
    };
    //User has Authorization for scope read-account
    AccountWithBalances[] accountsBob = check testClient->get("/accounts/account", headers);
    test:assertEquals(accountsBob, getExpectedAccounts("bob"));
    //User has Authorization for scope read-balance
    AccountWithBalances[] accountsWithBalanceBob = check testClient->get("/accounts/balances", headers);
    test:assertEquals(accountsWithBalanceBob, getExpectedAccountsWithBalance("bob"));
    //User does not have Authorization for scope funds-transfer
    http:Response response = check testClient->post("/payments/transfer", { amount: "1001", currency: "INR", creditor: "bob" }, headers);
    test:assertEquals(response.statusCode, http:STATUS_FORBIDDEN);
}

//Test for User david, scopes = read-account
@test:Config {}
public function testRequestsWithUserHavingAuthorizationOfOnlyOneScope() returns error? {
    //Request with correct authorization header
    map<string|string[]> headers = {
        "Authorization": "Basic ZGF2aWQ6ZGF2aWRAMTIz"
    };
    //User has Authorization for scope read-account
    AccountWithBalances[] accountsDavid = check testClient->get("/accounts/account", headers);
    test:assertEquals(accountsDavid, getExpectedAccounts("david"));
    //User does not have Authorization for scope read-balance
    http:Response response = check testClient->get("/accounts/balances");
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
    //User does not have Authorization for scope funds-transfer
    response = check testClient->post("/payments/transfer", { amount: "100", currency: "INR", creditor: "bob" }, headers);
    test:assertEquals(response.statusCode, http:STATUS_FORBIDDEN);
}

public function getExpectedAccounts(string customerId) returns AccountWithBalances[] {
    AccountWithBalances[] accountBalance = accountBalances
            .filter(acc => acc.customerId == customerId)
            .toArray();
    AccountWithBalances[] accountBalance1 = accountBalance.clone();
    accountBalance1[0].balances = [];
    return accountBalance1;
}

public function getExpectedAccountsWithBalance(string customerId) returns AccountWithBalances[] {
    AccountWithBalances[] accountBalance = accountBalances
            .filter(acc => acc.customerId == customerId)
            .toArray();
    return accountBalance;
}
