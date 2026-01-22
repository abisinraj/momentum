# Code Regeneration Required

After merging this PR, you will need to regenerate the Riverpod provider code:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

This is required because the `currentCyclePosition` provider was changed from a synchronous `int` provider to an asynchronous `Future<int>` provider.

## What Changed

The `currentCyclePosition` provider in `lib/core/providers/core_providers.dart` now properly fetches the current cycle position from the database instead of returning a hardcoded `0`.

This change requires the Riverpod code generator to regenerate `lib/core/providers/core_providers.g.dart`.

## Impact

- No existing code uses `currentCyclePosition` provider yet, so there are no breaking changes to existing functionality
- The generated provider type will change from `AutoDisposeProvider<int>` to `AutoDisposeFutureProvider<int>`
- Any future consumers will need to use `ref.watch(currentCyclePositionProvider).when(...)` to handle the async state
