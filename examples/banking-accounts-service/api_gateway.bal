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

type Account readonly & record {|
    string id;
    string accountNumber;
    string customerId;
    string customerName;
    string productType;
    string status;
|};

type Balance readonly & record {|
    string name;
    string amount;
    string currency;
|};

type AccountWithBalances readonly & record {|
    string id;
    string accountNumber;
    string customerId;
    string customerName;
    string productType;
    string status;
    Balance[] balances;
|};

table<AccountWithBalances> key(customerId) accountBalances = table [
    {id: "vgshdkrokjhbbb", accountNumber: "1234 1234 1234", customerId: "alice", customerName: "Alice Alice", productType: "Savings Account", status: "Active", balances: [ { name: "Available", amount: "1000", currency: "INR" } ] },

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

@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["read-account"]
        }
    ]
}

service /accounts on apiGateway {
    resource function get account() returns string {
        return "Hello, World!";
    }

    @http:ResourceConfig {
        auth: [
            {
                fileUserStoreConfig: {},
                scopes: ["read-balance"]
            }
        ]
    }
    resource function get balance() returns string {
        return "Hello, World!";
    }
}
