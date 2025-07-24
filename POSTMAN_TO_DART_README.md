# Postman to Dart Converter

This script converts Postman collections to Dart implementation following the feature structure created by `feature.sh`.

## Prerequisites

- `jq` command-line tool (for JSON parsing)
- Flutter project with the required dependencies:
  - `dio` for HTTP requests
  - `dartz` for functional programming
  - `json_annotation` and `json_serializable` for JSON serialization
  - `flutter_riverpod` for state management

## Usage

```bash
./postman_to_dart.sh <postman_collection_file> <feature_name>
```

### Parameters

- `postman_collection_file`: Path to your Postman collection JSON file
- `feature_name`: Name of the feature (will be converted to snake_case for directories and PascalCase for class names)

### Example

```bash
./postman_to_dart.sh my_api_collection.json user_management
```

## What the Script Generates

The script creates a complete feature structure with the following files:

### 1. Data Layer
- **`lib/features/<feature>/bloc/data/i_<feature>_data.dart`**: Abstract interface with API method signatures
- **`lib/features/<feature>/bloc/data/implementation/<feature>_data.dart`**: Implementation using Dio for HTTP requests

### 2. Repository Layer
- **`lib/features/<feature>/bloc/repositories/i_<feature>_repository.dart`**: Abstract repository interface with `Either<RepositoryError, Model>` return types
- **`lib/features/<feature>/bloc/repositories/implementation/<feature>_repository.dart`**: Implementation with error handling and model conversion

### 3. Models
- **`lib/features/<feature>/bloc/models/`**: Individual model files for each API
- **`lib/features/<feature>/bloc/models/models.dart`**: Index file exporting all models

### 4. Providers
- **`lib/features/<feature>/bloc/providers/<feature>_provider.dart`**: Riverpod providers for dependency injection

## Features

### Automatic HTTP Method Handling
- **GET/DELETE**: Uses `queryParameters` for URL parameters
- **POST/PUT**: Uses `data` for request body

### Smart List Detection
The script automatically detects if an API should return a list based on:
- Method name containing "list", "getAll", or "fetch"
- API name containing "List"
- API name containing "Get Users" (common pattern)

### Error Handling
- Uses `Either<RepositoryError, Model>` pattern for functional error handling
- Integrates with the existing `BaseRepository` mixin
- Proper error propagation with stack traces

### Model Generation
- Creates JSON-serializable models with `@JsonSerializable()` annotation
- Includes commented examples for field definitions
- Generates proper import statements

## Postman Collection Format

Your Postman collection should have the following structure:

```json
{
  "info": {
    "name": "Collection Name"
  },
  "item": [
    {
      "name": "API Name",
      "request": {
        "method": "GET|POST|PUT|DELETE",
        "url": {
          "raw": "/api/endpoint"
        }
      }
    }
  ]
}
```

## Next Steps After Generation

1. **Update Models**: Edit the generated model files to add your actual fields
2. **Generate JSON Code**: Run `dart run build_runner build` to generate JSON serialization code
3. **Test Implementation**: Test the generated APIs with your actual endpoints
4. **Add Business Logic**: Implement your business logic in the repository methods

## Example Generated Code

### Data Interface
```dart
abstract class IUserManagementData {
  Future<Response> getUsers(Map<String, dynamic> params);
  Future<Response> createUser(Map<String, dynamic> params);
}
```

### Repository Interface
```dart
abstract class IUserManagementRepository {
  Future<Either<RepositoryError, List<GetUsersModel>>> getUsers(Map<String, dynamic> params);
  Future<Either<RepositoryError, CreateUserModel>> createUser(Map<String, dynamic> params);
}
```

### Model Template
```dart
@JsonSerializable()
class GetUsersModel {
  // TODO: Add your model fields here
  // Example:
  // final int id;
  // final String name;
  
  // const GetUsersModel({
  //   required this.id,
  //   required this.name,
  // });
  
  // factory GetUsersModel.fromJson(Map<String, dynamic> json) => _$GetUsersModelFromJson(json);
  // Map<String, dynamic> toJson() => _$GetUsersModelToJson(this);
}
```

## Integration with feature.sh

This script complements the existing `feature.sh` script:
- `feature.sh` creates the basic feature structure
- `postman_to_dart.sh` populates it with API implementations

You can use them together or independently depending on your needs. 