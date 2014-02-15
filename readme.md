# Service Layer Prototype
## Features
* Stateless authentication
* Accepts only POST requests per v3 API specs
    * Has a (currently primitive) way of routing gets to legacy endpoints
* Following session start, passes requests to program creator via same endpoints (thanks in part to nginx)
    * I am running a hacked version of program creator locally with native authentication stripped out which I am testing this against.

## Coming
* Event queueing
* User roles
* Session persistence on device
* Handle events before authenticated session
* Oauth support
