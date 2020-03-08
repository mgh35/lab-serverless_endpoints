# Lab: Serverless Endpoint


## Introduction

How can I set up and connect to serverless endpoints?

The point of this lab is to investigate how to set up serverless endpoints. Specifically, I want to have set up on each 
of AWS, GCP, and Azure a serverless collection that will exercise:

* authenticated HTTP REST endpoints
* calling authenticated HTTP REST endpoints from other endpoints
* reading from and writing to a database from endpoints


## Application

The app will be a simple postboard. It will let you POST Messages to a Board and GET Messages from a Board. It will
offer basic substition with the `@` escape character. Specifically `@random_word` will get replaced with a random word.

Endpoints:

| Endpoint          | Method        | Description   |
| ---               | ---           | ---           |
| /board/<board-id> | GET           | Returns a list of the Messages posted to Board <board-id> |
|                   | POST          | Adds the content as a Message to Board <board-id>. Returns the resolved message |
| /random_word      | GET           | Returns a random word. | 


See flask_postboard for a basic Flask implementation.
