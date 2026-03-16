enum Affiliation {
  unauthenticated, // sem sessão ativa
  visitor, // logado, sem membership ou affiliation=VISITOR
  congregated, // affiliation=CONGREGATED
  member, // affiliation=MEMBER
  leader, // TODO: integração de liderança (futuro)
  somaLeader, // TODO: ExtensionSubscription SOMA ativa (futuro)
  unitAdmin, // TODO: criou/administra a unidade (futuro)
}
