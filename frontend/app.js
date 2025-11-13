const { html } = window.htm;
const { render } = window.preact;

const API_URL = window.API_URL || "http://localhost:8000";

const state = {
  loading: true,
  error: null,
  assets: [],
  filteredAssets: [],
  workspaces: [],
  roles: [],
  users: [],
  assignments: [],
  filters: {
    text: "",
    type: "",
    tags: "",
  },
  lineage: [],
};

async function fetchJSON(path, options = {}) {
  const response = await fetch(`${API_URL}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(errorText || response.statusText);
  }
  if (response.status === 204) return null;
  return response.json();
}

function buildLineage(assets) {
  return assets.map((asset) => {
    const dependencies = asset.metadata_entries
      .filter((entry) => entry.key.toLowerCase().includes("depends_on"))
      .flatMap((entry) => entry.value.split(",").map((item) => item.trim()).filter(Boolean));
    const downstream = assets
      .filter((candidate) =>
        candidate.metadata_entries.some((entry) =>
          entry.key.toLowerCase().includes("depends_on") && entry.value.includes(asset.name)
        )
      )
      .map((candidate) => candidate.name);
    return { asset, dependencies, downstream };
  });
}

function workspaceName(workspaceId) {
  const workspace = state.workspaces.find((item) => item.id === workspaceId);
  return workspace ? workspace.name : `Workspace ${workspaceId}`;
}

function update() {
  render(AssetsSection({ state, onFilterChange, onSearch: searchAssets }), document.getElementById("assets"));
  render(PermissionsSection({ state, onAssignRole }), document.getElementById("permissions"));
  render(LineageSection({ state }), document.getElementById("lineage"));
}

function onFilterChange(event) {
  const { name, value } = event.target;
  state.filters = { ...state.filters, [name]: value };
  update();
}

async function searchAssets(event) {
  event?.preventDefault();
  try {
    state.loading = true;
    updateLoading();
    const params = new URLSearchParams();
    if (state.filters.text) params.set("text", state.filters.text);
    if (state.filters.type) params.set("asset_type", state.filters.type);
    if (state.filters.tags) params.set("tags", state.filters.tags);
    const path = `/metadata/search${params.toString() ? `?${params}` : ""}`;
    const results = await fetchJSON(path);
    state.filteredAssets = results;
    state.lineage = buildLineage(results.length ? results : state.assets);
    state.error = null;
  } catch (error) {
    console.error(error);
    state.error = error.message;
  } finally {
    state.loading = false;
    update();
  }
}

async function onAssignRole(event) {
  event.preventDefault();
  const formData = new FormData(event.target);
  const payload = {
    user_id: Number(formData.get("user_id")),
    role_id: Number(formData.get("role_id")),
    scope: formData.get("scope"),
  };
  const workspaceId = Number(formData.get("workspace_id"));
  try {
    await fetchJSON(`/workspaces/${workspaceId}/assignments`, {
      method: "POST",
      body: JSON.stringify(payload),
    });
    await loadAssignments();
    event.target.reset();
  } catch (error) {
    alert(`Failed to assign role: ${error.message}`);
  }
}

async function loadAssets() {
  state.assets = await fetchJSON("/assets");
  state.filteredAssets = state.assets;
  state.lineage = buildLineage(state.assets);
}

async function loadWorkspaces() {
  state.workspaces = await fetchJSON("/workspaces");
}

async function loadRoles() {
  state.roles = await fetchJSON("/roles");
}

async function loadUsers() {
  state.users = await fetchJSON("/users");
}

async function loadAssignments() {
  const assignments = await Promise.all(
    state.workspaces.map(async (workspace) => {
      const records = await fetchJSON(`/workspaces/${workspace.id}/assignments`);
      return records.map((record) => ({ ...record, workspace_id: workspace.id }));
    })
  );
  state.assignments = assignments.flat();
}

async function bootstrap() {
  try {
    state.loading = true;
    updateLoading();
    await Promise.all([loadWorkspaces(), loadRoles(), loadUsers()]);
    await loadAssets();
    await loadAssignments();
    state.error = null;
  } catch (error) {
    console.error(error);
    state.error = error.message;
  } finally {
    state.loading = false;
    update();
  }
}

function updateLoading() {
  const section = document.getElementById("assets");
  if (state.loading) {
    section.innerHTML = `<p>Loading…</p>`;
  }
}

function AssetsSection({ state, onFilterChange, onSearch }) {
  const assetTypes = Array.from(new Set(state.assets.map((asset) => asset.asset_type))).sort();
  return html`
    <div>
      <h2>Workspace Assets</h2>
      <p>Search across notebooks, datasets, features, and ML models with semantic filters.</p>
      <form onSubmit=${onSearch}>
        <label>
          Keyword search
          <input name="text" type="search" value=${state.filters.text} onInput=${onFilterChange} placeholder="e.g. churn notebook" />
        </label>
        <label>
          Asset type
          <select name="type" value=${state.filters.type} onInput=${onFilterChange}>
            <option value="">All types</option>
            ${assetTypes.map((type) => html`<option value=${type}>${type}</option>`)}
          </select>
        </label>
        <label>
          Tags (comma separated)
          <input name="tags" value=${state.filters.tags} onInput=${onFilterChange} placeholder="owner:ml-platform,product:fraud" />
        </label>
        <button type="submit">Search assets</button>
      </form>
      ${state.error ? html`<p role="alert">${state.error}</p>` : null}
      <div class="asset-grid" aria-live="polite">
        ${state.filteredAssets.map((asset) => html`
          <article class="asset-card" key=${asset.id}>
            <span class="badge">${asset.asset_type}</span>
            <h3>${asset.name}</h3>
            <p>${asset.uri}</p>
            <div>
              <strong>Workspaces</strong>
              <ul>
                ${asset.workspaces.map((workspace) => html`<li key=${workspace.id}>${workspace.name}</li>`)}
              </ul>
            </div>
            ${asset.metadata_entries.length
              ? html`<div>
                  <strong>Metadata</strong>
                  <ul>
                    ${asset.metadata_entries.map((entry) => html`<li key=${entry.id}><code>${entry.key}</code>: ${entry.value}</li>`)}
                  </ul>
                </div>`
              : html`<p>No metadata indexed yet.</p>`}
          </article>
        `)}
      </div>
    </div>
  `;
}

function PermissionsSection({ state, onAssignRole }) {
  return html`
    <div>
      <h2>Access control</h2>
      <p>Role assignments ensure notebooks, libraries, and checkpoints honor IAM boundaries.</p>
      <table>
        <thead>
          <tr>
            <th>Workspace</th>
            <th>User</th>
            <th>Role</th>
            <th>Scope</th>
            <th>Granted</th>
          </tr>
        </thead>
        <tbody>
          ${state.assignments.length === 0
            ? html`<tr><td colspan="5">No role assignments have been configured.</td></tr>`
            : state.assignments.map((assignment) => {
                const user = state.users.find((candidate) => candidate.id === assignment.user_id);
                const role = state.roles.find((candidate) => candidate.id === assignment.role_id);
                return html`
                  <tr key=${assignment.id}>
                    <td>${workspaceName(assignment.workspace_id)}</td>
                    <td>${user ? user.display_name || user.email : assignment.user_id}</td>
                    <td>${role ? role.name : assignment.role_id}</td>
                    <td>${assignment.scope}</td>
                    <td>${new Date(assignment.created_at).toLocaleString()}</td>
                  </tr>
                `;
              })}
        </tbody>
      </table>
      <form onSubmit=${onAssignRole}>
        <fieldset>
          <legend>Assign role</legend>
          <label>
            Workspace
            <select name="workspace_id" required>
              <option value="">Select workspace</option>
              ${state.workspaces.map((workspace) => html`<option value=${workspace.id}>${workspace.name}</option>`)}
            </select>
          </label>
          <label>
            User
            <select name="user_id" required>
              <option value="">Select user</option>
              ${state.users.map((user) => html`<option value=${user.id}>${user.display_name || user.email}</option>`)}
            </select>
          </label>
          <label>
            Role
            <select name="role_id" required>
              <option value="">Select role</option>
              ${state.roles.map((role) => html`<option value=${role.id}>${role.name}</option>`)}
            </select>
          </label>
          <label>
            Scope
            <input name="scope" value="workspace" />
          </label>
          <button type="submit">Grant access</button>
        </fieldset>
      </form>
    </div>
  `;
}

function LineageSection({ state }) {
  return html`
    <div>
      <h2>Lineage explorer</h2>
      <p>Metadata-derived relationships reveal upstream dependencies and downstream consumers.</p>
      <div class="lineage-list">
        ${state.lineage.map((item) => html`
          <div class="lineage-item" key=${item.asset.id}>
            <div><strong>${item.asset.name}</strong></div>
            <div>Depends on: ${item.dependencies.length ? item.dependencies.join(", ") : "—"}</div>
            <div>Feeds: ${item.downstream.length ? item.downstream.join(", ") : "—"}</div>
          </div>
        `)}
      </div>
    </div>
  `;
}

bootstrap();

document.querySelectorAll("nav button").forEach((button) => {
  button.addEventListener("click", () => {
    const tab = button.dataset.tab;
    document.querySelectorAll("nav button").forEach((element) => element.classList.toggle("active", element === button));
    document.querySelectorAll("main section").forEach((section) => {
      section.hidden = section.id !== tab;
    });
  });
});
