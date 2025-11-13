import { VStack, Heading, Divider, Button } from '@chakra-ui/react';
import { Link, useLocation } from 'react-router-dom';

interface EnvironmentSidebarProps {
  environments: Array<{ id: string }>;
}

export const EnvironmentSidebar: React.FC<EnvironmentSidebarProps> = ({ environments }) => {
  const location = useLocation();

  return (
    <VStack align="stretch" spacing={4} p={6} bg="gray.900" minW="240px" h="100%">
      <Heading size="md" color="gray.100">
        Environments
      </Heading>
      <Divider borderColor="gray.700" />
      <VStack align="stretch" spacing={2}>
        {environments.map((env) => {
          const isActive = location.pathname.includes(env.id);
          return (
            <Button
              as={Link}
              to={`/environments/${env.id}`}
              key={env.id}
              justifyContent="flex-start"
              variant={isActive ? 'solid' : 'ghost'}
              colorScheme="teal"
            >
              {env.id}
            </Button>
          );
        })}
      </VStack>
    </VStack>
  );
};
