"""FastAPI application exposing control plane and metadata APIs."""
from __future__ import annotations

from typing import Dict, List, Optional

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from . import metadata as metadata_service_module
from .database import Base, SessionLocal, engine
from .models import (
    Asset,
    AssetCreate,
    AssetRead,
    MetadataEntry,
    MetadataEntryCreate,
    MetadataEntryRead,
    Project,
    ProjectCreate,
    ProjectRead,
    Role,
    RoleCreate,
    RoleRead,
    RoleAssignment,
    RoleAssignmentCreate,
    RoleAssignmentRead,
    Tenant,
    TenantCreate,
    TenantRead,
    Workspace,
    WorkspaceCreate,
    WorkspaceRead,
    User,
    UserCreate,
    UserRead,
)
from .storage import StorageProfile, storage_registry

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Kora Semantics Control Plane")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"]
    ,
    allow_headers=["*"],
)


def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# -----------------------------
# Tenant and project management
# -----------------------------


@app.post("/tenants", response_model=TenantRead)
def create_tenant(tenant: TenantCreate, db: Session = Depends(get_db)) -> Tenant:
    instance = Tenant(**tenant.dict())
    db.add(instance)
    db.commit()
    db.refresh(instance)
    return instance


@app.get("/tenants", response_model=List[TenantRead])
def list_tenants(db: Session = Depends(get_db)) -> List[Tenant]:
    return db.query(Tenant).all()


@app.post("/projects", response_model=ProjectRead)
def create_project(project: ProjectCreate, db: Session = Depends(get_db)) -> Project:
    tenant = db.get(Tenant, project.tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
    instance = Project(**project.dict())
    db.add(instance)
    db.commit()
    db.refresh(instance)
    return instance


@app.get("/projects", response_model=List[ProjectRead])
def list_projects(db: Session = Depends(get_db)) -> List[Project]:
    return db.query(Project).all()




@app.post("/users", response_model=UserRead)
def create_user(user: UserCreate, db: Session = Depends(get_db)) -> User:
    instance = User(email=user.email, display_name=user.display_name, active=user.active)
    db.add(instance)
    db.commit()
    db.refresh(instance)
    return instance


@app.get("/users", response_model=List[UserRead])
def list_users(db: Session = Depends(get_db)) -> List[User]:
    return db.query(User).all()

# -----------------------------
# Workspace metadata and role assignments
# -----------------------------


@app.post("/workspaces", response_model=WorkspaceRead)
def create_workspace(workspace: WorkspaceCreate, db: Session = Depends(get_db)) -> Workspace:
    project = db.get(Project, workspace.project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    instance = Workspace(**workspace.dict())
    db.add(instance)
    db.commit()
    db.refresh(instance)
    return instance


@app.get("/workspaces", response_model=List[WorkspaceRead])
def list_workspaces(
    project_id: Optional[int] = None, db: Session = Depends(get_db)
) -> List[Workspace]:
    query = db.query(Workspace)
    if project_id:
        query = query.filter(Workspace.project_id == project_id)
    return query.all()




@app.get("/roles", response_model=List[RoleRead])
def list_roles(db: Session = Depends(get_db)) -> List[Role]:
    return db.query(Role).all()
@app.post("/roles", response_model=RoleRead)
def create_role(role: RoleCreate, db: Session = Depends(get_db)) -> Role:
    role_instance = Role(name=role.name, description=role.description, permissions=role.permissions)
    db.add(role_instance)
    db.commit()
    db.refresh(role_instance)
    return role_instance


@app.post("/workspaces/{workspace_id}/assignments", response_model=RoleAssignmentRead)
def assign_role(
    workspace_id: int, assignment: RoleAssignmentCreate, db: Session = Depends(get_db)
) -> RoleAssignment:
    workspace = db.get(Workspace, workspace_id)
    if not workspace:
        raise HTTPException(status_code=404, detail="Workspace not found")
    role = db.get(Role, assignment.role_id)
    if not role:
        raise HTTPException(status_code=404, detail="Role not found")
    user = db.get(User, assignment.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    role_assignment = RoleAssignment(workspace_id=workspace_id, **assignment.dict())
    db.add(role_assignment)
    db.commit()
    db.refresh(role_assignment)
    return role_assignment


@app.get("/workspaces/{workspace_id}/assignments", response_model=List[RoleAssignmentRead])
def list_assignments(workspace_id: int, db: Session = Depends(get_db)) -> List[RoleAssignment]:
    return db.query(RoleAssignment).filter(RoleAssignment.workspace_id == workspace_id).all()


# -----------------------------
# Asset registration and metadata indexing
# -----------------------------


@app.get("/assets", response_model=List[AssetRead])
def list_assets(db: Session = Depends(get_db)) -> List[Asset]:
    assets = db.query(Asset).all()
    for asset in assets:
        _ = asset.metadata_entries
        _ = asset.workspaces
    return assets


@app.post("/assets", response_model=AssetRead)
def register_asset(asset: AssetCreate, db: Session = Depends(get_db)) -> Asset:
    workspaces = db.query(Workspace).filter(Workspace.id.in_(asset.workspace_ids)).all()
    if len(workspaces) != len(asset.workspace_ids):
        raise HTTPException(status_code=400, detail="Workspace list contains unknown ids")

    instance = Asset(
        name=asset.name,
        asset_type=asset.asset_type,
        uri=asset.uri,
        workspace_default=asset.workspace_default,
    )
    instance.workspaces = workspaces
    db.add(instance)
    db.commit()
    db.refresh(instance)
    _ = instance.workspaces
    _ = instance.metadata_entries
    metadata_service_module.metadata_service.rebuild_index(db)
    return instance


@app.post("/metadata", response_model=MetadataEntryRead)
def add_metadata(entry: MetadataEntryCreate, db: Session = Depends(get_db)) -> MetadataEntry:
    asset = db.get(Asset, entry.asset_id)
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    metadata = MetadataEntry(**entry.dict())
    db.add(metadata)
    db.commit()
    db.refresh(metadata)
    metadata_service_module.metadata_service.add_metadata(db, metadata)
    return metadata


@app.get("/metadata/search", response_model=List[AssetRead])
def search_metadata(
    asset_type: Optional[str] = None,
    text: Optional[str] = None,
    tags: Optional[str] = None,
    db: Session = Depends(get_db),
) -> List[Asset]:
    tag_list = tags.split(",") if tags else None
    results = metadata_service_module.metadata_service.search(
        db, asset_type=asset_type, text=text, tags=tag_list
    )
    return results


# -----------------------------
# Storage profiles
# -----------------------------


@app.post("/storage/profiles", response_model=str)
def create_storage_profile(name: str, bucket: str, db: Session = Depends(get_db)) -> str:
    profile = StorageProfile(name=name, bucket=bucket, iam_policies={})
    storage_registry.register_profile(profile)
    return profile.name


@app.post("/storage/{profile_name}/policy/{role}")
def update_storage_policy(
    profile_name: str, role: str, resource_path: str, policy: dict
) -> Dict[str, Dict[str, str]]:
    storage_registry.update_policy(profile_name, resource_path, role, policy)
    return storage_registry._profiles[profile_name].iam_policies


@app.get("/storage/{profile_name}/url")
def generate_presigned_url(profile_name: str, provider: str, path: str) -> str:
    client = storage_registry.get_client(profile_name, provider)
    return client.generate_presigned_url(path)
