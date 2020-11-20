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
function testAuthenticationOfNonExistingUser() {
    string usernameAndPassword = "amila:abc";
    boolean|Error result = authenticate(usernameAndPassword);
    if (result is boolean) {
        test:assertFalse(result);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>result.message());
    }
}

@test:Config {}
function testAuthenticationOfNonExistingPassword() {
    string usernameAndPassword = "isuru:xxy";
    boolean|Error result = authenticate(usernameAndPassword);
    if (result is boolean) {
        test:assertFalse(result);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>result.message());
    }
}

@test:Config {}
function testAuthentication() {
    string usernameAndPassword = "isuru:xxx";
    boolean|Error result = authenticate(usernameAndPassword);
    if (result is boolean) {
        test:assertTrue(result);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>result.message());
    }
}

@test:Config {}
function testAuthenticationWithEmptyUsername() {
    string usernameAndPassword = ":xxx";
    boolean|Error result = authenticate(usernameAndPassword);
    if (result is boolean) {
        test:assertFalse(result);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>result.message());
    }
}

@test:Config {}
function testAuthenticationWithEmptyPassword() {
    InboundBasicAuthProvider basicAuthProvider = new;
    string usernameAndPassword = "isuru:";
    boolean|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
function testAuthenticationWithEmptyPasswordAndInvalidUsername() {
    InboundBasicAuthProvider basicAuthProvider = new;
    string usernameAndPassword = "invalid:";
    boolean|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
function testAuthenticationWithEmptyUsernameAndEmptyPassword() {
    string usernameAndPassword = ":";
    boolean|Error result = authenticate(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {}
function testAuthenticationSha256() {
    string usernameAndPassword = "hashedSha256:xxx";
    boolean|Error result = authenticate(usernameAndPassword);
    if (result is boolean) {
        test:assertTrue(result);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>result.message());
    }
}

@test:Config {}
function testAuthenticationSha384() {
    string usernameAndPassword = "hashedSha384:xxx";
    boolean|Error result = authenticate(usernameAndPassword);
    if (result is boolean) {
        test:assertTrue(result);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>result.message());
    }
}

@test:Config {}
function testAuthenticationSha512() {
    string usernameAndPassword = "hashedSha512:xxx";
    boolean|Error result = authenticate(usernameAndPassword);
    if (result is boolean) {
        test:assertTrue(result);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>result.message());
    }
}

@test:Config {}
function testAuthenticationPlain() {
    string usernameAndPassword = "plain:plainpassword";
    boolean|Error result = authenticate(usernameAndPassword);
    if (result is boolean) {
        test:assertTrue(result);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>result.message());
    }
}

function testAuthenticationSha512Negative() {
    string usernameAndPassword = "hashedSha512:xxx ";
    boolean|Error result = authenticate(usernameAndPassword);
    if (result is boolean) {
        test:assertFalse(result);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>result.message());
    }
}

@test:Config {}
function testAuthenticationPlainNegative() {
    string usernameAndPassword = "plain:plainpassword ";
    boolean|Error result = authenticate(usernameAndPassword);
    if (result is boolean) {
        test:assertFalse(result);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>result.message());
    }
}

@test:Config {}
function testAuthenticationWithCustomTableName() {
    string usernameAndPassword = "alice:123";
    boolean|Error result = authenticate(usernameAndPassword, "custom.users");
    if (result is boolean) {
        test:assertTrue(result);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>result.message());
    }
}

@test:Config {}
function testAuthenticationWithNonExistingTableName() {
    string usernameAndPassword = "alice:123";
    boolean|Error result = authenticate(usernameAndPassword, "invalid.table");
    if (result is boolean) {
        test:assertFalse(result);
    } else {
        test:assertFail(msg = "Test Failed! " + <string>result.message());
    }
}

function authenticate(string usernameAndPassword, string? tableName = ()) returns boolean|Error {
    InboundBasicAuthProvider basicAuthProvider;
    if (tableName is string) {
        basicAuthProvider = new({ tableName: tableName });
    } else {
        basicAuthProvider = new;
    }
    string credential = usernameAndPassword.toBytes().toBase64();
    return basicAuthProvider.authenticate(credential);
}
