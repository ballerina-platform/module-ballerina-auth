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
isolated function testAuthenticationEmptyCredential() {
    string usernameAndPassword = "";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Credential cannot be empty.");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationOfNonExistingUser() {
    string usernameAndPassword = "dave:123";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Failed authentication file user store with username: dave");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationOfInvalidPassword() {
    string usernameAndPassword = "alice:xxy";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Failed authentication file user store with username: alice");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationSuccess() {
    string usernameAndPassword = "alice:xxx";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is UserDetails) {
        test:assertEquals(result.username, "alice");
        test:assertEquals(result.scopes, ["read", "write"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationWithEmptyUsername() {
    string usernameAndPassword = ":xxx";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationWithEmptyPassword() {
    string usernameAndPassword = "alice:";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationWithEmptyPasswordAndInvalidUsername() {
    string usernameAndPassword = "invalid:";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationWithEmptyUsernameAndEmptyPassword() {
    string usernameAndPassword = ":";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationSha256() {
    string usernameAndPassword = "hashedSha256:xxx";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is UserDetails) {
        test:assertEquals(result.username, "hashedSha256");
        test:assertEquals(result.scopes, ["read"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationSha256Negative() {
    string usernameAndPassword = "hashedSha256:invalid";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Failed authentication file user store with username: hashedSha256");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationSha384() {
    string usernameAndPassword = "hashedSha384:xxx";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is UserDetails) {
        test:assertEquals(result.username, "hashedSha384");
        test:assertEquals(result.scopes, ["read"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationSha384Negative() {
    string usernameAndPassword = "hashedSha384:invalid";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Failed authentication file user store with username: hashedSha384");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationSha512() {
    string usernameAndPassword = "hashedSha512:xxx";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is UserDetails) {
        test:assertEquals(result.username, "hashedSha512");
        test:assertEquals(result.scopes, ["read"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationSha512Negative() {
    string usernameAndPassword = "hashedSha512:invalid";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Failed authentication file user store with username: hashedSha512");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationWithPlainTextCredentials() {
    string usernameAndPassword = "peter:plain-password";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is UserDetails) {
        test:assertEquals(result.username, "peter");
        test:assertEquals(result.scopes, ["update", "write"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationPlainWithPlainTextCredentialsNegative() {
    string usernameAndPassword = "peter:plain-password ";
    UserDetails|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Failed authentication file user store with username: peter");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationWithCustomTableName() {
    string usernameAndPassword = "eve:123";
    UserDetails|Error result = authenticate(usernameAndPassword, "custom.users");
    if (result is UserDetails) {
        test:assertEquals(result.username, "eve");
        test:assertEquals(result.scopes, []);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
isolated function testAuthenticationWithNonExistingTableName() {
    string usernameAndPassword = "eve:123";
    UserDetails|Error result = authenticate(usernameAndPassword, "invalid.table");
    if (result is Error) {
        test:assertEquals(result.message(), "Failed authentication file user store with username: eve");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

isolated function authenticate(string usernameAndPassword, string? tableName = ()) returns UserDetails|Error {
    ListenerFileUserStoreBasicAuthProvider basicAuthProvider;
    if (tableName is string) {
        basicAuthProvider = new({ tableName: tableName });
    } else {
        basicAuthProvider = new({});
    }
    string credential = usernameAndPassword.toBytes().toBase64();
    return basicAuthProvider.authenticate(credential);
}
