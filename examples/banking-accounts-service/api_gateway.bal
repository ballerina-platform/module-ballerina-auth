// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/io;
import ballerina/auth;

type Balance record {|
    string name;
    string amount;
    string currency;
|};

type AccountWithBalances record {|
    string id;
    string accountNumber;
    readonly string customerId;
    string customerName;
    string productType;
    string status;
    Balance[] balances;
|};

type PaymentRequest readonly & record {|
    string amount;
    string currency;
    string creditor;
|};

type PaymentResponse readonly & record {|
    string id;
    string status;
|};

table<AccountWithBalances> key(customerId) accountBalances = table [
    {id: "vgshdkrokjhbbb", accountNumber: "1234 1234 1234", customerId: "alice", customerName: "Alice Alice", productType: "Savings Account", status: "Active", balances: [ { name: "Available", amount: "1000", currency: "INR" }, { name: "Ledger", amount: "1000", currency: "INR" }, { name: "Uncleared", amount: "0", currency: "INR" } ] },

    {id: "vgksurbkfldppd", accountNumber: "1234 1234 6789", customerId: "bob", customerName: "Bob Bob", productType: "Current Account", status: "Active", balances: [] },

    {id: "vgskspwldkdddn", accountNumber: "1234 1234 2345", customerId: "david", customerName: "David David", productType: "Savings Account", status: "Active", balances: [] }
];

listener http:Listener apiGateway = new (9090,
    secureSocket = {
        key: {
            certFile: "./banking-accounts-service/resources/public.crt",
            keyFile: "./banking-accounts-service/resources/private.key"
        }
    }
);

// Imperative approach as we need to know about customer authozation details for filtering data
// https://ballerina.io/spec/http/#912-imperative-approach
http:FileUserStoreConfig config = {};
http:ListenerFileUserStoreBasicAuthHandler handler = new (config);

@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["read-account"]
        }
    ]
}
service /accounts on apiGateway {
    resource function get account(@http:Header string? Authorization) returns AccountWithBalances[] {
        string customerId = getCustomerId(Authorization);
        AccountWithBalances[] accountBalance = check accountBalances
            .filter(acc => acc.customerId == customerId)
            .toArray();
        AccountWithBalances[] accountBalance1 = accountBalance.clone();
        accountBalance1[0].balances = [];
        return accountBalance1;
    }

    @http:ResourceConfig {
        auth: [
            {
                fileUserStoreConfig: {},
                scopes: ["read-balance"]
            }
        ]
    }
    resource function get balances(@http:Header string? Authorization) returns AccountWithBalances[] {
        string customerId = getCustomerId(Authorization);
        return accountBalances
            .filter(acc => acc.customerId == customerId)
            .toArray();
    }
}

@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["funds-transfer"]
        }
    ]
}
service /payments on apiGateway {
    resource function post transfer(@http:Payload PaymentRequest paymentRequest, @http:Header string? Authorization) returns PaymentResponse {
        string customerId = getCustomerId(Authorization);
        Balance[] accountBalancesForCustomer = from AccountWithBalances accountWithBalance in accountBalances
            where accountWithBalance.customerId == customerId
            select accountWithBalance.balances;
        io:println(accountBalancesForCustomer);
        Balance avlBalance = from Balance balance in accountBalancesForCustomer
            where balance.type == "Available"
            select balance;
        io:println(avlBalance);
        //io:println(availableBalance);
        return {
           id: "jduridhhddhhd",
           status: "Success"
        };
    }
}

public function getCustomerId(string? authorization) returns string {
    auth:UserDetails|http:Unauthorized authn = handler.authenticate(authorization is () ? "" : authorization);
    string customerId = "";
    if authn is auth:UserDetails {
        customerId = authn.username;
    }
    return customerId;
}
