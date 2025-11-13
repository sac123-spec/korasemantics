import { useMemo } from 'react';
import { useParams } from 'react-router-dom';
import { Box, Heading, SimpleGrid, Stack, Text, Alert, AlertIcon } from '@chakra-ui/react';
import { useEnvironments } from '../lib/hooks/useEnvironments';
import { ModuleCard } from '../components/ModuleCard';

export const EnvironmentDashboard: React.FC = () => {
  const params = useParams();
  const environments = useEnvironments();

  const environment = useMemo(
    () => environments.find((env) => env.id === params.environmentId),
    [environments, params.environmentId]
  );

  if (!environment) {
    return (
      <Alert status="warning" borderRadius="md">
        <AlertIcon /> The selected environment could not be found in infrastructure/terraform/envs.
      </Alert>
    );
  }

  return (
    <Stack spacing={6} align="stretch">
      <Box>
        <Heading size="lg" color="gray.100">
          {environment.id.toUpperCase()} Environment
        </Heading>
        <Text color="gray.400" mt={2}>
          Data is derived directly from Terraform configuration files. AWS runtime information is mocked until live APIs
          are integrated.
        </Text>
      </Box>
      <SimpleGrid columns={{ base: 1, md: 2 }} spacing={6}>
        {environment.modules.map((module) => (
          <ModuleCard key={module.moduleId} module={module} />
        ))}
      </SimpleGrid>
    </Stack>
  );
};
