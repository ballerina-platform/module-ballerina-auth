// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/auth;
import ballerina/http;
import ballerina/io;
import ballerina/uuid;

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
    string failureReason?;
|};

table<AccountWithBalances> key(customerId) accountBalances = table [
    {
        id: "vgshdkrokjhbbb",
        accountNumber: "1234 1234 1234",
        customerId: "alice", 
        customerName: "Alice Alice", 
        productType: "Savings Account", 
        status: "Active", 
        balances: [ 
            { name: "Available", amount: "1000", currency: "INR" }, 
            { name: "Ledger", amount: "1000", currency: "INR" }, 
            { name: "Uncleared", amount: "0", currency: "INR" }
        ]
    },
    {
        id: "vgksurbkfldppd",
        accountNumber: "1234 1234 6789",
        customerId: "bob",
        customerName: "Bob Bob",
        productType: "Current Account",
        status: "Active",
        balances: [
            { name: "Available", amount: "10000", currency: "INR" },
            { name: "Ledger", amount: "1000", currency: "INR" }, 
            { name: "Uncleared", amount: "0", currency: "INR" }
        ]
    },
    {
        id: "vgskspwldkdddn",
        accountNumber: "1234 1234 2345",
        customerId: "david",
        customerName: "David David",
        productType: "Savings Account",
        status: "Active",
        balances: [
            { name: "Available", amount: "8000", currency: "INR" },
            { name: "Ledger", amount: "1000", currency: "INR" },
            { name: "Uncleared", amount: "0", currency: "INR" }
        ]
    }
];

listener http:Listener apiGateway = new (9090,
    secureSocket = {
        key: {
            certFile: "../banking-accounts-service/resources/public.crt",
            keyFile: "../banking-accounts-service/resources/private.key"
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
        AccountWithBalances[] accountBalance = from AccountWithBalances account in accountBalances 
                where account.customerId == customerId
                select account;
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
        AccountWithBalances[] accountBalance = from AccountWithBalances account in accountBalances 
                where account.customerId == customerId
                select account;
        return accountBalance;
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
        AccountWithBalances[] accountBalance = from AccountWithBalances account in accountBalances
                where account.customerId == customerId
                select account;
        boolean balAvailable = accountBalance[0].balances
            .filter(bal => bal.name=="Available").some(bal1 => bal1.amount>=paymentRequest.amount);
        if !balAvailable {
            io:println("Insufficient Balance in account");
            return {
                id: uuid:createType4AsString(),
                status: "FAILED",
                failureReason: "Insufficient Balance in account"
            };
        }
        return {
           id: uuid:createType4AsString(),
           status: "SUCCESS"
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
