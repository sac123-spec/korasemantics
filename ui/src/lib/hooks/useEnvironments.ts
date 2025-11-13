import { useMemo } from 'react';
import { loadEnvironmentMetadata } from '../adapters/environmentMetadata';
import { loadModuleCatalog } from '../adapters/moduleCatalog';
import { getMockModuleStatus } from '../adapters/mockAwsStatus';

export const useEnvironments = () => {
  return useMemo(() => {
    const environments = loadEnvironmentMetadata();
    const modules = loadModuleCatalog();

    return environments.map((env) => {
      const detailedModules = env.modules.map((module) => {
        const moduleId = module.source?.split('/').at(-1) ?? module.name;
        const definition = modules.find((mod) => mod.id === moduleId);
        const status = getMockModuleStatus(moduleId);
        return {
          ...module,
          moduleId,
          definition,
          status,
        };
      });

      return {
        ...env,
        modules: detailedModules,
      };
    });
  }, []);
};
