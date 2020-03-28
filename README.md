# Lab: Serverless Endpoint


## Introduction

How can I set up and connect to serverless endpoints?

The point of this lab is to investigate how to set up serverless endpoints. Specifically, I want to have set up on each 
of AWS, GCP, and Azure a serverless collection that will exercise:

* authenticated HTTP REST endpoints
* calling authenticated HTTP REST endpoints from other endpoints
* reading from and writing to a database from endpoints

The focus is strictly on the serverless setup itself. So things like authentication will be kept as simple as possible 
(eg hard-coded user lists), albeit in the spirit of how they live in the wild. Also, there won't be any sharing of the 
library across examples - it should be the simplest possible setup not on each environment.



## Application

The app will be a simple postboard. It will let you POST Messages to a Board and GET Messages from a Board. It will
offer basic substition with the `@` escape character. Specifically `@random_word` will get replaced with a random word.

Endpoints:

| Endpoint          | Method        | Description   |
| ---               | ---           | ---           |
| /board/{board-id} | GET           | Returns a list of the Messages posted to Board {board-id}. |
|     "             | POST          | Adds the content as a Message to Board {board-id}. Returns the resolved message. |
| /random_word      | GET           | Returns a random word. | 


See flask_postboard for a basic Flask implementation.



# Deployment

For the obvious reasons, deployment should be entirely automated. As far as direct cloud provisioning tools go, 
Terraform seems to be the only one that works across all the major clouds. It has all the nice features:
* open source
* declarative
* masterless
* large community
* engine behind a lot of enterprise stacks
So Terraform it is.

The alternatives seem to lie in two main groups:

1) Cloud-specific. Each cloud has their own CLI, which allows building a procedural script to provision a cluster. Some 
provide a declarative layer on to, eg CloudFormation on AWS (with SAM a serverless-specific component on top).
2) API abstractions. There are a few API frameworks which provide an additional layer of abstraction by allowing the
user just to define an API and have ther framework decide the appropriate things to provision. The Serverless framework
seems to be the leader here.

While (2) sounds closer to where I'd like to eventually end up, the point of this lab is to explore the different 
clouds' setups so I will avoid these extra abstractions.



## Findings

[Terraform](./findings/Terraform.md)



## References

### Terraform

https://learn.hashicorp.com/terraform#getting-started

https://www.endava.com/en/blog/Engineering/2019/11-Things-I-wish-I-knew-before-working-with-Terraform-I

https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9


### AWS

https://medium.com/galvanize/aws-lambda-deployment-with-terraform-24d36cc86533

https://learn.hashicorp.com/terraform/aws/lambda-api-gateway

https://www.davidbegin.com/the-most-minimal-aws-lambda-function-with-python-terraform/

https://github.com/awslabs/aws-apigateway-lambda-authorizer-blueprints/blob/master/blueprints/python/api-gateway-authorizer-python.py

https://github.com/terraform-providers/terraform-provider-aws/issues/6352