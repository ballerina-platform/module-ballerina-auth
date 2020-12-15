// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

# Represents the listener Basic Auth provider, which could be used to authenticate credentials.
# The `auth:ListenerBasicAuthProvider` acts as the interface for all the Basic Auth listener authentication providers.
# Any type of implementation such as file store, LDAP user store, in memory user store, JDBC user store etc. should be
# object-wise similar.
public type ListenerBasicAuthProvider object {

    # Authenticates the user based on the user credentials (i.e., the username/password).
    #
    # + credential - The `string` credential value
    # + return - `auth:UserDetails` if the authentication is successful, `auth:Error` in case of an error of
    #            authentication failure
    public isolated function authenticate(string credential) returns UserDetails|Error;
};
