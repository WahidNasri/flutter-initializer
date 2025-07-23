#!/bin/bash

set -e

# Usage: ./feature.sh create <feature_name> [--with-screen=true|false] [--fill-bloc=true|false]

COMMAND=$1
FEATURE_NAME=$2
shift 2
WITH_SCREEN=false
FILL_BLOC=false

# Manual argument parsing for optional flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --with-screen)
      WITH_SCREEN=$2
      shift 2
      ;;
    --with-screen=*)
      WITH_SCREEN="${1#*=}"
      shift 1
      ;;
    --fill-bloc)
      FILL_BLOC=$2
      shift 2
      ;;
    --fill-bloc=*)
      FILL_BLOC="${1#*=}"
      shift 1
      ;;
    *)
      shift 1
      ;;
  esac
done

if [ "$COMMAND" != "create" ] || [ -z "$FEATURE_NAME" ]; then
  echo "Usage: $0 create <feature_name> [--with-screen true|false] [--fill-bloc true|false]"
  exit 1
fi

# Normalize --with-screen=true to --with-screen true, and same for --fill-bloc
if [[ "$WITH_SCREEN" == *=* ]]; then
  WITH_SCREEN="${WITH_SCREEN#*=}"
fi
if [[ "$FILL_BLOC" == *=* ]]; then
  FILL_BLOC="${FILL_BLOC#*=}"
fi

FEATURE_DIR="lib/features/$FEATURE_NAME"

# Create directory structure
mkdir -p "$FEATURE_DIR/bloc/data/implementation"
mkdir -p "$FEATURE_DIR/bloc/repositories/implementation"
mkdir -p "$FEATURE_DIR/bloc/models"
mkdir -p "$FEATURE_DIR/bloc/providers"
mkdir -p "$FEATURE_DIR/ui"

if [ "$WITH_SCREEN" = "true" ]; then
  mkdir -p "$FEATURE_DIR/ui/screens"
fi

echo "Feature structure created for $FEATURE_NAME."
echo "FILL_BLOC is: $FILL_BLOC"

if [ "$FILL_BLOC" = "true" ]; then
  echo "Entering BLoC file generation block..."
  # Format feature name for class names (PascalCase)
  FEATURE_CLASS_NAME=$(echo "$FEATURE_NAME" | awk -F'_' '{for(i=1;i<=NF;i++){printf toupper(substr($i,1,1)) tolower(substr($i,2))}}')
  FEATURE_SNAKE_NAME=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]')

  # bloc/data/i_<feature_name>_data.dart
  DATA_ABSTRACT_FILE="$FEATURE_DIR/bloc/data/i_${FEATURE_SNAKE_NAME}_data.dart"
  cat > "$DATA_ABSTRACT_FILE" <<EOF
abstract class I${FEATURE_CLASS_NAME}Data {}
EOF

  # bloc/data/implementation/<FeatureName>Data.dart
  DATA_IMPL_FILE="$FEATURE_DIR/bloc/data/implementation/${FEATURE_CLASS_NAME}Data.dart"
  cat > "$DATA_IMPL_FILE" <<EOF
import '../i_${FEATURE_SNAKE_NAME}_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ${FEATURE_CLASS_NAME}Data implements I${FEATURE_CLASS_NAME}Data {}

final ${FEATURE_SNAKE_NAME}DataProvider = Provider<I${FEATURE_CLASS_NAME}Data>((ref) => ${FEATURE_CLASS_NAME}Data());
EOF

  # bloc/repositories/i_<feature_name>_repository.dart
  REPO_ABSTRACT_FILE="$FEATURE_DIR/bloc/repositories/i_${FEATURE_SNAKE_NAME}_repository.dart"
  cat > "$REPO_ABSTRACT_FILE" <<EOF
abstract class I${FEATURE_CLASS_NAME}Repository {}
EOF

  # bloc/repositories/implementation/<feature_name>_repository.dart
  REPO_IMPL_FILE="$FEATURE_DIR/bloc/repositories/implementation/${FEATURE_SNAKE_NAME}_repository.dart"
  cat > "$REPO_IMPL_FILE" <<EOF
import '../i_${FEATURE_SNAKE_NAME}_repository.dart';
import '../../data/i_${FEATURE_SNAKE_NAME}_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/implementation/${FEATURE_CLASS_NAME}Data.dart';

class ${FEATURE_CLASS_NAME}Repository implements I${FEATURE_CLASS_NAME}Repository {
  final I${FEATURE_CLASS_NAME}Data data;
  ${FEATURE_CLASS_NAME}Repository(this.data);
}

final ${FEATURE_SNAKE_NAME}RepositoryProvider = Provider<I${FEATURE_CLASS_NAME}Repository>((ref) {
  final data = ref.read(${FEATURE_SNAKE_NAME}DataProvider);
  return ${FEATURE_CLASS_NAME}Repository(data);
});
EOF

  # bloc/providers/<feature_name>_provider.dart
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

  echo "BLoC files generated for $FEATURE_NAME."
fi

if [ "$WITH_SCREEN" = "true" ]; then
  mkdir -p "$FEATURE_DIR/ui/screens"
  mkdir -p "$FEATURE_DIR/ui/widgets"
  SCREEN_FILE="$FEATURE_DIR/ui/screens/${FEATURE_SNAKE_NAME}_screen.dart"
  cat > "$SCREEN_FILE" <<EOF
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class ${FEATURE_CLASS_NAME}Screen extends ConsumerStatefulWidget {
  const ${FEATURE_CLASS_NAME}Screen({super.key});

  @override
  ConsumerState<${FEATURE_CLASS_NAME}Screen> createState() => _${FEATURE_CLASS_NAME}ScreenState();
}

class _${FEATURE_CLASS_NAME}ScreenState extends ConsumerState<${FEATURE_CLASS_NAME}Screen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('${FEATURE_CLASS_NAME}')),
      body: const Center(child: Text('${FEATURE_CLASS_NAME} Screen')),
    );
  }
}
EOF
  echo "Screen file generated for $FEATURE_NAME."

  # Add import and route to app_router.dart
  ROUTER_FILE="lib/base/router/app_router.dart"
  ROUTE_ENTRY="    AutoRoute(page:${FEATURE_CLASS_NAME}Route.page),"


  # Insert route if not present
  grep -qxF "$ROUTE_ENTRY" "$ROUTER_FILE" || \
    sed -i '' "/List<AutoRoute> get routes => \[/a\\
$ROUTE_ENTRY
" "$ROUTER_FILE"

  # Run build_runner
  echo "Running build_runner..."
  dart run build_runner build --delete-conflicting-outputs
fi
