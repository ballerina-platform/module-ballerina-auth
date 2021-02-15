// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/crypto;
import ballerina/'lang.config;

type AuthInfo record {
  readonly string username;
  string password;
  string[] scopes?;
};

final configurable table<AuthInfo> key(username) & readonly users = ?;

# Represents the file user store based listener Basic Auth provider, which is an implementation of the
# `auth:ListenerBasicAuthProvider` object.
# ```ballerina
#  auth:ListenerFileUserStoreBasicAuthProvider provider = new;
#  ```
# The users are denoted by a section in the Ballerina configurations file. The username, password and the scopes
# of a particular user are denoted as keys under the users section as shown below. For multiple users, the complete
# section has to be duplicated.
# ```
# [[auth.users]]
# username = "alice"
# password = "password1"
# scopes = ["scope1", "scope2"]
# ```
public class ListenerFileUserStoreBasicAuthProvider {

    *ListenerBasicAuthProvider;

    # Authenticate the base64-encoded `username:password` credentials.
    # ```ballerina
    # auth:UserDetails|auth:Error result = provider.authenticate("<credential>");
    # ```
    #
    # + credential - Base64-encoded `username:password` value
    # + return - `auth:UserDetails` if the authentication is successful, `auth:Error` in case of an error of
    #            authentication failure
    public isolated function authenticate(string credential) returns UserDetails|Error {
        if (credential == "") {
            return prepareError("Credential cannot be empty.");
        }
        [string, string] [username, password] = check extractUsernameAndPassword(credential);
        if (users.hasKey(username)) {
            AuthInfo authInfo = users.get(username);
            boolean authenticated = checkPasswordEquality(authInfo.password, password);
            if (authenticated) {
                UserDetails userDetails = {
                    username: username
                };
                string[]? scopes = authInfo?.scopes;
                if (scopes is string[]) {
                    userDetails.scopes = scopes;
                }
                return userDetails;
            }
        }
        return prepareError("Failed to authenticate file user store with username: " + username);
    }
}

// Check the password equality of token password and configuration password
isolated function checkPasswordEquality(string passwordFromConfig, string passwordFromToken) returns boolean {
    // This check is added to avoid having to go through multiple condition evaluations, when value is plain text.
    if (passwordFromConfig.startsWith(CONFIG_PREFIX)) {
        if (passwordFromConfig.startsWith(CONFIG_PREFIX_ENCRYPTED)) {
            return config:decryptString(passwordFromConfig).equalsIgnoreCaseAscii(crypto:hashSha256(passwordFromToken.toBytes()).toBase16());
        } else if (passwordFromConfig.startsWith(CONFIG_PREFIX_SHA256)) {
            return extractHash(passwordFromConfig).equalsIgnoreCaseAscii(crypto:hashSha256(passwordFromToken.toBytes()).toBase16());
        } else if (passwordFromConfig.startsWith(CONFIG_PREFIX_SHA384)) {
            return extractHash(passwordFromConfig).equalsIgnoreCaseAscii(crypto:hashSha384(passwordFromToken.toBytes()).toBase16());
        } else if (passwordFromConfig.startsWith(CONFIG_PREFIX_SHA512)) {
            return extractHash(passwordFromConfig).equalsIgnoreCaseAscii(crypto:hashSha512(passwordFromToken.toBytes()).toBase16());
        }
    }
    return passwordFromConfig == passwordFromToken;
}

// Extracts the password hash from the configuration file.
isolated function extractHash(string configValue) returns string {
    return configValue.substring(<int>configValue.indexOf("{") + 1, <int>configValue.lastIndexOf("}"));
}
