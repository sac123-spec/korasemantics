"""Storage integration layer supporting S3, GCS and ADLS."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Dict, Protocol


class StorageClient(Protocol):
    """Protocol describing required storage client operations."""

    def generate_presigned_url(self, path: str, *, expires_in: int = 3600) -> str:
        ...

    def put_iam_policy(self, path: str, policy: Dict[str, str]) -> None:
        ...


@dataclass
class StorageProfile:
    """Describe a logical storage bucket and access policy."""

    name: str
    bucket: str
    iam_policies: Dict[str, Dict[str, str]]  # mapping of role -> policy document


class S3StorageClient:
    """Mocked S3 storage client that demonstrates IAM policy delegation."""

    def __init__(self, profile: StorageProfile) -> None:
        self.profile = profile

    def generate_presigned_url(self, path: str, *, expires_in: int = 3600) -> str:
        expiry = datetime.utcnow() + timedelta(seconds=expires_in)
        return f"s3://{self.profile.bucket}/{path}?expires={expiry.isoformat()}"

    def put_iam_policy(self, path: str, policy: Dict[str, str]) -> None:
        self.profile.iam_policies[path] = policy


class GCSStorageClient(S3StorageClient):
    def generate_presigned_url(self, path: str, *, expires_in: int = 3600) -> str:
        expiry = datetime.utcnow() + timedelta(seconds=expires_in)
        return f"gs://{self.profile.bucket}/{path}?Expires={int(expiry.timestamp())}"


class ADLSStorageClient(S3StorageClient):
    def generate_presigned_url(self, path: str, *, expires_in: int = 3600) -> str:
        expiry = datetime.utcnow() + timedelta(seconds=expires_in)
        return f"abfss://{self.profile.bucket}@dfs.core.windows.net/{path}?se={expiry.isoformat()}"


class StorageRegistry:
    """Registry that resolves storage clients and enforces fine-grained IAM policies."""

    def __init__(self) -> None:
        self._profiles: Dict[str, StorageProfile] = {}

    def register_profile(self, profile: StorageProfile) -> None:
        self._profiles[profile.name] = profile

    def get_client(self, profile_name: str, provider: str) -> StorageClient:
        profile = self._profiles[profile_name]
        if provider == "s3":
            return S3StorageClient(profile)
        if provider == "gcs":
            return GCSStorageClient(profile)
        if provider == "adls":
            return ADLSStorageClient(profile)
        raise ValueError(f"Unsupported provider: {provider}")

    def update_policy(self, profile_name: str, resource_path: str, role: str, policy: Dict[str, str]) -> None:
        profile = self._profiles[profile_name]
        profile.iam_policies.setdefault(role, {})[resource_path] = policy


storage_registry = StorageRegistry()
