An abstraction layer for REST HTTP API

## Features

Takes off the dependency of the Infrastructure layer on concrete HTTP 
implementation.

## Getting started

This package contains an API layer for the REST client and needs to be completed 
with an implementation layer.

## Usage

1. Configuration

```dart
Rest.config = Config(
    rest: RestConfig(builder: () => RestDioClient(dio), api: "https://example.com/api"),
    auth: AuthConfig(builder: () => BearerAuthorization(token: "test_token"))
);
```

2. API Call

```dart
final CancelableOperation<UserProfile> operation = rest(path: "/user/current")
  .decode(withDecoder: (json) => UserProfile.fromJson(json))
.get();

final user = await o.value;

print(user); // prints: UserProfile(firstName: "John", lastName: "Doe")

```

