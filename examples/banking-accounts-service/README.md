# Secured Banking Account Management Service with File Store Basic Auth with Scopes

[![Star on Github](https://img.shields.io/badge/-Star%20on%20Github-blue?style=social&logo=github)](https://github.com/ballerina-platform/module-ballerina-auth)

_Authors_: [@harshalkh](https://github.com/harshalkh) \
_Reviewers_: @ThisaruGuruge @DimuthuMadushan \
_Created_: 2023/10/16 \
_Updated_: 2023/10/16

## Overview

This guide explains how to secure the 'Banking Account Management Service' (RESTful service) with Basic Auth using File Store in Ballerina. 

The end-user (customer) in this example, Alice, Bob and David, interacts with the system using the web/mobile app provided. This web/mobile app acts as a 'Client' on behalf of the user’s actions and calls to the 'API Gateway'. The 'API Gateway' routes the requests to 'Banking Service', which is responsible for processing the requests for the customer. 

> **NOTE:** For this guide, since discussion is about the File Store based Basic Auth security aspects, focus is on the network 
interactions once the 'API Gateway' receives a request. The transaction data is stored locally in [table](https://ballerina.io/learn/by-example/table/)

- The 'API Gateway' intercepts the request from the end-user, extracts the credentials (username and password which is 
  concatenated with a `:` and Base64 encoded), and then talks to File Store Listener to validate the credentials.
- After validating the credentials, the 'API Gateway' talks to 'Banking Account Service' with mTLS (mutual TLS).
- The 'Banking Account Service' uses table data to process customer request based on their authorization scopes.

## Implementation

- You can get started with the 'API Gateway', which is responsible to authorize the requests using Basic Auth with the use of File user store and forward the request to the actual microservice via mTLS (mutual TLS). In this scenario, it is 'Banking Account Service'. The 'API Gateway' service is secured by setting the `auth` attribute of `http:ServiceConfig` with the Basic Auth - File user store configurations, so that the Ballerina HTTP service knows how to validate the credentials with the configured File user store from Config.toml. Once validated, the business logic defined inside the resource will get executed. In this case, it will call the 'Banking Account Service' via mTLS and return the response to the 'Client'.
- In addition to declarative approach for Authentication and Authorization, service uses [Imperative Approach](https://ballerina.io/spec/http/#912-imperative-approach) as service needs to have granular control on authorization of customer. For example knowing customer id of user to fetch account details, available balance before proceeding for execution of payment.

> **NOTE:** The rest of the components such as Database Management System are not implemented as the main purpose of this article is to showcase the Basic Auth functionalities. But for the completeness of the story, the API Gateway will return a response from the data stored on in-memory tables.

## Testing

You can run the 'API Gateway' that we developed above, in our local environment. In order to run this service you need to setup prerequisite of Ballerina. You can refer documentation [here](https://ballerina.io/learn/get-started/)

Now, navigate to [`examples`](../) directory and execute the following command.
```shell
$ bal run banking-accounts-service
```

The successful execution of the service should show us the following output.
```shell
Compiling source
    auth/banking_account_service:1.0.0

Running executable
```

Now, you can test authentication and authorization checks being enforced on different actions by sending HTTP requests.
This example uses the Unit Tests to test each scenario as follows.

#### Without authentication

```ballerina
http:Response response = check testClient->get("/accounts/account");
test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
```

#### Authenticating as anonymous user

```ballerina
map<string|string[]> headers = {
    "Authorization": "Basic random"
};
http:Response response = check testClient->get("/accounts/account", headers);
test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
```

#### Detailed scenarios:

| Scenario\User | Alice | Bob | David |
| --- | --- | --- | --- |
| Scopes | `read-account` `read-balance` `funds-transfer` | `read-account` `read-balance` | `read-account` |
| Accessing `GET /accounts/account` | `200` Account Details for Alice | `200` Account Details for Bob | `200` Account Details for David |
| Accessing `GET /accounts/balance` | `200` Account Details with Balance for Alice | `200` Account Details with Balance for Bob | `403` Forbidden |
| Accessing `POST /payments/transfer` where transaction amount within available balance | `200` Response with unique paymentId and status as SUCCESS | `403` Forbidden | `403` Forbidden |
| Accessing `POST /payments/transfer` where transaction amount higher than available balance| `200` Response with unique paymentId and status as FAILED | `403` Forbidden | `403` Forbidden |



## Deployment

Once the development is done, you can deploy the service using any of the methods that are listed below.

### Deploying Locally

Now, you can build Ballerina executable files (.jar) of the components that we developed above. Open the terminal and
navigate to [`examples/banking-account-service`](../banking-accounts-service/), and execute the following command for
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

Once the `*.jar` file is created inside the `target/bin` directories, we can run the components with the following commands in order.

```shell
$ bal run target/bin/api_gateway.jar
```

### Deploying Code to Cloud

Ballerina code to cloud supports generating the deployment artifacts of the Docker and Kubernetes.
Refer to [Code to Cloud](https://ballerina.io/learn/code-to-cloud-deployment/) guide for more information.

## Observability

HTTP/HTTPS based Ballerina services and any client connectors are observable by default.
[Observing Ballerina Code](https://ballerina.io/learn/observe-ballerina-programs/#provide-observability-in-ballerina) guide provides
information on enabling Ballerina service observability with some of its supported systems.
