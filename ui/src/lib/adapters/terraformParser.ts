export interface TerraformBlock {
  name: string;
  body: string;
}

export const extractBlocks = (type: string, content: string): TerraformBlock[] => {
  const blocks: TerraformBlock[] = [];
  const pattern = new RegExp(`${type}\\s+\"([^\"]+)\"\\s*\\{`, 'g');
  let match: RegExpExecArray | null;

  while ((match = pattern.exec(content))) {
    const name = match[1];
    let index = pattern.lastIndex;
    let depth = 1;

    while (index < content.length && depth > 0) {
      const char = content[index];
      if (char === '{') {
        depth += 1;
      } else if (char === '}') {
        depth -= 1;
      }
      index += 1;
    }

    const body = content.slice(match.index + match[0].length, index - 1).trim();
    blocks.push({ name, body });
    pattern.lastIndex = index;
  }

  return blocks;
};

export interface TerraformAttribute {
  key: string;
  value: string;
}

export const parseAttributes = (body: string): TerraformAttribute[] => {
  const attributes: TerraformAttribute[] = [];
  const lines = body.split(/\r?\n/);
  let currentKey: string | null = null;
  let buffer: string[] = [];

  const flush = () => {
    if (!currentKey) return;
    const value = buffer.join('\n').trim();
    if (value) {
      attributes.push({ key: currentKey, value });
    }
    currentKey = null;
    buffer = [];
  };

  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;

    const attributeMatch = line.match(/^([A-Za-z0-9_]+)\s*=\s*(.+)$/);
    if (attributeMatch && line.endsWith('{') === false && line.endsWith('[') === false) {
      flush();
      currentKey = attributeMatch[1];
      buffer.push(attributeMatch[2]);
    } else if (attributeMatch && (line.endsWith('{') || line.endsWith('['))) {
      flush();
      currentKey = attributeMatch[1];
      buffer.push(attributeMatch[2]);
    } else if (line === '}' || line === ']') {
      buffer.push(line);
      flush();
    } else {
      buffer.push(line);
    }
  }

  flush();

  return attributes;
};
