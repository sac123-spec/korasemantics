import { extractBlocks, parseAttributes, TerraformAttribute } from './terraformParser';

export interface EnvironmentModule {
  name: string;
  source?: string;
  attributes: TerraformAttribute[];
  rawBody: string;
}

export interface EnvironmentVariable {
  name: string;
  description?: string;
  type?: string;
  defaultValue?: string;
  required: boolean;
}

export interface EnvironmentMetadata {
  id: string;
  path: string;
  modules: EnvironmentModule[];
  variables: EnvironmentVariable[];
}

export const loadEnvironmentMetadata = (): EnvironmentMetadata[] => {
  const mainFiles = import.meta.glob<string>('#infrastructure/terraform/envs/*/main.tf', {
    eager: true,
    as: 'raw',
  });
  const variableFiles = import.meta.glob<string>('#infrastructure/terraform/envs/*/variables.tf', {
    eager: true,
    as: 'raw',
  });

  return Object.entries(mainFiles).map(([path, content]) => {
    const id = path.split('/').at(-2) ?? path;
    const variablesContent = variableFiles[path.replace('main.tf', 'variables.tf')];

    return {
      id,
      path,
      modules: parseModules(content),
      variables: variablesContent ? parseVariables(variablesContent) : [],
    };
  });
};

const parseModules = (content: string): EnvironmentModule[] => {
  const moduleBlocks = extractBlocks('module', content);

  return moduleBlocks.map((block) => {
    const attributes = parseAttributes(block.body);
    const sourceAttr = attributes.find((attr) => attr.key === 'source');
    return {
      name: block.name,
      source: sourceAttr?.value.replace(/\"/g, ''),
      attributes,
      rawBody: block.body,
    };
  });
};

const parseVariables = (content: string): EnvironmentVariable[] => {
  const variableBlocks = extractBlocks('variable', content);

  return variableBlocks.map((block) => {
    const attributes = parseAttributes(block.body);
    const description = attributes.find((attr) => attr.key === 'description')?.value.replace(/^"|"$/g, '');
    const type = attributes.find((attr) => attr.key === 'type')?.value;
    const defaultValue = attributes.find((attr) => attr.key === 'default')?.value;
    return {
      name: block.name,
      description,
      type,
      defaultValue,
      required: defaultValue === undefined,
    };
  });
};
