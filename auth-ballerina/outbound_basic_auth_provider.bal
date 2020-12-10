// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/log;

# Represents the Basic Authentication configurations, which are used by the HTTP endpoint.
#
# + username - Username for Basic authentication
# + password - Password for Basic authentication
public type Credential record {|
    string username;
    string password;
|};

# Represents the outbound Basic Auth authenticator, which is an implementation of the `auth:OutboundAuthProvider` interface.
# This uses the usernames and passwords provided by the Ballerina configurations to authenticate external endpoints.
# ```ballerina
#  auth:OutboundBasicAuthProvider outboundBasicAuthProvider = new({
#      username: "tom",
#      password: "123"
#  });
#  ```
public class ClientBasicAuthProvider {

    Credential credential;

    # Provides authentication based on the provided Basic Auth configurations.
    #
    # + credential - Credential configurations
    public isolated function init(Credential credential) {
        self.credential = credential;
    }

    # Generates a token for Basic authentication.
    # ```ballerina
    # string|auth:Error token = outboundBasicAuthProvider.generateToken();
    # ```
    #
    # + return - The generated token or else an `auth:Error` occurred during the validation
    public isolated function generateToken() returns string|Error {
        return prepareBasicAuthToken(self.credential);
    }
}

# Processes the auth token for Basic Auth.
#
# + credential - The `auth:Credential` configurations
# + return - The auth token or else an `auth:Error` occurred during the validation
isolated function prepareBasicAuthToken(Credential credential) returns string|Error {
    string username = credential.username;
    string password = credential.password;
    if (username == "" || password == "") {
        return prepareError("Username or password cannot be empty.");
    }
    string str = username + ":" + password;
    string token = str.toBytes().toBase64();
    log:printDebug("Authorization header is generated for basic auth scheme.");
    return token;
}
