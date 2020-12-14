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

import ballerina/config;
import ballerina/crypto;

# Represents the file user store configurations.
#
# + tableName - The table name specified in the user-store TOML configuration
# + scopeKey - The key used for define scopes in the user-store TOML configuration
public type FileUserStoreConfig record {|
    // TODO: Support path
    // string path;
    string tableName = CONFIG_USER_SECTION;
    string scopeKey = CONFIG_SCOPE_SECTION;
|};

# Represents the details of the authenticated user.
#
# + username - The username of the authenticated user
# + scopes - The scopes of the authenticated user
public type UserDetails record {|
    string username;
    string[] scopes;
|};

# Represents the configuration file based inbound Basic Auth provider, which is an implementation of the
# `auth:InboundAuthProvider` interface.
# ```ballerina
#  auth:InboundBasicAuthProvider inboundBasicAuthProvider = new;
#  ```
# A user is denoted by a section in the Ballerina configuration file. The password and the scopes assigned to the user
# are denoted as keys under the relevant user section as shown below.
# ```
# [b7a.users.<username>]
# password="<password>"
# scopes="<comma_separated_scopes>"
# ```
public class ListenerFileUserStoreBasicAuthProvider {

    *ListenerBasicAuthProvider;

    FileUserStoreConfig fileUserStoreConfig;

    # Provides authentication based on the provided configurations.
    #
    # + basicAuthConfig - Basic Auth provider configurations
    public isolated function init(FileUserStoreConfig fileUserStoreConfig) {
        self.fileUserStoreConfig = fileUserStoreConfig;
    }

    # Attempts to authenticate the base64-encoded `username:password` credentials.
    # ```ballerina
    # boolean|auth:Error authenticationResult = inboundBasicAuthProvider.authenticate("<credential>");
    # ```
    #
    # + credential - Base64-encoded `username:password` value
    # + return - `true` if the authentication is successful, `false` otherwise, or else an `auth:Error` occurred
    #             while authenticating the credentials
    public isolated function authenticate(string credential) returns UserDetails|Error {
        if (credential == "") {
            return prepareError("Credential cannot be empty.");
        }
        [string, string] [username, password] = check extractUsernameAndPassword(credential);
        string passwordFromConfig = readPassword(username, self.fileUserStoreConfig.tableName);
        boolean authenticated = checkPasswordEquality(passwordFromConfig, password);
        if (authenticated) {
            string[] scopes = readScopes(username, self.fileUserStoreConfig.tableName);
            UserDetails userDetails = {
                username: username,
                scopes: scopes
            };
            return userDetails;
        }
        return prepareError("Failed authentication file user store with username: " + username);
    }
}

isolated function checkPasswordEquality(string passwordFromConfig, string passwordFromToken) returns boolean {
    // This check is added to avoid having to go through multiple condition evaluations, when value is plain text.
    if (passwordFromConfig.startsWith(CONFIG_PREFIX)) {
        if (passwordFromConfig.startsWith(CONFIG_PREFIX_SHA256)) {
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

// Reads the password hash of a user.
isolated function readPassword(string username, string tableName) returns string {
    // First, reads the user ID from the user->id mapping.
    // Then, reads the hashed password from the user-store file using the user ID.
    return readConfigValue(tableName + "." + username, "password");
}

// Read the value from the configuration file.
isolated function readConfigValue(string instanceId, string property) returns string {
    return config:getAsString(instanceId + "." + property, "");
}

// Reads the scope(s) of the user identified by the provided username.
isolated function readScopes(string username, string tableName) returns string[] {
    // First, reads the user ID from the user->id mapping.
    // Then, reads the scopes of the user-id.
    return convertToArray(readConfigValue(tableName + "." + username, "scopes"));
}
