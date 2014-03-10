# Service Layer Prototype
## Features
* Stateless authentication
    * Will later record selected aspects of sessions per project requirements. 
* Accepts only POST requests per v3 API specs
    * Has a (currently primitive) way of routing gets to legacy endpoints
* Following session start, passes requests to program creator via same endpoints (thanks in part to nginx)
    * I am running a hacked version of program creator locally with native authentication stripped out which I am testing this against.
* Handle events before authenticated session

## Coming
* Event queueing
* User roles
* Session persistence on device
* Oauth support
