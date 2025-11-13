# Kora Semantics Platform Prototype

This repository contains a lightweight prototype of the Kora Semantics control plane, metadata index, storage abstraction, and asset workspace UI. It is intended to demonstrate how tenants, projects, and workspaces can be administered while offering discovery, permissioning, and lineage visibility for notebooks, libraries, and model artifacts.

## Project layout

```
backend/
  app/
    database.py      # SQLAlchemy session and SQLite configuration
    main.py          # FastAPI application exposing control plane and metadata APIs
    metadata.py      # In-memory metadata indexing and search service
    models.py        # SQLAlchemy ORM models & Pydantic schemas
    storage.py       # Object storage integration layer with fine-grained IAM policies
  requirements.txt  # Python dependencies for the API server
frontend/
  index.html        # Single-page application shell
  app.js            # UI logic for assets, permissions, and lineage tabs
  styles.css        # Design system for the workspace pages
```

## Running the API

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

The API will start on `http://localhost:8000`.

## Serving the workspace UI

Any static web server can host the frontend files. While the API is running, open a new terminal and run:

```bash
cd frontend
python -m http.server 5173
```

Navigate to `http://localhost:5173` and the UI will call the API at `http://localhost:8000`. Set `window.API_URL` before loading the script if the backend runs on a different origin.

## Capabilities

* **Control plane modeling** – Tenants, projects, workspaces, users, roles, and assignments are persisted with SQLAlchemy models and exposed through REST endpoints for CRUD flows.
* **Fine-grained storage policies** – Storage profiles register S3, GCS, or ADLS style buckets and allow presigned URL generation alongside IAM policy updates per role and resource.
* **Metadata indexing & search** – A dedicated service indexes metadata entries for assets, enabling type, tag, and full-text search via `/metadata/search`.
* **Workspace UI** – The frontend provides three tabs: asset catalog browsing with filters, permission management with role assignment forms, and metadata-derived lineage summaries.

## Sample workflow

1. Create a tenant, project, workspace, storage profile, role, and user via the API.
2. Register assets and metadata entries tied to the workspace.
3. Use the Permissions tab to grant the user access to the workspace.
4. Explore the Assets and Lineage tabs to confirm metadata indexing and relationships.

## API quick reference

| Endpoint | Description |
| --- | --- |
| `POST /tenants` | Create a tenant |
| `POST /projects` | Create a project under a tenant |
| `POST /workspaces` | Register a workspace for a project |
| `POST /roles`, `GET /roles` | Manage role definitions |
| `POST /users`, `GET /users` | Manage user directory entries |
| `POST /workspaces/{id}/assignments` | Grant a role to a user within a workspace |
| `POST /assets`, `GET /assets` | Register or list registered assets |
| `POST /metadata` | Add metadata entries to an asset |
| `GET /metadata/search` | Filter assets by type, tags, or keyword |
| `POST /storage/profiles` | Register an object storage profile |
| `POST /storage/{profile}/policy/{role}` | Attach IAM policy JSON to a role for a resource path |
| `GET /storage/{profile}/url` | Generate a presigned URL for notebooks, libraries, or checkpoints |

This prototype offers a foundation for future enhancements such as background sync, lineage graph visualizations, and policy propagation to cloud providers.
