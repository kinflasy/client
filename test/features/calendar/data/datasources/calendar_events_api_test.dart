import 'package:client/features/calendar/data/datasources/calendar_events_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late CalendarEventsApi api;

  setUpAll(() {
    registerFallbackValue(FormData());
  });

  setUp(() {
    dio = _MockDio();
    api = CalendarEventsApi(dio);
  });

  test('normalizes enveloped create response', () async {
    when(
      () => dio.post<dynamic>(
        '/v1/core/calendar-events/unit/unit-1',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/unit/unit-1',
        ),
        data: {
          'data': {'id': 'event-1'},
        },
      ),
    );

    final json = await api.createUnitEvent('unit-1', {'title': 'Evento'});

    expect(json, {'id': 'event-1'});
  });

  test('normalizes list create response', () async {
    when(
      () => dio.post<dynamic>(
        '/v1/core/calendar-events/department/dep-1',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/department/dep-1',
        ),
        data: [
          {'id': 'event-1'},
        ],
      ),
    );

    final json = await api.createDepartmentEvent('dep-1', {'title': 'Evento'});

    expect(json, {'id': 'event-1'});
  });

  test('normalizes enveloped event list response', () async {
    final start = DateTime(2026, 5);
    final end = DateTime(2026, 6);
    when(
      () => dio.get<dynamic>(
        '/v1/core/calendar-events/unit/unit-1',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/unit/unit-1',
        ),
        data: {
          'content': [
            {'id': 'event-1'},
          ],
        },
      ),
    );

    final list = await api.getUnitEvents('unit-1', start, end);

    expect(list, [
      {'id': 'event-1'},
    ]);
  });

  test('gets visible events using range query', () async {
    final start = DateTime(2026, 5, 30, 9);
    final end = DateTime(2026, 11, 30, 23, 59, 59);
    when(
      () => dio.get<dynamic>(
        '/v1/core/calendar-events/visible',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/visible',
        ),
        data: [
          {'id': 'event-1'},
        ],
      ),
    );

    final list = await api.getVisibleEvents(start, end);

    expect(list, [
      {'id': 'event-1'},
    ]);
    verify(
      () => dio.get<dynamic>(
        '/v1/core/calendar-events/visible',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      ),
    ).called(1);
  });

  test('gets department events with collabs using range query', () async {
    final start = DateTime(2026, 5, 30, 9);
    final end = DateTime(2026, 11, 30, 23, 59, 59);
    when(
      () => dio.get<dynamic>(
        '/v1/core/calendar-events/department/dep-1/with-collabs',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/department/dep-1/with-collabs',
        ),
        data: {
          'events': [
            {'id': 'event-1'},
          ],
        },
      ),
    );

    final list = await api.getDepartmentEventsWithCollabs('dep-1', start, end);

    expect(list, [
      {'id': 'event-1'},
    ]);
    verify(
      () => dio.get<dynamic>(
        '/v1/core/calendar-events/department/dep-1/with-collabs',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      ),
    ).called(1);
  });

  test('gets unit birthdays using MonthDay path params', () async {
    when(
      () => dio.get<dynamic>('/v1/core/church/units/birthdays/--06-01/--06-30'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/units/birthdays/--06-01/--06-30',
        ),
        data: [
          {'id': 'person-1', 'birthday': '--06-07'},
        ],
      ),
    );

    final list = await api.getUnitBirthdays('--06-01', '--06-30');

    expect(list, [
      {'id': 'person-1', 'birthday': '--06-07'},
    ]);
    verify(
      () => dio.get<dynamic>('/v1/core/church/units/birthdays/--06-01/--06-30'),
    ).called(1);
  });

  test('normalizes enveloped unit birthdays response', () async {
    when(
      () => dio.get<dynamic>('/v1/core/church/units/birthdays/--06-01/--06-30'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/church/units/birthdays/--06-01/--06-30',
        ),
        data: {
          'birthdays': [
            {'id': 'person-1', 'birthday': '--06-07'},
          ],
        },
      ),
    );

    final list = await api.getUnitBirthdays('--06-01', '--06-30');

    expect(list, [
      {'id': 'person-1', 'birthday': '--06-07'},
    ]);
  });

  test('sends card image upload as multipart file field', () async {
    when(
      () => dio.put<dynamic>(
        '/v1/core/calendar-events/event-1/card-image',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/event-1/card-image',
        ),
        data: {'id': 'event-1'},
      ),
    );

    final file = MultipartFile.fromBytes([1, 2, 3], filename: 'card.png');

    await api.updateCardImage('event-1', file);

    final data =
        verify(
              () => dio.put<dynamic>(
                '/v1/core/calendar-events/event-1/card-image',
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as FormData;

    expect(data.files, hasLength(1));
    expect(data.files.single.key, 'file');
    expect(data.files.single.value.filename, 'card.png');
  });

  test('gets collaborators using event route', () async {
    when(
      () => dio.get<dynamic>('/v1/core/calendar-events/event-1/collaborators'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/event-1/collaborators',
        ),
        data: {
          'data': [
            {'id': 'collab-1'},
          ],
        },
      ),
    );

    final list = await api.getCollaborators('event-1');

    expect(list, [
      {'id': 'collab-1'},
    ]);
  });

  test('adds collaborator using department route parameter', () async {
    when(
      () => dio.post<dynamic>(
        '/v1/core/calendar-events/event-1/collaborators/dep-1',
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/event-1/collaborators/dep-1',
        ),
        data: {
          'data': {'id': 'collab-1'},
        },
      ),
    );

    final json = await api.addCollaborator('event-1', 'dep-1');

    expect(json, {'id': 'collab-1'});
  });

  test('removes collaborator using department route parameter', () async {
    when(
      () => dio.delete<void>(
        '/v1/core/calendar-events/event-1/collaborators/dep-1',
      ),
    ).thenAnswer(
      (_) async => Response<void>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/event-1/collaborators/dep-1',
        ),
      ),
    );

    await api.removeCollaborator('event-1', 'dep-1');

    verify(
      () => dio.delete<void>(
        '/v1/core/calendar-events/event-1/collaborators/dep-1',
      ),
    ).called(1);
  });

  test('gets event scales using event route', () async {
    when(
      () => dio.get<dynamic>('/v1/core/calendar-events/event-1/scales'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/event-1/scales',
        ),
        data: {
          'scales': [
            {'id': 'scale-1'},
          ],
        },
      ),
    );

    final list = await api.getEventScales('event-1');

    expect(list, [
      {'id': 'scale-1'},
    ]);
  });

  test('creates event scale with lineup payload', () async {
    when(
      () => dio.post<dynamic>(
        '/v1/core/calendar-events/event-1/scales',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/event-1/scales',
        ),
        data: {
          'scale': {'id': 'scale-1', 'lineupId': 'lineup-1'},
        },
      ),
    );

    final json = await api.createEventScale('event-1', {
      'lineupId': 'lineup-1',
    });

    expect(json, {'id': 'scale-1', 'lineupId': 'lineup-1'});
    verify(
      () => dio.post<dynamic>(
        '/v1/core/calendar-events/event-1/scales',
        data: {'lineupId': 'lineup-1'},
      ),
    ).called(1);
  });

  test('creates collaborator event scale with lineup payload', () async {
    when(
      () => dio.post<dynamic>(
        '/v1/core/calendar-events/event-1/collaborators/dep-1/scales',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/event-1/collaborators/dep-1/scales',
        ),
        data: {
          'scale': {
            'id': 'scale-1',
            'lineupId': 'lineup-1',
            'type': 'COLLABORATOR',
            'collaborationId': 'collab-1',
          },
        },
      ),
    );

    final json = await api.createCollaboratorEventScale('event-1', 'dep-1', {
      'lineupId': 'lineup-1',
    });

    expect(json, {
      'id': 'scale-1',
      'lineupId': 'lineup-1',
      'type': 'COLLABORATOR',
      'collaborationId': 'collab-1',
    });
    verify(
      () => dio.post<dynamic>(
        '/v1/core/calendar-events/event-1/collaborators/dep-1/scales',
        data: {'lineupId': 'lineup-1'},
      ),
    ).called(1);
  });

  test('gets scale by id using scale route', () async {
    when(
      () => dio.get<dynamic>('/v1/core/calendar-events/scales/scale-1'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/scales/scale-1',
        ),
        data: {
          'scale': {
            'id': 'scale-1',
            'lineupId': 'lineup-1',
            'type': 'OWNER',
            'calendarEventId': 'event-1',
          },
        },
      ),
    );

    final json = await api.getScaleById('scale-1');

    expect(json, {
      'id': 'scale-1',
      'lineupId': 'lineup-1',
      'type': 'OWNER',
      'calendarEventId': 'event-1',
    });
    verify(
      () => dio.get<dynamic>('/v1/core/calendar-events/scales/scale-1'),
    ).called(1);
  });

  test('gets scale items using scale items route', () async {
    when(
      () => dio.get<dynamic>('/v1/core/calendar-events/scales/scale-1/items'),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/scales/scale-1/items',
        ),
        data: {
          'items': [
            {'id': 'item-1'},
          ],
        },
      ),
    );

    final list = await api.getScaleItems('scale-1');

    expect(list, [
      {'id': 'item-1'},
    ]);
    verify(
      () => dio.get<dynamic>('/v1/core/calendar-events/scales/scale-1/items'),
    ).called(1);
  });

  test('gets my scales using range query', () async {
    final start = DateTime(2026, 5, 30, 9);
    final end = DateTime(2026, 11, 30, 23, 59, 59);
    when(
      () => dio.get<dynamic>(
        '/v1/core/calendar-events/scales/person',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/scales/person',
        ),
        data: [
          {'id': 'scale-1'},
        ],
      ),
    );

    final list = await api.getMyScales(start, end);

    expect(list, [
      {'id': 'scale-1'},
    ]);
    verify(
      () => dio.get<dynamic>(
        '/v1/core/calendar-events/scales/person',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      ),
    ).called(1);
  });

  test('normalizes enveloped my scales response', () async {
    final start = DateTime(2026, 5, 30, 9);
    final end = DateTime(2026, 11, 30, 23, 59, 59);
    when(
      () => dio.get<dynamic>(
        '/v1/core/calendar-events/scales/person',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/scales/person',
        ),
        data: {
          'scales': [
            {'id': 'scale-1'},
          ],
        },
      ),
    );

    final list = await api.getMyScales(start, end);

    expect(list, [
      {'id': 'scale-1'},
    ]);
  });

  test('adds scale item using scale items route', () async {
    when(
      () => dio.post<dynamic>(
        '/v1/core/calendar-events/scales/scale-1/items',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/scales/scale-1/items',
        ),
        data: {
          'item': {
            'id': 'item-1',
            'scaleId': 'scale-1',
            'roleId': 'role-1',
            'personId': 'person-1',
          },
        },
      ),
    );

    final json = await api.addScaleItem('scale-1', {
      'roleId': 'role-1',
      'personId': 'person-1',
    });

    expect(json, {
      'id': 'item-1',
      'scaleId': 'scale-1',
      'roleId': 'role-1',
      'personId': 'person-1',
    });
    verify(
      () => dio.post<dynamic>(
        '/v1/core/calendar-events/scales/scale-1/items',
        data: {'roleId': 'role-1', 'personId': 'person-1'},
      ),
    ).called(1);
  });

  test('removes scale item with request body', () async {
    when(
      () => dio.delete<void>(
        '/v1/core/calendar-events/scales/scale-1/items',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<void>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/scales/scale-1/items',
        ),
      ),
    );

    await api.removeScaleItem('scale-1', {
      'roleId': 'role-1',
      'personId': 'person-1',
    });

    verify(
      () => dio.delete<void>(
        '/v1/core/calendar-events/scales/scale-1/items',
        data: {'roleId': 'role-1', 'personId': 'person-1'},
      ),
    ).called(1);
  });

  test('gets department scales using range query', () async {
    final start = DateTime(2026, 5, 30, 9);
    final end = DateTime(2026, 11, 30, 23, 59, 59);
    when(
      () => dio.get<dynamic>(
        '/v1/core/calendar-events/scales/department/dep-1',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/core/calendar-events/scales/department/dep-1',
        ),
        data: {
          'scales': [
            {'id': 'scale-1'},
          ],
        },
      ),
    );

    final list = await api.getDepartmentScales('dep-1', start, end);

    expect(list, [
      {'id': 'scale-1'},
    ]);
    verify(
      () => dio.get<dynamic>(
        '/v1/core/calendar-events/scales/department/dep-1',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      ),
    ).called(1);
  });
}
