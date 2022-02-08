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

import ballerina/test;

@test:Config {}
isolated function testFileAuthenticationSuccessWithScopes() returns Error? {
    string usernameAndPassword = "alice:xxx";
    UserDetails result = check authenticateFile(usernameAndPassword);
    test:assertEquals(result.username, "alice");
    test:assertEquals(result?.scopes, ["read", "write"]);
}

@test:Config {}
isolated function testFileAuthenticationSuccessWithoutScopes() returns Error? {
    string usernameAndPassword = "bob:yyy";
    UserDetails result = check authenticateFile(usernameAndPassword);
    test:assertEquals(result.username, "bob");
    test:assertTrue(result?.scopes is ());
}

@test:Config {}
isolated function testFileAuthenticationEmptyCredential() {
    string usernameAndPassword = "";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if result is Error {
        test:assertEquals(result.message(), "Credential cannot be empty.");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {}
isolated function testFileAuthenticationOfNonExistingUser() {
    string usernameAndPassword = "dave:123";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if result is Error {
        test:assertEquals(result.message(), "Username 'dave' does not exists in file user store.");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {}
isolated function testFileAuthenticationOfInvalidPassword() {
    string usernameAndPassword = "alice:xxy";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if result is Error {
        test:assertEquals(result.message(), "Failed to authenticate username 'alice' from file user store.");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {}
isolated function testFileAuthenticationWithEmptyUsername() {
    string usernameAndPassword = ":xxx";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if result is Error {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {}
isolated function testFileAuthenticationWithEmptyPassword() {
    string usernameAndPassword = "alice:";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if result is Error {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {}
isolated function testFileAuthenticationWithEmptyPasswordAndInvalidUsername() {
    string usernameAndPassword = "invalid:";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if result is Error {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {}
isolated function testFileAuthenticationWithEmptyUsernameAndEmptyPassword() {
    string usernameAndPassword = ":";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if result is Error {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail("Expected error not found.");
    }
}

isolated function authenticateFile(string usernameAndPassword) returns UserDetails|Error {
    ListenerFileUserStoreBasicAuthProvider basicAuthProvider = new();
    string credential = usernameAndPassword.toBytes().toBase64();
    return basicAuthProvider.authenticate(credential);
}
