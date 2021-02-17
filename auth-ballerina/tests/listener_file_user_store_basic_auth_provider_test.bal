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
isolated function testFileAuthenticationWithPlainTextCredentials() {
    string usernameAndPassword = "peter:plain-password";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is UserDetails) {
        test:assertEquals(result.username, "peter");
        test:assertEquals(result?.scopes, ["update", "write"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationPlainWithPlainTextCredentialsNegative() {
    string usernameAndPassword = "peter:plain-password ";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Failed to authenticate username 'peter' from file user store.");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationEmptyCredential() {
    string usernameAndPassword = "";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Credential cannot be empty.");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationOfNonExistingUser() {
    string usernameAndPassword = "dave:123";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Username 'dave' does not exists in file user store.");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationOfInvalidPassword() {
    string usernameAndPassword = "alice:xxy";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Failed to authenticate username 'alice' from file user store.");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationSuccess() {
    string usernameAndPassword = "alice:xxx";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is UserDetails) {
        test:assertEquals(result.username, "alice");
        test:assertEquals(result?.scopes, ["read", "write"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationWithEmptyUsername() {
    string usernameAndPassword = ":xxx";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationWithEmptyPassword() {
    string usernameAndPassword = "alice:";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationWithEmptyPasswordAndInvalidUsername() {
    string usernameAndPassword = "invalid:";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationWithEmptyUsernameAndEmptyPassword() {
    string usernameAndPassword = ":";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationSha256() {
    string usernameAndPassword = "hashedSha256:xxx";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is UserDetails) {
        test:assertEquals(result.username, "hashedSha256");
        test:assertEquals(result?.scopes, ["read"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationSha256Negative() {
    string usernameAndPassword = "hashedSha256:invalid";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Failed to authenticate username 'hashedSha256' from file user store.");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationSha384() {
    string usernameAndPassword = "hashedSha384:xxx";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is UserDetails) {
        test:assertEquals(result.username, "hashedSha384");
        test:assertEquals(result?.scopes, ["read"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationSha384Negative() {
    string usernameAndPassword = "hashedSha384:invalid";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Failed to authenticate username 'hashedSha384' from file user store.");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationSha512() {
    string usernameAndPassword = "hashedSha512:xxx";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is UserDetails) {
        test:assertEquals(result.username, "hashedSha512");
        test:assertEquals(result?.scopes, ["read"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testFileAuthenticationSha512Negative() {
    string usernameAndPassword = "hashedSha512:invalid";
    UserDetails|Error result = authenticateFile(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Failed to authenticate username 'hashedSha512' from file user store.");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

isolated function authenticateFile(string usernameAndPassword) returns UserDetails|Error {
    ListenerFileUserStoreBasicAuthProvider basicAuthProvider = new();
    string credential = usernameAndPassword.toBytes().toBase64();
    return basicAuthProvider.authenticate(credential);
}
