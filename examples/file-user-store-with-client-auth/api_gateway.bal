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

import ballerina/auth;
import ballerina/http;
import ballerina/io;
import ballerina/uuid;

// Data types for the API
type Product record {|
    readonly string id;
    string name;
    string category;
    decimal price;
    int stock;
    string description;
|};

type OrderItem record {|
    string productId;
    int quantity;
    decimal unitPrice;
|};

type Order record {|
    readonly string id;
    string customerId;
    OrderItem[] items;
    decimal totalAmount;
    string status;
    string createdAt;
|};

type OrderRequest record {|
    OrderItem[] items;
|};

type InventoryCheckRequest record {|
    string productId;
    int quantity;
|};

type InventoryCheckResponse record {|
    string productId;
    boolean available;
    int availableStock;
|};

// Sample data
table<Product> key(id) products = table [
    {
        id: "P001",
        name: "Laptop Pro",
        category: "Electronics",
        price: 1500.00,
        stock: 25,
        description: "High-performance laptop for professionals"
    },
    {
        id: "P002",
        name: "Wireless Headphones",
        category: "Electronics", 
        price: 299.99,
        stock: 50,
        description: "Premium noise-cancelling headphones"
    },
    {
        id: "P003",
        name: "Office Chair",
        category: "Furniture",
        price: 449.00,
        stock: 15,
        description: "Ergonomic office chair with lumbar support"
    },
    {
        id: "P004",
        name: "Coffee Maker",
        category: "Appliances",
        price: 199.99,
        stock: 30,
        description: "Programmable drip coffee maker"
    }
];

table<Order> key(id) orders = table [];

// Configure HTTPS listener with file user store authentication
listener http:Listener apiGateway = new (9090,
    secureSocket = {
        key: {
            certFile: "./resources/public.crt",
            keyFile: "./resources/private.key"
        }
    }
);

// File user store configuration for listener authentication
http:FileUserStoreConfig config = {};
http:ListenerFileUserStoreBasicAuthHandler authHandler = new (config);

// Client configuration for backend inventory service
auth:CredentialsConfig clientCredentials = {
    username: "inventory_service",
    password: "inv_secret123"
};

auth:ClientBasicAuthProvider clientAuthProvider = new (clientCredentials);

// HTTP client to inventory service with basic auth
http:Client inventoryServiceClient = check new ("https://localhost:8080",
    auth = {
        username: "inventory_service",
        password: "inv_secret123"
    },
    secureSocket = {
        cert: "./resources/public.crt"
    }
);

// Product catalog service - requires read access
@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["products:read"]
        }
    ]
}
service /catalog on apiGateway {
    
    // Get all products - requires products:read scope
    resource function get products() returns Product[] {
        io:println("Fetching all products from catalog");
        return products.toArray();
    }
    
    // Get product by ID - requires products:read scope
    resource function get products/[string productId]() returns Product|http:NotFound {
        Product? product = products[productId];
        if product is () {
            return http:NOT_FOUND;
        }
        return product;
    }
    
    // Search products by category - requires products:read scope
    resource function get products/category/[string category]() returns Product[] {
        io:println(string `Searching products in category: ${category}`);
        Product[] filteredProducts = from Product product in products
                                   where product.category.toLowerAscii() == category.toLowerAscii()
                                   select product;
        return filteredProducts;
    }
}

// Inventory management service - requires admin access
@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["inventory:manage"]
        }
    ]
}
service /inventory on apiGateway {
    
    // Update product stock - requires inventory:manage scope
    resource function put products/[string productId]/stock(int newStock) returns Product|http:NotFound|http:BadRequest {
        if newStock < 0 {
            return http:BAD_REQUEST;
        }
        
        Product? product = products[productId];
        if product is () {
            return http:NOT_FOUND;
        }
        
        // Update stock in the table
        Product updatedProduct = {
            id: product.id,
            name: product.name,
            category: product.category,
            price: product.price,
            stock: newStock,
            description: product.description
        };
        
        products.put(updatedProduct);
        io:println(string `Updated stock for product ${productId}: ${newStock}`);
        return updatedProduct;
    }
    
    // Add new product - requires inventory:manage scope
    resource function post products(@http:Payload Product newProduct) returns Product|http:BadRequest {
        if products.hasKey(newProduct.id) {
            return http:BAD_REQUEST;
        }
        
        products.add(newProduct);
        io:println(string `Added new product: ${newProduct.name}`);
        return newProduct;
    }
}

// Order management service - requires order access and uses client auth for inventory checks
@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["orders:create", "orders:read"]
        }
    ]
}
service /orders on apiGateway {
    
    // Create new order - requires orders:create scope and uses client auth for inventory verification
    resource function post .(OrderRequest orderRequest, @http:Header string? Authorization) returns Order|http:BadRequest|http:InternalServerError {
        // Extract customer ID from authentication
        string customerId = getCustomerId(Authorization);
        
        decimal totalAmount = 0.0;
        OrderItem[] validatedItems = [];
        
        // Validate each order item and check inventory using client authentication
        foreach OrderItem item in orderRequest.items {
            Product? product = products[item.productId];
            if product is () {
                io:println(string `Product not found: ${item.productId}`);
                return http:BAD_REQUEST;
            }
            
            // Check inventory availability
            if product.stock < item.quantity {
                io:println(string `Insufficient stock for product ${item.productId}. Requested: ${item.quantity}, Available: ${product.stock}`);
                return http:BAD_REQUEST;
            }
            
            // Calculate total amount
            totalAmount += item.quantity * item.unitPrice;
            validatedItems.push(item);
        }
        
        // Create order
        Order newOrder = {
            id: uuid:createType4AsString(),
            customerId: customerId,
            items: validatedItems,
            totalAmount: totalAmount,
            status: "PENDING",
            createdAt: "2025-01-01T10:00:00Z" // In real scenario, use current timestamp
        };
        
        orders.add(newOrder);
        io:println(string `Created order ${newOrder.id} for customer ${customerId}`);
        return newOrder;
    }
    
    // Get user's orders - requires orders:read scope
    resource function get .(@http:Header string? Authorization) returns Order[] {
        string customerId = getCustomerId(Authorization);
        Order[] customerOrders = from Order orderRecord in orders
                               where orderRecord.customerId == customerId
                               select orderRecord;
        return customerOrders;
    }
    
    // Get specific order by ID - requires orders:read scope
    resource function get [string orderId](@http:Header string? Authorization) returns Order|http:NotFound|http:Forbidden {
        string customerId = getCustomerId(Authorization);
        Order? orderRecord = orders[orderId];
        
        if orderRecord is () {
            return http:NOT_FOUND;
        }
        
        // Check if the order belongs to the authenticated user
        if orderRecord.customerId != customerId {
            return http:FORBIDDEN;
        }
        
        return orderRecord;
    }
}

// Admin service - requires admin scope
@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["admin"]
        }
    ]
}
service /admin on apiGateway {
    
    // Get all orders - admin only
    resource function get orders() returns Order[] {
        io:println("Admin fetching all orders");
        return orders.toArray();
    }
    
    // Update order status - admin only
    resource function put orders/[string orderId]/status(string status) returns Order|http:NotFound {
        Order? orderRecord = orders[orderId];
        if orderRecord is () {
            return http:NOT_FOUND;
        }
        
        Order updatedOrder = {
            id: orderRecord.id,
            customerId: orderRecord.customerId,
            items: orderRecord.items,
            totalAmount: orderRecord.totalAmount,
            status: status,
            createdAt: orderRecord.createdAt
        };
        
        orders.put(updatedOrder);
        io:println(string `Updated order ${orderId} status to ${status}`);
        return updatedOrder;
    }
}

// Helper function to extract customer ID from authorization header
public function getCustomerId(string? authorization) returns string {
    auth:UserDetails|http:Unauthorized authn = authHandler.authenticate(authorization is () ? "" : authorization);
    string customerId = "";
    if authn is auth:UserDetails {
        customerId = authn.username;
    }
    return customerId;
}

