// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_paypal/otel_paypal.dart';

/// Traces Paypal calls with OpenTelemetry.
///
/// `otel_paypal` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Paypal call in
/// [tracedPaypal]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'paypal-example');

  // Wraps any PayPal REST API call in a CLIENT span.
  final paypalId = await tracedPaypal<String>(
    resource: 'orders',
    action: 'create',
    orderId: 'order_8f3a2c',
    captureId: 'capture_8f3a2c',
    subscriptionId: 'subscription_8f3a2c',
    environment: 'example',
    invoke: () async {
      // Make the Paypal call here, then report what it returned.
      return 'paypal_8f3a2c';
    },
  );
  OTelLog.info('tracedPaypal returned $paypalId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutPaypalInstrumentationAsync.
  await runWithoutPaypalInstrumentationAsync(
    () => tracedPaypal<String>(
      resource: 'orders',
      action: 'create',
      orderId: 'order_8f3a2c',
      captureId: 'capture_8f3a2c',
      subscriptionId: 'subscription_8f3a2c',
      environment: 'example',
      invoke: () async {
        return 'paypal_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
