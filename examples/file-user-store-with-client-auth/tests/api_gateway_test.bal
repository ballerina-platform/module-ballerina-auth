// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
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

http:Client aliceClient = check new ("https://localhost:9090",
    auth = { username: "alice", password: "alice@123" },
    secureSocket = { cert: "./tests/resources/public.crt" }
);

http:Client bobClient = check new ("https://localhost:9090",
    auth = { username: "bob", password: "bob@123" },
    secureSocket = { cert: "./tests/resources/public.crt" }
);

http:Client adminClient = check new ("https://localhost:9090",
    auth = { username: "admin", password: "admin@999" },
    secureSocket = { cert: "./tests/resources/public.crt" }
);

http:Client inventoryMgrClient = check new ("https://localhost:9090",
    auth = { username: "inventory_manager", password: "inv_mgr@456" },
    secureSocket = { cert: "./tests/resources/public.crt" }
);

// Invalid credentials client
http:Client invalidClient = check new ("https://localhost:9090",
    auth = { username: "invalid", password: "invalid" },
    secureSocket = { cert: "./tests/resources/public.crt" }
);

@test:Config {}
function testProductCatalogWithValidAuth() returns error? {
    // Test with alice (has products:read scope) — use auth-configured client
    http:Response response = check aliceClient->get("/catalog/products");
    test:assertEquals(response.statusCode, 200);
    json products = check response.getJsonPayload();
    test:assertTrue(products is json[]);
}

@test:Config {}
function testProductCatalogWithInvalidAuth() returns error? {
    // Test with invalid credentials — use invalidClient
    http:Response response = check invalidClient->get("/catalog/products");
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
    json orderRequest = {
        "items": [
            {
                "productId": "P001",
                "quantity": 2,
                "unitPrice": 1500.00
            }
        ]
    };
    http:Response response = check aliceClient->post("/orders", orderRequest, { "Content-Type": mime:APPLICATION_JSON });
    test:assertEquals(response.statusCode, 201);  // POST operations return 201 (Created)
    json createdOrder = check response.getJsonPayload();
    test:assertEquals(createdOrder.customerId, "alice");
    test:assertEquals(createdOrder.status, "PENDING");
}

@test:Config {}
function testOrderCreationWithInvalidScope() returns error? {
    json orderRequest = {
        "items": [
            {
                "productId": "P001",
                "quantity": 1,
                "unitPrice": 1500.00
            }
        ]
    };
    // Use bobClient (bob does not have orders:create scope)
    http:Response response = check bobClient->post("/orders", orderRequest, { "Content-Type": mime:APPLICATION_JSON });
    test:assertEquals(response.statusCode, 403);
}

@test:Config {}
function testGetUserOrdersWithValidAuth() returns error? {
    // First create an order with alice (use aliceClient)
    json orderRequest = {
        "items": [
            {
                "productId": "P002",
                "quantity": 1,
                "unitPrice": 299.99
            }
        ]
    };
    http:Response createResponse = check aliceClient->post("/orders", orderRequest, { "Content-Type": mime:APPLICATION_JSON });
    test:assertEquals(createResponse.statusCode, 201);  // POST operations return 201 (Created)

    // Now get alice's orders
    http:Response getResponse = check aliceClient->get("/orders");
    test:assertEquals(getResponse.statusCode, 200);
    json orders = check getResponse.getJsonPayload();
    test:assertTrue(orders is json[]);
}

@test:Config {}
function testAdminAccessWithValidScope() returns error? {
    // Test with admin (has admin scope)
    http:Response response = check adminClient->get("/admin/orders");
    test:assertEquals(response.statusCode, 200);
    json allOrders = check response.getJsonPayload();
    test:assertTrue(allOrders is json[]);
}

@test:Config {}
function testAdminAccessWithInvalidScope() returns error? {
    // Test with alice (doesn't have admin scope)
    http:Response response = check aliceClient->get("/admin/orders");
    test:assertEquals(response.statusCode, 403);
}

@test:Config {}
function testProductSearchByCategory() returns error? {
    // Test with alice (has products:read scope)
    http:Response response = check aliceClient->get("/catalog/products/category/Electronics");
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
    http:Response response = check aliceClient->get("/catalog/products/P001");
    test:assertEquals(response.statusCode, 200);
    json product = check response.getJsonPayload();
    test:assertEquals(product.id, "P001");
    test:assertEquals(product.name, "Laptop Pro");
}

@test:Config {}
function testGetNonExistentProduct() returns error? {
    // Test with alice (has products:read scope)
    http:Response response = check aliceClient->get("/catalog/products/P999");
    test:assertEquals(response.statusCode, 404);
}

@test:Config {}
function testAddNewProductWithValidScope() returns error? {
    // Test with inventory_manager (has inventory:manage scope)
    json newProduct = {
        "id": "P005",
        "name": "Gaming Mouse",
        "category": "Electronics",
        "price": 89.99,
        "stock": 40,
        "description": "High-precision gaming mouse"
    };
    http:Response response = check inventoryMgrClient->post("/inventory/products", newProduct, { "Content-Type": mime:APPLICATION_JSON });
    test:assertEquals(response.statusCode, 201);  // POST operations return 201 (Created)
    json addedProduct = check response.getJsonPayload();
    test:assertEquals(addedProduct.id, "P005");
    test:assertEquals(addedProduct.name, "Gaming Mouse");
}

@test:Config {}
function testOrderCreationWithInsufficientStock() returns error? {
    json orderRequest = {
        "items": [
            {
                "productId": "P003", // Office Chair has stock of 15
                "quantity": 20,     // Requesting more than available
                "unitPrice": 449.00
            }
        ]
    };
    // Use aliceClient to submit the request with alice's credentials
    http:Response response = check aliceClient->post("/orders", orderRequest, { "Content-Type": mime:APPLICATION_JSON });
    test:assertEquals(response.statusCode, 400); // Bad Request due to insufficient stock
}
