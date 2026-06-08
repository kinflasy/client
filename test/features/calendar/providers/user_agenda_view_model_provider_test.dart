import 'package:client/features/calendar/providers/user_agenda_providers.dart';
import 'package:client/features/calendar/providers/user_agenda_view_model_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        userAgendaTodayProvider.overrideWithValue(DateTime(2026, 6, 3)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('estado inicial seleciona hoje e mostra a semana inteira', () {
    final state = container.read(userAgendaViewModelProvider);

    expect(state.today, DateTime(2026, 6, 3));
    expect(state.selectedDate, DateTime(2026, 6, 3));
    expect(state.focusedMonth, DateTime(2026, 6));
    expect(state.visibleWeekStart, DateTime(2026, 5, 31));
    expect(state.visibleWeekEnd, DateTime(2026, 6, 6));
    expect(state.weeklyGroups.map((group) => group.date), [
      DateTime(2026, 5, 31),
      DateTime(2026, 6),
      DateTime(2026, 6, 2),
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 4),
      DateTime(2026, 6, 5),
      DateTime(2026, 6, 6),
    ]);
  });

  test('estado inicial nao define alvo de foco', () {
    final state = container.read(userAgendaViewModelProvider);

    expect(state.focusTargetDate, isNull);
  });

  test('selecionar dia pelo usuario define alvo de foco', () {
    final notifier = container.read(userAgendaViewModelProvider.notifier);

    notifier.selectDate(DateTime(2026, 6, 5, 18));
    final state = container.read(userAgendaViewModelProvider);

    expect(state.selectedDate, DateTime(2026, 6, 5));
    expect(state.focusTargetDate, DateTime(2026, 6, 5));
    expect(state.visibleWeekStart, DateTime(2026, 5, 31));
    expect(state.visibleWeekEnd, DateTime(2026, 6, 6));
  });

  test('troca para mes anterior selecionando o primeiro dia do mes', () {
    final notifier = container.read(userAgendaViewModelProvider.notifier);

    notifier.goToPreviousMonth();
    final state = container.read(userAgendaViewModelProvider);

    expect(state.focusedMonth, DateTime(2026, 5));
    expect(state.selectedDate, DateTime(2026, 5));
    expect(state.visibleWeekStart, DateTime(2026, 4, 26));
    expect(state.visibleWeekEnd, DateTime(2026, 5, 2));
    expect(state.focusTargetDate, isNull);
  });

  test('troca para proximo mes selecionando o primeiro dia do mes', () {
    final notifier = container.read(userAgendaViewModelProvider.notifier);

    notifier.goToNextMonth();
    final state = container.read(userAgendaViewModelProvider);

    expect(state.focusedMonth, DateTime(2026, 7));
    expect(state.selectedDate, DateTime(2026, 7));
    expect(state.visibleWeekStart, DateTime(2026, 6, 28));
    expect(state.visibleWeekEnd, DateTime(2026, 7, 4));
    expect(state.focusTargetDate, isNull);
  });

  test('botao Hoje retorna para mes e semana atuais', () {
    final notifier = container.read(userAgendaViewModelProvider.notifier);

    notifier.goToNextMonth();
    notifier.goToToday();
    final state = container.read(userAgendaViewModelProvider);

    expect(state.focusedMonth, DateTime(2026, 6));
    expect(state.selectedDate, DateTime(2026, 6, 3));
    expect(state.visibleWeekStart, DateTime(2026, 5, 31));
    expect(state.visibleWeekEnd, DateTime(2026, 6, 6));
    expect(state.focusTargetDate, isNull);
  });
}
