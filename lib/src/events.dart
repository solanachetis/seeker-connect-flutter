import 'errors.dart';

/// A wallet interaction lifecycle event, used to drive progress/error UI.
sealed class SeekerInteractionEvent {
  const SeekerInteractionEvent();
}

/// A wallet interaction started. Pass [id] to `SeekerConnect.cancelInteraction` to cancel it.
class SeekerInteractionStarted extends SeekerInteractionEvent {
  const SeekerInteractionStarted(this.id);
  final int id;
}

/// The interaction [id] ended (successfully or not).
class SeekerInteractionSettled extends SeekerInteractionEvent {
  const SeekerInteractionSettled(this.id);
  final int id;
}

/// The last interaction failed with [code].
class SeekerInteractionFailed extends SeekerInteractionEvent {
  const SeekerInteractionFailed(this.code);
  final SeekerConnectErrorCode code;
}
