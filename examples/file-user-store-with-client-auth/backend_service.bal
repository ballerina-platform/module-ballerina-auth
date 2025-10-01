// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/http;
import ballerina/io;

// Sample inventory data
map<int> inventory = {
    "P001": 25,
    "P002": 50,
    "P003": 15,
    "P004": 30
};

// Backend inventory service listener with HTTPS
listener http:Listener inventoryService = new (8080,
    secureSocket = {
        key: {
            certFile: "./resources/public.crt",
            keyFile: "./resources/private.key"
        }
    }
);

// Inventory service with file user store authentication
@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["system:inventory"]
        }
    ]
}
service /inventory on inventoryService {
    
    // Check product availability - requires system:inventory scope
    resource function post 'check(@http:Payload json request) returns json|error {
        string productId = check request.productId.ensureType(string);
        int quantity = check request.quantity.ensureType(int);
        
        io:println(string `Checking inventory for product: ${productId}, quantity: ${quantity}`);
        
        int availableStock = inventory[productId] ?: 0;
        boolean available = availableStock >= quantity;
        
        json response = {
            "productId": productId,
            "available": available,
            "availableStock": availableStock
        };
        
        io:println(string `Inventory check result - Product: ${productId}, Available: ${available}, Stock: ${availableStock}`);
        return response;
    }
    
    // Update inventory - requires system:inventory scope
    resource function put products/[string productId]/stock(int newStock) returns map<string>|http:NotFound {
        if !inventory.hasKey(productId) {
            return http:NOT_FOUND;
        }
        
        inventory[productId] = newStock;
        io:println(string `Updated inventory for product ${productId}: ${newStock}`);
        
        return {
            "productId": productId,
            "newStock": newStock.toString(),
            "message": "Inventory updated successfully"
        };
    }
    
    // Get current stock - requires system:inventory scope
    resource function get products/[string productId]/stock() returns map<string>|http:NotFound {
        int? stock = inventory[productId];
        if stock is () {
            return http:NOT_FOUND;
        }
        
        return {
            "productId": productId,
            "currentStock": stock.toString()
        };
    }
}

public function main() {
    io:println("Backend Inventory Service started on https://localhost:8080");
    io:println("Available endpoints:");
    io:println("  POST /inventory/check - Check product availability");
    io:println("  PUT /inventory/products/{productId}/stock - Update product stock");
    io:println("  GET /inventory/products/{productId}/stock - Get current stock");
    io:println("Authentication required: Basic Auth with 'inventory_service' user and 'system:inventory' scope");
}