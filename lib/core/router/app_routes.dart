class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const homeFeed = '/home/feed';
  static const homeCalendar = '/home/calendar';
  static const homeChurch = '/home/church';
  static const homeChurchDepartmentsCategory =
      '/home/church/departamentos/categoria/:category';
  static const homeChurchDepartmentDetail = '/home/church/departamentos/:id';
  static const homeMenu = '/home/menu';
  static const homeMenuMyDepartments = '/home/menu/meus-departamentos';
  static const homeMenuEditProfile = '/home/menu/editar-informacoes';
  static const homeMenuEditProfileInfo = '/home/menu/editar-informacoes/dados';
  static const homeMenuEditProfilePhoto = '/home/menu/editar-informacoes/foto';
  static const registerChurch = '/register-church';
  static const churchSearch = '/church-search';
  static const churchProfile = '/church/:id';
  static const churchPublicProfile = '/church/:id/info';
  static const peopleList = '/people';
  static const peopleDetail = '/people/:id';
  static const peopleEdit = '/people/:id/edit';
  static const adminPanel = '/admin/gestao';
  static const adminMembers = '/admin/membros';
  static const adminMembershipRequests = '/admin/membros/solicitacoes';
  static const adminMembersRegister = '/admin/membros/cadastrar';
  static const adminDepartments = '/admin/departamentos';
  static const adminDepartmentsRegister = '/admin/departamentos/cadastrar';
  static const adminGeneralInfo = '/admin/informacoes-gerais';
  static const adminGeneralInfoIdentityEdit =
      '/admin/informacoes-gerais/editar-identidade';
  static const adminGeneralInfoAddressEdit =
      '/admin/informacoes-gerais/editar-endereco';
  static const adminGeneralInfoLinks = '/admin/informacoes-gerais/links';
  static const adminGeneralInfoImages = '/admin/informacoes-gerais/imagens';
  static const adminCalendar = '/admin/calendario';
  static const adminCalendarCreate = '/admin/calendario/criar';
  static const adminCalendarEdit = '/admin/calendario/:id/editar';
  static const departmentDetail = '/departamentos/:id';
  static const departmentEventCreate = '/departamentos/:id/eventos/criar';
  static const departmentParticipantsAdd =
      '/departamentos/:id/participantes/adicionar';

  static const splashName = 'splash';
  static const loginName = 'login';
  static const registerName = 'register';
  static const homeFeedName = 'home-feed';
  static const homeCalendarName = 'home-calendar';
  static const homeChurchName = 'home-church';
  static const homeChurchDepartmentsCategoryName =
      'home-church-departments-category';
  static const homeChurchDepartmentDetailName = 'home-church-department-detail';
  static const homeMenuName = 'home-menu';
  static const homeMenuMyDepartmentsName = 'home-menu-my-departments';
  static const homeMenuEditProfileName = 'home-menu-edit-profile';
  static const homeMenuEditProfileInfoName = 'home-menu-edit-profile-info';
  static const homeMenuEditProfilePhotoName = 'home-menu-edit-profile-photo';
  static const registerChurchName = 'register-church';
  static const churchSearchName = 'church-search';
  static const churchProfileName = 'church-profile';
  static const churchPublicProfileName = 'church-public-profile';
  static const peopleDetailName = 'people-detail';
  static const peopleEditName = 'people-edit';
  static const adminPanelName = 'admin-panel';
  static const adminMembersName = 'admin-members';
  static const adminMembershipRequestsName = 'admin-membership-requests';
  static const adminMembersRegisterName = 'admin-members-register';
  static const adminDepartmentsName = 'admin-departments';
  static const adminDepartmentsRegisterName = 'admin-departments-register';
  static const adminGeneralInfoName = 'admin-general-info';
  static const adminGeneralInfoIdentityEditName =
      'admin-general-info-identity-edit';
  static const adminGeneralInfoAddressEditName =
      'admin-general-info-address-edit';
  static const adminGeneralInfoLinksName = 'admin-general-info-links';
  static const adminGeneralInfoImagesName = 'admin-general-info-images';
  static const adminCalendarName = 'admin-calendar';
  static const adminCalendarCreateName = 'admin-calendar-create';
  static const adminCalendarEditName = 'admin-calendar-edit';
  static const departmentDetailName = 'department-detail';
  static const departmentEventCreateName = 'department-event-create';
  static const departmentParticipantsAddName = 'department-participants-add';
}
