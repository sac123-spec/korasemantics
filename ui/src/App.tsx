import { Box, Flex } from '@chakra-ui/react';
import { Navigate, Route, Routes } from 'react-router-dom';
import { EnvironmentSidebar } from './components/EnvironmentSidebar';
import { EnvironmentDashboard } from './routes/EnvironmentDashboard';
import { useEnvironments } from './lib/hooks/useEnvironments';

const App: React.FC = () => {
  const environments = useEnvironments();

  return (
    <Flex minH="100vh" bg="gray.950" color="gray.50">
      <EnvironmentSidebar environments={environments} />
      <Box flex="1" p={8} overflowY="auto">
        <Routes>
          <Route path="/" element={<Navigate to={environments[0] ? `/environments/${environments[0].id}` : '/empty'} />} />
          <Route path="/environments/:environmentId" element={<EnvironmentDashboard />} />
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
      </Box>
    </Flex>
  );
};

export default App;
