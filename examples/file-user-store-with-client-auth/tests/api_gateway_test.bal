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
import ballerina/test;
import ballerina/mime;

// Test HTTP client configuration
http:Client testClient = check new ("https://localhost:9090",
    secureSocket = {
        cert: "./tests/resources/public.crt"
    }
);

@test:Config {}
function testProductCatalogWithValidAuth() returns error? {
    // Test with alice (has products:read scope)
    string authHeader = "Basic " + "alice:alice@123".toBytes().toBase64();
    
    http:Response response = check testClient->get("/catalog/products", {
        "Authorization": authHeader
    });
    
    test:assertEquals(response.statusCode, 200);
    json products = check response.getJsonPayload();
    test:assertTrue(products is json[]);
}

@test:Config {}
function testProductCatalogWithInvalidAuth() returns error? {
    // Test with invalid credentials
    string authHeader = "Basic " + "invalid:invalid".toBytes().toBase64();
    
    http:Response response = check testClient->get("/catalog/products", {
        "Authorization": authHeader
    });
    
    test:assertEquals(response.statusCode, 401);
}

@test:Config {}
function testProductCatalogWithoutAuth() returns error? {
    // Test without authorization header
    http:Response response = check testClient->get("/catalog/products");
    test:assertEquals(response.statusCode, 401);
}

@test:Config {}
function testOrderCreationWithValidScope() returns error? {
    // Test with alice (has orders:create scope)
    string authHeader = "Basic " + "alice:alice@123".toBytes().toBase64();
    
    json orderRequest = {
        "items": [
            {
                "productId": "P001",
                "quantity": 2,
                "unitPrice": 1500.00
            }
        ]
    };
    
    http:Response response = check testClient->post("/orders", orderRequest, {
        "Authorization": authHeader,
        "Content-Type": mime:APPLICATION_JSON
    });
    
    test:assertEquals(response.statusCode, 201);  // POST operations return 201 (Created)
    json createdOrder = check response.getJsonPayload();
    test:assertEquals(createdOrder.customerId, "alice");
    test:assertEquals(createdOrder.status, "PENDING");
}

@test:Config {}
function testOrderCreationWithInvalidScope() returns error? {
    // Test with bob (doesn't have orders:create scope)
    string authHeader = "Basic " + "bob:bob@123".toBytes().toBase64();
    
    json orderRequest = {
        "items": [
            {
                "productId": "P001",
                "quantity": 1,
                "unitPrice": 1500.00
            }
        ]
    };
    
    http:Response response = check testClient->post("/orders", orderRequest, {
        "Authorization": authHeader,
        "Content-Type": mime:APPLICATION_JSON
    });
    
    test:assertEquals(response.statusCode, 403);
}

@test:Config {}
function testGetUserOrdersWithValidAuth() returns error? {
    // First create an order with alice
    string authHeader = "Basic " + "alice:alice@123".toBytes().toBase64();
    
    json orderRequest = {
        "items": [
            {
                "productId": "P002",
                "quantity": 1,
                "unitPrice": 299.99
            }
        ]
    };
    
    http:Response createResponse = check testClient->post("/orders", orderRequest, {
        "Authorization": authHeader,
        "Content-Type": mime:APPLICATION_JSON
    });
    
    test:assertEquals(createResponse.statusCode, 201);  // POST operations return 201 (Created)
    
    // Now get alice's orders
    http:Response getResponse = check testClient->get("/orders", {
        "Authorization": authHeader
    });
    
    test:assertEquals(getResponse.statusCode, 200);
    json orders = check getResponse.getJsonPayload();
    test:assertTrue(orders is json[]);
}

@test:Config {}
function testAdminAccessWithValidScope() returns error? {
    // Test with admin (has admin scope)
    string authHeader = "Basic " + "admin:admin@999".toBytes().toBase64();
    
    http:Response response = check testClient->get("/admin/orders", {
        "Authorization": authHeader
    });
    
    test:assertEquals(response.statusCode, 200);
    json allOrders = check response.getJsonPayload();
    test:assertTrue(allOrders is json[]);
}

@test:Config {}
function testAdminAccessWithInvalidScope() returns error? {
    // Test with alice (doesn't have admin scope)
    string authHeader = "Basic " + "alice:alice@123".toBytes().toBase64();
    
    http:Response response = check testClient->get("/admin/orders", {
        "Authorization": authHeader
    });
    
    test:assertEquals(response.statusCode, 403);
}

@test:Config {}
function testProductSearchByCategory() returns error? {
    // Test with alice (has products:read scope)
    string authHeader = "Basic " + "alice:alice@123".toBytes().toBase64();
    
    http:Response response = check testClient->get("/catalog/products/category/Electronics", {
        "Authorization": authHeader
    });
    
    test:assertEquals(response.statusCode, 200);
    json products = check response.getJsonPayload();
    test:assertTrue(products is json[]);
    
    // Check that all returned products are in Electronics category
    json[] productArray = <json[]>products;
    foreach json product in productArray {
        test:assertEquals(product.category, "Electronics");
    }
}

@test:Config {}
function testGetSpecificProduct() returns error? {
    // Test with alice (has products:read scope)
    string authHeader = "Basic " + "alice:alice@123".toBytes().toBase64();
    
    http:Response response = check testClient->get("/catalog/products/P001", {
        "Authorization": authHeader
    });
    
    test:assertEquals(response.statusCode, 200);
    json product = check response.getJsonPayload();
    test:assertEquals(product.id, "P001");
    test:assertEquals(product.name, "Laptop Pro");
}

@test:Config {}
function testGetNonExistentProduct() returns error? {
    // Test with alice (has products:read scope)
    string authHeader = "Basic " + "alice:alice@123".toBytes().toBase64();
    
    http:Response response = check testClient->get("/catalog/products/P999", {
        "Authorization": authHeader
    });
    
    test:assertEquals(response.statusCode, 404);
}

@test:Config {}
function testAddNewProductWithValidScope() returns error? {
    // Test with inventory_manager (has inventory:manage scope)
    string authHeader = "Basic " + "inventory_manager:inv_mgr@456".toBytes().toBase64();
    
    json newProduct = {
        "id": "P005",
        "name": "Gaming Mouse",
        "category": "Electronics",
        "price": 89.99,
        "stock": 40,
        "description": "High-precision gaming mouse"
    };
    
    http:Response response = check testClient->post("/inventory/products", newProduct, {
        "Authorization": authHeader,
        "Content-Type": mime:APPLICATION_JSON
    });
    
    test:assertEquals(response.statusCode, 201);  // POST operations return 201 (Created)
    json addedProduct = check response.getJsonPayload();
    test:assertEquals(addedProduct.id, "P005");
    test:assertEquals(addedProduct.name, "Gaming Mouse");
}

@test:Config {}
function testOrderCreationWithInsufficientStock() returns error? {
    // Test with alice trying to order more than available stock
    string authHeader = "Basic " + "alice:alice@123".toBytes().toBase64();
    
    json orderRequest = {
        "items": [
            {
                "productId": "P003", // Office Chair has stock of 15
                "quantity": 20,     // Requesting more than available
                "unitPrice": 449.00
            }
        ]
    };
    
    http:Response response = check testClient->post("/orders", orderRequest, {
        "Authorization": authHeader,
        "Content-Type": mime:APPLICATION_JSON
    });
    
    test:assertEquals(response.statusCode, 400); // Bad Request due to insufficient stock
}