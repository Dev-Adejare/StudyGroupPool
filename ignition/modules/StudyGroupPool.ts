import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StudyGroupPoolModule = buildModule("StudyGroupPoolModule", (m) => {

  const StudyGroupPoolModule = m.contract("StudyGroupPool", );

  return { StudyGroupPoolModule };
});

export default StudyGroupPoolModule;