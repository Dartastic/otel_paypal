// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_paypal/otel_paypal.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_paypal-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('orders.capture records CLIENT span', () async {
    await tracedPaypal<String>(
      resource: 'orders',
      action: 'capture',
      orderId: '9X-99',
      captureId: 'cap-1',
      environment: 'sandbox',
      invoke: () async => 'captured',
    );
    final a = attrsOf(spans.findSpanByName('paypal orders.capture')!);
    expect(a['paypal.resource'], 'orders');
    expect(a['paypal.action'], 'capture');
    expect(a['paypal.operation'], 'orders.capture');
    expect(a['paypal.order.id'], '9X-99');
    expect(a['paypal.capture.id'], 'cap-1');
    expect(a['paypal.environment'], 'sandbox');
  });

  test('suppression skips spans', () async {
    await runWithoutPaypalInstrumentationAsync(() async {
      await tracedPaypal<String>(
        resource: 'orders',
        action: 'capture',
        invoke: () async => 'c',
      );
    });
    expect(spans.findSpansStartingWith('paypal '), isEmpty);
  });
}
