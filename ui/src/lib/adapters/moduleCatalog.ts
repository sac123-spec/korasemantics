import { extractBlocks, parseAttributes } from './terraformParser';

export interface ModuleDefinition {
  id: string;
  path: string;
  variables: Array<{
    name: string;
    description?: string;
    type?: string;
    defaultValue?: string;
    required: boolean;
  }>;
}

export const loadModuleCatalog = (): ModuleDefinition[] => {
  const variableFiles = import.meta.glob<string>('#infrastructure/terraform/modules/*/variables.tf', {
    eager: true,
    as: 'raw',
  });

  return Object.entries(variableFiles).map(([path, content]) => {
    const id = path.split('/').at(-2) ?? path;
    const blocks = extractBlocks('variable', content);
    return {
      id,
      path,
      variables: blocks.map((block) => {
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
      }),
    };
  });
};
