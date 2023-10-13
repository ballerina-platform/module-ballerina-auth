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

listener http:Listener apiGateway = new (9090/*, 
    secureSocket = {
        key: {
            certFile: "./resources/public.crt",
            keyFile: "./resources/private.key"
        }
    }*/
);

@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {
            },
            scopes: ["read-account"]
        }
    ]
}
service /accounts on apiGateway {
    resource function get account() returns string {
        // we will be returning a success mock response.
        return "Hello, Getting account";
    }
}

service /foo on apiGateway {
    resource function get bar() returns string {
        return "Hello, World!";
    }
}
