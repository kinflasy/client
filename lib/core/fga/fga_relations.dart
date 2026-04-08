class FgaObject {
  static String unit(String id) => 'unit:$id';

  static String church(String id) => 'church:$id';

  static String department(String id) => 'department:$id';

  static String membership(String id) => 'membership:$id';

  static String personData(String id) => 'person_data:$id';
}

class FgaRelation {
  static const admin = 'admin';
  static const member = 'member';
  static const congregated = 'congregated';
  static const visitor = 'visitor';
  static const leader = 'leader';
  static const canEdit = 'can_edit';
  static const canView = 'can_view';
  static const canManage = 'can_manage';
  static const canObserve = 'can_observe';
}
