#!/bin/bash

set -e

# Usage: ./postman_to_dart.sh <postman_collection_file> <feature_name>

if [ $# -ne 2 ]; then
  echo "Usage: $0 <postman_collection_file> <feature_name>"
  exit 1
fi

POSTMAN_FILE=$1
FEATURE_NAME=$2

# Check if Postman file exists
if [ ! -f "$POSTMAN_FILE" ]; then
  echo "Error: Postman collection file '$POSTMAN_FILE' not found"
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed. Please install jq first."
  exit 1
fi

# Format feature name for class names (PascalCase)
FEATURE_CLASS_NAME=$(echo "$FEATURE_NAME" | awk -F'_' '{for(i=1;i<=NF;i++){printf toupper(substr($i,1,1)) tolower(substr($i,2))}}')
FEATURE_SNAKE_NAME=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]')

FEATURE_DIR="lib/features/$FEATURE_NAME"

# Create directory structure
mkdir -p "$FEATURE_DIR/bloc/data/implementation"
mkdir -p "$FEATURE_DIR/bloc/repositories/implementation"
mkdir -p "$FEATURE_DIR/bloc/models"
mkdir -p "$FEATURE_DIR/bloc/providers"

echo "Converting Postman collection to Dart implementation for feature: $FEATURE_NAME"

# Extract APIs from Postman collection (try both formats)
APIS=$(jq -r '.item[] | select(.request) | "\(.name)|\(.request.method)|\(.request.url.raw)"' "$POSTMAN_FILE" 2>/dev/null || jq -r '.requests[] | select(.method) | "\(.name)|\(.method)|\(.url)"' "$POSTMAN_FILE" 2>/dev/null || echo "")

if [ -z "$APIS" ]; then
  echo "Error: No APIs found in the Postman collection or invalid JSON format"
  exit 1
fi

# Generate data abstraction file
DATA_ABSTRACT_FILE="$FEATURE_DIR/bloc/data/i_${FEATURE_SNAKE_NAME}_data.dart"
cat > "$DATA_ABSTRACT_FILE" <<EOF
import 'package:dio/dio.dart';
import '../models/models.dart';

abstract class I${FEATURE_CLASS_NAME}Data {
EOF

# Generate data implementation file
DATA_IMPL_FILE="$FEATURE_DIR/bloc/data/implementation/${FEATURE_SNAKE_NAME}_data.dart"
cat > "$DATA_IMPL_FILE" <<EOF
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../base/network/dio_client.dart';
import '../i_${FEATURE_SNAKE_NAME}_data.dart';
import '../../models/models.dart';

class ${FEATURE_CLASS_NAME}Data implements I${FEATURE_CLASS_NAME}Data {
  final Dio dio;

  ${FEATURE_CLASS_NAME}Data({required this.dio});

EOF

# Generate repository abstraction file
REPO_ABSTRACT_FILE="$FEATURE_DIR/bloc/repositories/i_${FEATURE_SNAKE_NAME}_repository.dart"
cat > "$REPO_ABSTRACT_FILE" <<EOF
import '../models/models.dart';
import 'package:dartz/dartz.dart';
import '../../../../base/exceptions/base_error.dart';

abstract class I${FEATURE_CLASS_NAME}Repository {
EOF

# Generate repository implementation file
REPO_IMPL_FILE="$FEATURE_DIR/bloc/repositories/implementation/${FEATURE_SNAKE_NAME}_repository.dart"
cat > "$REPO_IMPL_FILE" <<EOF
import '../../models/models.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../base/exceptions/base_error.dart';
import '../../../../../base/utils/base_repository.dart';
import '../i_${FEATURE_SNAKE_NAME}_repository.dart';
import '../../data/i_${FEATURE_SNAKE_NAME}_data.dart';
import '../../data/implementation/${FEATURE_SNAKE_NAME}_data.dart';

class ${FEATURE_CLASS_NAME}Repository extends BaseRepository implements I${FEATURE_CLASS_NAME}Repository {
  final I${FEATURE_CLASS_NAME}Data data;
  
  ${FEATURE_CLASS_NAME}Repository(this.data);

EOF

# Generate provider file
PROVIDER_FILE="$FEATURE_DIR/bloc/providers/${FEATURE_SNAKE_NAME}_provider.dart"
cat > "$PROVIDER_FILE" <<EOF
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../base/view_states.dart';
import '../repositories/i_${FEATURE_SNAKE_NAME}_repository.dart';
import '../repositories/implementation/${FEATURE_SNAKE_NAME}_repository.dart';

class ${FEATURE_CLASS_NAME}Provider extends StateNotifier<ViewState> {
  final I${FEATURE_CLASS_NAME}Repository repository;
  
  ${FEATURE_CLASS_NAME}Provider(this.repository) : super(InitialViewState());
}

final ${FEATURE_SNAKE_NAME}Provider = StateNotifierProvider<${FEATURE_CLASS_NAME}Provider, ViewState>((ref) {
  final repo = ref.read(${FEATURE_SNAKE_NAME}RepositoryProvider);
  return ${FEATURE_CLASS_NAME}Provider(repo);
});
EOF

# Process each API
API_COUNT=0
while IFS='|' read -r api_name method url; do
  if [ -n "$api_name" ] && [ -n "$method" ] && [ -n "$url" ]; then
    API_COUNT=$((API_COUNT + 1))
    
    # Convert API name to camelCase for method name
    METHOD_NAME=$(echo "$api_name" | sed 's/[^a-zA-Z0-9]/ /g' | awk '{for(i=1;i<=NF;i++){if(i==1)printf tolower($i);else printf toupper(substr($i,1,1)) tolower(substr($i,2))}}')
    
    # Generate model name (PascalCase)
    MODEL_NAME=$(echo "$api_name" | sed 's/[^a-zA-Z0-9]/ /g' | awk '{for(i=1;i<=NF;i++){printf toupper(substr($i,1,1)) tolower(substr($i,2))}}')
    
    # Generate file name (snake_case) for Dart convention
    MODEL_FILE_NAME=$(echo "$api_name" | sed 's/[^a-zA-Z0-9]/ /g' | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g' | sed 's/__*/_/g' | sed 's/^_//' | sed 's/_$//')
    
    # Determine if it's a list response based on method and naming
    IS_LIST=false
    if [[ "$METHOD_NAME" == *"list"* ]] || [[ "$METHOD_NAME" == *"getAll"* ]] || [[ "$METHOD_NAME" == *"fetch"* ]] || [[ "$api_name" == *"List"* ]] || [[ "$api_name" == *"Get Users"* ]]; then
      IS_LIST=true
    fi
    
    # Check if URL has path parameters (contains single {})
    HAS_PATH_PARAMS=false
    if [[ "$url" == *"/{"* ]] || [[ "$url" == *"{/"* ]]; then
      HAS_PATH_PARAMS=true
    fi
    
    # Extract query parameters from URL (only if URL contains ?)
    QUERY_PARAMS=""
    if [[ "$url" == *"?"* ]]; then
      QUERY_PARAMS=$(echo "$url" | sed 's/.*?//' | tr '&' '\n' | cut -d'=' -f1 | sort -u | grep -v '^$' || echo "")
    fi
    
    # Determine if we need any parameter class
    HAS_QUERY_PARAMS=false
    if [ -n "$QUERY_PARAMS" ]; then
      HAS_QUERY_PARAMS=true
    fi
    
    # Check if method supports request body (POST, PUT, PATCH)
    SUPPORTS_REQUEST_BODY=false
    if [[ "$method" == "POST" ]] || [[ "$method" == "PUT" ]] || [[ "$method" == "PATCH" ]]; then
      SUPPORTS_REQUEST_BODY=true
    fi
    
    # Generate parameter class names
    PARAM_CLASS_NAME="${MODEL_NAME}Params"
    INPUT_CLASS_NAME="${MODEL_NAME}Input"
    
    # Add to data abstraction
    if [ "$HAS_PATH_PARAMS" = true ] && [ "$HAS_QUERY_PARAMS" = false ] && [ "$SUPPORTS_REQUEST_BODY" = false ]; then
      # Only path parameters, no query params or request body
      echo "  Future<Response> $METHOD_NAME(${PARAM_CLASS_NAME} params);" >> "$DATA_ABSTRACT_FILE"
    elif [ "$HAS_QUERY_PARAMS" = true ] || [ "$SUPPORTS_REQUEST_BODY" = true ]; then
      # Has query params or request body (may also have path params)
      echo "  Future<Response> $METHOD_NAME(${INPUT_CLASS_NAME} params);" >> "$DATA_ABSTRACT_FILE"
    else
      # No parameters at all
      echo "  Future<Response> $METHOD_NAME();" >> "$DATA_ABSTRACT_FILE"
    fi
    
    # Extract base URL (remove query parameters)
    BASE_URL=$(echo "$url" | cut -d'?' -f1)
    
    # Add to data implementation
    echo "" >> "$DATA_IMPL_FILE"
    echo "  @override" >> "$DATA_IMPL_FILE"
    if [ "$HAS_PATH_PARAMS" = true ] && [ "$HAS_QUERY_PARAMS" = false ] && [ "$SUPPORTS_REQUEST_BODY" = false ]; then
      # Only path parameters, no query params or request body
      echo "  Future<Response> $METHOD_NAME(${PARAM_CLASS_NAME} params) async {" >> "$DATA_IMPL_FILE"
      # Extract path parameters from URL
      PATH_PARAMS=$(echo "$BASE_URL" | grep -o '{[^}]*}' | sed 's/{/"/; s/}/"/' | tr '\n' ',' | sed 's/,$//')
      
      # Replace path parameters in URL
      echo "    final url = '$BASE_URL'.replaceAllMapped(RegExp(r'\\{[^}]*\\}'), (match) {" >> "$DATA_IMPL_FILE"
      echo "      final paramName = match.group(0)!.replaceAll('{', '').replaceAll('}', '');" >> "$DATA_IMPL_FILE"
      echo "      return params.toJson()[paramName]?.toString() ?? '';" >> "$DATA_IMPL_FILE"
      echo "    });" >> "$DATA_IMPL_FILE"
      echo "" >> "$DATA_IMPL_FILE"
      
      # Create request params without path parameters
      if [ -n "$PATH_PARAMS" ]; then
        echo "    final pathParams = <String>[$PATH_PARAMS];" >> "$DATA_IMPL_FILE"
        echo "    final requestParams = Map<String, dynamic>.from(params.toJson());" >> "$DATA_IMPL_FILE"
        echo "    for (final param in pathParams) {" >> "$DATA_IMPL_FILE"
        echo "      requestParams.remove(param);" >> "$DATA_IMPL_FILE"
        echo "    }" >> "$DATA_IMPL_FILE"
        echo "" >> "$DATA_IMPL_FILE"
      else
        echo "    final requestParams = params.toJson();" >> "$DATA_IMPL_FILE"
        echo "" >> "$DATA_IMPL_FILE"
      fi
      
      if [[ "$method" == "GET" ]] || [[ "$method" == "DELETE" ]]; then
        echo "    return await dio.$(echo "$method" | tr '[:upper:]' '[:lower:]')(url, queryParameters: requestParams);" >> "$DATA_IMPL_FILE"
      else
        echo "    return await dio.$(echo "$method" | tr '[:upper:]' '[:lower:]')(url, data: requestParams);" >> "$DATA_IMPL_FILE"
      fi
    elif [ "$HAS_QUERY_PARAMS" = true ] || [ "$SUPPORTS_REQUEST_BODY" = true ]; then
      # Has query params or request body (may also have path params)
      echo "  Future<Response> $METHOD_NAME(${INPUT_CLASS_NAME} params) async {" >> "$DATA_IMPL_FILE"
      
      # Handle path parameters if they exist
      if [ "$HAS_PATH_PARAMS" = true ]; then
        # Extract path parameters from URL
        PATH_PARAMS=$(echo "$BASE_URL" | grep -o '{[^}]*}' | sed 's/{/"/; s/}/"/' | tr '\n' ',' | sed 's/,$//')
        
        # Replace path parameters in URL
        echo "    final url = '$BASE_URL'.replaceAllMapped(RegExp(r'\\{[^}]*\\}'), (match) {" >> "$DATA_IMPL_FILE"
        echo "      final paramName = match.group(0)!.replaceAll('{', '').replaceAll('}', '');" >> "$DATA_IMPL_FILE"
        echo "      return params.toJson()[paramName]?.toString() ?? '';" >> "$DATA_IMPL_FILE"
        echo "    });" >> "$DATA_IMPL_FILE"
        echo "" >> "$DATA_IMPL_FILE"
        
        # Create request params without path parameters
        if [ -n "$PATH_PARAMS" ]; then
          echo "    final pathParams = <String>[$PATH_PARAMS];" >> "$DATA_IMPL_FILE"
          echo "    final requestParams = Map<String, dynamic>.from(params.toJson());" >> "$DATA_IMPL_FILE"
          echo "    for (final param in pathParams) {" >> "$DATA_IMPL_FILE"
          echo "      requestParams.remove(param);" >> "$DATA_IMPL_FILE"
          echo "    }" >> "$DATA_IMPL_FILE"
          echo "" >> "$DATA_IMPL_FILE"
        else
          echo "    final requestParams = params.toJson();" >> "$DATA_IMPL_FILE"
          echo "" >> "$DATA_IMPL_FILE"
        fi
        
        if [[ "$method" == "GET" ]] || [[ "$method" == "DELETE" ]]; then
          echo "    return await dio.$(echo "$method" | tr '[:upper:]' '[:lower:]')(url, queryParameters: requestParams);" >> "$DATA_IMPL_FILE"
        else
          echo "    return await dio.$(echo "$method" | tr '[:upper:]' '[:lower:]')(url, data: requestParams);" >> "$DATA_IMPL_FILE"
        fi
      else
        # No path parameters, just query params or request body
        if [[ "$method" == "GET" ]] || [[ "$method" == "DELETE" ]]; then
          echo "    return await dio.$(echo "$method" | tr '[:upper:]' '[:lower:]')('$BASE_URL', queryParameters: params.toJson());" >> "$DATA_IMPL_FILE"
        else
          echo "    return await dio.$(echo "$method" | tr '[:upper:]' '[:lower:]')('$BASE_URL', data: params.toJson());" >> "$DATA_IMPL_FILE"
        fi
      fi
    else
      # No parameters at all
      echo "  Future<Response> $METHOD_NAME() async {" >> "$DATA_IMPL_FILE"
      if [[ "$method" == "GET" ]] || [[ "$method" == "DELETE" ]]; then
        echo "    return await dio.$(echo "$method" | tr '[:upper:]' '[:lower:]')('$BASE_URL');" >> "$DATA_IMPL_FILE"
      else
        echo "    return await dio.$(echo "$method" | tr '[:upper:]' '[:lower:]')('$BASE_URL');" >> "$DATA_IMPL_FILE"
      fi
    fi
    
    echo "  }" >> "$DATA_IMPL_FILE"
    
    # Add to repository abstraction
    if [ "$HAS_PATH_PARAMS" = true ] && [ "$HAS_QUERY_PARAMS" = false ] && [ "$SUPPORTS_REQUEST_BODY" = false ]; then
      # Only path parameters, no query params or request body
      if [ "$IS_LIST" = true ]; then
        echo "  Future<Either<RepositoryError, List<${MODEL_NAME}Model>>> $METHOD_NAME(${PARAM_CLASS_NAME} params);" >> "$REPO_ABSTRACT_FILE"
      else
        echo "  Future<Either<RepositoryError, ${MODEL_NAME}Model>> $METHOD_NAME(${PARAM_CLASS_NAME} params);" >> "$REPO_ABSTRACT_FILE"
      fi
    elif [ "$HAS_QUERY_PARAMS" = true ] || [ "$SUPPORTS_REQUEST_BODY" = true ]; then
      # Has query params or request body (may also have path params)
      if [ "$IS_LIST" = true ]; then
        echo "  Future<Either<RepositoryError, List<${MODEL_NAME}Model>>> $METHOD_NAME(${INPUT_CLASS_NAME} params);" >> "$REPO_ABSTRACT_FILE"
      else
        echo "  Future<Either<RepositoryError, ${MODEL_NAME}Model>> $METHOD_NAME(${INPUT_CLASS_NAME} params);" >> "$REPO_ABSTRACT_FILE"
      fi
    else
      # No parameters at all
      if [ "$IS_LIST" = true ]; then
        echo "  Future<Either<RepositoryError, List<${MODEL_NAME}Model>>> $METHOD_NAME();" >> "$REPO_ABSTRACT_FILE"
      else
        echo "  Future<Either<RepositoryError, ${MODEL_NAME}Model>> $METHOD_NAME();" >> "$REPO_ABSTRACT_FILE"
      fi
    fi
    
    # Add to repository implementation
    echo "" >> "$REPO_IMPL_FILE"
    echo "  @override" >> "$REPO_IMPL_FILE"
    if [ "$HAS_PATH_PARAMS" = true ] && [ "$HAS_QUERY_PARAMS" = false ] && [ "$SUPPORTS_REQUEST_BODY" = false ]; then
      # Only path parameters, no query params or request body
      if [ "$IS_LIST" = true ]; then
        echo "  Future<Either<RepositoryError, List<${MODEL_NAME}Model>>> $METHOD_NAME(${PARAM_CLASS_NAME} params) async {" >> "$REPO_IMPL_FILE"
      else
        echo "  Future<Either<RepositoryError, ${MODEL_NAME}Model>> $METHOD_NAME(${PARAM_CLASS_NAME} params) async {" >> "$REPO_IMPL_FILE"
      fi
    elif [ "$HAS_QUERY_PARAMS" = true ] || [ "$SUPPORTS_REQUEST_BODY" = true ]; then
      # Has query params or request body (may also have path params)
      if [ "$IS_LIST" = true ]; then
        echo "  Future<Either<RepositoryError, List<${MODEL_NAME}Model>>> $METHOD_NAME(${INPUT_CLASS_NAME} params) async {" >> "$REPO_IMPL_FILE"
      else
        echo "  Future<Either<RepositoryError, ${MODEL_NAME}Model>> $METHOD_NAME(${INPUT_CLASS_NAME} params) async {" >> "$REPO_IMPL_FILE"
      fi
    else
      # No parameters at all
      if [ "$IS_LIST" = true ]; then
        echo "  Future<Either<RepositoryError, List<${MODEL_NAME}Model>>> $METHOD_NAME() async {" >> "$REPO_IMPL_FILE"
      else
        echo "  Future<Either<RepositoryError, ${MODEL_NAME}Model>> $METHOD_NAME() async {" >> "$REPO_IMPL_FILE"
      fi
    fi
    echo "    try {" >> "$REPO_IMPL_FILE"
    if [ "$HAS_PATH_PARAMS" = true ] && [ "$HAS_QUERY_PARAMS" = false ] && [ "$SUPPORTS_REQUEST_BODY" = false ]; then
      # Only path parameters
      echo "      final response = await data.$METHOD_NAME(params);" >> "$REPO_IMPL_FILE"
    elif [ "$HAS_QUERY_PARAMS" = true ] || [ "$SUPPORTS_REQUEST_BODY" = true ]; then
      # Has query params or request body (may also have path params)
      echo "      final response = await data.$METHOD_NAME(params);" >> "$REPO_IMPL_FILE"
    else
      # No parameters at all
      echo "      final response = await data.$METHOD_NAME();" >> "$REPO_IMPL_FILE"
    fi
    echo "      final result = response.data;" >> "$REPO_IMPL_FILE"
    echo "" >> "$REPO_IMPL_FILE"
    echo "      if (result != null) {" >> "$REPO_IMPL_FILE"
    
    if [ "$IS_LIST" = true ]; then
      echo "        final List<dynamic> items = result is List ? result : [result];" >> "$REPO_IMPL_FILE"
      echo "        final models = items.map((item) => ${MODEL_NAME}Model.fromJson(item)).toList();" >> "$REPO_IMPL_FILE"
      echo "        return Right(models);" >> "$REPO_IMPL_FILE"
    else
      echo "        final model = ${MODEL_NAME}Model.fromJson(result);" >> "$REPO_IMPL_FILE"
      echo "        return Right(model);" >> "$REPO_IMPL_FILE"
    fi
    
    echo "      } else {" >> "$REPO_IMPL_FILE"
    echo "        return Left(handleError(error: 'No data received'));" >> "$REPO_IMPL_FILE"
    echo "      }" >> "$REPO_IMPL_FILE"
    echo "    } catch (error, stackTrace) {" >> "$REPO_IMPL_FILE"
    echo "      return Left(handleError(error: error, stackTrace: stackTrace));" >> "$REPO_IMPL_FILE"
    echo "    }" >> "$REPO_IMPL_FILE"
    echo "  }" >> "$REPO_IMPL_FILE"
    
    # Create model file
    MODEL_FILE="$FEATURE_DIR/bloc/models/${MODEL_FILE_NAME}_model.dart"
    cat > "$MODEL_FILE" <<EOF
import 'package:json_annotation/json_annotation.dart';

part '${MODEL_FILE_NAME}_model.g.dart';

@JsonSerializable()
class ${MODEL_NAME}Model {
  // TODO: Add your model fields here
  // Example:
  // final int id;
  // final String name;
  // final String? description;
  
  // const ${MODEL_NAME}Model({
  //   required this.id,
  //   required this.name,
  //   this.description,
  // });
  
  // Default constructor for json_serializable
  const ${MODEL_NAME}Model();
  
  factory ${MODEL_NAME}Model.fromJson(Map<String, dynamic> json) => _\$${MODEL_NAME}ModelFromJson(json);
  Map<String, dynamic> toJson() => _\$${MODEL_NAME}ModelToJson(this);
}
EOF

    # Create parameter class if API has ONLY path parameters (no query params or request body)
    if [ "$HAS_PATH_PARAMS" = true ] && [ "$HAS_QUERY_PARAMS" = false ] && [ "$SUPPORTS_REQUEST_BODY" = false ]; then
      PARAM_FILE="$FEATURE_DIR/bloc/models/${MODEL_FILE_NAME}_params.dart"
      cat > "$PARAM_FILE" <<EOF
import 'package:json_annotation/json_annotation.dart';

part '${MODEL_FILE_NAME}_params.g.dart';

@JsonSerializable()
class ${PARAM_CLASS_NAME} {
  // TODO: Add your parameter fields here based on the API path parameters
  // Example for /api/users/{id}:
  // final String id;
  
  // const ${PARAM_CLASS_NAME}({
  //   required this.id,
  // });
  
  // Default constructor for json_serializable
  const ${PARAM_CLASS_NAME}();
  
  factory ${PARAM_CLASS_NAME}.fromJson(Map<String, dynamic> json) => _\$${PARAM_CLASS_NAME}FromJson(json);
  Map<String, dynamic> toJson() => _\$${PARAM_CLASS_NAME}ToJson(this);
}
EOF
    fi
    
    # Create input class if API has query parameters or supports request body
    if [ "$HAS_QUERY_PARAMS" = true ] || [ "$SUPPORTS_REQUEST_BODY" = true ]; then
      INPUT_FILE="$FEATURE_DIR/bloc/models/${MODEL_FILE_NAME}_input.dart"
      
      cat > "$INPUT_FILE" <<EOF
import 'package:json_annotation/json_annotation.dart';

part '${MODEL_FILE_NAME}_input.g.dart';

@JsonSerializable()
class ${INPUT_CLASS_NAME} {
EOF
      
      # Add fields for query parameters if they exist
      if [ -n "$QUERY_PARAMS" ]; then
        echo "$QUERY_PARAMS" | while read -r param; do
          if [ -n "$param" ] && [[ "$param" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            # Convert parameter name to camelCase
            CAMEL_PARAM=$(echo "$param" | sed 's/_\([a-z]\)/\U\1/g')
            echo "  // TODO: Add proper type for $param" >> "$INPUT_FILE"
            echo "  final String? $CAMEL_PARAM;" >> "$INPUT_FILE"
          fi
        done
      fi
      
      # Add path parameter fields if API has path parameters
      if [ "$HAS_PATH_PARAMS" = true ]; then
        if [ -n "$QUERY_PARAMS" ]; then
          echo "" >> "$INPUT_FILE"
        fi
        echo "  // TODO: Add path parameter fields here" >> "$INPUT_FILE"
        echo "  // Example for /api/users/{id}:" >> "$INPUT_FILE"
        echo "  // final String id;" >> "$INPUT_FILE"
      fi
      
      # Add request body fields if method supports request body
      if [ "$SUPPORTS_REQUEST_BODY" = true ]; then
        if [ -n "$QUERY_PARAMS" ] || [ "$HAS_PATH_PARAMS" = true ]; then
          echo "" >> "$INPUT_FILE"
        fi
        echo "  // TODO: Add request body fields here" >> "$INPUT_FILE"
        echo "  // Example:" >> "$INPUT_FILE"
        echo "  // final String name;" >> "$INPUT_FILE"
        echo "  // final String email;" >> "$INPUT_FILE"
        echo "  // final int age;" >> "$INPUT_FILE"
      fi
      
      # Add constructor
      echo "" >> "$INPUT_FILE"
      if [ -n "$QUERY_PARAMS" ]; then
        echo "  const ${INPUT_CLASS_NAME}({" >> "$INPUT_FILE"
        echo "$QUERY_PARAMS" | while read -r param; do
          if [ -n "$param" ] && [[ "$param" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            CAMEL_PARAM=$(echo "$param" | sed 's/_\([a-z]\)/\U\1/g')
            echo "    this.$CAMEL_PARAM," >> "$INPUT_FILE"
          fi
        done
        echo "  });" >> "$INPUT_FILE"
      else
        echo "  const ${INPUT_CLASS_NAME}();" >> "$INPUT_FILE"
      fi
      echo "" >> "$INPUT_FILE"
      echo "  factory ${INPUT_CLASS_NAME}.fromJson(Map<String, dynamic> json) => _\$${INPUT_CLASS_NAME}FromJson(json);" >> "$INPUT_FILE"
      echo "  Map<String, dynamic> toJson() => _\$${INPUT_CLASS_NAME}ToJson(this);" >> "$INPUT_FILE"
      echo "}" >> "$INPUT_FILE"
    fi
    
    echo "  - Processed API: $api_name ($method $url)"
  fi
done <<< "$APIS"

# Close the class definitions
echo "}" >> "$DATA_ABSTRACT_FILE"
echo "}" >> "$DATA_IMPL_FILE"

# Add provider to data implementation file
echo "" >> "$DATA_IMPL_FILE"
echo "final ${FEATURE_SNAKE_NAME}DataProvider = Provider<I${FEATURE_CLASS_NAME}Data>((ref) {" >> "$DATA_IMPL_FILE"
echo "  final dio = ref.read(appDio);" >> "$DATA_IMPL_FILE"
echo "  return ${FEATURE_CLASS_NAME}Data(dio: dio);" >> "$DATA_IMPL_FILE"
echo "});" >> "$DATA_IMPL_FILE"

echo "}" >> "$REPO_ABSTRACT_FILE"
echo "}" >> "$REPO_IMPL_FILE"

# Add provider to repository implementation file
echo "" >> "$REPO_IMPL_FILE"
echo "final ${FEATURE_SNAKE_NAME}RepositoryProvider = Provider<I${FEATURE_CLASS_NAME}Repository>((ref) {" >> "$REPO_IMPL_FILE"
echo "  final data = ref.read(${FEATURE_SNAKE_NAME}DataProvider);" >> "$REPO_IMPL_FILE"
echo "  return ${FEATURE_CLASS_NAME}Repository(data);" >> "$REPO_IMPL_FILE"
echo "});" >> "$REPO_IMPL_FILE"

# Create a models index file
MODELS_INDEX_FILE="$FEATURE_DIR/bloc/models/models.dart"
cat > "$MODELS_INDEX_FILE" <<EOF
// Export all models here
EOF

# Add model exports
for model_file in "$FEATURE_DIR/bloc/models"/*.dart; do
  if [ -f "$model_file" ] && [[ "$(basename "$model_file")" != "models.dart" ]]; then
    model_name=$(basename "$model_file" .dart)
    echo "export '$model_name.dart';" >> "$MODELS_INDEX_FILE"
  fi
done

echo ""
echo "✅ Successfully converted Postman collection to Dart implementation!"
echo "📁 Feature directory: $FEATURE_DIR"
echo "📊 Processed $API_COUNT APIs"
echo ""
echo "📝 Next steps:"
echo "1. Review and update the generated models in $FEATURE_DIR/bloc/models/"
echo "2. Run 'dart run build_runner build' to generate JSON serialization code"
echo "3. Update the model fields based on your API responses"
echo "4. Test the generated implementation"
echo ""
echo "🔧 Generated files:"
echo "  - Data abstraction: $DATA_ABSTRACT_FILE"
echo "  - Data implementation: $DATA_IMPL_FILE"
echo "  - Repository abstraction: $REPO_ABSTRACT_FILE"
echo "  - Repository implementation: $REPO_IMPL_FILE"
echo "  - Provider: $PROVIDER_FILE"
echo "  - Models: $FEATURE_DIR/bloc/models/"

# Run build_runner to generate JSON serialization code
echo ""
echo "🔄 Running build_runner to generate JSON serialization code..."
dart run build_runner build --delete-conflicting-outputs

echo ""
echo "✅ Build runner completed! JSON serialization code generated." 