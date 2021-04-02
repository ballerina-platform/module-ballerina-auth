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

import ballerina/lang.'array;
import ballerina/lang.'string;
import ballerina/regex;

# Extracts the username and the password from the base64-encoded `username:password` value.
# ```ballerina
# [string, string]|auth:Error [username, password] = auth:extractUsernameAndPassword("<credential>");
# ```
#
# + credential - Base64-encoded `username:password` value
# + return - A `string` tuple with the extracted username and password or else an `auth:Error` occurred while
#            extracting credentials
public isolated function extractUsernameAndPassword(string credential) returns [string, string]|Error {
    byte[]|error base64Decoded = 'array:fromBase64(credential);
    if (base64Decoded is byte[]) {
        string|error base64DecodedResults = 'string:fromBytes(base64Decoded);
        if (base64DecodedResults is string) {
            string[] decodedCredentials = regex:split(base64DecodedResults, ":");
            if (decodedCredentials.length() != 2 || decodedCredentials[0].length() == 0) {
                return prepareError("Incorrect credential format. Format should be username:password");
            } else {
                return [decodedCredentials[0], decodedCredentials[1]];
            }
        } else {
            return prepareError("Failed to convert byte[] credential to string.", base64DecodedResults);
        }
    } else {
        return prepareError("Failed to convert string credential to byte[].", base64Decoded);
    }
}
