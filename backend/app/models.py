"""Domain models for the control plane and metadata services."""
from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, JSON, String, Table
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


# Association table for many-to-many relationships between workspaces and assets
workspace_assets = Table(
    "workspace_assets",
    Base.metadata,
    Column("workspace_id", ForeignKey("workspaces.id"), primary_key=True),
    Column("asset_id", ForeignKey("assets.id"), primary_key=True),
)


class Tenant(Base):
    __tablename__ = "tenants"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String, unique=True, index=True)
    description: Mapped[Optional[str]] = mapped_column(String)

    projects: Mapped[List["Project"]] = relationship("Project", back_populates="tenant")


class Project(Base):
    __tablename__ = "projects"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String, index=True)
    description: Mapped[Optional[str]] = mapped_column(String)
    tenant_id: Mapped[int] = mapped_column(ForeignKey("tenants.id"))

    tenant: Mapped[Tenant] = relationship("Tenant", back_populates="projects")
    workspaces: Mapped[List["Workspace"]] = relationship("Workspace", back_populates="project")


class Workspace(Base):
    __tablename__ = "workspaces"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String, index=True)
    description: Mapped[Optional[str]] = mapped_column(String)
    project_id: Mapped[int] = mapped_column(ForeignKey("projects.id"))
    default_storage_profile: Mapped[Optional[str]] = mapped_column(String)

    project: Mapped[Project] = relationship("Project", back_populates="workspaces")
    role_assignments: Mapped[List["RoleAssignment"]] = relationship(
        "RoleAssignment", back_populates="workspace", cascade="all, delete-orphan"
    )
    assets: Mapped[List["Asset"]] = relationship(
        "Asset", secondary=workspace_assets, back_populates="workspaces"
    )


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String, unique=True, index=True)
    display_name: Mapped[Optional[str]] = mapped_column(String)
    active: Mapped[bool] = mapped_column(Boolean, default=True)

    role_assignments: Mapped[List["RoleAssignment"]] = relationship("RoleAssignment", back_populates="user")


class Role(Base):
    __tablename__ = "roles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String, unique=True)
    description: Mapped[Optional[str]] = mapped_column(String)
    permissions: Mapped[dict] = mapped_column(JSON, default=dict)

    assignments: Mapped[List["RoleAssignment"]] = relationship("RoleAssignment", back_populates="role")


class RoleAssignment(Base):
    __tablename__ = "role_assignments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    workspace_id: Mapped[int] = mapped_column(ForeignKey("workspaces.id"))
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    role_id: Mapped[int] = mapped_column(ForeignKey("roles.id"))
    scope: Mapped[str] = mapped_column(String, default="workspace")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    workspace: Mapped[Workspace] = relationship("Workspace", back_populates="role_assignments")
    user: Mapped[User] = relationship("User", back_populates="role_assignments")
    role: Mapped[Role] = relationship("Role", back_populates="assignments")


class Asset(Base):
    __tablename__ = "assets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String)
    asset_type: Mapped[str] = mapped_column(String)
    uri: Mapped[str] = mapped_column(String)
    workspace_default: Mapped[bool] = mapped_column(Boolean, default=False)

    workspaces: Mapped[List[Workspace]] = relationship(
        "Workspace", secondary=workspace_assets, back_populates="assets"
    )
    metadata_entries: Mapped[List["MetadataEntry"]] = relationship(
        "MetadataEntry", back_populates="asset", cascade="all, delete-orphan"
    )


class MetadataEntry(Base):
    __tablename__ = "metadata_entries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    asset_id: Mapped[int] = mapped_column(ForeignKey("assets.id"))
    key: Mapped[str] = mapped_column(String, index=True)
    value: Mapped[str] = mapped_column(String)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    asset: Mapped[Asset] = relationship("Asset", back_populates="metadata_entries")


# -----------------------------
# Pydantic schemas
# -----------------------------


class RoleCreate(BaseModel):
    name: str
    description: Optional[str] = None
    permissions: dict = Field(default_factory=dict)


class RoleRead(RoleCreate):
    id: int

    class Config:
        orm_mode = True


class RoleAssignmentCreate(BaseModel):
    user_id: int
    role_id: int
    scope: str = Field(default="workspace", description="Scope of the role assignment")


class RoleAssignmentRead(RoleAssignmentCreate):
    id: int
    workspace_id: int
    created_at: datetime

    class Config:
        orm_mode = True


class WorkspaceCreate(BaseModel):
    name: str
    description: Optional[str] = None
    project_id: int
    default_storage_profile: Optional[str] = None


class WorkspaceRead(WorkspaceCreate):
    id: int

    class Config:
        orm_mode = True


class UserCreate(BaseModel):
    email: str
    display_name: Optional[str] = None
    active: bool = True


class UserRead(UserCreate):
    id: int

    class Config:
        orm_mode = True


class TenantCreate(BaseModel):
    name: str
    description: Optional[str] = None


class TenantRead(TenantCreate):
    id: int

    class Config:
        orm_mode = True


class ProjectCreate(BaseModel):
    name: str
    tenant_id: int
    description: Optional[str] = None


class ProjectRead(ProjectCreate):
    id: int

    class Config:
        orm_mode = True


class AssetCreate(BaseModel):
    name: str
    asset_type: str
    uri: str
    workspace_ids: List[int]
    workspace_default: bool = False


class AssetRead(BaseModel):
    id: int
    name: str
    asset_type: str
    uri: str
    workspace_default: bool
    metadata_entries: List[MetadataEntryRead] = Field(default_factory=list)
    workspaces: List[WorkspaceRead] = Field(default_factory=list)

    class Config:
        orm_mode = True


class MetadataEntryCreate(BaseModel):
    asset_id: int
    key: str
    value: str


class MetadataEntryRead(MetadataEntryCreate):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True
