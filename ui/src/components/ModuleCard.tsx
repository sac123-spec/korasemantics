import {
  Box,
  Heading,
  Text,
  Stack,
  Badge,
  Table,
  Tbody,
  Tr,
  Td,
  TableContainer,
  Tag,
  HStack,
} from '@chakra-ui/react';
import { EnvironmentModule } from '../lib/adapters/environmentMetadata';
import { ModuleDefinition } from '../lib/adapters/moduleCatalog';
import { ModuleStatus } from '../lib/adapters/mockAwsStatus';

interface ModuleCardProps {
  module: EnvironmentModule & {
    moduleId: string;
    definition?: ModuleDefinition;
    status: ModuleStatus;
  };
}

export const ModuleCard: React.FC<ModuleCardProps> = ({ module }) => {
  const statusColor = module.status.status === 'healthy' ? 'green' : module.status.status === 'warning' ? 'yellow' : 'red';

  return (
    <Box borderWidth="1px" borderRadius="lg" p={6} bg="gray.800" borderColor="gray.700" shadow="sm">
      <Stack spacing={4}>
        <HStack justify="space-between">
          <Heading size="md" color="gray.100">
            {module.moduleId}
          </Heading>
          <Badge colorScheme={statusColor}>{module.status.status.toUpperCase()}</Badge>
        </HStack>
        <Text color="gray.400" fontSize="sm">
          {module.status.summary}
        </Text>
        {module.definition && module.definition.variables.length > 0 && (
          <Box>
            <Heading size="sm" mb={2} color="gray.200">
              Module Inputs
            </Heading>
            <TableContainer>
              <Table size="sm" variant="simple">
                <Tbody>
                  {module.definition.variables.map((variable) => (
                    <Tr key={variable.name}>
                      <Td>
                        <Stack spacing={1}>
                          <Text fontWeight="bold" color="gray.100">
                            {variable.name}
                          </Text>
                          {variable.description && (
                            <Text color="gray.400" fontSize="xs">
                              {variable.description}
                            </Text>
                          )}
                        </Stack>
                      </Td>
                      <Td>
                        <Stack spacing={2}>
                          {variable.type && (
                            <Tag colorScheme="cyan" size="sm">
                              {variable.type}
                            </Tag>
                          )}
                          <Text color="gray.300" fontSize="xs">
                            {variable.required ? 'Required' : `Default: ${variable.defaultValue ?? 'n/a'}`}
                          </Text>
                        </Stack>
                      </Td>
                    </Tr>
                  ))}
                </Tbody>
              </Table>
            </TableContainer>
          </Box>
        )}
        <Box>
          <Heading size="sm" mb={2} color="gray.200">
            Terraform Attributes
          </Heading>
          <TableContainer>
            <Table size="sm" variant="simple">
              <Tbody>
                {module.attributes.map((attr) => (
                  <Tr key={attr.key}>
                    <Td width="40%">
                      <Text fontWeight="medium" color="gray.200">
                        {attr.key}
                      </Text>
                    </Td>
                    <Td>
                      <Text color="gray.300" fontSize="sm" whiteSpace="pre-wrap">
                        {attr.value}
                      </Text>
                    </Td>
                  </Tr>
                ))}
              </Tbody>
            </Table>
          </TableContainer>
        </Box>
      </Stack>
    </Box>
  );
};
