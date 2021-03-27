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

type AuthInfo record {
  readonly string username;
  string password;
  string[] scopes?;
};

final configurable table<AuthInfo> key(username) & readonly users = table [{ username: "", password: "" }];

# Represents the file user store configurations.
public type FileUserStoreConfig record {|
    // This is intentionally kept blank.
|};

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

    # Provides authentication based on the provided configurations.
    #
    # + fileUserStoreConfig - file user store configurations
    public isolated function init(FileUserStoreConfig fileUserStoreConfig = {}) {
        // This is intentionally kept blank.
    }

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
            return prepareError("Failed to authenticate username '" + username + "' from file user store.");
        }
        return prepareError("Username '" + username + "' does not exists in file user store.");
    }
}

// Check the password equality of token password and configuration password
isolated function checkPasswordEquality(string passwordFromConfig, string passwordFromToken) returns boolean {
    return passwordFromConfig == passwordFromToken;
}
