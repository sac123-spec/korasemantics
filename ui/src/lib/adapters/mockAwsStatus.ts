export interface ModuleStatus {
  id: string;
  status: 'healthy' | 'warning' | 'error';
  lastChecked: string;
  summary: string;
}

const randomStatuses: ModuleStatus['status'][] = ['healthy', 'warning'];

export const getMockModuleStatus = (moduleId: string): ModuleStatus => {
  const status = randomStatuses[Math.floor(moduleId.length % randomStatuses.length)];
  return {
    id: moduleId,
    status,
    lastChecked: new Date().toISOString(),
    summary:
      status === 'healthy'
        ? 'Terraform state is in sync and latest apply succeeded.'
        : 'Awaiting initial apply or drift detected in mock data.',
  };
};
