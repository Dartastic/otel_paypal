// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_paypal_suppression.dart';

const _tracerName = 'dartastic_otel_libs_paypal';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps any PayPal REST API call in a CLIENT span. [resource] is
/// one of `orders`, `payments`, `subscriptions`, etc.; [action] is
/// `create`, `capture`, `refund`, `get`, etc.
Future<T> tracedPaypal<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? orderId,
  String? captureId,
  String? subscriptionId,
  String? environment,
}) async {
  if (paypalInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'paypal.resource': resource,
    'paypal.action': action,
    'paypal.operation': '$resource.$action',
  };
  if (orderId != null) m['paypal.order.id'] = orderId;
  if (captureId != null) m['paypal.capture.id'] = captureId;
  if (subscriptionId != null) m['paypal.subscription.id'] = subscriptionId;
  if (environment != null) m['paypal.environment'] = environment;

  final span = _tracer().startSpan(
    'paypal $resource.$action',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
