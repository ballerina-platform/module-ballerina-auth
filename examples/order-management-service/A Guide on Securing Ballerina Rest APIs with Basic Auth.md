# Secured Order Management Service with Basic Auth

[![Star on Github](https://img.shields.io/badge/-Star%20on%20Github-blue?style=social&logo=github)](https://github.com/ballerina-platform/module-ballerina-auth)

_Authors_: @ldclakmal  
_Reviewers_: @shafreenAnfar  
_Created_: 2022/03/10  
_Updated_: 2022/03/10

## Overview

This guide explains how to secure an 'Order Management Service' (RESTful service) with Basic Auth using Ballerina. 
The following figure illustrates a high-level design diagram of the complete use case.

![Securing Microservice with Basic Auth](./order-management-service.png)

The end-user (customer), in this example, Alice and Bob, interacts with the system using the web/mobile app provided.
This web/mobile app acts as a 'Client' on behalf of the user’s actions and calls to the 'API Gateway'. The 'API Gateway'
routes the requests to 'Order Service', which is responsible for processing the order for the customer. The 'Inventory 
Service' is called by the 'Order Service' to process the inventory-related operations.

**NOTE**: For this guide, since we are discussing the Basic Auth security aspects, we are focussing on the network 
interactions once the 'API Gateway' receives a request.

- The 'API Gateway' intercepts the request from the end-user, extracts the credentials (username and password which is 
  concatenated with a `:` and Base64 encoded), and then talks to the 'Active Directory' connected via LDAP
  (Lightweight Directory Access Protocol) to validate the credentials.
- After validating the credentials, the 'API Gateway' talks to 'Order Service' with mTLS (mutual TLS).
- The 'Order Service' talks to 'Inventory Service' with mTLS (mutual TLS).

## Implementation

- We can get started with the 'API Gateway', which is responsible to authorize the requests using Basic Auth with
  the use of LDAP user store and forward the request to the actual microservice via mTLS (mutual TLS). In this scenario,
  it is 'Order Service'. The 'API Gateway' service is secured by setting the `auth` attribute of `http:ServiceConfig`
  with the Basic Auth - LDAP user store configurations, so that the Ballerina HTTP service knows how to validate the 
  credentials with the configured 'Active Directory'. Once validated, the business logic defined inside the resource 
  will get executed. In this case, it will call the 'Order Service' via mTLS and return the response to the 'Client'.

**NOTE**: For the simplicity of the article, since we are interested only in Basic Auth security aspects the rest of the
components like 'Order Service' and 'Inventory Service' is not implemented. But, to complete the story, we
will be returning a successful mock response from the 'API Gateway'.

## Testing

We can run the 'API Gateway' that we developed above, in our local environment. To complete the design diagram
illustrated above, we have to run the 'Active Directory' first. Open the terminal and navigate to 
[`examples/order-management-service/active_directory`](./active_directory) directory and execute the following command. 
This will take few seconds to start and run.
```shell
$ docker-compose -f docker-compose.yml up
```

Now, navigate to [`examples/order-management-service/api_gateway`](./api_gateway) directory and execute the following command.
```shell
$ bal run
```

The successful execution of the service should show us the following output.
```shell
Compiling source
        auth/api_gateway:1.0.0

Running executable
```

Now, we can test authentication and authorization checks being enforced on different actions by sending HTTP requests.
For example, we have used the CURL commands to test each scenario as follows.

#### Without authentication

```shell
curl -k -v "https://localhost:9090/order/100500"
```

Output:
```shell
< HTTP/1.1 401 Unauthorized
< content-length: 0
< server: ballerina
< date: Thu, 10 Mar 2022 10:40:23 +0530
```

#### Authenticating as 'Eve' user, who is an anonymous user

```shell
curl -k -v -H "Authorization: Basic ZXZlOmV2ZUAxMjM=" \
"https://localhost:9090/order/100500"
```

Output:
```shell
< HTTP/1.1 401 Unauthorized
< content-length: 0
< server: ballerina
< date: Thu, 10 Mar 2022 10:40:43 +0530
```

#### Authenticating as 'Bob' user, who does not have permission

```shell
curl -k -v -H "Authorization: Basic Ym9iOmJvYkAxMjM=" \
"https://localhost:9090/order/100500"
```

Output:
```shell
< HTTP/1.1 403 Forbidden
< content-length: 0
< server: ballerina
< date: Thu, 10 Mar 2022 10:40:53 +0530
```

#### Authenticating as 'Alice' user, who has permission

```shell
curl -k -v -H "Authorization: Basic YWxpY2U6YWxpY2VAMTIz" \
"https://localhost:9090/order/100500"
```

Output:
```shell
< HTTP/1.1 200 OK
< content-type: application/json
< content-length: 163
< server: ballerina
< date: Thu, 10 Mar 2022 10:45:02 +0530

{"id":"100500", "name":"Sample order", "items":[{"category":"electronics", "code":"SOWH1000XM4", "qty":2}, {"category":"books", "code":"978-1617295959", "qty":1}]}
```

## Deployment

Once we are done with the development, we can deploy the service using any of the methods that are listed below.

### Deploying Locally

As the first step, we have to run the 'Active Directory' first. Open the terminal and navigate to
[`examples/order-management-service/active_directory`](./active_directory) directory and execute the following command.
This will take few seconds to start and run.
```shell
$ docker-compose -f docker-compose.yml up
```

Now, we can build Ballerina executable files (.jar) of the components that we developed above. Open the terminal and
navigate to [`examples/order-management-service/api_gateway`](./api_gateway), and execute the following command for
each of them.
```shell
$ bal build
```

The successful execution of the above command should show us the following outputs in order.
```shell
Compiling source
        auth/api_gateway:1.0.0

Generating executable
        target/bin/api_gateway.jar
```

Once the `*.jar` file is created inside the `target/bin` directories, we can run the components with the following
commands in order.
```shell
$ bal run target/bin/api_gateway.jar
```

### Deploying Code to Cloud

Ballerina code to cloud supports generating the deployment artifacts of the Docker and Kubernetes.
Refer to [Code to Cloud](https://ballerina.io/learn/user-guide/deployment/code-to-cloud/) guide for more information.

## Observability

HTTP/HTTPS based Ballerina services and any client connectors are observable by default.
[Observing Ballerina Code](https://ballerina.io/learn/user-guide/observability/observing-ballerina-code/) guide provides
information on enabling Ballerina service observability with some of its supported systems.
